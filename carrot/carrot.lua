-- on Init action
if not aura_env.trinkets then
    local slots = { 13, 14 }
    aura_env.trinkets = {}
    aura_env.trinkets.carrot = 11122
    aura_env.trinkets.slotId = slots[aura_env.config.trinket_slot]
    aura_env.trinkets.fallbackNotFound = false
end

if not aura_env.boots then
    aura_env.boots = {}
    aura_env.boots.spursBoots = aura_env.config.boots.spursBoots -- enchantID: 464
    aura_env.boots.regularBoots = aura_env.config.boots.regularBoots
end

if not aura_env.gloves then
    aura_env.gloves = {}
    aura_env.gloves.ridingGloves = aura_env.config.gloves.ridingGloves -- enchantID: 930
    aura_env.gloves.regularGloves = aura_env.config.gloves.regularGloves
end

function aura_env.trinkets:Update()
    aura_env.trinkets.top = GetInventoryItemID("player", 13)
    aura_env.trinkets.bottom = GetInventoryItemID("player", 14)
    aura_env.boots.equipped = GetInventoryItemLink("player", 8)
    aura_env.gloves.equipped = GetInventoryItemLink("player", 10)
    aura_env.trinkets.equipped = {
        aura_env.trinkets.top,
        aura_env.trinkets.bottom,
    }
    if aura_env.trinkets.equipped[aura_env.config.trinket_slot] ~= aura_env.trinkets.carrot then
        aura_env.trinkets.previous = aura_env.trinkets.equipped[aura_env.config.trinket_slot]
    end
end

function aura_env.trinkets:TryEquip(item, slotId)
    if not InCombatLockdown() then
        EquipItemByName(item, slotId)
        aura_env.trinkets:Update()
    else
        aura_env.trinkets.scheduledTrinkets = aura_env.trinkets.scheduledTrinkets or {}
        aura_env.trinkets.scheduledTrinkets[item] = slotId
    end
end

function aura_env.trinkets:IsCarrotEquipped()
    aura_env.trinkets.top = GetInventoryItemID("player", 13)
    aura_env.trinkets.bottom = GetInventoryItemID("player", 14)
    return aura_env.trinkets.top == aura_env.trinkets.carrot or aura_env.trinkets.bottom == aura_env.trinkets.carrot
end

aura_env.trinkets:Update()

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

-- Trigger 4  condition code
if not IsMounted() and not InCombatLockdown() and aura_env.trinkets:IsCarrotEquipped() and aura_env.config.fallbackTrinket ~= "" then
    if GetItemCount(aura_env.config.fallbackTrinket) == 0 then
        if aura_env.trinkets.fallbackNotFound then return end
        print(string.format("\124cFF85e5ccCarrotEnjoyer\124r: Carrot equipped, but %s not found in bags",
            aura_env.config.fallbackTrinket))
        aura_env.trinkets.fallbackNotFound = true
        return
    end
    aura_env.trinkets:TryEquip(aura_env.config.fallbackTrinket, aura_env.trinkets.slotId)
    aura_env.trinkets.fallbackNotFound = false
end

if not IsMounted() and not InCombatLockdown() and aura_env.boots.spursBoots and aura_env.boots.equipped == aura_env.boots.spursBoots then
    if GetItemCount(aura_env.boots.regularBoots) == 0 then return end
    aura_env.trinkets:TryEquip(aura_env.boots.regularBoots, 8)
end

if not IsMounted() and not InCombatLockdown() and aura_env.gloves.ridingGloves and aura_env.gloves.equipped == aura_env.gloves.ridingGloves then
    if GetItemCount(aura_env.gloves.regularGloves) == 0 then return end
    aura_env.trinkets:TryEquip(aura_env.gloves.regularGloves, 10)
end
