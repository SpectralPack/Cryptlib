-- Forcetrigger results for Vanilla Jokers
-- (You should really be using context.forcetrigger in Joker calculation)

------------
-- MACROS --
------------

local function suit_mult(card, context)
    return { mult = card.ability.extra.s_mult }
end
local function hand_mult(card, context)
    return { mult = card.ability.t_mult }
end
local function hand_chips(card, context)
    return { chips = card.ability.t_chips }
end
local function hand_xmult(card, context)
    return { xmult = card.ability.x_mult }
end
local function simple_return(ret_key, ability_key, extra_key)
    if ability_key == "extra" and extra_key then
        return function(card, context)
            return { [ret_key] = card.ability.extra[extra_key] }
        end
    else
        return function(card, context)
            return { [ret_key] = card.ability[ability_key] }
        end
    end
end
--[[
simple_return("mult", "mult") -> return { mult = card.ability.mult }
simple_return("mult", "extra", "mult") -> return { mult = card.ability.extra.mult }
]]
local function add_consumable(set, key_append)
    local loc_key = 'k_plus_' .. set:lower()
    local colour = set == "Spectral" and G.C.SECONDARY_SET.Spectral or nil
    return function (card, context)
        Spectrallib.event{
            function ()
                SMODS.add_card{
                    set = set,
                    key_append = key_append
                }
                return true
            end,
            trigger = "after",
            delay = 0.4,
        }
        return {
            message = localize(loc_key),
            colour = colour
        }
    end
end

-----------------
-- DEFINITIONS --
-----------------

