-- this is an example/default implementation for AP autotracking
-- it will use the mappings defined in item_mapping.lua and location_mapping.lua to track items and locations via their ids
-- it will also keep track of the current index of on_item messages in CUR_INDEX
-- addition it will keep track of what items are local items and which one are remote using the globals LOCAL_ITEMS and GLOBAL_ITEMS
-- this is useful since remote items will not reset but local items might
-- if you run into issues when touching A LOT of items/locations here, see the comment about Tracker.AllowDeferredLogicUpdate in autotracking.lua
BASE_LOCATION_ID = 12905168

ScriptHost:LoadScript("scripts/autotracking/item_mapping.lua")
ScriptHost:LoadScript("scripts/autotracking/location_mapping.lua")
-- used for hint tracking to quickly map hint status to a value from the Highlight enum
HINT_STATUS_MAPPING = {}
if Highlight then
	HINT_STATUS_MAPPING = {
		[20] = Highlight.Avoid,
		[40] = Highlight.None,
		[10] = Highlight.NoPriority,
		[0] = Highlight.Unspecified,
		[30] = Highlight.Priority,
	}
end

CUR_INDEX = -1
LOCAL_ITEMS = {}
GLOBAL_ITEMS = {}

-- gets the data storage key for hints for the current player
-- returns nil when not connected to AP
function getHintDataStorageKey()
	if AutoTracker:GetConnectionState("AP") ~= 3 or Archipelago.TeamNumber == nil or Archipelago.TeamNumber == -1 or Archipelago.PlayerNumber == nil or Archipelago.PlayerNumber == -1 then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print("Tried to call getHintDataStorageKey while not connect to AP server")
		end
		return nil
	end
	return string.format("_read_hints_%s_%s", Archipelago.TeamNumber, Archipelago.PlayerNumber)
end

-- resets an item to its initial state
function resetItem(item_code, item_type)
	local obj = Tracker:FindObjectForCode(item_code)
	if obj then
		item_type = item_type or obj.Type
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("resetItem: resetting item %s of type %s", item_code, item_type))
		end
		if item_type == "toggle" or item_type == "toggle_badged" then
			obj.Active = false
		elseif item_type == "progressive" or item_type == "progressive_toggle" then
			obj.CurrentStage = 0
			obj.Active = false
		elseif item_type == "consumable" then
			obj.AcquiredCount = 0
		elseif item_type == "static" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("resetItem: tried to reset static item %s", item_code))
		elseif item_type == "composite_toggle" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format(
				"resetItem: tried to reset composite_toggle item %s but composite_toggle cannot be accessed via lua." ..
				"Please use the respective left/right toggle item codes instead.", item_code))
		elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("resetItem: unknown item type %s for code %s", item_type, item_code))
		end
	elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("resetItem: could not find item object for code %s", item_code))
	end
end

-- advances the state of an item
function incrementItem(item_code, item_type, multiplier)
	local obj = Tracker:FindObjectForCode(item_code)
	if obj then
		item_type = item_type or obj.Type
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("incrementItem: code: %s, type %s", item_code, item_type))
		end
		if item_type == "toggle" or item_type == "toggle_badged" then
			obj.Active = true
		elseif item_type == "progressive" or item_type == "progressive_toggle" then
			if obj.Active then
				obj.CurrentStage = obj.CurrentStage + 1
			else
				obj.Active = true
			end
		elseif item_type == "consumable" then
			obj.AcquiredCount = obj.AcquiredCount + obj.Increment * multiplier
		elseif item_type == "static" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("incrementItem: tried to increment static item %s", item_code))
		elseif item_type == "composite_toggle" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format(
				"incrementItem: tried to increment composite_toggle item %s but composite_toggle cannot be access via lua." ..
				"Please use the respective left/right toggle item codes instead.", item_code))
		elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("incrementItem: unknown item type %s for code %s", item_type, item_code))
		end
	elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("incrementItem: could not find object for code %s", item_code))
	end
end

