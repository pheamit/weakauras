local aura_env -- getting rid of the "undefined global" warning

-- Money Actions Custom Init
aura_env.money = GetMoney()

-- Money Trigger
-- TSU: PLAYER_MONEY
-- 133789 Copper, 133787 Silver, 133785 Gold
--- @diagnostic disable-next-line:miss-name
function(allstates, event, ...)
    if event == "PLAYER_MONEY" then
        local currentMoney = GetMoney()
        local moneyDiff = currentMoney - aura_env.money
        local coinText = C_CurrencyInfo.GetCoinText(math.abs(moneyDiff))
        local moneyString = GetMoneyString(math.abs(moneyDiff))
        local moneyText = ""
        if moneyDiff > 0 then
            moneyText = "You |cff00ff00gain|r " .. moneyString
        else
            moneyText = "You |cffff0000lose|r " .. moneyString
            
        end
        aura_env.money = currentMoney
        aura_env.moneyText = moneyText
        local guid = GetTimePreciseSec()
        local icon = 133789
        if coinText:find("Gold") then
            icon = 133785
        elseif coinText:find("Silver") then
            icon = 133787
        end
        allstates[guid] = {
            show = true,
            changed = true,
            progressType = "timed",
            duration = aura_env.config.duration,
            icon = icon,
            autoHide = true,
            moneyText = moneyText,
            totalMoney = aura_env.config.total and GetMoneyString(GetMoney(), true) or "",
        }
        return true
    end
end

-- Items Actions Custom Init
aura_env.auctionatorLoaded = select(2, C_AddOns.IsAddOnLoaded("Auctionator"))
aura_env.tsmLoaded = select(2, C_AddOns.IsAddOnLoaded("TradeSkillMaster"))
aura_env.tsmPrice = {"dbmarket", "dbminbuyout", "dbregionsaleavg", "dbregionmarketavg"}
aura_env.isAucAddonLoaded = aura_env.auctionatorLoaded or aura_env.tsmLoaded
if _G.Auctionator and _G.Auctionator.API and _G.Auctionator.API.v1 then
    aura_env.getPrice = _G.Auctionator.API.v1.GetAuctionPriceByItemID
elseif _G.TSM_API and _G.TSM_API.GetCustomPriceValue then
    aura_env.getPrice = _G.TSM_API.GetCustomPriceValue
end

aura_env.playerName = UnitName("player")

function aura_env:getItemLinkFromText(chatText)
    return chatText and chatText:match("(|c.+|r)")
end

function aura_env:getItemQuantityFromText(chatText)
    local quantity = chatText and chatText:match("x(%d+)")
    return tonumber(quantity) or 1 
end

function aura_env:getItemBasics(itemInfo)
    local itemID, _, _, _, icon = C_Item.GetItemInfoInstant(itemInfo)
    local name = C_Item.GetItemNameByID(itemID)
    local quality = C_Item.GetItemQualityByID(itemID)
    local hex = "ffffffff"
    if quality then
        local _, _, _, hexColor = C_Item.GetItemQualityColor(quality)
        hex = hexColor or hex
    end
    
    return itemID, icon, name or "", hex, quality
end

function aura_env:getFreeSlotsText()
    local total = 0
    local numBags = _G.NUM_BAG_SLOTS or 4
    for bag = 0, numBags do
        local free = C_Container.GetContainerNumFreeSlots(bag)
        total = total + (free or 0)
    end
    local s = tostring(total)
    if total <= 5 then
        return RED_FONT_COLOR:WrapTextInColorCode(s)
    elseif total <= 10 then
        return YELLOW_FONT_COLOR:WrapTextInColorCode(s)
    else
        return GREEN_FONT_COLOR:WrapTextInColorCode(s)
    end
end

