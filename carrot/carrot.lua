-- on Init action
if not aura_env.trinkets then
    local slots = { 13, 14 }
    aura_env.trinkets = {}
    aura_env.trinkets.carrot = 11122
    aura_env.trinkets.slotId = slots[aura_env.config.trinket_slot]
    aura_env.trinkets.fallbackNotFound = false
end

function aura_env.trinkets:Update()
    aura_env.trinkets.top = GetInventoryItemID("player", 13)
    aura_env.trinkets.bottom = GetInventoryItemID("player", 14)
    aura_env.trinkets.equipped = {
        aura_env.trinkets.top,
        aura_env.trinkets.bottom,
    }
    if aura_env.trinkets.equipped[aura_env.config.trinket_slot] ~= aura_env.trinkets.carrot then
        aura_env.trinkets.previous = aura_env.trinkets.equipped[aura_env.config.trinket_slot]
    end
end

function aura_env.trinkets:TryEquip(trinket, slotId)
    if not InCombatLockdown() then
        EquipItemByName(trinket, slotId)
    else
        aura_env.trinkets.scheduledTrinket = trinket
        aura_env.trinkets.scheduledSlotId = slotId
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

-- Trigger 2  condition code
aura_env.trinkets:Update()

if UnitOnTaxi("player") then return end

if aura_env.trinkets.top == aura_env.trinkets.carrot or aura_env.trinkets.bottom == aura_env.trinkets.carrot then
    if aura_env.trinkets.previous then
        aura_env.trinkets:TryEquip(aura_env.trinkets.previous, aura_env.trinkets.slotId)
        aura_env.trinkets:Update()
    end
end

-- Trigger 3  condition code
if aura_env.trinkets.scheduledTrinket then
    aura_env.trinkets:TryEquip(aura_env.trinkets.scheduledTrinket, aura_env.trinkets.scheduledSlotId)
    aura_env.trinkets.scheduledTrinket = nil
    aura_env.trinkets.scheduledSlotId = nil
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