function getAutoTabDataStorageKeys()
	if AutoTracker:GetConnectionState("AP") ~= 3 or Archipelago.TeamNumber == nil or Archipelago.TeamNumber == -1 or Archipelago.PlayerNumber == nil or Archipelago.PlayerNumber == -1 then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print("Tried to call getAutoTabDataStorageKeys while not connect to AP server")
		end
		return nil
	end
	local auto_tab_keys = { "current_level", "current_map" }
	for i, key in ipairs(auto_tab_keys) do
		auto_tab_keys[i] = string.format("Slot:%s:%s", Archipelago.PlayerNumber, key)
	end

	return auto_tab_keys
end

function getDeathlinkDataStorageKey()
	if AutoTracker:GetConnectionState("AP") ~= 3 or Archipelago.TeamNumber == nil or Archipelago.TeamNumber == -1 or Archipelago.PlayerNumber == nil or Archipelago.PlayerNumber == -1 then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print("Tried to call getAutoTabDataStorageKeys while not connect to AP server")
		end
		return nil
	end
	local deathlink_key = string.format("Slot:%s:deathlink_grace_count", Archipelago.PlayerNumber)
	return deathlink_key
end

function getQuestDataStorageKeys()
	if AutoTracker:GetConnectionState("AP") ~= 3 or Archipelago.TeamNumber == nil or Archipelago.TeamNumber == -1 or Archipelago.PlayerNumber == nil or Archipelago.PlayerNumber == -1 then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print("Tried to call getAutoTabDataStorageKeys while not connect to AP server")
		end
		return nil
	end
	local quest_keys = { "agrade_levels", "pacifist_levels", "dlc_chaliced_levels_p1", "dlc_chaliced_levels_p2" }
	for i, key in ipairs(quest_keys) do
		quest_keys[i] = string.format("Slot:%s:%s", Archipelago.PlayerNumber, key)
	end

	return quest_keys
end

function getMapsVisitedDataStorageKey()
	if AutoTracker:GetConnectionState("AP") ~= 3 or Archipelago.TeamNumber == nil or Archipelago.TeamNumber == -1 or Archipelago.PlayerNumber == nil or Archipelago.PlayerNumber == -1 then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print("Tried to call getAutoTabDataStorageKeys while not connect to AP server")
		end
		return nil
	end
	local maps_visited_key = string.format("Slot:%s:maps_visited", Archipelago.PlayerNumber)
	return maps_visited_key
end

