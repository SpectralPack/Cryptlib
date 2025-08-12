-- gameset.lua: functions for gameset UI and logic

------------------------
---- GAMESET SYSTEM ----
------------------------

-- designed to work on any object type
function Cryptid.gameset(card, center)
	if not center then
		if not card then
			return G.PROFILES[G.SETTINGS.profile].cry_gameset or "mainline"
		end
		center = card.config and card.config.center or card.effect and card.effect.center or card
	end
	if card.force_gameset then
		return card.force_gameset
	end
	if center.force_gameset then
		return center.force_gameset
	end
	if center.fake_card then
		return G.PROFILES[G.SETTINGS.profile].cry_gameset or "mainline"
	end
	if not center.key then
		if center.tag and center.tag.key then --dumb fix for tags
			center = center.tag
		else
			if false then
				print("Could not find key for center: " .. tprint(center))
			end
			return G.PROFILES[G.SETTINGS.profile].cry_gameset or "mainline"
		end
	end
	local gameset = G.PROFILES[G.SETTINGS.profile].cry_gameset or "mainline"
	if
		G.PROFILES[G.SETTINGS.profile].cry_gameset_overrides and G.PROFILES[G.SETTINGS.profile].cry_gameset_overrides[center.key]
	then
		return G.PROFILES[G.SETTINGS.profile].cry_gameset_overrides[center.key]
	end
	return gameset
end
-- set_ability accounts for gamesets
function Card:get_gameset(center)
	return Cryptid.gameset(self, center)
end
local csa = Card.set_ability
function Card:set_ability(center, y, z)
	if not center then
		return
	end
	-- Addition by IcyEthics to make compatible with strings used on set_ability. Copied directly from the smods set_ability implementation
	if type(center) == "string" then
		assert(G.P_CENTERS[center], ('Could not find center "%s"'):format(center))
		center = G.P_CENTERS[center]
	end
	if not center.config then
		center.config = {} --crashproofing
	end
	csa(self, center, y, z)
	if center.gameset_config and center.gameset_config[self:get_gameset(center)] then
		for k, v in pairs(center.gameset_config[self:get_gameset(center)]) do
			if k ~= "disabled" and k ~= "center" then
				if k == "cost" then
					self.base_cost = v
				else
					self.ability[k] = v
				end
			end
		end
		if center.gameset_config[self:get_gameset(center)].disabled then
			self.cry_disabled = true
		end
		if center.gameset_config[self:get_gameset(center)].center and not self.gameset_select then
			for k, v in pairs(center.gameset_config[self:get_gameset(center)].center) do
				center[k] = v
				self[k] = v
				if k == "rarity" then
					center:set_rarity(v)
				else
					self.config.center[k] = v
				end
			end
		end
	end
end

-- open gameset config UI when clicking on a card in the Cryptid collection
local ccl = Card.click
function Card:click()
	ccl(self)
	if G.your_collection then
		for k, v in pairs(G.your_collection) do
			if
				self.area == v
				and G.ACTIVE_MOD_UI
				and (Cryptid.mod_gameset_whitelist[G.ACTIVE_MOD_UI.id] or G.ACTIVE_MOD_UI.id == "Cryptid")
			then
				if not self.config.center or self.config.center and self.config.center.set == "Default" then
					--make a fake center
					local old_force_gameset = self.config.center and self.config.center.force_gameset
					if self.seal then
						self.config.center = SMODS.Seal.obj_table[self.seal]
						self.config.center.set = "Seal"
					end
					for k, v in pairs(SMODS.Stickers) do
						if self.ability[k] then
							self.config.center = SMODS.Sticker.obj_table[k]
							self.config.center.set = "Sticker"
						end
					end
					if self.config.center then
						self.config.center.force_gameset = old_force_gameset
					end
				end
				if self.gameset_select then
					Card.cry_set_gameset(self, self.config.center, self.config.center.force_gameset)
					Cryptid.update_obj_registry()
				end
				Cryptid.gameset_config_UI(self.config.center)
			end
		end
	end
end

