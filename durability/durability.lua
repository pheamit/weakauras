-- On Init
if not aura_env.dura then
    aura_env.dura = {}
end

function aura_env.dura:Update()
    local slots = {
        1,
        3,
        5,
        6,
        7,
        8,
        9,
        10,
        16,
        17,
        18,
    }

    local avg_durability = 0
    local numItems = 0

    for i = 1, #slots do
        local current, maximum = GetInventoryItemDurability(slots[i])
        if current then
            local percent = math.floor((current / maximum) * 100)
            avg_durability = avg_durability + percent
            numItems = numItems + 1
        end
    end

    -- Check in case all durability items are taken off
    if avg_durability == 0 then
        avg_durability = string.format("\124cFFccfaf7%d%s\124r", 0, "%")
        return
    end

    avg_durability = math.floor(avg_durability / numItems)


    if avg_durability <= 25 then
        avg_durability = string.format("\124cFFff0000%d%s\124r", avg_durability, "%")
    elseif avg_durability <= 50 then
        avg_durability = string.format("\124cFFffa500%d%s\124r", avg_durability, "%")
    elseif avg_durability <= 75 then
        avg_durability = string.format("\124cFFfef65b%d%s\124r", avg_durability, "%")
    else
        avg_durability = string.format("\124cFF00ff00%d%s\124r", avg_durability, "%")
    end
    aura_env.dura.avg_durability = avg_durability
end

aura_env.dura:Update()

-- Trigger 1
function(event)
    if event == "UPDATE_INVENTORY_DURABILITY" then
        aura_env.dura:Update()
    end
end

-- Display Text Custom Function
function()
    return aura_env.dura.avg_durability
end