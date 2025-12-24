local aura_env -- getting rid of the "undefined global" warning

-- Money Actions Custom Init
aura_env.money = GetMoney()

-- Money Trigger
-- TSU: PLAYER_MONEY
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
            totalMoney = aura_env.config["total"] and GetMoneyString(GetMoney(), true) or "",
        }
        return true
    end
end

-- Items Actions Custom Init
local _, isAuctionatorLoaded = C_AddOns.IsAddOnLoaded("Auctionator")
aura_env.isAucLoaded = isAuctionatorLoaded
if _G.Auctionator and _G.Auctionator.API and _G.Auctionator.API.v1 then
    aura_env.getPrice = _G.Auctionator.API.v1.GetAuctionPriceByItemID
end

-- Store the player's GUID to quickly compare against loot events
aura_env.playerGUID = UnitGUID("player")

-- Extract item link from chat message
function aura_env:getItemLinkFromText(chatText)
  return chatText and chatText:match("(|c.+|r)")
end

-- Parse quantity of items from chat message (default 1)
function aura_env:getItemQuantityFromText(chatText)
  local quantityString = chatText and chatText:match("x(%d+)")
  return tonumber(quantityString) or 1
end

-- Get item quality hex color, defaults to white
function aura_env:getItemQualityHex(itemID)
  local itemQuality = itemID and C_Item.GetItemQualityByID(itemID)
  if itemQuality then
    local _, _, _, hexColor = C_Item.GetItemQualityColor(itemQuality)
    return hexColor or "ffffffff"
  end
  return "ffffffff"
end

-- Return reagent quality markup if item is crafting reagent
function aura_env:getReagentQualityMarkup(itemID)
  if not itemID then return "" end
  local _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, isCraftingReagent = C_Item.GetItemInfo(itemID)
  if not isCraftingReagent then return "" end
  local reagentQuality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(itemID)
  return (reagentQuality and C_Texture.GetCraftingReagentQualityChatIcon(reagentQuality)) or ""
end

-- Calculate free bag slots and return as colored text
function aura_env:getColoredFreeSlotsText(enabled)
  if not enabled then return "" end
  local totalFreeSlots = 0
  for bagIndex = 0, Constants.InventoryConstants.NumBagSlots do
    totalFreeSlots = totalFreeSlots + (C_Container.GetContainerNumFreeSlots(bagIndex) or 0)
  end
  local freeSlotsString = tostring(totalFreeSlots)
  if totalFreeSlots <= 5 then
    return RED_FONT_COLOR:WrapTextInColorCode(freeSlotsString)
  elseif totalFreeSlots <= 10 then
    return YELLOW_FONT_COLOR:WrapTextInColorCode(freeSlotsString)
  else
    return GREEN_FONT_COLOR:WrapTextInColorCode(freeSlotsString)
  end
end

-- Get auction price string for item * quantity, or empty if not configured
function aura_env:getAuctionPriceString(itemID, quantity)
  if not (aura_env.config.auctionPrice and aura_env.isAucLoaded and aura_env.getPrice) then
    return ""
  end
  local unitPrice = aura_env.getPrice("Toasty Loot", itemID) or 0
  return GetMoneyString((unitPrice * (quantity or 0)) or 0, true) or ""
end

-- Items Trigger
-- TSU: CHAT_MSG_LOOT,BAG_UPDATE_DELAYED
function(allstates, event, ...)
  if event == "CHAT_MSG_LOOT" then
    local chatText, _, _, _, _, _, _, _, _, _, _, messageGUID = ...
    if messageGUID ~= aura_env.playerGUID then return false end

    local itemLink = aura_env:getItemLinkFromText(chatText)
    if not itemLink then return false end

    local itemID, _, _, _, itemIcon = C_Item.GetItemInfoInstant(itemLink)
    if not itemID then return false end

    local lootedQuantity  = aura_env:getItemQuantityFromText(chatText)
    local itemName = C_Item.GetItemNameByID(itemID) or ""
    local itemHexColor  = aura_env:getItemQualityHex(itemID)

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
        reagentQuality = aura_env:getReagentQualityMarkup(itemID),
      }
    end
    return false
  end

  if event == "BAG_UPDATE_DELAYED" then
    local freeSlotsText = aura_env:getColoredFreeSlotsText(aura_env.config.freeSpace)

    for itemID, state in pairs(allstates) do
      if aura_env.config.count then
        local inventoryCount = C_Item.GetItemCount(itemID)
        state.itemCount = (inventoryCount > 0) and inventoryCount or (state.itemsLooted or 0)
      end

      state.auctionPrice = aura_env:getAuctionPriceString(itemID, state.itemsLooted)
      state.lootText     = ("|c%s%s|cff00ff00 x %d"):format(state.hex, state.name, state.itemsLooted)
      state.freeSlots    = aura_env.config.freeSpace and freeSlotsText or ""

      state.show    = true
      state.changed = true
    end

    return true
  end

  return false
end