-- apply everything needed from slot_data, called from onClear
function apply_slot_data(slot_data)
	-- put any code here that slot_data should affect (toggling setting items for example)

	-- setting the goal
	local goal_handlers = {
		[2] = function(slot_data)
				Tracker:FindObjectForCode("collect_contracts").AcquiredCount = 
				slot_data["contract_goal_requirements"]
		end,
		
		[4] = function(slot_data)
				Tracker:FindObjectForCode("buy_out_shop").Active = true
		end,

		[8] = function(slot_data)
				Tracker:FindObjectForCode("beat_saltbaker").Active = true
				Tracker:FindObjectForCode("collect_ingredients").AcquiredCount = 
					slot_data["dlc_ingredient_requirements"]
		end,

		[9] = function(slot_data)
				Tracker:FindObjectForCode("beat_devil").Active = true
				Tracker:FindObjectForCode("beat_saltbaker").Active = true
				Tracker:FindObjectForCode("collect_contracts").AcquiredCount = slot_data["contract_requirements"][1]
				Tracker:FindObjectForCode("collect_ingredients").AcquiredCount = slot_data["dlc_ingredient_requirements"]
		end,

		[16] = function(slot_data)
				Tracker:FindObjectForCode("collect_ingredients").AcquiredCount = 
					slot_data["dlc_ingredient_goal_requirements"]
		end,

		[18] = function(slot_data)
					Tracker:FindObjectForCode("collect_contracts").AcquiredCount = slot_data["contract_goal_requirements"]
					Tracker:FindObjectForCode("collect_ingredients").AcquiredCount = slot_data["dlc_ingredient_goal_requirements"]
		end,
	}

	local goal = slot_data["mode"]
	if goal_handlers[goal] then
		goal_handlers[goal](slot_data)
	else
		Tracker:FindObjectForCode("beat_devil").Active = true
		Tracker:FindObjectForCode("collect_contracts").AcquiredCount = 
			slot_data["contract_requirements"][1]
	end

	Tracker:FindObjectForCode("use_dlc").Active = slot_data["use_dlc"]
	Tracker:FindObjectForCode("expert_mode").Active = slot_data["expert_mode"]
	Tracker:FindObjectForCode("hard_logic").Active = slot_data["logic_mode"]
	Tracker:FindObjectForCode("freemove_isles").Active = slot_data["freemove_isles"]
	Tracker:FindObjectForCode("kings_leap_p_sugar").Active = slot_data["dlc_kingsleap_psugar"]
		Tracker:FindObjectForCode("chess_chalice_checks").Active = slot_data["dlc_chess_chalice_checks"]

	if not (slot_data["deathlink"] == 0) then
		Tracker:FindObjectForCode("deathlink").AcquiredCount = slot_data["deathlink_grace_count"]
	end

	-- Inferring settings based on existing location
	local checked_locations = Archipelago.CheckedLocations
	local missing_locations = Archipelago.MissingLocations

	local IDs = {
		28005,
		28004,
		10040000,
		30000
	}

	local idToItemCode = {
    	[28005] = "silverworth_quest",
    	[28004] = "pacifist_quest",
    	[10040000] = "cactus_girl_quest",
    	[30000] = "boss_secret_checks"
	}

	for _, id in ipairs(IDs) do
		if table_contains_value(checked_locations,id) or table_contains_value(missing_locations,id) then
			local item_code = idToItemCode[id]
			if item_code then
				Tracker:FindObjectForCode(item_code).Active = true
			end
		end
	end

	local kings_leap_mode = slot_data["dlc_kingsleap"]
	local kings_leap_obj = Tracker:FindObjectForCode("kings_leap")

	if kings_leap_mode == 0 then
		kings_leap_obj.CurrentStage = 0
	elseif kings_leap_mode == 3 then
		kings_leap_obj.CurrentStage = 2
	else
		kings_leap_obj.CurrentStage = 1
	end

	local chalice_mode = slot_data["dlc_chalice"]
	local chalice_mode_obj = Tracker:FindObjectForCode("chalice_mode")

	if chalice_mode == 0 then
		chalice_mode_obj.CurrentStage = 0
	elseif chalice_mode == 1 then
		chalice_mode_obj.CurrentStage = 1
		Tracker:FindObjectForCode("astral_cookie").Active = true
	elseif chalice_mode == 2 then
		chalice_mode_obj.CurrentStage = 2
		if can_access_isle("4") then
			Tracker:FindObjectForCode("astral_cookie").Active = true
		end
	else
		chalice_mode_obj.CurrentStage = 3
	end

	local boss_chalice_checks_mode = slot_data["dlc_boss_chalice_checks"]
	local run_gun_chalice_checks_mode = slot_data["dlc_rungun_chalice_checks"]
	local boss_chalice_checks_mode_obj = Tracker:FindObjectForCode("boss_chalice_checks")
	local run_gun_chalice_checks_mode_obj = Tracker:FindObjectForCode("run_gun_chalice_checks")
	
		if chalice_mode == 0 or boss_chalice_checks_mode == 0 then
			boss_chalice_checks_mode_obj.CurrentStage = 0
		elseif boss_chalice_checks_mode == 4 or boss_chalice_checks_mode == 6 then
			boss_chalice_checks_mode_obj.CurrentStage = 2
		end

		if chalice_mode == 0 or run_gun_chalice_checks_mode == 0 then
			run_gun_chalice_checks_mode_obj.CurrentStage = 0
		elseif run_gun_chalice_checks_mode == 4 or run_gun_chalice_checks_mode == 6 then
			run_gun_chalice_checks_mode_obj.CurrentStage = 2
		end




	local abilities = {
		"dash",
		"crouch",
		"parry",
		"plane_parry",
		"plane_shrink",
		"chalice_double_jump"
	}

	if slot_data["randomize_abilities"] == 0 then
		for _, ability in ipairs(abilities) do
			Tracker:FindObjectForCode(ability).Active = true
		end
	else
		Tracker:FindObjectForCode("randomize_abilities").Active = true
	end

	-- checking whether the starting weapon is excepted
	local start_weapon_exception = true
	if slot_data["weapon_mode"] == 1  or slot_data["weapon_mode"] == 2 then start_weapon_exception = false
	elseif slot_data["weapon_mode"] == 0 or slot_data["weapon_mode"] == 5 or slot_data["weapon_mode"] == 6  then start_weapon_exception = true
	else 
	end

	local is_start_progressive = (slot_data["weapon_mode"] == 1)

	--giving the starting weapon (and EX if needed)
	local weapons = {
		[0] = "peashooter",
		[1] = "spread",
		[2] = "chaser",
		[3] = "lobber",
		[4] = "charge",
		[5] = "roundabout",
		[6] = "crackshot",
		[7] = "converge",
		[8] = "twist_up"
	}

	if slot_data["weapon_mode"] ~= 127 then
		for index, weapon in pairs(weapons) do
			local Weapon = Tracker:FindObjectForCode(weapon)
			if Weapon then
				if slot_data["start_weapon"] == index then
				Weapon.Active = true
					if start_weapon_exception then
						local Weapon_EX = Tracker:FindObjectForCode(weapon.."_EX")
						if Weapon_EX then
						Weapon_EX.Active = true
						end
					end
					if is_start_progressive then
						local progressive_weapon = Tracker:FindObjectForCode("progressive_"..weapon)
						if progressive_weapon then
							progressive_weapon.CurrentStage = 1
						end
					end
				end
			end
		end
	end

	local boss_grade_checks = Tracker:FindObjectForCode("boss_grade_checks")
	if boss_grade_checks then
		boss_grade_checks.CurrentStage = slot_data["boss_grade_checks"]
	end

	local run_n_gun_grade_checks = Tracker:FindObjectForCode("run_n_gun_grade_checks")
	if run_n_gun_grade_checks then
		run_n_gun_grade_checks.CurrentStage = slot_data["rungun_grade_checks"]
	end

	-- if the root pack is shuffled then level shuffle must be on
	if slot_data["level_map"]["0"] then
		LEVEL_MAP = slot_data["level_map"]
	end

	-- if king dice isn't randomized (which he currently can't be) he doesn't appear in level_map and gets overwritten by the previous if statement
	if not LEVEL_MAP["17"] then
		LEVEL_MAP["17"] = 17
	end

	update_location_mapping()

	CONTRACT_REQUIREMENT_ISLE_2 = slot_data["contract_requirements"][2]
	CONTRACT_REQUIREMENT_ISLE_3 = slot_data["contract_requirements"][3]
	CONTRACT_REQUIREMENT_KING_DICE = slot_data["contract_requirements"][1]

	-- this variable is used for auto-tabbing. this is the default value
	CURRENT_MAP = 0

