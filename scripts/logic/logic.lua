-- put logic functions here using the Lua API: https://github.com/black-sliver/PopTracker/blob/master/doc/PACKS.md#lua-interface
-- don't be afraid to use custom logic functions. it will make many things a lot easier to maintain, for example by adding logging.
-- to see how this function gets called, check: locations/locations.json
-- example:
function has_more_then_n_consumable(n)
    local count = Tracker:ProviderCountForCode('consumable')
    local val = (count > tonumber(n))
    if ENABLE_DEBUG_LOG then
        print(string.format("called has_more_then_n_consumable: count: %s, n: %s, val: %s", count, n, val))
    end
    if val then
        return 1 -- 1 => access is in logic
    end
    return 0 -- 0 => no access
end

LEVEL_ID_TO_ISLE_INDEX = {
    ["0"] = "1",
    ["1"] = "1",
    ["2"] = "1",
    ["3"] = "1",
    ["4"] = "2",
    ["5"] = "2",
    ["6"] = "2",
    ["7"] = "3",
    ["8"] = "3",
    ["9"] = "3",
    ["10"] = "3",
    ["11"] = "3",
    ["12"] = "1",
    ["13"] = "2",
    ["14"] = "2",
    ["15"] = "3",
    ["16"] = "3",
    ["17"] = "hell",
    ["28"] = "1",
    ["29"] = "1",
    ["30"] = "2",
    ["31"] = "2",
    ["32"] = "3",
    ["33"] = "3"
}

-- Default values
LEVEL_MAP = {
    ["0"] = 0,
    ["1"] = 1,
    ["2"] = 2,
    ["3"] = 3,
    ["4"] = 4,
    ["5"] = 5,
    ["6"] = 6,
    ["7"] = 7,
    ["8"] = 8,
    ["9"] = 9,
    ["10"] = 10,
    ["11"] = 11,
    ["12"] = 12,
    ["13"] = 13,
    ["14"] = 14,
    ["15"] = 15,
    ["16"] = 16,
    ["17"] = 17,
    ["28"] = 28,
    ["29"] = 29,
    ["30"] = 30,
    ["31"] = 31,
    ["32"] = 32,
    ["33"] = 33
}

    -- Default Values
	CONTRACT_REQUIREMENT_ISLE_2 = 5
	CONTRACT_REQUIREMENT_ISLE_3 = 10
    CONTRACT_REQUIREMENT_HELL = 17

-- Checks whether the map location for level_index is cleared    
function boss_complete(level_index)
    return Tracker:FindObjectForCode(BOSS_COMPLETE_MAP_CODES[level_index]).AccessibilityLevel == AccessibilityLevel["Cleared"] 
end

-- Checks whether the map location for level_index is cleared
function run_n_gun_complete(level_index) 
    return Tracker:FindObjectForCode(RUNGUN_COMPLETE_MAP_CODES[level_index]).AccessibilityLevel == AccessibilityLevel["Cleared"] 
end

function freemove_isles()
    return Tracker:FindObjectForCode("freemove_isles").Active
end

function can_access_isle_1()
    return true
end

function can_access_isle_2()
    local contracts = Tracker:FindObjectForCode("contract").AcquiredCount
    return (boss_complete(3)) and contracts >= CONTRACT_REQUIREMENT_ISLE_2
end

function can_access_isle_3()
    local contracts = Tracker:FindObjectForCode("contract").AcquiredCount
    return can_access_grim_level() and contracts >= CONTRACT_REQUIREMENT_ISLE_3
end

function can_access_hell()
    return boss_complete(11)
end

local isle_access_funcs = {
    ["1"] = can_access_isle_1,
    ["2"] = can_access_isle_2,
    ["3"] = can_access_isle_3,
    ["hell"] = can_access_hell
}

function get_contract_requirement(isle)
    if isle == "1" then return 0 end
    if isle == "2" then return CONTRACT_REQUIREMENT_ISLE_2 end
    if isle == "3" then return CONTRACT_REQUIREMENT_ISLE_3 end
    if isle == "hell" then return CONTRACT_REQUIREMENT_ISLE_3 end
end

function can_access_isle(isle_index)
    local contracts = Tracker:FindObjectForCode("contract").AcquiredCount
    if freemove_isles() then
        return contracts >= get_contract_requirement(isle_index)
    else
        return isle_access_funcs[isle_index]()
    end
