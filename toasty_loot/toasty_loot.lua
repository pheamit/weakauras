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
    aura_env.text = text
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