-- gameset config UI
function Cryptid.gameset_config_UI(center)
	if not center then
		center = G.viewedContentSet
	end
	G.SETTINGS.paused = true
	G.your_collection = {}
	G.your_collection[1] = CardArea(
		G.ROOM.T.x + 0.2 * G.ROOM.T.w / 2,
		G.ROOM.T.h,
		5.3 * G.CARD_W,
		1.03 * G.CARD_H,
		{ card_limit = 5, type = "title", highlight_limit = 0, collection = true }
	)
	local deck_tables = {
		n = G.UIT.R,
		config = { align = "cm", padding = 0, no_fill = true },
		nodes = {
			{ n = G.UIT.O, config = { object = G.your_collection[1] } },
		},
	}

	local gamesets = { "disabled", "mainline" }
	if center.set == "Content Set" then
		gamesets = { "disabled", G.PROFILES[G.SETTINGS.profile].cry_gameset or "mainline" }
	end
	for i = 1, #gamesets do
		if
			not (
				center.gameset_config
				and center.gameset_config[gamesets[i]]
				and center.gameset_config[gamesets[i]].disabled
			)
		then
			local _center = Cryptid.deep_copy(center)
			_center.force_gameset = gamesets[i]
			local card = Cryptid.generic_card(_center)
			card.gameset_select = true
			if gamesets[i] == "disabled" then
				card.debuff = true
			end
			G.your_collection[1]:emplace(card)
			--[[if not is_back then
				local card = Card(
					G.your_collection[1].T.x + G.your_collection[1].T.w / 2,
					G.your_collection[1].T.y,
					G.CARD_W,
					G.CARD_H,
					G.P_CARDS.empty,
					_center
				)
				card:start_materialize()
				card.gameset_select = true
				G.your_collection[1]:emplace(card)
			else
				local fake_center = {
					set = "Back",
					force_gameset = gamesets[i],
					pos = center.pos,
					atlas = center.atlas,
					key = center.key,
					config = {}
				}
				local card = Card(G.ROOM.T.x + 0.2*G.ROOM.T.w/2,G.ROOM.T.h, G.CARD_W, G.CARD_H, G.P_CARDS.empty, fake_center)
				card:start_materialize()
				card.gameset_select = true
				G.your_collection[1]:emplace(card)
			end--]]
		end
	end

	INIT_COLLECTION_CARD_ALERTS()
	local args = {
		infotip = localize("cry_gameset_explanation"),
		back_func = G.cry_prev_collec,
		snap_back = true,
		contents = {
			{
				n = G.UIT.R,
				config = { align = "cm", minw = 2.5, padding = 0.1, r = 0.1, colour = G.C.BLACK, emboss = 0.05 },
				nodes = { deck_tables },
			},
		},
	}
	if center.set == "Content Set" and not (SMODS.Mods["Cryptid"] or {}).can_load then
		G.viewedContentSet = center
		args.back2 = true
		args.back2_func = "your_collection_current_set"
		args.back2_label = localize("cry_view_set_contents")
		args.back2_colour = G.C.CRY_SELECTED
	end
	local t = create_UIBox_generic_options(args)
	G.FUNCS.overlay_menu({
		definition = t,
	})
end

function G.FUNCS.cry_gameset_config_UI()
	G.cry_prev_collec = "your_collection_content_sets"
	Cryptid.gameset_config_UI()
end

local collection_shtuff = {
	"blinds",
	"jokers",

	-- consumables don't work
	-- idk what smods is doing with consumable collection stuff, anyone know what the buttons are doing?
	"tarots",
	"planets",
	"spectrals",
	"codes",

	"vouchers",
	"enhancements",
	"decks",
	"editions",
	"tags",
	"seals",
	"boosters",
	"stickers",
	"content_sets",
}

-- sure this is cool and all but it doesn't keep page yet so it's pretty useless
-- would need to regex patch that

for i, v in ipairs(collection_shtuff) do
	local ref = G.FUNCS["your_collection_" .. v]
	G.FUNCS["your_collection_" .. v] = function(e)
		G.cry_prev_collec = "your_collection_" .. v
		ref(e)
	end
end
G.cry_prev_collec = "your_collection_jokers"

-- change the rarity sticker's color for gameset selection on an item
local gtc = get_type_colour
function get_type_colour(center, card)
	local color = gtc(center, card)
	if center.set == "Back" or center.set == "Tag" or center.set == "Blind" then
		color = G.C.CRY_SELECTED
	end
	if card.gameset_select then
		if center.force_gameset == "mainline" then
			color = G.C.PURPLE
		end
	end
	if
		Cryptid.gameset(card, center) == "disabled"
		or (center.cry_disabled and (not card.gameset_select or center.cry_disabled.type ~= "manual"))
	then
		color = mix_colours(G.C.RED, G.C.GREY, 0.7)
		card.debuff = true
	end
	return color
end

function Card:cry_set_gameset(center, gameset)
	if
		G.PROFILES[G.SETTINGS.profile].cry_gameset == gameset
		and not G.PROFILES[G.SETTINGS.profile].cry_gameset_overrides
	then
		return
	end
	if not G.PROFILES[G.SETTINGS.profile].cry_gameset_overrides then
		G.PROFILES[G.SETTINGS.profile].cry_gameset_overrides = {}
	end
	G.PROFILES[G.SETTINGS.profile].cry_gameset_overrides[center.key] = gameset
	if G.PROFILES[G.SETTINGS.profile].cry_gameset == gameset then
		G.PROFILES[G.SETTINGS.profile].cry_gameset_overrides[center.key] = nil
	end
	local empty = true
	for _, _ in pairs(G.PROFILES[G.SETTINGS.profile].cry_gameset_overrides) do
		empty = false
		break
	end
	if empty then
		G.PROFILES[G.SETTINGS.profile].cry_gameset_overrides = nil
	end
	G:save_progress()
end

function G.FUNCS.reset_gameset_config()
	G.PROFILES[G.SETTINGS.profile].cry_gameset_overrides = nil
	Cryptid.update_obj_registry()
	G:save_progress()
end

