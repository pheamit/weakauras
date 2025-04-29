-- Money
-- 133789 Copper, 133787 Silver, 133785 Gold
-- 133789 Copper, 133787 Silver, 133785 Gold
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
        }
        return true
    end
end

-- Items
function(allstates, event, ...)
    if event == "CHAT_MSG_LOOT" and select(5, ...) == UnitName("player") then
        local text = select(1, ...)
        local link = text:match("(|c.+|r)")
        local name, _, quality, _, _, _, _, _, _, icon = C_Item.GetItemInfo(link)
        local r, g, b, hex = C_Item.GetItemQualityColor(quality)
        local itemsLooted = ""
        -- % is an escape character for search pattern special characters such as '.'
        if text:find("r%.") then
            itemsLooted = "1"
        else
            itemsLooted = text:sub(text:find("rx") + 2, text:find("%.") - 1)
        end
        -- This guid is needed for the WA table to be unique and not override itself
        local guid = select(11, ...)
        local text = "|c" .. hex .. name .. "|cff00ff00 x " .. itemsLooted
        aura_env.item = {
            guid = guid,
            text = text,
            link = link,
            icon = icon,
            looted = itemsLooted,
            count = "",
        }
    end 
    if event == "BAG_UPDATE_DELAYED" and aura_env.item then
        local count = C_Item.GetItemCount(aura_env.item.link)
        local totalCount = count > 0 and count or aura_env.item.looted
        aura_env.item.count = aura_env.config["count"] and totalCount or ""
        allstates[aura_env.item.guid] = {
            show = true,
            changed = true,
            progressType = "timed",
            duration = aura_env.config.duration,
            icon = aura_env.item.icon,
            autoHide = true,
            link = aura_env.item.link,
        }
        return true
    end
end


