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


function deep_copy(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            copy[k] = deep_copy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function update_location_mapping()
	--resetting LOCATION_MAPPING to a clean version
	LOCATION_MAPPING = deep_copy(BASE_LOCATION_MAPPING)

    --dealing with boss shuffling
	local boss_indices = {}

	for i = 0, 17 do
		table.insert(boss_indices, i)
	end

	for i = 100, 104 do
		table.insert(boss_indices, i)
	end

    for _, original_boss_index in ipairs(boss_indices) do
    	local new_boss_index = LEVEL_MAP[tostring(original_boss_index)]

   		if new_boss_index then
        	local original_boss_complete_code = BOSS_COMPLETE_MAP_CODES[original_boss_index]
			local original_boss_top_grade_code = BOSS_TOP_GRADE_MAP_CODES[original_boss_index]
			local original_boss_chaliced_code = BOSS_CHALICED_MAP_CODES[original_boss_index]

        	-- Normal completion shuffle
        	local new_boss_complete_id = BOSS_COMPLETE_IDS[new_boss_index]
        	table.insert(LOCATION_MAPPING[new_boss_complete_id], { original_boss_complete_code })

        	-- Top grade shuffle
        	local new_boss_top_grade_id = BOSS_TOP_GRADE_IDS[new_boss_index]
        	table.insert(LOCATION_MAPPING[new_boss_top_grade_id], { original_boss_top_grade_code })

			-- Chalice completion shuffle
        	local new_boss_chaliced_id = BOSS_CHALICED_IDS[new_boss_index]
        	table.insert(LOCATION_MAPPING[new_boss_chaliced_id], { original_boss_chaliced_code })
		end
    end

	--dealing with run 'n gun shuffling
	for original_rungun_index = 28, 33 do
    	local new_rungun_index = LEVEL_MAP[tostring(original_rungun_index)]

   		if new_rungun_index then
        	local original_rungun_complete_code = RUNGUN_COMPLETE_MAP_CODES[original_rungun_index]
			local original_rungun_top_grade_code = RUNGUN_TOP_GRADE_MAP_CODES[original_rungun_index]
			local original_rungun_chaliced_code = RUNGUN_CHALICED_MAP_CODES[original_rungun_index]

        	-- Normal completion shuffle
        	local new_rungun_complete_id = RUNGUN_COMPLETE_IDS[new_rungun_index]
        	table.insert(LOCATION_MAPPING[new_rungun_complete_id], { original_rungun_complete_code })

        	-- Top grade shuffle
			for i = 1, 2 do
        	local new_rungun_top_grade_id = RUNGUN_TOP_GRADE_IDS[new_rungun_index][i]
        	table.insert(LOCATION_MAPPING[new_rungun_top_grade_id], { original_rungun_top_grade_code })
			end

        	-- Chalice completion shuffle
        	local new_rungun_chaliced_id = RUNGUN_CHALICED_IDS[new_rungun_index]
        	table.insert(LOCATION_MAPPING[new_rungun_chaliced_id], { original_rungun_chaliced_code })

			-- Coin shuffle
			for i = 1, 5 do
				local new_rungun_coin_id = RUNGUN_COIN_IDS[new_rungun_index][i]
				local original_rungun_coin_code = RUNGUN_COIN_MAP_CODES[original_rungun_index][i]
				table.insert(LOCATION_MAPPING[new_rungun_coin_id], { original_rungun_coin_code }) 
			end
		end
    end
end

function countSetBits(num)
    local count = 0
    -- Clear the top 32 signed bits (if there are any) so that we get the number as unsigned
    num = num & 0xFFFFFFFF
    while num > 0 do
        --Remove the least significant set bit
        num = num & (num - 1)
        count = count + 1
    end
    return count
end