function Cryptid.enabled(key, iter)
	if not iter then
		iter = 0
	end --iter is used to prevent infinite loops from freezing on startup
	if iter > 10 then
		print("Warning: Circular dependency with " .. key)
		return true
	end
	local card = Cryptid.get_center(key)
	if
		not card
		or Cryptid.gameset(card) == "disabled"
		or card.gameset_config
			and card.gameset_config[Cryptid.gameset(card)]
			and card.gameset_config[Cryptid.gameset(card)].disabled
	then
		return { type = "manual" }
	end
	if card.dependencies then
		if card.dependencies.items then
			for i = 1, #card.dependencies.items do
				if Cryptid.enabled(card.dependencies.items[i], iter + 1) ~= true then
					return { type = "card_dependency", key = card.dependencies.items[i] }
				end
			end
		end
		if card.dependencies.mods then
			for i = 1, #card.dependencies.mods do
				if not (SMODS.Mods[card.dependencies.mods[i]] or {}).can_load then
					return { type = "mod_dependency", key = card.dependencies.mods[i] }
				end
			end
		end
	end
	if card.conflicts then
		if card.conflicts.mods then
			for i = 1, #card.conflicts.mods do
				if (SMODS.Mods[card.conflicts.mods[i]] or {}).can_load then
					return { type = "mod_conflict", key = card.conflicts.mods[i] }
				end
			end
		end
	end
	return true
end

function Cryptid.get_center(key, m)
	if not m then
		-- check for non game objects
		if SMODS.Seals.obj_table and SMODS.Seals.obj_table[key] then
			return SMODS.Seals.obj_table[key]
		end
		if SMODS.Stickers.obj_table and SMODS.Stickers.obj_table[key] then
			return SMODS.Stickers.obj_table[key]
		end
		m = SMODS.GameObject
		if m.subclasses then
			for k, v in pairs(m.subclasses) do
				local c = Cryptid.get_center(key, v)
				if c then
					return c
				end
			end
		end
	end
	return m.obj_table and m.obj_table[key]
end

function Cryptid.gameset_loc(card, config)
	local gameset = Cryptid.gameset(card)
	if config[gameset] then
		return card.key .. "_" .. config[gameset]
	else
		return card.key
	end
end

------------------------------
---- CARD ENABLING SYSTEM ----
------------------------------

---@type fun(self: SMODS.GameObject|table, reason: table)?
SMODS.GameObject._disable = function(self, reason)
	if not self.cry_disabled then
		self.cry_disabled = reason or { type = "manual" } --used to display more information that can be used later
	end
end
---@type fun(self: SMODS.GameObject|table)?
SMODS.GameObject.enable = function(self)
	if self.cry_disabled then
		self.cry_disabled = nil
	end
end

-- Note: For custom pools, these only support Center.pools, not ObjectType.cards
-- That could cause issues with mod compat in the future
-- Potential improvement: automatic pool detection from gamesets?
---@type fun(self: SMODS.Center|table, reason: table)?
SMODS.Center._disable = function(self, reason)
	if not self.cry_disabled then
		self.cry_disabled = reason or { type = "manual" } --used to display more information that can be used later
		SMODS.remove_pool(G.P_CENTER_POOLS[self.set], self.key)
		for k, v in pairs(self.pools or {}) do
			if SMODS.ObjectTypes[k] then
				SMODS.ObjectTypes[k]:delete_card(self)
			end
		end
		G.P_CENTERS[self.key] = nil
	end
end
---@type fun(self: SMODS.Center|table)?
SMODS.Center.enable = function(self)
	if self.cry_disabled then
		self.cry_disabled = nil
		SMODS.insert_pool(G.P_CENTER_POOLS[self.set], self)
		G.P_CENTERS[self.key] = self
		for k, v in pairs(self.pools or {}) do
			SMODS.ObjectTypes[k]:inject_card(self)
		end
	end
end

---@type fun(self: SMODS.Joker|table)?
SMODS.Joker.enable = function(self)
	if self.cry_disabled then
		SMODS.Center.enable(self)
		SMODS.insert_pool(G.P_JOKER_RARITY_POOLS[self.rarity], self)
		local vanilla_rarities = { ["Common"] = 1, ["Uncommon"] = 2, ["Rare"] = 3, ["Legendary"] = 4 }
		if vanilla_rarities[self.rarity] then
			SMODS.insert_pool(G.P_JOKER_RARITY_POOLS[vanilla_rarities[self.rarity]], self)
		end
	end
end
---@type fun(self: SMODS.Joker|table, reason: table)?
SMODS.Joker._disable = function(self, reason)
	if not self.cry_disabled then
		SMODS.Center._disable(self, reason)
		SMODS.remove_pool(G.P_JOKER_RARITY_POOLS[self.rarity], self.key)
		local vanilla_rarities = { ["Common"] = 1, ["Uncommon"] = 2, ["Rare"] = 3, ["Legendary"] = 4 }
		if vanilla_rarities[self.rarity] then
			SMODS.remove_pool(G.P_JOKER_RARITY_POOLS[vanilla_rarities[self.rarity]], self.key)
		end
	end
end
---@type fun(self: SMODS.Joker|table, rarity: string|number)?
SMODS.Joker.set_rarity = function(self, rarity)
	SMODS.remove_pool(G.P_JOKER_RARITY_POOLS[self.rarity], self.key)
	self.rarity = rarity
	SMODS.insert_pool(G.P_JOKER_RARITY_POOLS[self.rarity], self)
	local vanilla_rarities = { ["Common"] = 1, ["Uncommon"] = 2, ["Rare"] = 3, ["Legendary"] = 4 }
	if vanilla_rarities[self.rarity] then
		SMODS.insert_pool(G.P_JOKER_RARITY_POOLS[vanilla_rarities[self.rarity]], self)
	end