function aura_env:getAuctionPriceString(itemID, quantity, quality)
    if not aura_env.isAucAddonLoaded then return "" end
    local vendorPrice
    if quality == 0 then
        vendorPrice = select(11, C_Item.GetItemInfo(itemID))
        if not vendorPrice then
            return ""
        end
        return GetMoneyString((vendorPrice * (quantity or 0)) or 0, true) or ""
    end
    if aura_env.auctionatorLoaded and _G.Auctionator.API and _G.Auctionator.API.v1 then
        local unit = aura_env.getPrice("Toasty Loot", itemID) or 0
        return GetMoneyString((unit * (quantity or 0)) or 0, true) or ""
    elseif aura_env.tsmLoaded and _G.TSM_API and _G.TSM_API.GetCustomPriceValue then
        local itemString = _G.TSM_API.ToItemString(tostring(itemID))
        local unit = aura_env.getPrice(aura_env.tsmPrice[aura_env.config.auctionPriceGroup.tsmPrice] or "dbmarket", itemString) or 0
        return GetMoneyString((unit * (quantity or 0)) or 0, true) or ""
    end
end

function aura_env:getInventoryCount(itemInfo)
    return C_Item.GetItemCount(itemInfo) or 0
end

-- Items Trigger
-- TSU: CHAT_MSG_LOOT,BAG_UPDATE_DELAYED
--- @diagnostic disable-next-line:miss-name
function(allstates, event, ...)
    C_UIColor:GetColors()
    if event == "CHAT_MSG_LOOT" and aura_env.config.qirajiArtifact and select(5, ...) ~= aura_env.playerName then
        local chatText = ...
        local itemLink = aura_env:getItemLinkFromText(chatText)
        if not itemLink then return false end
        local itemID, itemIcon, itemName, itemHexColor = aura_env:getItemBasics(itemLink)
        local playerName = select(5, ...)
        if itemID == 21230 then
            WeakAuras.ScanEvents("ANCIENT_QIRAJI_ARTIFACT", playerName, itemLink)
        end
    end
    if event == "CHAT_MSG_LOOT" and select(5, ...) == aura_env.playerName then
        local chatText = ...
        local itemLink = aura_env:getItemLinkFromText(chatText)
        if not itemLink then return false end
        
        local itemID, itemIcon, itemName, itemHexColor, quality = aura_env:getItemBasics(itemLink)
        if not itemID then return false end
        
        local lootedQuantity = aura_env:getItemQuantityFromText(chatText)
        
        local state = allstates[itemID]
        if state and state.show == false then
            state.itemsLooted = (state.itemsLooted or 0) + lootedQuantity
        else
            allstates[itemID] = {
                show           = false,
                changed        = true,
                progressType   = "timed",
                expirationTime = GetTime() + aura_env.config.duration,
                duration       = aura_env.config.duration,
                autoHide       = true,
                icon           = itemIcon,
                link           = itemLink,
                hex            = itemHexColor,
                name           = itemName,
                lootText       = "",
                itemsLooted    = lootedQuantity,
                quality        = quality,
            }
        end
        return false
    end
    
    if event == "BAG_UPDATE_DELAYED" then
        local freeSlotsText = aura_env:getFreeSlotsText()
        
        for itemID, state in pairs(allstates) do
            if aura_env.config.count then
                local invCount, bankCount = aura_env:getInventoryCount(itemID)
                state.invCount = (invCount and invCount > 0) and invCount or (state.itemsLooted or 0)
                state.bankCount = bankCount or 0
            end
            
            state.auctionPrice = aura_env:getAuctionPriceString(itemID, state.itemsLooted, state.quality)
            state.lootText     = ("|c%s%s|cff00ff00 x %d"):format(state.hex, state.name, state.itemsLooted)
            state.freeSlots    = freeSlotsText
            state.show    = true
            state.changed = true
        end
        
        return true
    end
    
    return false
end

-- Items Trigger
-- Event: ANCIENT_QIRAJI_ARTIFACT
--- @diagnostic disable-next-line:miss-name
function(event, ...)
    local playerName, itemLink = ...
    aura_env.qirajiLooter = WA_ClassColorName(playerName)
    aura_env.qirajiLink = itemLink
    return true        
end



