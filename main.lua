Cryptid_config = {
    gameset_toggle = true
}

local files = {
    "talisman",
    "manipulate",
    "forcetrigger",
    "utilities",
    "content_sets"
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