end

---@type fun(self: SMODS.Consumable|table)?
SMODS.Consumable.enable = function(self)
	if self.cry_disabled then
		SMODS.Center.enable(self)
		SMODS.insert_pool(G.P_CENTER_POOLS["Consumeables"], self)
	end
end
---@type fun(self: SMODS.Consumable|table, reason: table)?
SMODS.Consumable._disable = function(self, reason)
	if not self.cry_disabled then
		SMODS.Center._disable(self, reason)
		SMODS.remove_pool(G.P_CENTER_POOLS["Consumeables"], self.key)
	end
end

---@type fun(self: SMODS.Tag|table, reason: table)?
SMODS.Tag._disable = function(self, reason)
	if not self.cry_disabled then
		self.cry_disabled = reason or { type = "manual" } --used to display more information that can be used later
		SMODS.remove_pool(G.P_CENTER_POOLS[self.set], self.key)
		G.P_TAGS[self.key] = nil
	end
end
---@type fun(self: SMODS.Tag|table)?
SMODS.Tag.enable = function(self)
	if self.cry_disabled then
		self.cry_disabled = nil
		SMODS.insert_pool(G.P_CENTER_POOLS[self.set], self)
		G.P_TAGS[self.key] = self
	end
end

---@type fun(self: SMODS.Blind|table, reason: table)?
SMODS.Blind._disable = function(self, reason)
	if not self.cry_disabled then
		self.cry_disabled = reason or { type = "manual" } --used to display more information that can be used later
		G.P_BLINDS[self.key] = nil
	end
end
---@type fun(self: SMODS.Blind|table)?
SMODS.Blind.enable = function(self)
	if self.cry_disabled then
		self.cry_disabled = nil
		G.P_BLINDS[self.key] = self
	end
end

--Removing seals from the center table causes issues
---@type fun(self: SMODS.Seal|table, reason: table)?
SMODS.Seal._disable = function(self, reason)
	if not self.cry_disabled then
		self.cry_disabled = reason or { type = "manual" } --used to display more information that can be used later
		SMODS.remove_pool(G.P_CENTER_POOLS[self.set], self.key)
	end
end
---@type fun(self: SMODS.Seal|table)?
SMODS.Seal.enable = function(self)
	if self.cry_disabled then
		self.cry_disabled = nil
		SMODS.insert_pool(G.P_CENTER_POOLS[self.set], self)
	end
end

--Removing editions from the center table causes issues, so instead we make them unable to spawn naturally
---@type fun(self: SMODS.Seal|table, reason: table)?
SMODS.Edition._disable = function(self, reason)
	if not self.cry_disabled then
		self.cry_disabled = reason or { type = "manual" } --used to display more information that can be used later
		SMODS.remove_pool(G.P_CENTER_POOLS[self.set], self.key)
		self.cry_get_weight = self.get_weight
		self.get_weight = function()
			return 0
		end
	end
end
---@type fun(self: SMODS.Seal|table)?
SMODS.Edition.enable = function(self)
	if self.cry_disabled then
		self.cry_disabled = nil
		SMODS.insert_pool(G.P_CENTER_POOLS[self.set], self)
		self.get_weight = self.cry_get_weight
		self.cry_get_weight = nil
	end
end

function Cryptid.update_obj_registry(m, force_enable)
	if not m then
		m = SMODS.GameObject
		if m.subclasses then
			for k, v in pairs(m.subclasses) do
				Cryptid.update_obj_registry(v, force_enable)
			end
		end
	end
	if m.obj_table then
		for k, v in pairs(m.obj_table) do
			if v.mod and (v.mod.id == "Cryptid" or Cryptid.mod_gameset_whitelist[v.mod.id]) then
				local en = force_enable or Cryptid.enabled(k)
				if en == true then
					if v.cry_disabled then
						v:enable()
					end
				else
					if not v.cry_disabled then
						v:_disable(en)
					end
				end
			end
		end
	end
end
function Cryptid.index_items(func, m)
	if not m then
		m = SMODS.GameObject
		if m.subclasses then
			for k, v in pairs(m.subclasses) do
				Cryptid.index_items(func, v)
			end
		end
	end
	if m.obj_table then
		for k, v in pairs(m.obj_table) do
			if v.mod and (v.mod.id == "Cryptid" or Cryptid.mod_gameset_whitelist[v.mod.id]) then
				func(v)
			end
		end
	end
end
local init_item_prototypes_ref = Game.init_item_prototypes
function Game:init_item_prototypes()
	Cryptid.update_obj_registry(nil, true) --force enable, to prevent issues with profile reloading
	init_item_prototypes_ref(self)
	Cryptid.update_obj_registry()
end

------------------------
----- CONTENT SETS -----
------------------------

SMODS.ContentSet = SMODS.Center:extend({
	set = "Content Set",
	pos = { x = 0, y = 0 },
	config = {},
	class_prefix = "set",
	required_params = {
		"key",
	},
	inject = function(self)
		if not G.P_CENTER_POOLS[self.set] then
			G.P_CENTER_POOLS[self.set] = {}
		end
		SMODS.Center.inject(self)
		if not self.cry_order then
			self.cry_order = 0
		end
	end,
})
G.P_CENTER_POOLS["Content Set"] = {}

