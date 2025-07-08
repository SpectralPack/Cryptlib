function Card:has_stickers()
	for i, v in pairs(SMODS.Sticker.obj_table) do
		if self.ability[i] then
			return true
		end
	end
end
function Card:remove_random_sticker(seed)
	local s = {}
	for i, v in pairs(SMODS.Sticker.obj_table) do
		if not v.hidden and i ~= "cry_absolute" and self.ability[i] then
			s[#s + 1] = i
		end
	end
	if #s > 0 then
		local sticker = pseudorandom_element(s, pseudoseed(seed))
		self.ability[sticker] = nil
		if sticker == "perishable" then
			self.ability.perish_tally = nil
		end
	end
end

function Cryptid.table_merge(t1, t2)
	local tbl = {}
	for i, v in pairs(t1) do
		tbl[#tbl + 1] = v
	end
	for i, v in pairs(t2) do
		tbl[#tbl + 1] = v
	end
	return tbl
end

function Cryptid.get_highlighted_cards(areas, ignore, min, max, blacklist, seed)
	ignore.checked = true
	blacklist = blacklist or function()
		return true
	end
	local cards = {}
	for i, area in pairs(areas) do
		if area.cards then
			for i2, card in pairs(area.cards) do
				if
					card ~= ignore
					and blacklist(card)
					and (card.highlighted or G.cry_force_use)
					and not card.checked
				then
					cards[#cards + 1] = card
					card.checked = true
				end
			end
		end
	end
	for i, v in ipairs(cards) do
		v.checked = nil
	end
	if (#cards >= min and #cards <= max) or not G.cry_force_use then
		ignore.checked = nil
		return cards
	else
		for i, v in pairs(cards) do
			v.f_use_order = i
		end
		pseudoshuffle(cards, pseudoseed("forcehighlight" or seed))
		local actual = {}
		for i = 1, max do
			if cards[i] and not cards[i].checked and actual ~= ignore then
				actual[#actual + 1] = cards[i]
			end
		end
		table.sort(actual, function(a, b)
			return a.f_use_order < b.f_use_order
		end)
		for i, v in pairs(cards) do
			v.f_use_order = nil
		end
		ignore.checked = nil
		return actual
	end
	return {}
end

function Card:is_food()
	--you cant really check if vanilla jokers are in a pool because its hardcoded
	--so i have to hardcode it here too for the starfruit unlock
	local food = {
		j_gros_michel = true,
		j_egg = true,
		j_ice_cream = true,
		j_cavendish = true,
		j_turtle_bean = true,
		j_diet_cola = true,
		j_popcorn = true,
		j_ramen = true,
		j_selzer = true,
	}
	if food[self.config.center.key] or Cryptid.safe_get(self.config.center, "pools", "Food") then
		return true
	end
end

function Cryptid.cry_rankname_to_id(rankname)
	for i, v in pairs(SMODS.Rank.obj_buffer) do
		if rankname == v then
			return i
		end
	end
	return nil
end

--Utility function to check things without erroring
---@param t table
---@param ... any
---@return table|false
function Cryptid.safe_get(t, ...)
	local current = t
	for _, k in ipairs({ ... }) do
		if not current or current[k] == nil then
			return false
		end
		current = current[k]
	end
	return current
end

function Cryptid.is_card_big(joker)
	if not Talisman then
		return false
	end
	local center = joker.config and joker.config.center
	if not center then
		return false
	end

	if center.immutable and center.immutable == true then
		return false
	end
    -- im making bignums not work with Cryptid. since i dont see the point
    -- could be changed but i dont feel like making 2 blacklists or making this mod use the cryptid table either
	if center.mod and not (Cryptid or {}).mod_whitelist[center.mod.name] then
		return false
	end

	local in_blacklist = (Cryptid or {}).big_num_blacklist[center.key or "Nope!"] or false

	return not in_blacklist --[[or
	       (center.mod and center.mod.id == "Cryptid" and not center.no_break_infinity) or center.break_infinity--]]
end

-- Check G.GAME as well as joker info for banned keys
function Card:no(m, no_no)
	if no_no then
		-- Infinifusion Compat
		if self.infinifusion then
			for i = 1, #self.infinifusion do
				if
					G.P_CENTERS[self.infinifusion[i].key][m]
					or (G.GAME and G.GAME[m] and G.GAME[m][self.infinifusion[i].key])
				then
					return true
				end
			end
			return false
		end
		if not self.config then
			--assume this is from one component of infinifusion
			return G.P_CENTERS[self.key][m] or (G.GAME and G.GAME[m] and G.GAME[m][self.key])
		end

		return self.config.center[m] or (G.GAME and G.GAME[m] and G.GAME[m][self.config.center_key]) or false
	end
	return Card.no(self, "no_" .. m, true)
end

function Cryptid.no(center, m, key, no_no)
	if no_no then
		return center[m] or (G.GAME and G.GAME[m] and G.GAME[m][key]) or false
	end
	return Cryptid.no(center, "no_" .. m, key, true)
end

function Cryptid.deck_effects(card, func)
	if not card.added_to_deck then
		return func(card)
	else
		card.from_quantum = true
		card:remove_from_deck(true)
		local ret = func(card)
		card:add_to_deck(true)
		card.from_quantum = nil
		return ret
	end
end

function Cryptid.deep_copy(obj, seen)
	if type(obj) ~= "table" then
		return obj
	end
	if seen and seen[obj] then
		return seen[obj]
	end
	local s = seen or {}
	local res = setmetatable({}, getmetatable(obj))
	s[obj] = res
	for k, v in pairs(obj) do
		res[Cryptid.deep_copy(k, s)] = Cryptid.deep_copy(v, s)
	end
	return res
end

-- generate a random edition (e.g. Antimatter Deck)
function Cryptid.poll_random_edition()
	local random_edition = pseudorandom_element(G.P_CENTER_POOLS.Edition, pseudoseed("cry_ant_edition"))
	while random_edition.key == "e_base" do
		random_edition = pseudorandom_element(G.P_CENTER_POOLS.Edition, pseudoseed("cry_ant_edition"))
	end
	ed_table = { [random_edition.key:sub(3)] = true }
	return ed_table
end

-- gets a random, valid consumeable (used for Hammerspace, CCD Deck, Blessing, etc.)
function Cryptid.random_consumable(seed, excluded_flags, banned_card, pool, no_undiscovered)
	-- set up excluded flags - these are the kinds of consumables we DON'T want to have generating
	excluded_flags = excluded_flags or { "hidden", "no_doe", "no_grc" }
	local selection = "n/a"
	local passes = 0
	local tries = 500
	while true do
		tries = tries - 1
		passes = 0
		-- create a random consumable naively
		local key = pseudorandom_element(pool or G.P_CENTER_POOLS.Consumeables, pseudoseed(seed or "grc")).key
		selection = G.P_CENTERS[key]
		-- check if it is valid
		if selection.discovered or not no_undiscovered then
			for k, v in pairs(excluded_flags) do
				if not Cryptid.no(selection, v, key, true) then
					--Makes the consumable invalid if it's a specific card unless it's set to
					--I use this so cards don't create copies of themselves (eg potential inf Blessing chain, Hammerspace from Hammerspace...)
					if not banned_card or (banned_card and banned_card ~= key) then
						passes = passes + 1
					end
				end
			end
		end
		-- use it if it's valid or we've run out of attempts
		if passes >= #excluded_flags or tries <= 0 then
			if tries <= 0 and no_undiscovered then
				return G.P_CENTERS["c_strength"]
			else
				return selection
			end
		end
	end
end

-- simple plural s function for localisation
function Cryptid.pluralize(str, vars)
	local inside = str:match("<(.-)>") -- finds args
	local _table = {}
	if inside then
		for v in inside:gmatch("[^,]+") do -- adds args to array
			table.insert(_table, v)
		end
		local num = vars[tonumber(string.match(str, ">(%d+)"))] -- gets reference variable
		if type(num) == "string" then
			num = (Big and to_number(to_big(num))) or num
		end
		if not num then
			num = 1
		end
		local plural = _table[1] -- default
		local checks = { [1] = "=" } -- checks 1 by default
		local checks1mod = false -- tracks if 1 was modified
		if #_table > 1 then
			for i = 2, #_table do
				local isnum = tonumber(_table[i])
				if isnum then
					if not checks1mod then
						checks[1] = nil
					end -- dumb stuff
					checks[isnum] = "<" .. (_table[i + 1] or "") -- do less than for custom values
					if isnum == 1 then
						checks1mod = true
					end
					i = i + 1
				elseif i == 2 then
					checks[1] = "=" .. _table[i]
				end
			end
		end
		local function fch(str, c)
			return string.sub(str, 1, 1) == c -- gets first char and returns boolean
		end
		local keys = {}
		for k in pairs(checks) do
			table.insert(keys, k)
		end
		table.sort(keys, function(a, b)
			return a < b
		end)
		if not (tonumber(num) or is_number(num)) then
			num = 1
		end
		for _, k in ipairs(keys) do
			if fch(checks[k], "=") then
				if to_big(math.abs(num - k)) < to_big(0.001) then
					return string.sub(checks[k], 2, -1)
				end
			elseif fch(checks[k], "<") then
				if to_big(num) < to_big(k - 0.001) then
					return string.sub(checks[k], 2, -1)
				end
			end
		end
		return plural
	end
end

function Cryptid.advanced_find_joker(name, rarity, edition, ability, non_debuff, area)
	local jokers = {}
	if not G.jokers or not G.jokers.cards then
		return {}
	end
	local filter = 0
	if name then
		filter = filter + 1
	end
	if edition then
		filter = filter + 1
	end
	if type(rarity) ~= "table" then
		if type(rarity) == "string" then
			rarity = { rarity }
		else
			rarity = nil
		end
	end
	if rarity then
		filter = filter + 1
	end
	if type(ability) ~= "table" then
		if type(ability) == "string" then
			ability = { ability }
		else
			ability = nil
		end
	end
	if ability then
		filter = filter + 1
	end
	-- return nothing if function is called with no useful arguments
	if filter == 0 then
		return {}
	end
	if not area or area == "j" then
		for k, v in pairs(G.jokers.cards) do
			if v and type(v) == "table" and (non_debuff or not v.debuff) then
				local check = 0
				if name and v.ability.name == name then
					check = check + 1
				end
				if
					edition
					and (v.edition and v.edition.key == edition) --[[ make this use Cryptid.safe_get later? if it's possible anyways]]
				then
					check = check + 1
				end
				if rarity then
					--Passes as valid if rarity matches ANY of the values in the rarity table
					for _, a in ipairs(rarity) do
						if v.config.center.rarity == a then
							check = check + 1
							break
						end
					end
				end
				if ability then
					--Only passes if the joker has everything in the ability table
					local abilitycheck = true
					for _, b in ipairs(ability) do
						if not v.ability[b] then
							abilitycheck = false
							break
						end
					end
					if abilitycheck then
						check = check + 1
					end
				end
				if check == filter then
					table.insert(jokers, v)
				end
			end
		end
	end
	if not area or area == "c" then
		for k, v in pairs(G.consumeables.cards) do
			if v and type(v) == "table" and (non_debuff or not v.debuff) then
				local check = 0
				if name and v.ability.name == name then
					check = check + 1
				end
				if
					edition
					and (v.edition and v.edition.key == edition) --[[ make this use Cryptid.safe_get later? if it's possible anyways]]
				then
					check = check + 1
				end
				if ability then
					--Only passes if the joker has everything in the ability table
					local abilitycheck = true
					for _, b in ipairs(ability) do
						if not v.ability[b] then
							abilitycheck = false
							break
						end
					end
					if abilitycheck then
						check = check + 1
					end
				end
				--Consumables don't have a rarity, so this should ignore it in that case (untested lmfao)
				if check == filter then
					table.insert(jokers, v)
				end
			end
		end
	end
	return jokers
end

-- backwards compat, not needed when smods updates, also doesnt do anything here really
-- mostly just to stop crashes
function cry_prob(owned, den, rigged)
	prob = G.GAME and G.GAME.probabilities.normal or 1
	if rigged then
		return to_number(math.min(den, 1e300))
	else
		if owned then return to_number(math.min(prob*owned, 1e300)) else return to_number(math.min(prob, 1e300)) end
	end
end

function Cryptid.with_deck_effects(card, func)
	if not card.added_to_deck then
		return func(card)
	else
		card.from_quantum = true
		card:remove_from_deck(true)
		local ret = func(card)
		card:add_to_deck(true)
		card.from_quantum = nil
		return ret
	end
end

local set_spritesref = Card.set_sprites
function Card:set_sprites(_center, _front)
	set_spritesref(self, _center, _front)
	if _center and _center.soul_pos and _center.soul_pos.extra then
		self.children.floating_sprite2 = Sprite(
			self.T.x,
			self.T.y,
			self.T.w,
			self.T.h,
			G.ASSET_ATLAS[_center.atlas or _center.set],
			_center.soul_pos.extra
		)
		self.children.floating_sprite2.role.draw_major = self
		self.children.floating_sprite2.states.hover.can = false
		self.children.floating_sprite2.states.click.can = false
	end
end


SMODS.DrawStep({
	key = "floating_sprite2",
	order = 59,
	func = function(self)
		if
			self.config.center.soul_pos
			and self.config.center.soul_pos.extra
			and (self.config.center.discovered or self.bypass_discovery_center)
		then
			local scale_mod = 0.07 -- + 0.02*math.cos(1.8*G.TIMERS.REAL) + 0.00*math.cos((G.TIMERS.REAL - math.floor(G.TIMERS.REAL))*math.pi*14)*(1 - (G.TIMERS.REAL - math.floor(G.TIMERS.REAL)))^3
			local rotate_mod = 0 --0.05*math.cos(1.219*G.TIMERS.REAL) + 0.00*math.cos((G.TIMERS.REAL)*math.pi*5)*(1 - (G.TIMERS.REAL - math.floor(G.TIMERS.REAL)))^2
			if self.children.floating_sprite2 then
				self.children.floating_sprite2:draw_shader(
					"dissolve",
					0,
					nil,
					nil,
					self.children.center,
					scale_mod,
					rotate_mod,
					nil,
					0.1 --[[ + 0.03*math.cos(1.8*G.TIMERS.REAL)--]],
					nil,
					0.6
				)
				self.children.floating_sprite2:draw_shader(
					"dissolve",
					nil,
					nil,
					nil,
					self.children.center,
					scale_mod,
					rotate_mod
				)
			else
				local center = self.config.center
				if _center and _center.soul_pos and _center.soul_pos.extra then
					self.children.floating_sprite2 = Sprite(
						self.T.x,
						self.T.y,
						self.T.w,
						self.T.h,
						G.ASSET_ATLAS[_center.atlas or _center.set],
						_center.soul_pos.extra
					)
					self.children.floating_sprite2.role.draw_major = self
					self.children.floating_sprite2.states.hover.can = false
					self.children.floating_sprite2.states.click.can = false
				end
			end
		end
	end,
	conditions = { vortex = false, facing = "front" },
})
SMODS.draw_ignore_keys.floating_sprite2 = true

local inj = SMODS.injectItems
function SMODS.injectItems(...)
	inj(...)
	local keys = {}
	local a_keys = {}
	for i, v in pairs(SMODS.calculation_keys) do
		if not keys[v] then
			a_keys[#a_keys+1] = v
		end
		keys[v] = true
	end
	SMODS.calculation_keys = a_keys
end
