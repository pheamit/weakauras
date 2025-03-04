-- Trigger 1:
function(allstates, event, ...)
    if event == "NAME_PLATE_UNIT_ADDED" then
        local unit = ...
        local UnitGUID = UnitGUID(unit)
        local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
        if allstates[UnitGUID] then
            allstates[UnitGUID].nameplate = nameplate
        else
            allstates[UnitGUID] = {
                nameplate = nameplate
            }
        end
        return true
    end
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, _, _, sourceGUID, _, _, _, destGUID, _, _, _, spellId = CombatLogGetCurrentEventInfo()
        local duration = 5
        local icon = select(3, GetSpellInfo(921))
        print(sourceGUID, destGUID, spellId)
        if sourceGUID == UnitGUID("player") and spellId == 921 then
            allstates[destGUID] = {
                show = true,
                changed = true,
                icon = icon,
                progressType = "timed",
                expirationTime = GetTime() + duration,
                duration = duration,
                autoHide = true,
            }
            return true
        end
    end
end

-- Display
function()
    -- set the aura region to the enemy nameplate
    print(aura_env.state.nameplate)
    aura_env.region:SetAnchor("RIGHT", aura_env.state.nameplate, "LEFT")
end