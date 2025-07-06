if SMODS and SMODS.Mods and (not SMODS.Mods.Talisman or not SMODS.Mods.Talisman.can_load) then
	function to_number(a)
		return a
	end
	function to_big(a)
		return a
	end
	function lenient_bignum(a)
		return a
	end
	function is_number(x)
		return type(x) == "number"
	end

	local smods_xchips = false
	for _, v in pairs(SMODS.calculation_keys) do
		if v == "x_chips" then
			smods_xchips = true
			break
		end
	end
	SMODS.Sound({
		key = "emult",
		path = "ExponentialMult.wav",
	})
	SMODS.Sound({
		key = "echips",
		path = "ExponentialChips.wav",
	})
	SMODS.Sound({
		key = "xchip",
		path = "MultiplicativeChips.wav",
	})
	local scie = SMODS.calculate_individual_effect
	function SMODS.calculate_individual_effect(effect, scored_card, key, amount, from_edition)
		local ret = scie(effect, scored_card, key, amount, from_edition)
		if ret then
			return ret
		end
		if (key == "e_chips" or key == "echips" or key == "Echip_mod") and amount ~= 1 then
			if effect.card then
				juice_card(effect.card)
			end
			hand_chips = mod_chips(hand_chips ^ amount)
			update_hand_text({ delay = 0 }, { chips = hand_chips, mult = mult })
			if not effect.remove_default_message then
				if from_edition then
					card_eval_status_text(
						scored_card,
						"jokers",
						nil,
						percent,
						nil,
						{ message = "^" .. amount, colour = G.C.EDITION, edition = true }
					)
				elseif key ~= "Echip_mod" then
					if effect.echip_message then
						card_eval_status_text(
							scored_card or effect.card or effect.focus,
							"extra",
							nil,
							percent,
							nil,
							effect.echip_message
						)
					else
						card_eval_status_text(scored_card or effect.card or effect.focus, "e_chips", amount, percent)
					end
				end
			end
			return true
		end
		if (key == "e_mult" or key == "emult" or key == "Emult_mod") and amount ~= 1 then
			if effect.card then
				juice_card(effect.card)
			end
			mult = mod_mult(mult ^ amount)
			update_hand_text({ delay = 0 }, { chips = hand_chips, mult = mult })
			if not effect.remove_default_message then
				if from_edition then
					card_eval_status_text(
						scored_card,
						"jokers",
						nil,
						percent,
						nil,
						{ message = "^" .. amount .. " " .. localize("k_mult"), colour = G.C.EDITION, edition = true }
					)
				elseif key ~= "Emult_mod" then
					if effect.emult_message then
						card_eval_status_text(
							scored_card or effect.card or effect.focus,
							"extra",
							nil,
							percent,
							nil,
							effect.emult_message
						)
					else
						card_eval_status_text(scored_card or effect.card or effect.focus, "e_mult", amount, percent)
					end
				end
			end
			return true
		end
	end
	for _, v in ipairs({
		"e_mult",
		"e_chips",
		"ee_mult",
		"ee_chips",
		"eee_mult",
		"eee_chips",
		"hyper_mult",
		"hyper_chips",
		"emult",
		"echips",
		"eemult",
		"eechips",
		"eeemult",
		"eeechips",
		"hypermult",
		"hyperchips",
		"Emult_mod",
		"Echip_mod",
		"EEmult_mod",
		"EEchip_mod",
		"EEEmult_mod",
		"EEEchip_mod",
		"hypermult_mod",
		"hyperchip_mod",
	}) do
		table.insert(SMODS.calculation_keys, v)
	end
	if not smods_xchips then
		for _, v in ipairs({ "x_chips", "xchips", "Xchip_mod" }) do
			table.insert(SMODS.calculation_keys, v)
		end
	end
end