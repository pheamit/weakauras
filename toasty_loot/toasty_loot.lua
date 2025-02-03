-- Money
-- 133789 Copper, 133787 Silver, 133785 Gold
function(allstates, event, ...)
    if event == "PLAYER_MONEY" then
        local moneyDiff = 0
        local moneyText = ""
        local currentMoney = GetMoney()
        moneyDiff = currentMoney - aura_env.money
        
        if moneyDiff > 0 then
            moneyText = "You gain " .. GetCoinText(moneyDiff)
        else
            moneyText = "You lose " .. GetCoinText(math.abs(moneyDiff))
        end
        aura_env.money = currentMoney
        local guid = select(11, ...)
    local icon = 133789
    if moneyText:find("gold") then
        icon = 133785
    elseif moneyText:find("silver") then
        icon = 133787
    end
    allstates[guid] = {
            show = true,
            changed = true,
            progressType = "timed",
            duration = aura_env.config["duration"],
            icon = icon,
            autoHide = true,
        }
        return true
    end
    if select(2, ...) == UnitName("player") or select(2, ...) == "" then
    local text = select(1, ...)
    -- This guid is needed for the WA table to be unique and not override itself
    local guid = select(11, ...)
    local icon = 133789
    if text:find("gold") then
        icon = 133785
    elseif text:find("silver") then
        icon = 133787
    end
    allstates[guid] = {
            show = true,
            changed = true,
            progressType = "timed",
            duration = aura_env.config["duration"],
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
        if aura_env.config["count"] then
            aura_env.count = GetItemCount(link) + itemCount
        end
        allstates[guid] = {
            show = true,
            changed = true,
            progressType = "timed",
            duration = aura_env.config["duration"],
            icon = icon,
            autoHide = true,
            link = link,
        }
        return true
    end
end


