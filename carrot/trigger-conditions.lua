---@diagnostic disable:unreachable-code
-- Trigger 1
-- PLAYER_MOUNT_DISPLAY_CHANGED
---@diagnostic disable-next-line:miss-name
function()
    aura_env.trinkets:Update()
    local mounted = IsMounted()

    if UnitOnTaxi("player") then
        return mounted
    end

    if mounted then
        if aura_env.trinkets.top ~= aura_env.trinkets.carrot and aura_env.trinkets.bottom ~= aura_env.trinkets.carrot then
            aura_env.trinkets.previous = GetInventoryItemID("player", aura_env.trinkets.slotId)
            aura_env.trinkets:TryEquip(aura_env.trinkets.carrot, aura_env.trinkets.slotId)
        end

        if aura_env.boots.spursBoots and aura_env.boots.equipped ~= aura_env.boots.spursBoots then
            aura_env.trinkets:TryEquip(aura_env.boots.spursBoots, 8)
        end

        if aura_env.gloves.ridingGloves and aura_env.gloves.equipped ~= aura_env.gloves.ridingGloves then
            aura_env.trinkets:TryEquip(aura_env.gloves.ridingGloves, 10)
        end
    else
        if aura_env.trinkets.top == aura_env.trinkets.carrot or aura_env.trinkets.bottom == aura_env.trinkets.carrot then
            if aura_env.trinkets.previous then
                aura_env.trinkets:TryEquip(aura_env.trinkets.previous, aura_env.trinkets.slotId)
            end
        end

        if aura_env.pvpMode and aura_env.boots.equipped ~= aura_env.boots.pvpBoots then
            aura_env.trinkets:TryEquip(aura_env.boots.pvpBoots, 8)
        elseif not aura_env.pvpMode and aura_env.boots.equipped ~= aura_env.boots.pveBoots then
            aura_env.trinkets:TryEquip(aura_env.boots.pveBoots, 8)
        end

        if aura_env.pvpMode and aura_env.gloves.equipped ~= aura_env.gloves.pvpGloves then
            aura_env.trinkets:TryEquip(aura_env.gloves.pvpGloves, 10)
        elseif not aura_env.pvpMode and aura_env.gloves.equipped ~= aura_env.gloves.pveGloves then
            aura_env.trinkets:TryEquip(aura_env.gloves.pveGloves, 10)
        end
    end

    return mounted
end

-- Trigger 2
-- TOGGLE_AURA,TOGGLE_PVP,TOGGLE_PROTECTION
---@diagnostic disable-next-line:miss-name
function(event, ...)
    if event == "TOGGLE_AURA" then
        aura_env.trinkets:Toggle()
    end
    if event == "TOGGLE_PVP" then
        aura_env.trinkets:PvpMode(...)
    end
    if event == "TOGGLE_PROTECTION" then
        aura_env.trinkets:ProtectedMode()
    end
end
