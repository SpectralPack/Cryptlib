Cryptid_config = {
    gameset_toggle = true
}

SMODS.Atlas {
    key = "modicon",
    path = "crylib_icon.png",
    px = 34,
    py = 34,
}:register()

local files = {
    "talisman",
    "manipulate",
    "forcetrigger",
    "utilities",
    "content_sets",
    "ascended",
    "unredeem"
}
for i, v in pairs(files) do
    local file, err = SMODS.load_file(v..".lua")
    if file then file() 
    else error("Error in file: "..v.." "..err) end
end
G.C.SET["Tag"] = G.C.SET["Spectral"]
G.C.SET["Blind"] = G.C.SET["Spectral"]
G.C.SET["Content Set"] = HEX("6db67f")

local ref = G.UIDEF.card_h_popup
function G.UIDEF.card_h_popup(card)
    if card.ability_UIBox_table then
      local AUT = card.ability_UIBox_table
        if not G.C.SET[AUT.card_type] then 
            G.C.SET[AUT.card_type] = G.C.SET["Spectral"]
        end
    end
    return ref(card)
end

if (SMODS.Mods["AntePreview"] or {}).can_load and not (SMODS.Mods["Cryptid"] or {}).can_load then
	local predict_hook = predict_next_ante
	function predict_next_ante()
		local predictions = predict_hook()
		local s = Cryptid.get_next_tag("Small")
		local b = Cryptid.get_next_tag("Big")
		if s or b then
			predictions.Small.tag = s or predictions.Small.tag
			predictions.Big.tag = b or predictions.Big.tag
		end
		if G.GAME.modifiers.cry_no_tags then
			for _, pred in pairs(predictions) do
				pred.tag = nil
			end
		end
		return predictions
	end
end
