---@class Global
---@field CropEnjoyer table
---@field CropEnjoyerTickerStore table
local Global = _G

-- GetShapeshiftFormID() form IDs for the Druid travel-type forms - a Druid
-- shifting into one of these isn't IsMounted(), but should be treated the
-- same for gear-swap purposes. IDs confirmed against warcraft.wiki.gg's
-- API_GetShapeshiftFormID (present since patch 2.0.1 / BC Anniversary).
local DRUID_TRAVEL_FORM_IDS = {
    [3] = true,  -- Travel Form
    [4] = true,  -- Aquatic Form
    [29] = true, -- Flight Form
    [27] = true, -- Swift Flight Form
}

local function IsInDruidTravelForm()
    local formID = GetShapeshiftFormID()
    return formID ~= nil and DRUID_TRAVEL_FORM_IDS[formID] or false
end

local function InitState()
    if aura_env.trinkets then return end
    Global.CropEnjoyer = Global.CropEnjoyer or {}
    Global.CropEnjoyer.warned = Global.CropEnjoyer.warned or false
    Global.CropEnjoyer.notFound = Global.CropEnjoyer.notFound or {}
    local slots = { 13, 14 }
    aura_env.enabled = true
    aura_env.protected = false
    aura_env.trinkets = {}
    aura_env.ticker = nil
    aura_env.trinkets.crop = 25653
    aura_env.trinkets.charm = 32481
    aura_env.trinkets.slotId = slots[aura_env.config.trinket_slot]
    aura_env.trinkets.fallbackNotFound = false
    aura_env.region:SetDesaturated(not aura_env.enabled)
    aura_env.snapshot = { active = false }
    aura_env.wasMounted = IsMounted() or IsInDruidTravelForm()
end

function aura_env:InitState()
    InitState()
end

local function isActive()
    return aura_env.enabled and WeakAuras.IsAuraLoaded(aura_env.id)
end

local function Print(msg)
    print((">\124cFF85e5ccCropEnjoyer\124r< %s"):format(msg))
end

local function Snapshot()
    aura_env.snapshot.trinket = GetInventoryItemLink("player", aura_env.trinkets.slotId)
    aura_env.snapshot.active = true
end

InitState()

local startTicker
local stopTicker
local UpdateVisualState

local function ShouldWarnMissingItem(item)
    if item ~= "" then return false end
    if Global.CropEnjoyer.warned then return true end
    Print("Consider setting up the items! Type /wa -> Crop Enjoyer -> Custom Options tab")
    Global.CropEnjoyer.warned = true
    return true
end

local function MarkMissingItem(item)
    if item == "" then return true end
    if Global.CropEnjoyer.notFound[item] then return true end
    Print(("%s not found in bags"):format(item))
    Global.CropEnjoyer.notFound[item] = true
    return true
end

-- Exposed on aura_env.trinkets (rather than left as the bare local above) so
-- trigger-conditions.lua's own custom trigger functions - a separate Lua
-- chunk that only shares state via aura_env - can use the same check.
function aura_env.trinkets:IsEffectivelyMounted()
    return IsMounted() or IsInDruidTravelForm()
end

function aura_env.trinkets:IsCropItem(item)
    if item == aura_env.trinkets.crop or item == aura_env.trinkets.charm then return true end
    if type(item) ~= "string" then return false end
    local id = tonumber(item:match("item:(%d+):"))
    return id == aura_env.trinkets.crop or id == aura_env.trinkets.charm
end

local function HasItemInBags(itemId)
    return C_Item.GetItemCount(itemId) > 0
end

function aura_env.trinkets:GetDesiredCropItem()
    if HasItemInBags(aura_env.trinkets.charm) then
        return aura_env.trinkets.charm
    end
    return aura_env.trinkets.crop
end

local function ShouldProtectSlot(slotId, item)
    if slotId ~= aura_env.trinkets.slotId then return false end
    if not aura_env.trinkets:IsCropItem(item) then return false end
    local _, duration, enable = GetInventoryItemCooldown("player", slotId)
    return enable == 1 and duration <= 30 and aura_env.protected
end

local function EquipNow(item, slotId)
    C_Item.EquipItemByName(item, slotId)
    aura_env.trinkets:Update()
end

