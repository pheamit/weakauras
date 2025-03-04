-- Init
aura_env.textColor = "FF00AEFF"
aura_env.groupColor = "FFFFC400"
aura_env.masterColor = "FFD400FF"


-- Trigger 1
function(event, ...)
    if UnitExists("mouseover") and not UnitIsDead("mouseover") then
        local name = UnitName("mouseover")
        local lootRules = GetLootMethod()
        if aura_env.config.ubrs[name] and UnitIsGroupLeader("player") and lootRules ~= "master" then
            SetLootMethod("master", "player")
            print(("\124c%sLoot rules are set to\124r \124c%sMaster\124r"):format(aura_env.textColor, aura_env.masterColor))
            return true
        end
        return false
    end
end

-- Trigger 2
function(event, ...)
    local destName = select(9, CombatLogGetCurrentEventInfo())
    local lootRules = GetLootMethod()
    if aura_env.config.ubrs[destName] and UnitIsGroupLeader("player") and lootRules ~= "group" then
        SetLootMethod("group")
        print(("\124c%sLoot rules are set to\124r \124c%sGroup\124r"):format(aura_env.textColor, aura_env.groupColor))
        return true
    end
    return false
end
