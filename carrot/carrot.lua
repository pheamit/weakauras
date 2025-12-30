if not aura_env.trinkets then
    _G.CarrotEnjoyer = _G.CarrotEnjoyer or {}
    _G.CarrotEnjoyer.warned = _G.CarrotEnjoyer.warned or false
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

local function isActive()
    return aura_env.enabled and WeakAuras.IsAuraLoaded(aura_env.id)
end

local function Print(msg)
    print((">\124cFF85e5ccCarrotEnjoyer\124r< %s"):format(msg))
end

local function getTickerStore()
    if not _G.CarrotEnjoyerTickerStore then
        _G.CarrotEnjoyerTickerStore = {}
    end
    return _G.CarrotEnjoyerTickerStore
end

local function startTicker()
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

local function stopTicker()
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

function aura_env.trinkets:TryEquip(item, slotId, skipDelay)
    if not isActive() then return end
    if item == "" and not _G.CarrotEnjoyer.warned then
        Print("Consider setting up the items! Type /wa -> Carrot Enjoyer -> Custom Options tab")
        _G.CarrotEnjoyer.warned = true
        return
    elseif item == "" and _G.CarrotEnjoyer.warned then
        return
    end
    if InCombatLockdown() then
        aura_env.trinkets.scheduledTrinkets[item] = slotId
        return
    end
    if C_Item.GetItemCount(item) == 0 then
        Print(("item %s not found"):format(item))
        return
    end

    local _, duration, enable = GetInventoryItemCooldown("player", slotId)
    if enable == 1 and duration <= 30 and aura_env.protected then return end

    local delayGroup = aura_env.config.delayGatheringGroup
    if delayGroup.toggleDelay and not skipDelay then
        if aura_env.trinkets.delayActive then return end
        local itemLink = GetInventoryItemLink("player", slotId)
        local enchants = { ":844:", ":845:", ":906:", ":909:" }
        for _, enchant in ipairs(enchants) do
            if string.find(tostring(itemLink), enchant) then
                Print(("delaying %s swap for %d seconds"):format(itemLink, delayGroup.delayDuration))
                aura_env.trinkets.delayActive = true
                stopTicker()
                C_Timer.After(delayGroup.delayDuration, function()
                    aura_env.trinkets.delayActive = false
                    aura_env.trinkets:TryEquip(item, slotId, true)
                    startTicker()
                end)
                return
            end
        end
    end

    C_Item.EquipItemByName(item, slotId)
    aura_env.trinkets:Update()
end

function aura_env.trinkets:IsCarrotEquipped()
    aura_env.trinkets.top = GetInventoryItemID("player", 13)
    aura_env.trinkets.bottom = GetInventoryItemID("player", 14)
    return aura_env.trinkets.top == aura_env.trinkets.carrot or aura_env.trinkets.bottom == aura_env.trinkets.carrot
end

function aura_env.trinkets:Enforce()
    if not isActive() or UnitOnTaxi("player") then return end
    aura_env.trinkets:Update()
    if not IsMounted() and not InCombatLockdown() and aura_env.trinkets:IsCarrotEquipped() and aura_env.config.fallbackTrinket ~= "" then
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

    if not IsMounted() and not InCombatLockdown() then
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

    if IsMounted() and not InCombatLockdown() then
        if aura_env.gloves.equipped ~= aura_env.gloves.ridingGloves then
            aura_env.trinkets:TryEquip(aura_env.gloves.ridingGloves, 10)
        end
        if aura_env.boots.equipped ~= aura_env.boots.spursBoots then
            aura_env.trinkets:TryEquip(aura_env.boots.spursBoots, 8)
        end
        if not aura_env.trinkets:IsCarrotEquipped() then
            aura_env.trinkets:TryEquip(aura_env.trinkets.carrot, aura_env.trinkets.slotId)
        end
    end
end

aura_env.trinkets:Update()
startTicker()

function aura_env.trinkets:CreateButton()
    local button = CreateFrame("BUTTON", nil, aura_env.region)

    local fontString = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local font, size, _ = fontString:GetFont()
    fontString:SetFont(font, size, "OUTLINE")
    fontString:SetTextToFit("PvP")
    fontString:SetTextColor(1, 1, 1, 1)
    fontString:SetShadowColor(1, 1, 1, 0)
    fontString:SetPoint("CENTER")
    button.fontString = fontString

    local hoverTex = button:CreateTexture(nil, "HIGHLIGHT")
    hoverTex:SetAllPoints()
    hoverTex:SetColorTexture(.3, .3, .3, 0.9)
    button:SetHighlightTexture(hoverTex)

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

    return button
end

if not aura_env.region.carrotButton then
    aura_env.region.carrotButton = aura_env.trinkets:CreateButton()
end

local carrotButton = aura_env.region.carrotButton
carrotButton:SetAllPoints()
carrotButton:EnableMouse(true)
carrotButton:SetMouseClickEnabled(true)
carrotButton:RegisterForClicks("AnyUp")

-- ensure font string exists even if Masque/WA replaced the button
if not carrotButton.fontString then
    local fontString = carrotButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local font, size, _ = fontString:GetFont()
    fontString:SetFont(font, size, "OUTLINE")
    fontString:SetTextToFit("PvP")
    fontString:SetTextColor(1, 1, 1, 1)
    fontString:SetShadowColor(1, 1, 1, 0)
    fontString:SetPoint("CENTER")
    carrotButton.fontString = fontString
end

carrotButton:SetScript("OnEnter", function(frame)
    local x = frame:GetRight() + 140
    local anchor = x < GetScreenWidth() and "ANCHOR_BOTTOMRIGHT" or "ANCHOR_BOTTOMLEFT"
    GameTooltip:SetOwner(frame, anchor)
    GameTooltip:AddLine("Left Click to toggle ON/OFF")
    GameTooltip:AddLine("Right Click to toggle PvP mode")
    GameTooltip:AddLine("Shift+Left Click to toggle on-use trinket protection")
    GameTooltip:Show()
end)

carrotButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

carrotButton:SetScript("OnClick", function(frame, btn)
    if btn == "LeftButton" and IsShiftKeyDown() then
        WeakAuras.ScanEvents("TOGGLE_PROTECTION")
    elseif btn == "LeftButton" then
        WeakAuras.ScanEvents("TOGGLE_AURA")
    elseif btn == "RightButton" then
        WeakAuras.ScanEvents("TOGGLE_PVP", frame.fontString)
    end
end)
