---@class Global
---@field CarrotEnjoyer table
---@field CarrotEnjoyerTickerStore table
local Global = _G

local function InitState()
    if aura_env.trinkets then return end
    Global.CarrotEnjoyer = Global.CarrotEnjoyer or {}
    Global.CarrotEnjoyer.warned = Global.CarrotEnjoyer.warned or false
    Global.CarrotEnjoyer.notFound = Global.CarrotEnjoyer.notFound or {}
    local slots = { 13, 14 }
    aura_env.enabled = true
    aura_env.pvpMode = true
    aura_env.protected = false
    aura_env.trinkets = {}
    aura_env.ticker = nil
    aura_env.tickerId = 0
    aura_env.trinkets.scheduledTrinkets = {}
    aura_env.trinkets.delayActive = false
    aura_env.trinkets.carrot = 11122
    aura_env.trinkets.slotId = slots[aura_env.config.trinket_slot]
    aura_env.trinkets.fallbackNotFound = false
    aura_env.region:SetDesaturated(not aura_env.enabled)
end

InitState()

local function isActive()
    return aura_env.enabled and WeakAuras.IsAuraLoaded(aura_env.id)
end

local function Print(msg)
    print((">\124cFF85e5ccCarrotEnjoyer\124r< %s"):format(msg))
end

local startTicker
local stopTicker

local ENCHANTS_DELAY = { ":844:", ":845:", ":906:", ":909:" }

local function ShouldWarnMissingItem(item)
    if item ~= "" then return false end
    if Global.CarrotEnjoyer.warned then return true end
    Print("Consider setting up the items! Type /wa -> Carrot Enjoyer -> Custom Options tab")
    Global.CarrotEnjoyer.warned = true
    return true
end

local function MarkMissingItem(item)
    if item == "" then return true end
    if Global.CarrotEnjoyer.notFound[item] then return true end
    Print(("%s not found in bags"):format(item))
    Global.CarrotEnjoyer.notFound[item] = true
    return true
end

local function ShouldProtectSlot(slotId)
    local _, duration, enable = GetInventoryItemCooldown("player", slotId)
    return enable == 1 and duration <= 30 and aura_env.protected
end

local function ScheduleDelay(delayedItem, slotId, delaySeconds)
    Print(("delaying %s for %d seconds due to %s enchant"):format(delayedItem, delaySeconds, aura_env.gloves.equipped))
    aura_env.trinkets.delayActive = true
    stopTicker()
    C_Timer.After(delaySeconds, function()
        aura_env.trinkets.delayActive = false
        aura_env.trinkets:TryEquip(delayedItem, slotId, true, true)
        startTicker()
    end)
end

local function ShouldDelaySwap(slotId)
    local delayGroup = aura_env.config.delayGatheringGroup
    if not delayGroup.toggleDelay then return false end
    if aura_env.trinkets.delayActive then return false end
    if IsMounted() then return false end
    local itemLink = GetInventoryItemLink("player", slotId)
    for _, enchant in ipairs(ENCHANTS_DELAY) do
        if string.find(tostring(itemLink), enchant) then
            return true
        end
    end
    return false
end

local function EquipNow(item, slotId, delayedEquip)
    C_Item.EquipItemByName(item, slotId)
    if delayedEquip then
        Print(("equipped a delayed item: %s"):format(item))
    end
    aura_env.trinkets:Update()
end

local function ValidateEquipRequest(item, slotId)
    if ShouldWarnMissingItem(item) then return false end
    if InCombatLockdown() then
        aura_env.trinkets.scheduledTrinkets[item] = slotId
        return false
    end
    if C_Item.GetItemCount(item) == 0 then
        MarkMissingItem(item)
        return false
    end
    if ShouldProtectSlot(slotId) then return false end
    return true
end

local function HandleDelay(item, slotId, skipDelay)
    if skipDelay then return false end
    if not ShouldDelaySwap(slotId) then return false end
    local delayGroup = aura_env.config.delayGatheringGroup
    ScheduleDelay(item, slotId, delayGroup.delayDuration)
    return true
end

local function getTickerStore()
    if not Global.CarrotEnjoyerTickerStore then
        Global.CarrotEnjoyerTickerStore = {}
    end
    return Global.CarrotEnjoyerTickerStore
end

startTicker = function()
    if not isActive() then return end
    local store = getTickerStore()
    if store[aura_env.id] then
        aura_env.ticker = store[aura_env.id]
        return
    end
    aura_env.tickerId = aura_env.tickerId + 1
    aura_env.ticker = C_Timer.NewTicker(5, function()
        aura_env.trinkets:Enforce()
    end)
    store[aura_env.id] = aura_env.ticker
end

stopTicker = function()
    if aura_env.ticker then
        aura_env.ticker:Cancel()
        aura_env.ticker = nil
    end
    local store = getTickerStore()
    if store[aura_env.id] then
        store[aura_env.id]:Cancel()
        store[aura_env.id] = nil
    end
end

function aura_env.trinkets:Toggle()
    aura_env.enabled = not aura_env.enabled
    aura_env.region:SetDesaturated(not aura_env.enabled)
    aura_env.region:SetGlow(aura_env.enabled and aura_env.protected)
    if aura_env.enabled then startTicker() else stopTicker() end
end

function aura_env.trinkets:PvpMode(fontString)
    if not isActive() then return end
    aura_env.pvpMode = not aura_env.pvpMode
    if fontString:IsVisible() then fontString:Hide() else fontString:Show() end
end

function aura_env.trinkets:ProtectedMode()
    if not isActive() then return end
    aura_env.protected = not aura_env.protected
    aura_env.region:SetGlow(aura_env.protected)
end