end



-- called right after an AP slot is connected
function onClear(slot_data)
	-- use bulk update to pause logic updates until we are done resetting all items/locations
	Tracker.BulkUpdate = true

	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onClear, slot_data:\n%s", dump_table(slot_data)))
	end


	CUR_INDEX = -1
	-- reset locations
	for _, mapping_entry in pairs(LOCATION_MAPPING) do
		for _, location_table in ipairs(mapping_entry) do
			if location_table then
				local location_code = location_table[1]
				if location_code then
					if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
						print(string.format("onClear: clearing location %s", location_code))
					end
					if location_code:sub(1, 1) == "@" then
						local obj = Tracker:FindObjectForCode(location_code)
						if obj then
							obj.AvailableChestCount = obj.ChestCount
							if obj.Highlight then
								obj.Highlight = Highlight.None
							end
						elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
							print(string.format("onClear: could not find location object for code %s", location_code))
						end
					else
						-- reset hosted item
						local item_type = location_table[2]
						resetItem(location_code, item_type)
					end
				elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
					print(string.format("onClear: skipping location_table with no location_code"))
				end
			elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("onClear: skipping empty location_table"))
			end
		end
	end
	-- reset items
	for _, mapping_entry in pairs(ITEM_MAPPING) do
		for _, item_table in ipairs(mapping_entry) do
			if item_table then
				local item_code = item_table[1]
				local item_type = item_table[2]
				if item_code then
					resetItem(item_code, item_type)
				elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
					print(string.format("onClear: skipping item_table with no item_code"))
				end
			elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("onClear: skipping empty item_table"))
			end
		end
	end

	-- reset slot data and progressive weapons
	local slot_data_items = {
		"beat_devil",
		"collect_contracts",
		"buy_out_shop",
		"beat_saltbaker",
		"collect_ingredients",
		"use_dlc",
		"expert_mode",
		"logic_mode",
		"deathlink",
		"ducklock_platdrop",
		"randomize_abilities",
		"start_maxhealth_p1",
		"start_maxhealth_p2",
		"silverworth_quest",
		"pacifist_quest",
		"cactus_girl_quest",
		"boss_secret_checks",
		"chalice_mode",
		"freemove_isles",
		"boss_grade_checks",
		"run_n_gun_grade_checks",
		"boss_chalice_checks",
		"run_gun_chalice_checks",
		"kings_leap",
		"progressive_peashooter",
		"progressive_spread",
		"progressive_chaser",
		"progressive_lobber",
		"progressive_charge",
		"progressive_roundabout"
	}
	for _, item_code in ipairs(slot_data_items) do
		resetItem(item_code,Tracker:FindObjectForCode(item_code).Type)
	end

	
	apply_slot_data(slot_data)
	LOCAL_ITEMS = {}
	GLOBAL_ITEMS = {}
	-- setup data storage tracking for hint tracking
	local data_storage_keys = {}
	if PopVersion >= "0.32.0" then
		data_storage_keys = { getHintDataStorageKey(), getDeathlinkDataStorageKey(), getMapsVisitedDataStorageKey() }
		for _, key in ipairs(getAutoTabDataStorageKeys()) do
			table.insert(data_storage_keys,key)
		end
		for _, key in ipairs(getQuestDataStorageKeys()) do
			table.insert(data_storage_keys,key)
		end
	end
	-- subscribes to the data storage keys for updates
	-- triggers callback in the SetNotify handler on update
	Archipelago:SetNotify(data_storage_keys)
	-- gets the current value for the data storage keys
	-- triggers callback in the Retrieved handler when result is received
	Archipelago:Get(data_storage_keys)
	Tracker.BulkUpdate = false
