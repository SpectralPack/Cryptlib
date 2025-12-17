function Card:unredeem()
	if self.ability.set == "Voucher" then
		stop_use()
		if not self.config.center.discovered then
			discover_card(self.config.center)
		end

		self.states.hover.can = false
		local top_dynatext = nil
		local bot_dynatext = nil

		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 0.4,
			func = function()
				top_dynatext = DynaText({
					string = localize({
						type = "name_text",
						set = self.config.center.set,
						key = self.config.center.key,
					}),
					colours = { G.C.RED },
					rotate = 1,
					shadow = true,
					bump = true,
					float = true,
					scale = 0.9,
					pop_in = 0.6 / G.SPEEDFACTOR,
					pop_in_rate = 1.5 * G.SPEEDFACTOR,
				})
				bot_dynatext = DynaText({
					string = localize("cry_unredeemed"),
					colours = { G.C.RED },
					rotate = 2,
					shadow = true,
					bump = true,
					float = true,
					scale = 0.9,
					pop_in = 1.4 / G.SPEEDFACTOR,
					pop_in_rate = 1.5 * G.SPEEDFACTOR,
					pitch_shift = 0.25,
				})
				self:juice_up(0.3, 0.5)
				play_sound("card1")
				play_sound("timpani")
				self.children.top_disp = UIBox({
					definition = {
						n = G.UIT.ROOT,
						config = { align = "tm", r = 0.15, colour = G.C.CLEAR, padding = 0.15 },
						nodes = {
							{ n = G.UIT.O, config = { object = top_dynatext } },
						},
					},
					config = { align = "tm", offset = { x = 0, y = 0 }, parent = self },
				})
				self.children.bot_disp = UIBox({
					definition = {
						n = G.UIT.ROOT,
						config = { align = "tm", r = 0.15, colour = G.C.CLEAR, padding = 0.15 },
						nodes = {
							{ n = G.UIT.O, config = { object = bot_dynatext } },
						},
					},
					config = { align = "bm", offset = { x = 0, y = 0 }, parent = self },
				})
				return true
			end,
		}))

		if not self.debuff then
			self:unapply_to_run()
		end

		delay(0.6)
		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 2.6,
			func = function()
				top_dynatext:pop_out(4)
				bot_dynatext:pop_out(4)
				return true
			end,
		}))

		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 0.5,
			func = function()
				self.children.top_disp:remove()
				self.children.top_disp = nil
				self.children.bot_disp:remove()
				self.children.bot_disp = nil
				return true
			end,
		}))
	end
	G.E_MANAGER:add_event(Event({
		func = function()
			Cryptid.update_used_vouchers()
			return true
		end,
	}))
end

function Card:unapply_to_run(center)
	local center_table = {
		name = center and center.name or self and self.ability.name,
		extra = self and self.ability.extra or center and center.config.extra,
	}
	local obj = center or self.config.center
	if obj.unredeem and type(obj.unredeem) == "function" then
		obj:unredeem(self)
		return
	end

	if center_table.name == "Overstock" or center_table.name == "Overstock Plus" then
		G.E_MANAGER:add_event(Event({
			func = function()
				change_shop_size(-center_table.extra)
				return true
			end,
		}))
	end
	if center_table.name == "Tarot Merchant" or center_table.name == "Tarot Tycoon" then
		G.E_MANAGER:add_event(Event({
			func = function()
				G.GAME.tarot_rate = G.GAME.tarot_rate / center_table.extra
				return true
			end,
		}))
	end
	if center_table.name == "Planet Merchant" or center_table.name == "Planet Tycoon" then
		G.E_MANAGER:add_event(Event({
			func = function()
				G.GAME.planet_rate = G.GAME.planet_rate / center_table.extra
				return true
			end,
		}))
	end
	if center_table.name == "Hone" or center_table.name == "Glow Up" then
		G.E_MANAGER:add_event(Event({
			func = function()
				G.GAME.edition_rate = G.GAME.edition_rate / center_table.extra
				return true
			end,
		}))
	end
	if center_table.name == "Magic Trick" then
		G.E_MANAGER:add_event(Event({
			func = function()
				G.GAME.playing_card_rate = 0
				return true
			end,
		}))
	end
	if center_table.name == "Crystal Ball" then
		G.E_MANAGER:add_event(Event({
			func = function()
				G.consumeables.config.card_limit = G.consumeables.config.card_limit - center_table.extra
				return true
			end,
		}))
	end
	if center_table.name == "Clearance Sale" then
		G.E_MANAGER:add_event(Event({
			func = function()
				G.GAME.discount_percent = 0
				for k, v in pairs(G.I.CARD) do
					if v.set_cost then
						v:set_cost()
					end
				end
				return true
			end,
		}))
	end
	if center_table.name == "Liquidation" then
		G.E_MANAGER:add_event(Event({
			func = function()
				G.GAME.discount_percent = 25 -- no idea why the below returns nil, so it's hardcoded now
				-- G.GAME.discount_percent = G.P_CENTERS.v_clearance_sale.extra
				for k, v in pairs(G.I.CARD) do
					if v.set_cost then
						v:set_cost()
					end
				end
				return true
			end,
		}))
	end
	if center_table.name == "Reroll Surplus" or center_table.name == "Reroll Glut" then
		G.E_MANAGER:add_event(Event({
			func = function()
				G.GAME.round_resets.reroll_cost = G.GAME.round_resets.reroll_cost + self.ability.extra
				G.GAME.current_round.reroll_cost = math.max(0, G.GAME.current_round.reroll_cost + self.ability.extra)
				return true
			end,
		}))
	end
	if center_table.name == "Seed Money" then
		G.E_MANAGER:add_event(Event({
			func = function()
				G.GAME.interest_cap = 25 --note: does not account for potential deck effects
				return true
			end,
		}))
	end
	if center_table.name == "Money Tree" then
		G.E_MANAGER:add_event(Event({
			func = function()
				if G.GAME.used_vouchers.v_seed_money then
					G.GAME.interest_cap = 50
				else
					G.GAME.interest_cap = 25
				end
				return true
			end,
		}))
	end
	if center_table.name == "Grabber" or center_table.name == "Nacho Tong" then
		G.GAME.round_resets.hands = G.GAME.round_resets.hands - center_table.extra
		ease_hands_played(-center_table.extra)
	end
	if center_table.name == "Paint Brush" or center_table.name == "Palette" then
		G.hand:change_size(-center_table.extra)
	end
	if center_table.name == "Wasteful" or center_table.name == "Recyclomancy" then
		G.GAME.round_resets.discards = G.GAME.round_resets.discards - center_table.extra
		ease_discard(-center_table.extra)
	end
	if center_table.name == "Antimatter" then
		G.E_MANAGER:add_event(Event({
			func = function()
				if G.jokers then
					G.jokers.config.card_limit = G.jokers.config.card_limit - center_table.extra
				end
				return true
			end,
		}))
	end
	if center_table.name == "Hieroglyph" or center_table.name == "Petroglyph" then
		ease_ante(center_table.extra)
		G.GAME.round_resets.blind_ante = G.GAME.round_resets.blind_ante or G.GAME.round_resets.ante
		G.GAME.round_resets.blind_ante = G.GAME.round_resets.blind_ante + center_table.extra

		if center_table.name == "Hieroglyph" then
			G.GAME.round_resets.hands = G.GAME.round_resets.hands + center_table.extra
			ease_hands_played(center_table.extra)
		end
		if center_table.name == "Petroglyph" then
			G.GAME.round_resets.discards = G.GAME.round_resets.discards + center_table.extra
			ease_discard(center_table.extra)
		end
	end
end