---@type { [string]: fun(card: Card, context: table): table|nil }
Spectrallib.vanilla_forcetrigger_results = {
    --#region Page 1
    ["Joker"]            = simple_return("mult", "mult"),
    ["Greedy Joker"]     = suit_mult,
    ["Lusty Joker"]      = suit_mult,
    ["Wrathful Joker"]   = suit_mult,
    ["Gluttonous Joker"] = suit_mult,
    ["Jolly Joker"]      = hand_mult,
    ["Zany Joker"]       = hand_mult,
    ["Mad Joker"]        = hand_mult,
    ["Crazy Joker"]      = hand_mult,
    ["Droll Joker"]      = hand_mult,
    ["Sly Joker"]        = hand_chips,
    ["Wily Joker"]       = hand_chips,
    ["Clever Joker"]     = hand_chips,
    ["Devious Joker"]    = hand_chips,
    ["Crafty Joker"]     = hand_chips,
    --#endregion
    --#region Page 2
    ["Half Joker"]    = simple_return("mult", "extra", "mult"),
    ["Joker Stencil"] = simple_return("xmult", "x_mult"),
    -- ["Four Fingers"]
    -- ["Mime"]
    -- ["Credit Card"]
    ["Ceremonial Dagger"] = function (card, context)
        local my_pos = card.rank
        local sliced_card = G.jokers.cards[my_pos + 1]
        if not sliced_card then return end
        if (
            not card.getting_sliced
            and sliced_card
            and not sliced_card.ability.eternal
            and not sliced_card.getting_sliced
        ) then
            sliced_card.getting_sliced = true
            G.GAME.joker_buffer = G.GAME.joker_buffer - 1
            G.E_MANAGER:add_event(Event({
                func = function ()
                    G.GAME.joker_buffer = 0
                    card.ability.mult = card.ability.mult + sliced_card.sell_cost * 2
                    card:juice_up(0.8, 0.8)
                    sliced_card:start_dissolve({ HEX("57ecab") }, nil, 1.6)
                    play_sound("slice1", 0.96 + math.random() * 0.08)
                    return true
                end
            }))
        end
        return { mut = card.ability.mult }
    end,
    ["Banner"]        = simple_return("chips", "extra"),
    ["Mystic Summit"] = simple_return("mult", "extra", "mult"),
    ["Marble Joker"]  = function (card, context)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.4,
            func = function()
                SMODS.add_card({
                    set = "Base",
                    enhancement = "m_stone",
                    area = G.deck,
                    key_append = 'marb_fr'
                })
                return true
            end,
        }))
    end,
    ["Loyalty Card"] = simple_return("xmult", "extra", "Xmult"),
    ["8 Ball"]       = add_consumable("Tarot", '8ba'),
    ["Misprint"]     = simple_return("mult", "extra", "max"),
    -- ["Dusk"]
    ["Raised Fist"] = function (card, context)
        return { mult = 22 }
    end,
    -- ["Chaos the Clown"]
    --#endregion
    --#region Page 3
    ["Fibonacci"] = simple_return("mult", "extra"),
    ["Steel Joker"] = function (card, context)
        return { xmult = card.ability.extra + 1 }
    end,
    ["Scary Face"]            = simple_return("chips", "extra"),
    ["Abstract Joker"]        = simple_return("mult", "extra"),
    ["Delayed Gratification"] = simple_return("dollars", "extra"),
    -- ["Hack"]
    -- ["Pareidolia"]
    ["Gros Michel"] = function (card, context)
        Spectrallib.event(function ()
            SMODS.destroy_cards(card, {pinch_anim = true})
            return true
        end)
        G.GAME.pool_flags.gros_michel_extinct = true
        return { mult = card.ability.extra.mult }
    end,
    ["Even Steven"] = simple_return("mult", "extra"),
    ["Odd Todd"]    = simple_return("chips", "extra"),
    ["Scholar"] = function (card, context)
        return {
            chips = card.ability.extra.chips,
            mult = card.ability.extra.mult
        }
    end,
    ["Business Card"] = function (card, context)
        return { dollars = 2 }
    end,
    ["Supernova"] = function (card, context)
        local hand = (
            context.other_context
            and context.other_context.scoring_name
            or context.scoring_name
        )
        if hand then
            return { mult = G.GAME.hands[hand].played }
        end
    end,
    ["Ride the Bus"] = simple_return("mult", "mult"),
    ["Space Joker"] = function (card, context)
        if #G.hand.highlighted > 0 then
            local text, disp_text = G.FUNCS.get_poker_hand_info(G.hand.highlighted)
            update_hand_text({ sound = "button", volume = 0.7, pitch = 0.8, delay = 0.3 }, {
                handname = localize(text, "poker_hands"),
                chips = G.GAME.hands[text].chips,
                mult = G.GAME.hands[text].mult,
                level = G.GAME.hands[text].level,
            })
            level_up_hand(card, text, nil, 1)
            update_hand_text(
                { sound = "button", volume = 0.7, pitch = 1.1, delay = 0 },
                { mult = 0, chips = 0, handname = "", level = "" }
            )
        elseif context.scoring_name then
            level_up_hand(card, context.scoring_name)
        end
    end,
    --#endregion
    --#region Page 4
    ["Egg"] = function (card, context)
        card.ability.extra_value = card.ability.extra_value + card.ability.extra
        card:set_cost()
    end,
    ["Burglar"] = function (card, context)
        Spectrallib.event(function()
            ease_discard(-G.GAME.current_round.discards_left, nil, true)
            ease_hands_played(card.ability.extra)
            return true
        end)
    end,
    ["Blackboard"] = simple_return("xmult", "extra"),
    ["Runner"]     = simple_return("chips", "extra", "chips"),
    ["Ice Cream"]  = simple_return("chips", "extra", "chips"),
    ["DNA"] = function (card, context)
        local card_copied = SMODS.copy_card(context.full_hand[1])
        card_copied.states.visible = nil
        Spectrallib.event(function ()
            card_copied:start_materialize()
            return true
        end)
    end,
    -- ["Splash"]
    ["Blue Joker"]     = simple_return("chips", "extra"),
    ["Sixth Sense"]    = add_consumable("Spectral", 'sixth'),
    ["Constellation"]  = simple_return("xmult", "x_mult"),
    -- ["Hiker"]
    ["Faceless Joker"] = simple_return("dollars", "extra", "dollars"),
    ["Green Joker"]    = simple_return("mult", "mult"),
    ["Superposition"]  = add_consumable("Tarot", 'sup'),
    ["To Do List"]     = simple_return("dollars", "extra", "dollars"),
    --#endregion
    --#region Page 5
    ["Cavendish"] = function (card, context)
        Spectrallib.event(function ()
            SMODS.destroy_cards(card, {pinch_anim = true})
            return true
        end)
        return { xmult = card.ability.extra.Xmult }
    end,
    ["Card Sharp"] = simple_return("xmult", "extra", "Xmult"),
    ["Red Card"]   = simple_return("mult", "mult"),
    ["Madness"] = function (card, context)
        card.ability.x_mult = card.ability.x_mult + card.ability.extra
        local destructable_jokers = {}
        for joker in Spectrallib.iter.areacards(G.jokers) do
            if
                joker ~= card
                and not joker.ability.eternal
                and not joker.getting_sliced
            then
                table.insert(destructable_jokers, joker)
            end
        end
        if #destructable_jokers <= 0 then return end

        local joker_to_destroy = pseudorandom_element(destructable_jokers, pseudoseed("madness"))
        SMODS.destroy_cards(joker_to_destroy, {
            colours = { G.C.RED },
            destroy_func = function (destroyed_card, args)
                destroyed_card:juice_up(0.8, 0.8)
                return destroyed_card:start_dissolve({ G.C.RED }, nil, 1.6)
            end
        })

        return { xmult = card.ability.x_mult }
    end,
    ["Square Joker"] = simple_return("chips", "extra", "chips"),
    ["Seance"]       = add_consumable("Spectral", 'sea'),
    ["Riff-raff"] = function (card, context)
        local empty_slots = G.jokers.config.card_limit - (#G.jokers.cards + G.GAME.joker_buffer)
        local jokers_to_create = math.min(2, empty_slots)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.4,
            func = function()
                for _ = 1, jokers_to_create do
                    SMODS.add_card({
                        set = "Joker",
                        rarity = 0,
                        key_append = "rif"
                    })
                end
            end,
        }))
    end,
    ["Vampire"]  = simple_return("xmult", "x_mult"),
    -- ["Shortcut"]
    ["Hologram"] = simple_return("xmult", "x_mult"),
    ["Vagabond"] = add_consumable("Tarot", 'vag'),
    ["Baron"]    = simple_return("xmult", "extra"),
    ["Cloud 9"] = function (card, context)
        return { dollars = card.ability.extra*(card.ability.nine_tally or 1) }
    end,
    ["Rocket"]  = simple_return("dollars", "extra", "dollars"),
    ["Obelisk"] = simple_return("xmult", "x_mult"), -- Sobelisk
    --#endregion
    --#region Page 6
    ["Midas Mask"] = function (card, context)
        local cardlist
        if context.scoring_hand then
            cardlist = context.scoring_hand
        elseif G and G.hand and #G.hand.highlighted > 0 then
            cardlist = G.hand.highlighted
        end

        for select_card in Spectrallib.iter.areacards(cardlist) do
            if select_card:is_face() then
                select_card:set_ability(G.P_CENTERS.m_gold, nil, true)
                G.E_MANAGER:add_event(Event({
                    trigger = "after",
                    delay = 0.4,
                    func = function()
                        select_card:juice_up()
                        return true
                    end,
                }))
            end
        end
    end,
    ["Luchador"] = function (card, context)
        if G.GAME.blind and ((not G.GAME.blind.disabled) and (G.GAME.blind:get_type() == "Boss")) then
            G.GAME.blind:disable()
        end
    end,
    ["Photograph"] = simple_return("xmult", "extra"),
    ["Gift Card"] = function (card, context)
        for select_card in Spectrallib.iter.areacards{G.jokers, G.consumeables} do
            if select_card.set_cost then
                select_card.ability.extra_value = (select_card.ability.extra_value or 0) + card.ability.extra
                select_card:set_cost()
            end
        end
    end,
    ["Turtle Bean"] = function (card, context)
        G.hand:change_size(-card.ability.extra.h_size)
        card.ability.extra.h_size = card.ability.extra.h_size - card.ability.extra.h_mod
        G.hand:change_size(card.ability.extra.h_size)
    end,
    ["Erosion"] = function (card, context)
        local mult_multiplier = G.GAME.starting_deck_size - #G.playing_cards
        return { mult = card.ability.extra * mult_multiplier }
    end,
    ["Reserved Parking"] = simple_return("dollars", "extra", "dollars"),
    ["Mail-In Rebate"]   = simple_return("dollars", "extra"),
    -- ["To the Moon"]
    ["Hallucination"]    = add_consumable("Tarot", 'hal'),
    ["Fortune Teller"] = function (card, context)
        return { mult = G.GAME.consumeable_usage_total.tarot or 1 }
    end,
    ["Juggler"] = function (card, context)
        G.hand:change_size(card.ability.h_size)
    end,
    ["Drunkard"] = function (card, context)
        ease_discard(card.ability.d_size)
    end,
    ["Stone Joker"] = function (card, context)
        return { chips = card.ability.extra * card.ability.stone_tally }
    end,
    ["Golden Joker"] = simple_return("dollars", "extra"),
    --#endregion
    --#region Page 7
    ["Lucky Cat"]     = simple_return("xmult", "x_mult"),
    ["Baseball Card"] = simple_return("xmult", "extra"),
    ["Bull"] = function (card, context)
        local current_dollars = G.GAME.dollars + (G.GAME.dollar_buffer or 0)
        local chips_multiplier = math.max(0, current_dollars)
        return { chips = card.ability.extra * chips_multiplier }
    end,
    ["Diet Cola"] = function (card, context)
        Spectrallib.event(function ()
            add_tag(Tag("tag_double"))
            play_sound("generic1", 0.9 + math.random() * 0.1, 0.8)
            play_sound("holo1", 1.2 + math.random() * 0.1, 0.4)
            return true
        end)
    end,
    ["Trading Card"]   = simple_return("dollars", "extra"),
    ["Flash Card"]     = simple_return("mult", "mult"),
    ["Popcorn"]        = simple_return("mult", "mult"),
    ["Spare Trousers"] = simple_return("mult", "mult"),
    ["Ancient Joker"]  = simple_return("xmult", "extra"),
    ["Ramen"]          = simple_return("xmult", "x_mult"),
    ["Walkie Talkie"] = function (card, context)
        return {
            mult = card.ability.extra.mult,
            chips = card.ability.extra.chips
        }
    end,
    -- ["Seltzer"]
    ["Castle"]      = simple_return("chips", "extra", "chips"),
    ["Smiley Face"] = simple_return("mult", "extra"),
    ["Campfire"]    = simple_return("xmult", "x_mult"),
    --#endregion
    --#region Page 8
    ["Golden Ticket"] = simple_return("dollars", "extra"),
    -- ["Mr Bones"]
    ["Acrobat"]       = simple_return("xmult", "extra"),
    -- ["Sock and Buskin"]
    ["Swashbuckler"]  = simple_return("mult", "mult"),
    ["Troubadour"] = function (card, context)
        G.hand:change_size(card.ability.extra.h_size)
        G.GAME.round_resets.hands = G.GAME.round_resets.hands + card.ability.extra.h_plays
    end,
    ["Certificate"] = function (card, context)
        local _card = SMODS.create_card({
            set = "Base",
            seal = SMODS.poll_seal({
                guaranteed = true,
                type_key = 'certsl'
            }),
            area = G.discard,
            key_append = 'cert_fr'
        })
        Spectrallib.event(function ()
            G.hand:emplace(_card)
            _card:start_materialize()
            G.GAME.blind:debuff_card(_card)
            G.hand:sort()
            return true
        end)
    end,
    -- ["Smeared Joker"]
    ["Throwback"]   = simple_return("xmult", "x_mult"),
    -- ["Hanging Chad"]
    ["Rough Gem"]   = simple_return("dollars", "extra"),
    ["Bloodstone"]  = simple_return("xmult", "extra", "Xmult"),
    ["Arrowhead"]   = simple_return("chips", "extra"),
    ["Onyx Agate"]  = simple_return("mult", "extra"),
    ["Glass Joker"] = simple_return("xmult", "x_mult"),
    --#endregion
    --#region Page 9
    ["Flower Pot"] = simple_return("xmult", "extra"),
    ["Blueprint"] = function (card, context)
        local my_pos = card.rank
        local other_joker = G.jokers.cards[my_pos + 1]
        if other_joker then
            local results = Spectrallib.get_forcetrigger_results(other_joker, context)
            if results and results.jokers then
                results.jokers.card = card
                SMODS.calculate_effect(results.jokers)
            end
        end
    end,
    ["Wee Joker"] = simple_return("chips", "extra", "chips"),
    ["Merry Andy"] = function (card, context)
        ease_discard(card.ability.d_size)
        G.hand:change_size(card.ability.h_size)
    end,
    -- ["Oops! All 6s"]
    ["The Idol"]      = simple_return("xmult", "extra"),
    ["Seeing Double"] = simple_return("xmult", "extra"),
    ["Matador"]       = simple_return("dollars", "extra"),
    ["Hit The Road"]  = simple_return("xmult", "x_mult"),
    ["The Duo"]       = hand_xmult,
    ["The Trio"]      = hand_xmult,
    ["The Family"]    = hand_xmult,
    ["The Order"]     = hand_xmult,
    ["The Tribe"]     = hand_xmult,
    --#endregion
    --#region Page 10
    ["Stuntman"] = function (card, context)
        G.hand:change_size(-card.ability.extra.h_size)
        return { chips = card.ability.extra.chip_mod }
    end,
    ["Invisible Joker"] = function (card, context)
        local jokers = {}
        for other_joker in Spectrallib.iter.areacards(G.jokers) do
            if other_joker ~= card then
                table.insert(jokers, other_joker)
            end
        end
        if #jokers <= 0 then return end

        Spectrallib.event(function ()
            local select_card = pseudorandom_element(jokers, pseudoseed("invisible"))
            local copy_card = SMODS.copy_card(select_card, {
                strip_edition = (select_card.edition or {}).key == "e_negative"
            })
            if copy_card.ability.invis_rounds then
                copy_card.ability.invis_rounds = 0
            end
            return true
        end)
    end,
    ["Brainstorm"] = function (card, context)
        local other_joker = G.jokers.cards[1]
        if other_joker then
            local results = Spectrallib.get_forcetrigger_results(other_joker, context)
            if results and results.jokers then
                results.jokers.card = card
                SMODS.calculate_effect(results.jokers)
            end
        end
    end,
    ["Satellite"] = function (card, context)
        local planets_used = 0
        for _,consumable in pairs(G.GAME.consumeable_usage) do
            if consumable.set == "Planet" then
                planets_used = planets_used + 1
            end
        end
        if planets_used <= 0 then return end
        return { dollars = card.ability.extra*planets_used }
    end,
    ["Shoot The Moon"] = function (card, context)
        return  { mult = 13 }
    end,
    ["Driver's License"] = simple_return("xmult", "extra"),
    ["Cartomancer"]      = add_consumable("Tarot", 'car'),
    ["Burnt Joker"] = function (card, context)
        if #G.hand.highlighted > 0 then
            local text, disp_text = G.FUNCS.get_poker_hand_info(G.hand.highlighted)
            update_hand_text({ sound = "button", volume = 0.7, pitch = 0.8, delay = 0.3 }, {
                handname = localize(text, "poker_hands"),
                chips = G.GAME.hands[text].chips,
                mult  = G.GAME.hands[text].mult,
                level = G.GAME.hands[text].level,
            })
            level_up_hand(card, text, nil, 1)
            update_hand_text(
                { sound = "button", volume = 0.7, pitch = 1.1, delay = 0 },
                { mult = 0, chips = 0, handname = "", level = "" }
            )
        elseif context.scoring_name then
            level_up_hand(card, context.scoring_name)
        end
    end,
    ["Bootstraps"] = function (card, context)
        local current_dollars = G.GAME.dollars + (G.GAME.dollar_buffer or 0)
        local mult_multiplier = math.floor(current_dollars / card.ability.extra.dollars)
        return { mult = card.ability.mult*mult_multiplier }
    end,
    ["Caino"]     = simple_return("xmult", "caino_xmult"),
    ["Triboulet"] = simple_return("xmult", "extra"),
    ["Yorick"]    = simple_return("xmult", "x_mult"),
    ["Chicot"] = function (card, context)
        if G.GAME.blind and G.GAME.blind:get_type() == "Boss" then
            G.GAME.blind:disable()
        end
    end,
    ["Perkeo"] = function (card, context)
        local eligible_consumables = {}
        for other_card in Spectrallib.iter.areacards(G.consumeables) do
            if other_card.ability.consumeable then
                table.insert(eligible_consumables, other_card)
            end
        end
        if #eligible_consumables <= 0 then return end

        Spectrallib.event(function ()
            local select_card = pseudorandom_element(eligible_consumables, pseudoseed("perkeo"))
            local copy_card = SMODS.copy_card(select_card)
            copy_card:set_edition("e_negative", true)
            return true
        end)
    end,
    ["Perkeo (Incantation)"] = function (card, context)
        if G.consumeables.cards[1] then
            G.E_MANAGER:add_event(Event({
                func = function()
                    local total, checked, center = 0, 0, nil
                    for i = 1, #G.consumeables.cards do
                        total = total + (G.consumeables.cards[i]:getQty())
                    end
                    local poll = pseudorandom(pseudoseed("perkeo")) * total
                    for i = 1, #G.consumeables.cards do
                        checked = checked + (G.consumeables.cards[i]:getQty())
                        if checked >= poll then
                            center = G.consumeables.cards[i]
                            break
                        end
                    end
                    local _card = copy_card(center, nil)
                    _card:set_edition({ negative = true }, true)
                    _card:add_to_deck()
                    G.consumeables:emplace(_card)
                    return true
                end,
            }))
        end
    end
    --#endregion
}
