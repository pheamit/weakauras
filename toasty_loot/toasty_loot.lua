local aura_env -- getting rid of the "undefined global" warning
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
        local itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subClassID = C_Item.GetItemInfoInstant(link)
        local quality = C_Item.GetItemQualityByID(link)
        local name = C_Item.GetItemNameByID(link)
        local r, g, b, hex = C_Item.GetItemQualityColor(quality)
        local itemsLooted = ""
        -- % is an escape character for search pattern special characters such as '.'
        if text:find("r%.") then
            itemsLooted = "1"
        else
            itemsLooted = text:sub(text:find("rx") + 2, text:find("%.") - 1)
        end
        if allstates[itemID] and allstates[itemID].show == false then
            allstates[itemID].itemsLooted = allstates[itemID].itemsLooted + itemsLooted
            allstates[itemID].timestamp = timestamp
        else
            allstates[itemID] = {
                show = false,
                changed = true,
                progressType = "timed",
                expirationTime = GetTime() + aura_env.config.duration,
                duration = aura_env.config.duration,
                autoHide = true,
                icon = icon,
                link = link,
                hex = hex,
                name = name,
                lootText = "",
                itemsLooted = itemsLooted,
            }
        end
    end
    if event == "BAG_UPDATE_DELAYED" then
        for itemID, state in pairs(allstates) do
            if aura_env.config["count"] then
                local initialCount = C_Item.GetItemCount(itemID)
                -- Check for when C_Item.GetItemCount() returns 0 if item is new for the inventory
                local totalCount = initialCount > 0 and initialCount or state.itemsLooted
                state.itemCount = totalCount
            end
            state.lootText = "|c" .. state.hex .. state.name .. "|cff00ff00 x " .. state.itemsLooted
            state.show = true
            state.changed = true
        end
        return true
    end
end