end

-- called when an item gets collected
function onItem(index, item_id, item_name, player_number)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onItem: %s, %s, %s, %s, %s", index, item_id, item_name, player_number, CUR_INDEX))
	end
	if not AUTOTRACKER_ENABLE_ITEM_TRACKING then
		return
	end
	if index <= CUR_INDEX then
		return
	end
	local is_local = player_number == Archipelago.PlayerNumber
	CUR_INDEX = index
	local mapping_entry = ITEM_MAPPING[item_id]
	if not mapping_entry then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("onItem: could not find item mapping for id %s", item_id))
		end
		return
	end

	for _, item_table in pairs(mapping_entry) do
		if item_table then
			local item_code = item_table[1]
			local item_type = item_table[2]
			local multiplier = item_table[3] or 1
			if item_code then
				incrementItem(item_code, item_type, multiplier)
				-- keep track which items we touch are local and which are global
				if is_local then
					if LOCAL_ITEMS[item_code] then
						LOCAL_ITEMS[item_code] = LOCAL_ITEMS[item_code] + 1
					else
						LOCAL_ITEMS[item_code] = 1
					end
				else
					if GLOBAL_ITEMS[item_code] then
						GLOBAL_ITEMS[item_code] = GLOBAL_ITEMS[item_code] + 1
					else
						GLOBAL_ITEMS[item_code] = 1
					end
				end
			elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("onClear: skipping item_table with no item_code"))
			end
		elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("onClear: skipping empty item_table"))
		end

	end
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("local items: %s", dump_table(LOCAL_ITEMS)))
		print(string.format("global items: %s", dump_table(GLOBAL_ITEMS)))
	end
end