end

function can_access_level(level_index)
    if level_index == "17" then
        return can_access_king_dice_level()
    elseif freemove_isles() then
        local isle_index = LEVEL_ID_TO_ISLE_INDEX[level_index]
        return can_access_isle(isle_index)
    else
        return ACCESS_FUNCS[tonumber(level_index)]()
    end
end

function can_beat_boss(level_index)
    local boss_index = LEVEL_MAP[level_index]
    if can_access_level(level_index) then
        return Tracker:FindObjectForCode(BOSS_COMPLETE_SUMMARY_CODES[boss_index]).AccessibilityLevel
    else
        return AccessibilityLevel["None"]
    end
end

function can_top_grade_boss(level_index)
    local boss_index = LEVEL_MAP[level_index]
    if can_beat_boss(level_index) ~= AccessibilityLevel["None"] then
        return Tracker:FindObjectForCode(BOSS_TOP_GRADE_SUMMARY_CODES[boss_index]).AccessibilityLevel
    else
        return AccessibilityLevel["None"]
    end
end

function can_beat_rungun(level_index)
    local rungun_index = LEVEL_MAP[level_index]
    if can_access_level(level_index) then 
        return Tracker:FindObjectForCode(RUNGUN_COMPLETE_SUMMARY_CODES[rungun_index]).AccessibilityLevel
    else
        return AccessibilityLevel["None"]
    end
end

function can_top_grade_rungun(level_index)
    local rungun_index = LEVEL_MAP[level_index]
    if can_beat_rungun(level_index) ~= AccessibilityLevel["None"] then
        return Tracker:FindObjectForCode(RUNGUN_TOP_GRADE_SUMMARY_CODES[rungun_index]).AccessibilityLevel
    else
        return AccessibilityLevel["None"]
    end
end

function can_get_coin_i_in_rungun_j(coin_index,level_index)
    local rungun_index = LEVEL_MAP[level_index]
    local coin_code = RUNGUN_COIN_SUMMARY_CODES[rungun_index][tonumber(coin_index)]
    if can_access_level(level_index) then 
        return Tracker:FindObjectForCode(coin_code).AccessibilityLevel
    else
        return AccessibilityLevel["None"]
    end    
end

function can_access_root_pack_level()
    return true
end

    function can_access_goopy_level()
            return true
        end

    function can_access_cagney_carnation_level()
            return true
        end

    function can_access_ribby_and_croaks_level()
            return boss_complete(0)
        end

    function can_access_bon_bon_level()
            return can_access_isle_2()
        end

    function can_access_beppi_level()
            return can_access_isle_2()
        end

    function can_access_grim_level()
            return boss_complete(4) or boss_complete(5)
        end

    function can_access_honeybottoms_level()
            return can_access_isle_3()
        end

    function can_access_briney_level()
            return can_access_isle_3()
        end

    function can_access_werner_level()
            return boss_complete(10) or 
                    (boss_complete(8) and run_n_gun_complete(32)) or
                    (boss_complete(7) and run_n_gun_complete(33))
        end

    function can_access_sally_level()
            return (boss_complete(7)) or
                    (boss_complete(9)) or
                    (boss_complete(15))
        end

    function can_access_phantom_express_level()
            return boss_complete(10)
        end


    function can_access_hilda_level()
            return boss_complete(1) 
        end

    function can_access_djimmi_level()
            return can_access_isle_2()
        end

    function can_access_wally_level()
            return boss_complete(4) or boss_complete(5)
        end

    function can_access_cala_maria_level()
            return boss_complete(8)
        end

    function can_access_kahl_level()
            return boss_complete(7) or
                    boss_complete(15) or
                    boss_complete(9)
        end
    
    function can_access_king_dice_level()
        local contracts = Tracker:FindObjectForCode("contract").AcquiredCount
            return can_access_isle("hell") and contracts >= CONTRACT_REQUIREMENT_HELL
        end

    function can_access_forest_follies_level()
            return true
        end

    function can_access_treetop_trouble_level()
            return true
        end

    function can_access_funfair_fever_level()
            return can_access_wally_level()
        end

    function can_access_funhouse_frazzle_level()
            return can_access_grim_level()
        end

    function can_access_rugged_ridge_level()
            return can_access_kahl_level()
        end

    function can_access_perilous_piers_level()
            return can_access_cala_maria_level()
        end
    

