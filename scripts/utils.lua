-- from https://stackoverflow.com/questions/9168058/how-to-dump-a-table-to-console
-- dumps a table in a readable string
function dump_table(o, depth)
    if depth == nil then
        depth = 0
    end
    if type(o) == 'table' then
        local tabs = ('\t'):rep(depth)
        local tabs2 = ('\t'):rep(depth + 1)
        local s = '{\n'
        for k, v in pairs(o) do
            local kc = k
            if type(k) ~= 'number' then
                kc = '"' .. k .. '"'
            end
            s = s .. tabs2 .. '[' .. kc .. '] = ' .. dump_table(v, depth + 1) .. ',\n'
        end
        return s .. tabs .. '}'
    else
        return tostring(o)
    end
end

function table_contains_value(table, value)
    for _, v in ipairs(table) do
        if v == value then return true end
    end
    return false
end

function calculate_coin_count(changed_code)
    local total = Tracker:FindObjectForCode("coin").AcquiredCount

    -- subtract charm costs
    for _, charm_code in ipairs(SHOP_CHARM_CODES) do
        local charm_location = Tracker:FindObjectForCode(charm_code)
        if charm_location and charm_location.AccessibilityLevel == AccessibilityLevel["Cleared"] then
            total = total - 3
        end
    end

    -- subtract weapon costs
    for _, weapon_code in ipairs(SHOP_WEAPON_CODES) do
        local weapon_location = Tracker:FindObjectForCode(weapon_code)
        if weapon_location and weapon_location.AccessibilityLevel == AccessibilityLevel["Cleared"] then
            total = total - 4
        end
    end

    Tracker:FindObjectForCode("current_coin_count").AcquiredCount = total
end