-- called when a location gets cleared
function onLocation(location_id, location_name)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onLocation: %s, %s", location_id, location_name))
	end
	if not AUTOTRACKER_ENABLE_LOCATION_TRACKING then
		return
	end
	local mapping_entry = LOCATION_MAPPING[location_id]
	if not mapping_entry then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("onLocation: could not find location mapping for id %s", location_id))
		end
		return
	end

	local a_grade_ids = {
		18000, 
		18001, 
		18002,
		18003, 
		18004, 
		18005
	}

	for _, location_table in pairs(mapping_entry) do
		if location_table then
			local location_code = location_table[1]
			if location_code then
				local obj = Tracker:FindObjectForCode(location_code)
				if obj then
					if location_code:sub(1, 1) == "@" then
						if not (Tracker:FindObjectForCode("run_n_gun_grade_checks").CurrentStage == 5 and table_contains_value(a_grade_ids,location_id)) then
							obj.AvailableChestCount = obj.AvailableChestCount - 1
						end
						
					else
						-- increment hosted item
						local item_type = location_table[2]
						incrementItem(location_code, item_type)
					end
				elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
					print(string.format("onLocation: could not find object for code %s", location_code))
				end
			elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("onLocation: skipping location_table with no location_code"))
			end
		elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("onLocation: skipping empty location_table"))
		end
	end
end

-- called when a locations is scouted
function onScout(location_id, location_name, item_id, item_name, item_player)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onScout: %s, %s, %s, %s, %s", location_id, location_name, item_id, item_name,
			item_player))
	end
	-- not implemented yet :(
end

-- called when a bounce message is received
function onBounce(json)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onBounce: %s", dump_table(json)))
	end
	-- your code goes here
end

-- called whenever Archipelago:Get returns data from the data storage or
-- whenever a subscribed to (via Archipelago:SetNotify) key in data storgae is updated
-- oldValue might be nil (always nil for "_read" prefixed keys and via retrieved handler (from Archipelago:Get))
function onDataStorageUpdate(key, value, oldValue)
	--if you plan to only use the hints key, you can remove this if
	if key == getHintDataStorageKey() then
		onHintsUpdate(value)
	elseif table_contains_value(getAutoTabDataStorageKeys(),key) then
		applyAutoTab(key,value)
	elseif key == getDeathlinkDataStorageKey() then
		updateGraceCount(value)
	elseif table_contains_value(getQuestDataStorageKeys(),key) then
		updateQuests(key,value)
	elseif key == getMapsVisitedDataStorageKey() then
		updateCookie(value)
	else
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print("key: %s doesn't exist", key)
		end
	end
end

-- called whenever the hints key in data storage updated
-- NOTE: this should correctly handle having multiple mapped locations in a section.
--       if you only map sections 1 to 1 you can simplfy this. for an example see
--       https://github.com/Cyb3RGER/sm_ap_tracker/blob/main/scripts/autotracking/archipelago.lua
function onHintsUpdate(hints)
	-- Highlight is only supported since version 0.32.0
	if PopVersion < "0.32.0" or not AUTOTRACKER_ENABLE_LOCATION_TRACKING then
		return
	end
	local player_number = Archipelago.PlayerNumber
	-- get all new highlight values per section
	local sections_to_update = {}
	for _, hint in ipairs(hints) do
		-- we only care about hints in our world
		if hint.finding_player == player_number then
			updateHint(hint, sections_to_update)
		end
	end
	-- update the sections
	for location_code, highlight_code in pairs(sections_to_update) do
		-- find the location object
		local obj = Tracker:FindObjectForCode(location_code)
		-- check if we got the location and if it supports Highlight
		if obj and obj.Highlight then
			obj.Highlight = highlight_code
		end
	end
end

-- update section highlight based on the hint
function updateHint(hint, sections_to_update)
	-- get the highlight enum value for the hint status
	local hint_status = hint.status
	local highlight_code = nil
	if hint_status then
		highlight_code = HINT_STATUS_MAPPING[hint_status]
	end
	if not highlight_code then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("updateHint: unknown hint status %s for hint on location id %s", hint.status,
				hint.location))
		end
		-- try to "recover" by checking hint.found (older AP versions without hint.status)
		if hint.found == true then
			highlight_code = Highlight.None
		elseif hint.found == false then
			highlight_code = Highlight.Unspecified
		else
			return
		end
	end
	-- get the location mapping for the location id
	local mapping_entry = LOCATION_MAPPING[hint.location]
	if not mapping_entry then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("updateHint: could not find location mapping for id %s", hint.location))
		end
		return
	end
	--get the "highest" highlight value pre section
	for _, location_table in pairs(mapping_entry) do
		if location_table then
			local location_code = location_table[1]
			-- skip hosted items, they don't support Highlight
			if location_code and location_code:sub(1, 1) == "@" then
				-- see if we already set a Highlight for this section
				local existing_highlight_code = sections_to_update[location_code]
				if existing_highlight_code then
					-- make sure we only replace None or "increase" the highlight but never overwrite with None
					-- this so sections with mulitple mapped locations show the "highest" Highlight and
					-- only show no Highlight when all hints are found
					if existing_highlight_code == Highlight.None or (existing_highlight_code < highlight_code and highlight_code ~= Highlight.None) then
						sections_to_update[location_code] = highlight_code
					end
				else
					sections_to_update[location_code] = highlight_code
				end
			end
		end
	end