ACCESS_FUNCS = {
    [0] = can_access_root_pack_level,
    [1] = can_access_goopy_level,
    [2] = can_access_ribby_and_croaks_level,
    [3] = can_access_cagney_carnation_level,
    [4] = can_access_bon_bon_level,
    [5] = can_access_beppi_level,
    [6] = can_access_grim_level,
    [7] = can_access_honeybottoms_level,
    [8] = can_access_briney_level,
    [9] = can_access_werner_level,
    [10] = can_access_sally_level,
    [11] = can_access_phantom_express_level,
    [12] = can_access_hilda_level,
    [13] = can_access_djimmi_level,        
    [14] = can_access_wally_level,           
    [15] = can_access_cala_maria_level,
    [16] = can_access_kahl_level,  
    [17] = can_access_king_dice_level,   
    [28] = can_access_forest_follies_level,
    [29] = can_access_treetop_trouble_level,
    [30] = can_access_funfair_fever_level,
    [31] = can_access_funhouse_frazzle_level,
    [32] = can_access_perilous_piers_level,
    [33] = can_access_rugged_ridge_level
}

function can_access_secret_coin(isle_index)
    if isle_index == "1" then
        return (boss_complete(0)) and
                (boss_complete(1)) and
                (boss_complete(2)) and
                (boss_complete(3)) and
                (boss_complete(12))
    elseif freemove_isles() then
        return can_access_isle(isle_index)
    elseif isle_index == "2" then
        return can_access_grim_level()
    elseif isle_index == "3" then
        return can_access_cala_maria_level()
    elseif isle_index == "hell" then
        return can_access_hell()
    else
        return false
    end
end

function can_complete_ginger_quest()   
    return can_access_level("14")
end

function can_complete_buster_quest()
    return can_access_level("6") and (Tracker:FindObjectForCode("parry").Active or Tracker:FindObjectForCode("p_sugar").Active)
end

function can_access_canteen_hughes()
    return can_access_isle("2")
end

function can_complete_barbershop_quest()
    return can_access_level("14")
end

function can_complete_silverworth_quest()
    return false
end

function can_complete_pacifist_quest()
    return false
end

function can_access_shop(shop_index)
    if freemove_isles() then
        return can_access_isle(shop_index)
    elseif shop_index == "1" then
        return true
    elseif shop_index == "2" then
        return boss_complete(6) or
                boss_complete(13) or
                boss_complete(14) or
                run_n_gun_complete(30) or
                run_n_gun_complete(31)
    elseif shop_index == "3" then
        return can_access_werner_level()
    else
        return false
    end
end

function can_buy_item_type(item_type)
    if item_type == "charm" then
        return Tracker:FindObjectForCode("current_coin_count").AcquiredCount >= 3
    elseif item_type == "weapon" then
        return Tracker:FindObjectForCode("current_coin_count").AcquiredCount >= 4
    else
        return false
    end
end

function can_access_mausoleum_1()
    if freemove_isles() then
        return true
    else
        return (boss_complete(2)) or
                (run_n_gun_complete(28)) or
                (run_n_gun_complete(29))
    end
end
function can_access_mausoleum_2()
    return can_access_shop("2")
end

function can_access_mausoleum_3()
    return can_access_shop("3")
end

function can_beat_mausoleum(mausoleum_index)
    if mausoleum_index == "1" then
        if can_access_mausoleum_1() then
            return Tracker:FindObjectForCode("@Mausoleum I Summary").AccessibilityLevel
        else
            return AccessibilityLevel["None"]
        end
    elseif mausoleum_index == "2" then
        if can_access_mausoleum_2() then
            return Tracker:FindObjectForCode("@Mausoleum II Summary").AccessibilityLevel
        else
            return AccessibilityLevel["None"]
        end
        
    elseif mausoleum_index == "3" then
        if can_access_mausoleum_3() then
            return Tracker:FindObjectForCode("@Mausoleum III Summary").AccessibilityLevel
        else
            return AccessibilityLevel["None"]
        end
    end
end