local function ValidateEquipRequest(item, slotId, bypassProtection)
    if ShouldWarnMissingItem(item) then return false end
    if InCombatLockdown() then
        return false
    end
    if C_Item.GetItemCount(item) == 0 then
        MarkMissingItem(item)
        return false
    end
    if not bypassProtection and ShouldProtectSlot(slotId, item) then return false end
    return true
end

local function getTickerStore()
    if not Global.CropEnjoyerTickerStore then
        Global.CropEnjoyerTickerStore = {}
    end
    return Global.CropEnjoyerTickerStore
end

startTicker = function()
    if not isActive() then return end
    local store = getTickerStore()
    if store[aura_env.id] then
        aura_env.ticker = store[aura_env.id]
        return
    end
    local tickRate = tonumber(aura_env.config.tickRate) or 3
    if tickRate <= 0 then
        tickRate = 3
    end
    aura_env.ticker = C_Timer.NewTicker(tickRate, function()
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

UpdateVisualState = function()
    local lineAlpha = 0.24
    aura_env.region:SetDesaturated(not aura_env.enabled)
    -- Disable WA default glow; we use a softer custom glow layer.
    aura_env.region:SetGlow(false)

    local button = aura_env.region and aura_env.region.cropButton
    if not button or not button.edgeGlowParts then return end

    if not aura_env.enabled then
        for _, part in ipairs(button.edgeGlowParts) do
            part:Hide()
        end
        return
    end

    if aura_env.protected then
        local color = { 1.0, 0.72, 0.22, lineAlpha }
        for _, part in ipairs(button.edgeGlowParts) do
            part:SetColorTexture(color[1], color[2], color[3], color[4])
            part:Show()
        end
    else
        local color = { 0.40, 1.0, 0.55, lineAlpha }
        for _, part in ipairs(button.edgeGlowParts) do
            part:SetColorTexture(color[1], color[2], color[3], color[4])
            part:Show()
        end
    end
end

function aura_env.trinkets:Toggle()
    aura_env.enabled = not aura_env.enabled
    UpdateVisualState()
    if aura_env.enabled then startTicker() else stopTicker() end
end

function aura_env.trinkets:ProtectedMode()
    if not isActive() then return end
    aura_env.protected = not aura_env.protected
    UpdateVisualState()
end

function aura_env.trinkets:Update()
    aura_env.trinkets.top = GetInventoryItemLink("player", 13)
    aura_env.trinkets.bottom = GetInventoryItemLink("player", 14)
    aura_env.trinkets.equipped = {
        aura_env.trinkets.top,
        aura_env.trinkets.bottom,
    }
    local equipped = aura_env.trinkets.equipped[aura_env.config.trinket_slot]
    if not aura_env.trinkets:IsCropItem(equipped) then
        aura_env.trinkets.previous = equipped
    end
end

function aura_env.trinkets:TryEquip(item, slotId)
    if not isActive() then return end
    if not ValidateEquipRequest(item, slotId) then return end
    EquipNow(item, slotId)
end

function aura_env.trinkets:TryEquipSnapshot(item, slotId)
    if not isActive() then return end
    if not item or item == "" then return end
    if not ValidateEquipRequest(item, slotId, true) then return end
    EquipNow(item, slotId)
end

local function EnforceFallbackTrinket()
    if IsMounted() or InCombatLockdown() then return end
    if aura_env.snapshot.active then return end
    if not aura_env.trinkets:IsCropEquipped() then return end
    local fallback = aura_env.config.fallbackTrinket
    if not fallback or fallback == "" then return end

    if C_Item.GetItemCount(fallback) == 0 then
        if aura_env.trinkets.fallbackNotFound then return end
        Print(string.format("Crop equipped, but %s not found in bags",
            fallback))
        aura_env.trinkets.fallbackNotFound = true
        return
    end

    aura_env.trinkets:TryEquip(fallback, aura_env.trinkets.slotId)
    aura_env.trinkets.fallbackNotFound = false
end

local function EnforceSnapshotSlot(slotId, equipped, desiredLink)
    if not desiredLink or desiredLink == "" then return end
    if equipped ~= desiredLink then
        aura_env.trinkets:TryEquipSnapshot(desiredLink, slotId)
    end
end

local function EnforceGear()
    if InCombatLockdown() then return end
    local mounted = IsMounted() or IsInDruidTravelForm()
    if mounted then
        if not aura_env.wasMounted then
            Snapshot()
        end
        aura_env.trinkets:TryEquip(aura_env.trinkets:GetDesiredCropItem(), aura_env.trinkets.slotId)
    elseif aura_env.snapshot.active then
        EnforceSnapshotSlot(aura_env.trinkets.slotId,
            aura_env.trinkets.equipped[aura_env.config.trinket_slot],
            aura_env.snapshot.trinket)
        aura_env.trinkets:Update()
        local trinketOk = not aura_env.snapshot.trinket
            or aura_env.trinkets.equipped[aura_env.config.trinket_slot] == aura_env.snapshot.trinket
        if trinketOk then
            aura_env.snapshot.active = false
        end
    end
    aura_env.wasMounted = mounted
end

function aura_env.trinkets:IsCropEquipped()
    aura_env.trinkets.top = GetInventoryItemLink("player", 13)
    aura_env.trinkets.bottom = GetInventoryItemLink("player", 14)
    return aura_env.trinkets:IsCropItem(aura_env.trinkets.top) or
        aura_env.trinkets:IsCropItem(aura_env.trinkets.bottom)
end

function aura_env.trinkets:Enforce()
    if not isActive() or UnitOnTaxi("player") then return end
    aura_env.trinkets:Update()
    EnforceFallbackTrinket()
    EnforceGear()
end

aura_env.trinkets:Update()
startTicker()

local function ApplyButtonScripts(button)
    button:SetScript("OnEnter", function(frame)
        local x = frame:GetRight() + 140
        local anchor = x < GetScreenWidth() and "ANCHOR_BOTTOMRIGHT" or "ANCHOR_BOTTOMLEFT"
        GameTooltip:SetOwner(frame, anchor)
        GameTooltip:AddLine("|cff85e5ccCropEnjoyer|r")
        GameTooltip:AddLine("|cff80ff80Left Click|r |cffffffff-> Toggle ON/OFF|r")
        GameTooltip:AddLine("|cffffb347Right Click|r |cffffffff-> Toggle On-Use Protection|r")
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button:SetScript("OnClick", function(_, btn)
        if btn == "LeftButton" then
            WeakAuras.ScanEvents("TOGGLE_AURA")
        elseif btn == "RightButton" then
            WeakAuras.ScanEvents("TOGGLE_PROTECTION")
        end
    end)
end

local function CreateButton()
    local button = CreateFrame("BUTTON", nil, aura_env.region)

    local function CreateEdgePart(layer)
        local tex = button:CreateTexture(nil, layer)
        tex:SetBlendMode("ADD")
        tex:Hide()
        return tex
    end

    local function SetEdgeLayout(tex, side, inset, thickness)
        local cornerPad = thickness
        tex:ClearAllPoints()
        if side == "top" then
            tex:SetPoint("TOPLEFT", button, "TOPLEFT", inset, -inset)
            tex:SetPoint("TOPRIGHT", button, "TOPRIGHT", -inset, -inset)
            tex:SetHeight(thickness)
        elseif side == "bottom" then
            tex:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", inset, inset)
            tex:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -inset, inset)
            tex:SetHeight(thickness)
        elseif side == "left" then
            tex:SetPoint("TOPLEFT", button, "TOPLEFT", inset, -inset - cornerPad)
            tex:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", inset, inset + cornerPad)
            tex:SetWidth(thickness)
        else -- right
            tex:SetPoint("TOPRIGHT", button, "TOPRIGHT", -inset, -inset - cornerPad)
            tex:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -inset, inset + cornerPad)
            tex:SetWidth(thickness)
        end
    end

    button.edgeGlowParts = {}
    for _, side in ipairs({ "top", "bottom", "left", "right" }) do
        local edge = CreateEdgePart("OVERLAY")
        SetEdgeLayout(edge, side, 0, 3)
        table.insert(button.edgeGlowParts, edge)
    end

    local hoverTex = button:CreateTexture(nil, "HIGHLIGHT")
    hoverTex:SetAllPoints()
    hoverTex:SetColorTexture(.3, .3, .3, 0.9)
    button:SetHighlightTexture(hoverTex)

    ApplyButtonScripts(button)
    return button
end

local function InitUI()
    if not aura_env.region.cropButton then
        aura_env.region.cropButton = CreateButton()
    end

    local button = aura_env.region.cropButton
    button:SetAllPoints()
    button:EnableMouse(true)
    button:SetMouseClickEnabled(true)
    button:RegisterForClicks("AnyUp")

    ApplyButtonScripts(button)
    UpdateVisualState()
end

InitUI()