end

function applyAutoTab(key,value)
	local auto_tab_key_indices = {
		["current_level"] = 1,
		["current_map"] = 2
	}
	local auto_tab_keys = getAutoTabDataStorageKeys()
	local key_values_to_tab_names = {
		[0] = "Isle I",
		[1] = "Isle II",
		[2] = "Isle III",
		[3] = "Inkwell Hell",
		[4] = "Isle IV"
	}
	if (key == auto_tab_keys[auto_tab_key_indices["current_level"]]) and 
	(Tracker:FindObjectForCode("auto_tab_mode").CurrentStage == 2) then
		if value == -1 then
			Tracker:UiHint("ActivateTab", key_values_to_tab_names[CURRENT_MAP])
		else
		Tracker:UiHint("ActivateTab", "Summary")
		end
	elseif key == auto_tab_keys[auto_tab_key_indices["current_map"]] then
		CURRENT_MAP = value
		if Tracker:FindObjectForCode("auto_tab_mode").CurrentStage ~= 0 then
			Tracker:UiHint("ActivateTab", key_values_to_tab_names[value])
		end
	else 
	end
end

function updateGraceCount(value)
	local deathlink_item = Tracker:FindObjectForCode("deaths_left")
	deathlink_item.AcquiredCount = value + 1
end

function updateQuests(key,value)
	local quest_key_indices = {
		["agrade_levels"] = 1,
		["pacifist_levels"] = 2,
		["dlc_chaliced_levels_p1"] = 3,
		["dlc_chaliced_levels_p2"] = 4
	}
	local quest_keys = getQuestDataStorageKeys()
	if (key == quest_keys[quest_key_indices["agrade_levels"]]) then
		Tracker:FindObjectForCode("silverworth_quest_progress").AcquiredCount = countSetBits(value)
	elseif (key == quest_keys[quest_key_indices["pacifist_levels"]]) then
		Tracker:FindObjectForCode("tully_quest_progress").AcquiredCount = countSetBits(value)
	elseif (key == quest_keys[quest_key_indices["dlc_chaliced_levels_p1"]]) then
		Tracker:FindObjectForCode("senita_quest_progress").AcquiredCount = countSetBits(value)
	else
	end
end

function updateCookie(value)
	local chalice_mode_item = Tracker:FindObjectForCode("chalice_mode")
	-- Check if the cookie hasn't been acquired, chalice mode is vanilla and map 4 (Isle IV) has been visited
	if (chalice_mode_item.CurrentStage == 2) and (((value >> 4) & 1) == 1) then
		Tracker:FindObjectForCode("astral_cookie").Active = true
	end		
end

-- add AP callbacks
-- un-/comment as needed
Archipelago:AddClearHandler("clear handler", onClear)
if AUTOTRACKER_ENABLE_ITEM_TRACKING then
	Archipelago:AddItemHandler("item handler", onItem)
end
if AUTOTRACKER_ENABLE_LOCATION_TRACKING then
	Archipelago:AddLocationHandler("location handler", onLocation)
end
Archipelago:AddRetrievedHandler("retrieved handler", onDataStorageUpdate)
Archipelago:AddSetReplyHandler("set reply handler", onDataStorageUpdate)
-- Archipelago:AddScoutHandler("scout handler", onScout)
-- Archipelago:AddBouncedHandler("bounce handler", onBounce)
