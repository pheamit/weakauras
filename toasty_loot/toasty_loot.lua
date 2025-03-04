-- Money
-- 133789 Copper, 133787 Silver, 133785 Gold
-- 133789 Copper, 133787 Silver, 133785 Gold
function(allstates, event, ...)
    if event == "PLAYER_MONEY" then
        local currentMoney = GetMoney()
        local moneyDiff = currentMoney - aura_env.money
        local coinText = GetCoinText(math.abs(moneyDiff))
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
    if select(5, ...) == UnitName("player") then
        local text = select(1, ...)
        local link = text:match("(|c.+|r)")
        local name, link, quality, _, _, _, _, _, _, icon = GetItemInfo(link)
        local r, g, b, hex = GetItemQualityColor(quality)
        local itemCount = ""
        -- % is an escape character for search pattern special characters such as '.'
        if text:find("r%.") then
            itemCount = "1"
        else
            itemCount = text:sub(text:find("rx") + 2, text:find("%.") - 1)
        end
        -- This guid is needed for the WA table to be unique and not override itself
        local guid = select(11, ...)
        aura_env.text = "|c" .. hex .. name .. "|cff00ff00 x " .. itemCount
        aura_env.count = ""
        aura_env.region:SetScript("OnEnter", function(self, motion)
            print("OnEnter")
        end)
        aura_env.region:SetScript("OnLeave", function(self, motion)
            print("OnLeave")
        end)
        if aura_env.config["count"] then
            aura_env.count = GetItemCount(link) + itemCount
        end
        allstates[guid] = {
            show = true,
            changed = true,
            progressType = "timed",
            expirationTime = GetTime() + aura_env.config.duration,
            duration = aura_env.config.duration,
            icon = icon,
            autoHide = true,
            link = link,
        }
        return true
    end
end


