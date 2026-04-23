function handleProgressiveUpdate(item_code)

    local stage = Tracker:FindObjectForCode(item_code).CurrentStage
    
    if item_code == "progressive_peashooter" then
        if stage == 1 then
            Tracker:FindObjectForCode("peashooter").Active = true
        elseif stage == 2 then
            Tracker:FindObjectForCode("peashooter_EX").Active = true
        else
        end
    end
    if item_code == "progressive_spread" then
        if stage == 1 then
            Tracker:FindObjectForCode("spread").Active = true
        elseif stage == 2 then
            Tracker:FindObjectForCode("spread_EX").Active = true
        else
        end
    end
        if item_code == "progressive_chaser" then
        if stage == 1 then
            Tracker:FindObjectForCode("chaser").Active = true
        elseif stage == 2 then
            Tracker:FindObjectForCode("chaser_EX").Active = true
        else
        end
    end
        if item_code == "progressive_lobber" then
        if stage == 1 then
            Tracker:FindObjectForCode("lobber").Active = true
        elseif stage == 2 then
            Tracker:FindObjectForCode("lobber_EX").Active = true
        else
        end
    end
        if item_code == "progressive_charge" then
        if stage == 1 then
            Tracker:FindObjectForCode("charge").Active = true
        elseif stage == 2 then
            Tracker:FindObjectForCode("charge_EX").Active = true
        else
        end
    end
        if item_code == "progressive_roundabout" then
        if stage == 1 then
            Tracker:FindObjectForCode("roundabout").Active = true
        elseif stage == 2 then
            Tracker:FindObjectForCode("roundabout_EX").Active = true
        else
        end
    end

end

function registerProgressiveWatchers()
    local watched_progressives = {
        "progressive_peashooter",
        "progressive_spread",
        "progressive_chaser",
        "progressive_lobber",
        "progressive_charge",
        "progressive_roundabout"
    }

    for _, code in ipairs(watched_progressives) do
        local obj = Tracker:FindObjectForCode(code)
        if obj then
            ScriptHost:AddWatchForCode(
                code.."_watcher",
                code,
            function(changed_code)
                handleProgressiveUpdate(changed_code)
            end
            )
        end
    end
end

