-- Trigger 1  condition code
aura_env.trinkets:Update()

if UnitOnTaxi("player") then return end

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

-- Trigger 2  condition code
aura_env.trinkets:Update()

if UnitOnTaxi("player") then return end

if aura_env.trinkets.top == aura_env.trinkets.carrot or aura_env.trinkets.bottom == aura_env.trinkets.carrot then
    if aura_env.trinkets.previous then
        aura_env.trinkets:TryEquip(aura_env.trinkets.previous, aura_env.trinkets.slotId)
    end
end

if aura_env.boots.spursBoots and aura_env.boots.equipped == aura_env.boots.spursBoots then
    print("spurs boots equipped")
    if aura_env.boots.regularBoots then
        aura_env.trinkets:TryEquip(aura_env.boots.regularBoots, 8)
    end
end

if aura_env.gloves.ridingGloves and aura_env.gloves.equipped == aura_env.gloves.ridingGloves then
    if aura_env.gloves.regularGloves then
        aura_env.trinkets:TryEquip(aura_env.gloves.regularGloves, 10)
    end
end

-- Trigger 3  condition code
if aura_env.trinkets.scheduledTrinkets then
    for item, slotId in pairs(aura_env.trinkets.scheduledTrinkets) do
        aura_env.trinkets:TryEquip(item, slotId)
        aura_env.trinkets.scheduledTrinkets[item] = nil
    end
end

-- Trigger 5
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