-- these are mostly copy/paste from vanilla code
G.FUNCS.your_collection_content_sets = function(e)
	G.cry_prev_collec = "your_collection_content_sets"
	G.SETTINGS.paused = true
	G.FUNCS.overlay_menu({
		definition = create_UIBox_your_collection_content_sets(),
	})
end

G.FUNCS.your_collection_current_set = function(e)
	G.cry_prev_collec = "your_collection_current_set"
	G.SETTINGS.paused = true
	G.FUNCS.overlay_menu({
		definition = create_UIBox_your_collection_current_set(),
	})
end

function create_UIBox_your_collection_content_sets()
	local deck_tables = {}

	G.your_collection = {}
	for j = 1, 3 do
		G.your_collection[j] = CardArea(
			G.ROOM.T.x + 0.2 * G.ROOM.T.w / 2,
			G.ROOM.T.h,
			5 * G.CARD_W,
			0.95 * G.CARD_H,
			{ card_limit = 5, type = "title", highlight_limit = 0, collection = true }
		)
		table.insert(deck_tables, {
			n = G.UIT.R,
			config = { align = "cm", padding = 0.07, no_fill = true },
			nodes = {
				{ n = G.UIT.O, config = { object = G.your_collection[j] } },
			},
		})
	end

	local joker_pool = {}
	for k, v in pairs(SMODS.ContentSet.obj_table) do
		if v.set == "Content Set" and v.original_mod.id == G.ACTIVE_MOD_UI.id then
			table.insert(joker_pool, v)
		end
	end
	table.sort(joker_pool, function(a, b)
		return a.cry_order < b.cry_order
	end)
	local joker_options = {}
	for i = 1, math.ceil(#joker_pool / (5 * #G.your_collection)) do
		table.insert(
			joker_options,
			localize("k_page")
				.. " "
				.. tostring(i)
				.. "/"
				.. tostring(math.ceil(#joker_pool / (5 * #G.your_collection)))
		)
	end

	for i = 1, 5 do
		for j = 1, #G.your_collection do
			local center = joker_pool[i + (j - 1) * 5]
			if not center then
				break
			end
			local card = Cryptid.generic_card(
				center,
				G.your_collection[j].T.x + G.your_collection[j].T.w / 2,
				G.your_collection[j].T.y
			)
			G.your_collection[j]:emplace(card)
		end
	end

	INIT_COLLECTION_CARD_ALERTS()

	local t = create_UIBox_generic_options({
		back_func = G.ACTIVE_MOD_UI and "openModUI_" .. G.ACTIVE_MOD_UI.id or "your_collection",
		contents = {
			{ n = G.UIT.R, config = { align = "cm", r = 0.1, colour = G.C.BLACK, emboss = 0.05 }, nodes = deck_tables },
			{
				n = G.UIT.R,
				config = { align = "cm" },
				nodes = {
					create_option_cycle({
						options = joker_options,
						w = 4.5,
						cycle_shoulders = true,
						opt_callback = "your_collection_content_set_page",
						current_option = 1,
						colour = G.C.RED,
						no_pips = true,
						focus_args = { snap_to = true, nav = "wide" },
					}),
				},
			},
		},
	})
	return t
end

function create_UIBox_your_collection_current_set()
	local deck_tables = {}

	G.your_collection = {}
	for j = 1, 3 do
		G.your_collection[j] = CardArea(
			G.ROOM.T.x + 0.2 * G.ROOM.T.w / 2,
			G.ROOM.T.h,
			5 * G.CARD_W,
			0.95 * G.CARD_H,
			{ card_limit = 5, type = "title", highlight_limit = 0, collection = true }
		)
		table.insert(deck_tables, {
			n = G.UIT.R,
			config = { align = "cm", padding = 0.07, no_fill = true },
			nodes = {
				{ n = G.UIT.O, config = { object = G.your_collection[j] } },
			},
		})
	end

	joker_pool = {}
	local function is_in_set(card)
		if card.dependencies and card.dependencies.items then
			for i = 1, #card.dependencies.items do
				if card.dependencies.items[i] == G.viewedContentSet.key then
					joker_pool[#joker_pool + 1] = card
					return true
				end
			end
		end
	end
	Cryptid.index_items(is_in_set)
	table.sort(joker_pool, function(a, b)
		return (a.cry_order or a.order or pseudorandom(a.key)) < (b.cry_order or b.order or pseudorandom(b.key))
	end)
	local joker_options = {}
	for i = 1, math.ceil(#joker_pool / (5 * #G.your_collection)) do
		table.insert(
			joker_options,
			localize("k_page")
				.. " "
				.. tostring(i)
				.. "/"
				.. tostring(math.ceil(#joker_pool / (5 * #G.your_collection)))
		)
	end

	for i = 1, 5 do
		for j = 1, #G.your_collection do
			local center = joker_pool[i + (j - 1) * 5]
			if not center then
				break
			end
			local card = Cryptid.generic_card(
				center,
				G.your_collection[j].T.x + G.your_collection[j].T.w / 2,
				G.your_collection[j].T.y
			)
			G.your_collection[j]:emplace(card)
		end
	end

	INIT_COLLECTION_CARD_ALERTS()

	local t = create_UIBox_generic_options({
		back_func = "cry_gameset_config_UI",
		contents = {
			{ n = G.UIT.R, config = { align = "cm", r = 0.1, colour = G.C.BLACK, emboss = 0.05 }, nodes = deck_tables },
			{
				n = G.UIT.R,
				config = { align = "cm" },
				nodes = {
					create_option_cycle({
						options = joker_options,
						w = 4.5,
						cycle_shoulders = true,
						opt_callback = "your_collection_current_set_page",
						current_option = 1,
						colour = G.C.RED,
						no_pips = true,
						focus_args = { snap_to = true, nav = "wide" },
					}),
				},
			},
		},
	})
	return t
end

G.FUNCS.your_collection_content_set_page = function(args)
	if not args or not args.cycle_config then
		return
	end
	for j = 1, #G.your_collection do
		for i = #G.your_collection[j].cards, 1, -1 do
			local c = G.your_collection[j]:remove_card(G.your_collection[j].cards[i])
			c:remove()
			c = nil
		end
	end
	local joker_pool = {}
	for k, v in pairs(SMODS.ContentSet.obj_table) do
		if v.set == "Content Set" and v.original_mod.id == G.ACTIVE_MOD_UI.id then
			table.insert(joker_pool, v)
		end
	end
	table.sort(joker_pool, function(a, b)
		return (a.cry_order or a.order or pseudorandom(a.key)) < (b.cry_order or b.order or pseudorandom(b.key))
	end)
	for i = 1, 5 do
		for j = 1, #G.your_collection do
			local center =
				joker_pool[i + (j - 1) * 5 + (5 * #G.your_collection * (args.cycle_config.current_option - 1))]
			if not center then
				break
			end
			local card = Cryptid.generic_card(
				center,
				G.your_collection[j].T.x + G.your_collection[j].T.w / 2,
				G.your_collection[j].T.y
			)
			G.your_collection[j]:emplace(card)
		end
	end
	INIT_COLLECTION_CARD_ALERTS()
end
G.FUNCS.your_collection_current_set_page = function(args)
	if not args or not args.cycle_config then
		return
	end
	for j = 1, #G.your_collection do
		for i = #G.your_collection[j].cards, 1, -1 do
			local c = G.your_collection[j]:remove_card(G.your_collection[j].cards[i])
			c:remove()
			c = nil
		end
	end
	joker_pool = {}
	local function is_in_set(card)
		if card.dependencies and card.dependencies.items then
			for i = 1, #card.dependencies.items do
				if card.dependencies.items[i] == G.viewedContentSet.key then
					joker_pool[#joker_pool + 1] = card
					return true
				end
			end
		end
	end
	Cryptid.index_items(is_in_set)
	table.sort(joker_pool, function(a, b)
		return (a.cry_order or a.order or pseudorandom(a.key)) < (b.cry_order or b.order or pseudorandom(b.key))
	end)
	for i = 1, 5 do
		for j = 1, #G.your_collection do
			local center =
				joker_pool[i + (j - 1) * 5 + (5 * #G.your_collection * (args.cycle_config.current_option - 1))]
			if not center then
				break
			end
			local card = Cryptid.generic_card(
				center,
				G.your_collection[j].T.x + G.your_collection[j].T.w / 2,
				G.your_collection[j].T.y
			)
			G.your_collection[j]:emplace(card)
		end
	end
	INIT_COLLECTION_CARD_ALERTS()
end

------------------------------
---- GENERIC COLLECTIONS -----
------------------------------

function Cryptid.generic_card(center, x, y)
	--todo: make gameset stickers play nicely with resized sprites
	local is_blind = center.set == "Blind" or center.cry_blind
	local is_tag = center.set == "Tag" or center.cry_tag
	local card = Card(
		x or G.ROOM.T.x + 0.2 * G.ROOM.T.w / 2,
		y or G.ROOM.T.h,
		is_blind and 0.7 * G.CARD_W or is_tag and 0.42 * G.CARD_W or G.CARD_W,
		is_blind and 0.7 * G.CARD_W or is_tag and 0.42 * G.CARD_W or G.CARD_H,
		nil,
		center.set ~= "Seal" and center.set ~= "Sticker" and center or G.P_CENTERS.c_base
	)
	--todo: make this work when the edition is disabled (although it's a good failsafe that it doesn't?)
	if center.set == "Edition" then
		card:set_edition(center.key, true, true)
	end
	if Cryptid.safe_get(center, "config", "cry_antimatter") then
		card:set_edition("e_negative", true, true)
		return card
	end
	if Cryptid.safe_get(center, "config", "cry_force_edition") then
		card:set_edition({ [center.config.cry_force_edition] = true }, true, true)
	end
	if center.set == "Seal" then
		card:set_seal(center.key, true, true)
		card.config.center = Cryptid.deep_copy(card.config.center)
		card.config.center.force_gameset = center.force_gameset
		card.config.center.key = center.key
	end
	if Cryptid.safe_get(center, "config", "cry_force_seal") then
		card:set_seal(center.config.cry_force_seal, true, true)
	end
	if center.set == "Sticker" then
		center:apply(card, true)
		card.config.center = Cryptid.deep_copy(card.config.center)
		card.config.center.force_gameset = center.force_gameset
		card.config.center.key = center.key
	end
	if Cryptid.safe_get(center, "config", "cry_force_sticker") then
		SMODS.Stickers[center.config.cry_force_sticker]:apply(card, true)
	end
	return card
end

-- Hooks for all collection types
local smcp = SMODS.collection_pool
SMODS.collection_pool = function(m)
	if G.ACTIVE_MOD_UI and (Cryptid.mod_gameset_whitelist[G.ACTIVE_MOD_UI.id] or G.ACTIVE_MOD_UI.id == "Cryptid") then
		-- use SMODS pools instead of vanilla pools, so disabled cards appear
		if m[1] and m[1].set and m[1].set == "Seal" then
			m = {}
			for k, v in pairs(SMODS.Seal.obj_table) do
				if v.mod and (Cryptid.mod_gameset_whitelist[v.mod.id] or v.mod.id == "Cryptid") then
					table.insert(m, v)
				end
			end
		elseif m[1] and m[1].set and m[1].set == "Sticker" then
			m = {}
			for k, v in pairs(SMODS.Sticker.obj_table) do
				if v.mod and (Cryptid.mod_gameset_whitelist[v.mod.id] or v.mod.id == "Cryptid") then
					table.insert(m, v)
				end
			end
		elseif m[1] and m[1].set and G.P_CENTER_POOLS[m[1].set] == m then
			local set = m[1].set
			m = {}
			for k, v in pairs(SMODS.Center.obj_table) do
				if v.set == set and v.mod and (Cryptid.mod_gameset_whitelist[v.mod.id] or v.mod.id == "Cryptid") then
					table.insert(m, v)
				end
			end
		end
		-- Fix blind issues
		for k, v in pairs(m) do
			if v.set == "Blind" and v.mod and (Cryptid.mod_gameset_whitelist[v.mod.id] or v.mod.id == "Cryptid") then
				v.config = {}
			end
		end
		table.sort(m, function(a, b)
			return (a.cry_order or a.order or pseudorandom(a.key)) < (b.cry_order or b.order or pseudorandom(b.key))
		end)
	end
	return smcp(m)
end

-- Make Cryptid show all collection boxes (kinda silly)
local mct = modsCollectionTally
function modsCollectionTally(pool, set)
	local t = mct(pool, set)
	if G.ACTIVE_MOD_UI and (Cryptid.mod_gameset_whitelist[G.ACTIVE_MOD_UI.id] or G.ACTIVE_MOD_UI.id == "Cryptid") then
		local obj_tally = { tally = 0, of = 0 }
		--infer pool
		local _set = set or Cryptid.safe_get(pool, 1, "set")
		--check for general consumables
		local consumable = false
		if _set and Cryptid.safe_get(pool, 1, "consumeable") then
			for i = 1, #pool do
				if Cryptid.safe_get(pool, i, "set") ~= _set then
					consumable = true
					break
				end
			end
		end
		if _set then
			if _set == "Seal" then
				pool = SMODS.Seal.obj_table
				set = _set
			elseif G.P_CENTER_POOLS[_set] then
				pool = SMODS.Center.obj_table
				set = _set
			end
		end
		for _, v in pairs(pool) do
			if v.mod and G.ACTIVE_MOD_UI.id == v.mod.id and not v.no_collection then
				if consumable then
					if Cryptid.safe_get(v, "consumeable") then
						obj_tally.of = obj_tally.of + 1
						if Cryptid.enabled(v.key) == true then
							obj_tally.tally = obj_tally.tally + 1
						end
					end
				elseif set then
					if v.set and v.set == set then
						obj_tally.of = obj_tally.of + 1
						if Cryptid.enabled(v.key) == true then
							obj_tally.tally = obj_tally.tally + 1
						end
					end
				else
					obj_tally.of = obj_tally.of + 1
					if Cryptid.enabled(v.key) == true then
						obj_tally.tally = obj_tally.tally + 1
					end
				end
			end
		end
		return obj_tally
	end
	return t
end

-- Make non-center collections show all cards as centers
local uibk = create_UIBox_your_collection_decks
function create_UIBox_your_collection_decks()
	if G.ACTIVE_MOD_UI and (Cryptid.mod_gameset_whitelist[G.ACTIVE_MOD_UI.id] or G.ACTIVE_MOD_UI.id == "Cryptid") then
		local generic_collection_pool = {}
		for k, v in pairs(SMODS.Center.obj_table) do
			if v.set == "Back" and v.mod and (v.mod.id == "Cryptid" or Cryptid.mod_gameset_whitelist[v.mod.id]) then
				table.insert(generic_collection_pool, v)
			end
		end
		return SMODS.card_collection_UIBox(generic_collection_pool, { 5, 5, 5 }, {
			modify_card = function(card, center, i, j)
				if center.config.cry_antimatter then
					card:set_edition("e_negative", true, true)
					return card
				end
				if center.config.cry_force_edition then
					card:set_edition({ [center.config.cry_force_edition] = true }, true, true)
				end
				if center.config.cry_force_seal then
					card:set_seal(center.config.cry_force_seal, true, true)
				end
				if center.config.cry_force_sticker then
					SMODS.Stickers[center.config.cry_force_sticker]:apply(card, true)
				end
			end,
		})
	else
		return uibk()
	end
end

local uitag = create_UIBox_your_collection_tags
function create_UIBox_your_collection_tags()
	if G.ACTIVE_MOD_UI and (Cryptid.mod_gameset_whitelist[G.ACTIVE_MOD_UI.id] or G.ACTIVE_MOD_UI.id == "Cryptid") then
		local generic_collection_pool = {}
		for k, v in pairs(SMODS.Tag.obj_table) do
			if v.set == "Tag" and v.mod and (v.mod.id == "Cryptid" or Cryptid.mod_gameset_whitelist[v.mod.id]) then
				table.insert(generic_collection_pool, v)
			end
		end
		return SMODS.card_collection_UIBox(generic_collection_pool, { 6, 6, 6, 6 }, {
			card_scale = 0.42,
			h_mod = 0.3,
			w_mod = 0.55,
			area_type = "title_2",
			modify_card = function(card, center, i, j)
				card.T.h = card.T.w
			end,
		})
	else
		return uitag()
	end
end

local uibl = create_UIBox_your_collection_blinds
function create_UIBox_your_collection_blinds()
	if G.ACTIVE_MOD_UI and (Cryptid.mod_gameset_whitelist[G.ACTIVE_MOD_UI.id] or G.ACTIVE_MOD_UI.id == "Cryptid") then
		local generic_collection_pool = {}
		for k, v in pairs(SMODS.Blind.obj_table) do
			if v.set == "Blind" and v.mod and (v.mod.id == "Cryptid" or Cryptid.mod_gameset_whitelist[v.mod.id]) then
				table.insert(generic_collection_pool, v)
			end
		end
		return SMODS.card_collection_UIBox(generic_collection_pool, { 5, 5, 5, 5, 5 }, {
			card_scale = 0.70,
			h_mod = 0.45,
			w_mod = 0.70,
			area_type = "title_2",
			modify_card = function(card, center, i, j)
				card.T.h = card.T.w
			end,
		})
	else
		return uibl()
	end
end

local uisl = create_UIBox_your_collection_seals
function create_UIBox_your_collection_seals()
	if G.ACTIVE_MOD_UI and (Cryptid.mod_gameset_whitelist[G.ACTIVE_MOD_UI.id] or G.ACTIVE_MOD_UI.id == "Cryptid") then
		return SMODS.card_collection_UIBox(G.P_CENTER_POOLS.Seal, { 5, 5 }, {
			snap_back = true,
			infotip = localize("ml_edition_seal_enhancement_explanation"),
			hide_single_page = true,
			collapse_single_page = true,
			center = "c_base",
			h_mod = 1.03,
			modify_card = function(card, center)
				card:set_seal(center.key, true)
				-- Make disabled UI appear
				card.config.center = Cryptid.deep_copy(card.config.center)
				card.config.center.key = center.key
			end,
		})
	else
		return uisl()
	end
end

local uist = create_UIBox_your_collection_stickers
function create_UIBox_your_collection_stickers()
	if G.ACTIVE_MOD_UI and (Cryptid.mod_gameset_whitelist[G.ACTIVE_MOD_UI.id] or G.ACTIVE_MOD_UI.id == "Cryptid") then
		return SMODS.card_collection_UIBox(SMODS.Stickers, { 5, 5 }, {
			snap_back = true,
			hide_single_page = true,
			collapse_single_page = true,
			center = "c_base",
			h_mod = 1.03,
			back_func = "your_collection_other_gameobjects",
			modify_card = function(card, center)
				card.ignore_pinned = true
				center:apply(card, true)
				-- Make disabled UI appear
				card.config.center = Cryptid.deep_copy(card.config.center)
				card.config.center.key = center.key
			end,
		})
	else
		return uist()
	end
end

--hacky fix to get animated atlases visible for centers
local smai = SMODS.Atlas.inject
SMODS.Atlas.inject = function(self)
	smai(self)
	if self.atlas_table ~= "ASSET_ATLAS" then
		G.ASSET_ATLAS[self.key_noloc or self.key] = G[self.atlas_table][self.key_noloc or self.key]
	end
end

-- add second back button to create_UIBox_generic_options
local cuigo = create_UIBox_generic_options
function create_UIBox_generic_options(args)
	local ret = cuigo(args)
	if args.back2 then
		local mainUI = ret.nodes[1].nodes[1].nodes
		mainUI[#mainUI + 1] = {
			n = G.UIT.R,
			config = {
				id = args.back2_id or "overlay_menu_back2_button",
				align = "cm",
				minw = 2.5,
				button_delay = args.back2_delay,
				padding = 0.1,
				r = 0.1,
				hover = true,
				colour = args.back2_colour or G.C.ORANGE,
				button = args.back2_func or "exit_overlay_menu",
				shadow = true,
				focus_args = { nav = "wide", button = "b", snap_to = args.snap_back2 },
			},
			nodes = {
				{
					n = G.UIT.R,
					config = { align = "cm", padding = 0, no_fill = true },
					nodes = {
						{
							n = G.UIT.T,
							config = {
								id = args.back2_id or nil,
								text = args.back2_label or localize("b_back"),
								scale = 0.5,
								colour = G.C.UI.TEXT_LIGHT,
								shadow = true,
								func = not args.no_pip and "set_button_pip" or nil,
								focus_args = not args.no_pip and { button = args.back2_button or "b" } or nil,
							},
						},
					},
				},
			},
		}
	end
	return ret
end