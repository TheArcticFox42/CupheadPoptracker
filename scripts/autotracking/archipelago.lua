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

-- apply everything needed from slot_data, called from onClear
function apply_slot_data(slot_data)
	-- put any code here that slot_data should affect (toggling setting items for example)
	-- setting the goal
	if slot_data["mode"] == 2 then Tracker:FindObjectForCode("collect_contracts").AcquiredCount = slot_data["contract_goal_requirements"]
	elseif slot_data["mode"] == 4 then Tracker:FindObjectForCode("buy_out_shop").Active = true
	elseif slot_data["mode"] == 8 then 
		Tracker:FindObjectForCode("beat_saltbaker").Active = true
	elseif slot_data["mode"] == 9 then 
		Tracker:FindObjectForCode("beat_devil").Active = true
		Tracker:FindObjectForCode("beat_saltbaker").Active = true
	elseif slot_data["mode"] == 16 then Tracker:FindObjectForCode("collect_ingredients").AcquiredCount= slot_data["dlc_ingredient_goal_requirements"]
	elseif slot_data["mode"] == 18 then 
		Tracker:FindObjectForCode("collect_contracts").AcquiredCount = slot_data["contract_goal_requirements"]
		Tracker:FindObjectForCode("collect_ingredients").AcquiredCount = slot_data["dlc_ingredient_goal_requirements"]
	else 
		Tracker:FindObjectForCode("beat_devil").Active = true
	end

	Tracker:FindObjectForCode("use_dlc").Active = slot_data["use_dlc"]
	Tracker:FindObjectForCode("expert_mode").Active = slot_data["expert_mode"]

	-- checking whether the starting weapon is excepted
	if slot_data["weapon_mode"] == 1 then Tracker:FindObjectForCode("start_weapon_exception").Active = false
	elseif slot_data["weapon_mode"] == 5 then 
		Tracker:FindObjectForCode("start_weapon_exception").Active = true
	elseif slot_data["weapon_mode"] == 2 then Tracker:FindObjectForCode("start_weapon_exception").Active = false
	elseif slot_data["weapon_mode"] == 6 then 
		Tracker:FindObjectForCode("start_weapon_exception").Active = true
	else Tracker:FindObjectForCode("start_weapon_exception").Active = true
	end
	
	--giving the starting weapon (and EX if needed)
	if slot_data["start_weapon"] == 0 then 
		Tracker:FindObjectForCode("peashooter").Active = true
		if Tracker:FindObjectForCode("start_weapon_exception").Active == true then 
			Tracker:FindObjectForCode("peashooter_EX").Active = true
		end
	elseif slot_data["start_weapon"] == 1 then 
		Tracker:FindObjectForCode("spread").Active = true
		if Tracker:FindObjectForCode("start_weapon_exception").Active == true then 
			Tracker:FindObjectForCode("spread_EX").Active = true
		end
	elseif slot_data["start_weapon"] == 2 then 
		Tracker:FindObjectForCode("chaser").Active = true
		if Tracker:FindObjectForCode("start_weapon_exception").Active == true then 
			Tracker:FindObjectForCode("chaser_EX").Active = true
		end
	elseif slot_data["start_weapon"] == 3 then 
		Tracker:FindObjectForCode("lobber").Active = true
		if Tracker:FindObjectForCode("start_weapon_exception").Active == true then 
			Tracker:FindObjectForCode("lobber_EX").Active = true
		end
	elseif slot_data["start_weapon"] == 4 then 
		Tracker:FindObjectForCode("charge").Active = true
		if Tracker:FindObjectForCode("start_weapon_exception").Active == true then 
			Tracker:FindObjectForCode("charge_EX").Active = true
		end
	elseif slot_data["start_weapon"] == 5 then 
		Tracker:FindObjectForCode("roundabout").Active = true
		if Tracker:FindObjectForCode("start_weapon_exception").Active == true then 
			Tracker:FindObjectForCode("roundabout_EX").Active = true
		end
	end

	if slot_data["boss_grade_checks"] == 0 then Tracker:FindObjectForCode("boss_grade_checks").CurrentStage = 0
	elseif slot_data["boss_grade_checks"] == 2 then Tracker:FindObjectForCode("boss_grade_checks").CurrentStage = 2
	elseif slot_data["boss_grade_checks"] == 3 then Tracker:FindObjectForCode("boss_grade_checks").CurrentStage = 3
	elseif slot_data["boss_grade_checks"] == 4 then Tracker:FindObjectForCode("boss_grade_checks").CurrentStage = 4
	else Tracker:FindObjectForCode("boss_grade_checks").CurrentStage = 1
	end

	if slot_data["rungun_grade_checks"] == 0 then Tracker:FindObjectForCode("run_n_gun_grade_checks").CurrentStage = 0
	elseif slot_data["rungun_grade_checks"] == 2 then Tracker:FindObjectForCode("run_n_gun_grade_checks").CurrentStage = 2
	elseif slot_data["rungun_grade_checks"] == 3 then Tracker:FindObjectForCode("run_n_gun_grade_checks").CurrentStage = 3
	elseif slot_data["rungun_grade_checks"] == 5 then Tracker:FindObjectForCode("run_n_gun_grade_checks").CurrentStage = 4
	else Tracker:FindObjectForCode("run_n_gun_grade_checks").CurrentStage = 1 
	end

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
		"start_weapon_exception",
		"boss_grade_checks",
		"run_n_gun_grade_checks",
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
	local data_strorage_keys = {}
	if PopVersion >= "0.32.0" then
		data_strorage_keys = { getHintDataStorageKey() }
	end
	-- subscribes to the data storage keys for updates
	-- triggers callback in the SetNotify handler on update
	Archipelago:SetNotify(data_strorage_keys)
	-- gets the current value for the data storage keys
	-- triggers callback in the Retrieved handler when result is received
	Archipelago:Get(data_strorage_keys)
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
	for _, location_table in pairs(mapping_entry) do
		if location_table then
			local location_code = location_table[1]
			if location_code then
				local obj = Tracker:FindObjectForCode(location_code)
				if obj then
					if location_code:sub(1, 1) == "@" then
						if not (Tracker:FindObjectForCode("run_n_gun_grade_checks").CurrentStage == 5 and 
						(location_id == BASE_LOCATION_ID + 51 or location_id == BASE_LOCATION_ID + 59 or location_id == BASE_LOCATION_ID + 67 or
						location_id == BASE_LOCATION_ID + 75 or location_id == BASE_LOCATION_ID + 83 or location_id == BASE_LOCATION_ID + 91)) then
							obj.AvailableChestCount = obj.AvailableChestCount - 1
						else
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