if not aura_env.boots then
    aura_env.boots = {}
    aura_env.boots.spursBoots = aura_env.config.boots.spursBoots or nil
    aura_env.boots.pvpBoots = aura_env.config.boots.pvpBoots or nil
    aura_env.boots.pveBoots = aura_env.config.boots.pveBoots or nil
end
if not aura_env.gloves then
    aura_env.gloves = {}
    aura_env.gloves.ridingGloves = aura_env.config.gloves.ridingGloves or nil
    aura_env.gloves.pvpGloves = aura_env.config.gloves.pvpGloves or nil
    aura_env.gloves.pveGloves = aura_env.config.gloves.pveGloves or nil
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

function aura_env.trinkets:TryEquip(item, slotId, skipDelay, delayedEquip)
    if not isActive() then return end
    if not ValidateEquipRequest(item, slotId) then return end
    if HandleDelay(item, slotId, skipDelay) then return end
    EquipNow(item, slotId, delayedEquip)
end

local function EnforceFallbackTrinket()
    if IsMounted() or InCombatLockdown() then return end
    if not aura_env.trinkets:IsCarrotEquipped() then return end
    if aura_env.config.fallbackTrinket == "" then return end

    if C_Item.GetItemCount(aura_env.config.fallbackTrinket) == 0 then
        if aura_env.trinkets.fallbackNotFound then return end
        Print(string.format("Carrot equipped, but %s not found in bags",
            aura_env.config.fallbackTrinket))
        aura_env.trinkets.fallbackNotFound = true
        return
    end

    aura_env.trinkets:TryEquip(aura_env.config.fallbackTrinket, aura_env.trinkets.slotId)
    aura_env.trinkets.fallbackNotFound = false
end

local function EnforceSlot(slotId, equipped, desired)
    if equipped ~= desired then
        aura_env.trinkets:TryEquip(desired, slotId)
    end
end

local function GetDesiredItem(mounted, mountedItem, pvpItem, pveItem)
    if mounted then return mountedItem end
    if aura_env.pvpMode then return pvpItem end
    return pveItem
end

local function EnforceGear()
    if InCombatLockdown() then return end
    local mounted = IsMounted()

    EnforceSlot(8, aura_env.boots.equipped,
        GetDesiredItem(mounted, aura_env.boots.spursBoots, aura_env.boots.pvpBoots, aura_env.boots.pveBoots))
    EnforceSlot(10, aura_env.gloves.equipped,
        GetDesiredItem(mounted, aura_env.gloves.ridingGloves, aura_env.gloves.pvpGloves, aura_env.gloves.pveGloves))

    if mounted and not aura_env.trinkets:IsCarrotEquipped() then
        aura_env.trinkets:TryEquip(aura_env.trinkets.carrot, aura_env.trinkets.slotId)
    end
end

function aura_env.trinkets:IsCarrotEquipped()
    aura_env.trinkets.top = GetInventoryItemID("player", 13)
    aura_env.trinkets.bottom = GetInventoryItemID("player", 14)
    return aura_env.trinkets.top == aura_env.trinkets.carrot or aura_env.trinkets.bottom == aura_env.trinkets.carrot
end

function aura_env.trinkets:Enforce()
    if not isActive() or UnitOnTaxi("player") then return end
    aura_env.trinkets:Update()
    EnforceFallbackTrinket()
    EnforceGear()
end

aura_env.trinkets:Update()
startTicker()

local function InitButtonFontString(button)
    local fontString = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local font, size, _ = fontString:GetFont()
    fontString:SetFont(font, size, "OUTLINE")
    fontString:SetTextToFit("PvP")
    fontString:SetTextColor(1, 1, 1, 1)
    fontString:SetShadowColor(1, 1, 1, 0)
    fontString:SetPoint("CENTER")
    button.fontString = fontString
end

local function ApplyButtonScripts(button)
    button:SetScript("OnEnter", function(frame)
        local x = frame:GetRight() + 140
        local anchor = x < GetScreenWidth() and "ANCHOR_BOTTOMRIGHT" or "ANCHOR_BOTTOMLEFT"
        GameTooltip:SetOwner(frame, anchor)
        GameTooltip:AddLine("Left Click to toggle ON/OFF")
        GameTooltip:AddLine("Right Click to toggle PvP mode")
        GameTooltip:AddLine("Shift+Left Click to toggle on-use trinket protection")
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button:SetScript("OnClick", function(frame, btn)
        if btn == "LeftButton" and IsShiftKeyDown() then
            WeakAuras.ScanEvents("TOGGLE_PROTECTION")
        elseif btn == "LeftButton" then
            WeakAuras.ScanEvents("TOGGLE_AURA")
        elseif btn == "RightButton" then
            WeakAuras.ScanEvents("TOGGLE_PVP", frame.fontString)
        end
    end)
end

local function CreateButton()
    local button = CreateFrame("BUTTON", nil, aura_env.region)
    InitButtonFontString(button)

    local hoverTex = button:CreateTexture(nil, "HIGHLIGHT")
    hoverTex:SetAllPoints()
    hoverTex:SetColorTexture(.3, .3, .3, 0.9)
    button:SetHighlightTexture(hoverTex)

    ApplyButtonScripts(button)
    return button
end

local function InitUI()
    if not aura_env.region.carrotButton then
        aura_env.region.carrotButton = CreateButton()
    end

    local button = aura_env.region.carrotButton
    button:SetAllPoints()
    button:EnableMouse(true)
    button:SetMouseClickEnabled(true)
    button:RegisterForClicks("AnyUp")

    -- ensure font string exists even if Masque/WA replaced the button
    if not button.fontString then
        InitButtonFontString(button)
    end

    ApplyButtonScripts(button)
end

InitUI()
