-- Trigger 1
---@diagnostic disable-next-line:miss-name
function (event)
    if event == "MERCHANT_SHOW" then
        aura_env.restock:BuildMerchantTable()
    elseif event == "MERCHANT_TABLE_BUILT" then
        for category, items in pairs(aura_env.config) do
            if category == aura_env.restock.className or category == "ammo" or category == "misc" then
                for itemID, quantity in pairs(items) do
                    if quantity > 0 and aura_env.restock.merchantItems[itemID] then
                        aura_env.restock:Restock(itemID, quantity, true)
                    end
                    if quantity > 0 and aura_env.restock.poisons[itemID] then
                        aura_env.restock:AddPoisonReagents(itemID, quantity)
                    end
                end
                if aura_env.restock.poisonReagents then
                    aura_env.restock:BuyPoisonReagents()
                end
            end
        end
        if aura_env.restock.totalSpent > 0 then
            aura_env:Print("spent total: " .. C_CurrencyInfo.GetCoinTextureString(aura_env.restock.totalSpent))
            aura_env.restock.totalSpent = 0
        end
    end
end

-- Untrigger 1
---@diagnostic disable-next-line: miss-name
function(event)
    if event == "MERCHANT_CLOSED" then
        return true
    end    
end

-- On Init section
if not aura_env.restock then
    aura_env.restock = {}
    aura_env.restock.debug = false
    aura_env.restock.totalSpent = 0
    aura_env.restock.merchantItems = {}
    aura_env.restock.poisonReagents = {}
    aura_env.restock.poisons = {
        ["3775"] = {
            ["2930"] = 1,
            ["3371"] = 1,
            name = "Crippling Poison",
        },
        ["3776"] = {
            ["8923"] = 3,
            ["8925"] = 1,
            name = "Crippling Poison II",
        },
        ["2892"] = {
            ["5173"] = 1,
            ["3372"] = 1,
            name = "Deadly Poison",
        },
        ["2893"] = {
            ["5173"] = 2,
            ["3372"] = 1,
            name = "Deadly Poison II",
        },
        ["8984"] = {
            ["5173"] = 1,
            ["8925"] = 1,
            name = "Deadly Poison III",
        },
        ["8985"] = {
            ["5173"] = 5,
            ["8925"] = 1,
            name = "Deadly Poison IV",
        },
        ["20844"] = {
            ["5173"] = 7,
            ["8925"] = 1,
            name = "Deadly Poison V",
        },
        ["6947"] = {
            ["2928"] = 1,
            ["3371"] = 1,
            name = "Instant Poison",
        },
        ["6949"] = {
            ["2928"] = 1,
            ["3372"] = 1,
            name = "Instant Poison II",
        },
        ["6950"] = {
            ["8924"] = 2,
            ["3372"] = 1,
            name = "Instant Poison III",
        },
        ["8926"] = {
            ["8924"] = 1,
            ["8925"] = 1,
            name = "Instant Poison IV",
        },
        ["8927"] = {
            ["8924"] = 2,
            ["8925"] = 1,
            name = "Instant Poison V",
        },
        ["8928"] = {
            ["8924"] = 4,
            ["8925"] = 1,
            name = "Instant Poison VI",
        },
        ["5237"] = {
            ["2928"] = 1,
            ["3371"] = 1,
            name = "Mind-numbing Poison",
        },
        ["6951"] = {
            ["8923"] = 1,
            ["3372"] = 1,
            name = "Mind-numbing Poison II",
        },
        ["9186"] = {
            ["8924"] = 2,
            ["8923"] = 2,
            ["8925"] = 1,
            name = "Mind-numbing Poison III",
        },
        ["10918"] = {
            ["2930"] = 1,
            ["3372"] = 1,
            name = "Wound Poison",
        },
        ["10920"] = {
            ["2930"] = 1,
            ["5173"] = 1,
            ["3372"] = 1,
            name = "Wound Poison II",
        },
        ["10921"] = {
            ["8923"] = 1,
            ["8925"] = 1,
            name = "Wound Poison III",
        },
        ["10922"] = {
            ["5173"] = 2,
            ["8923"] = 2,
            ["8925"] = 1,
            name = "Wound Poison IV",
        },
    }
end
local className, classFilename, classId = UnitClass("player")
aura_env.restock.className = className:lower()

function aura_env:DebugPrint(message)
    if not aura_env.restock.debug then return end
    print(">\124cFF85e5ccRestock\124r< [DEBUG] " .. message)
end

function aura_env:Print(message)
    print(">\124cFF85e5ccRestock\124r< " .. message)
end

function aura_env.restock:BuildMerchantTable()
    -- Clear the table before rebuilding
    aura_env.restock.merchantItems = {}
    local numItems = GetMerchantNumItems()
    aura_env:DebugPrint("BuildMerchantTable: items=" .. numItems)
    for i = 1, numItems do
        local itemLink = GetMerchantItemLink(i)
        if not itemLink then
            aura_env:DebugPrint("BuildMerchantTable: no itemLink at index " .. i)
        else
            local linkParse = { strsplit(":", itemLink) }
            local reagentID = linkParse[2]
            if not reagentID then
                aura_env:DebugPrint("BuildMerchantTable: failed to parse link " .. itemLink)
            else
                local stackSize = select(8, C_Item.GetItemInfo(reagentID))
                if not stackSize then
                    aura_env:DebugPrint("BuildMerchantTable: missing item info for " .. reagentID)
                end
                local price, quantity = select(3, GetMerchantItemInfo(i))
                if not price or not quantity or quantity == 0 then
                    aura_env:DebugPrint("BuildMerchantTable: invalid price/quantity for " .. itemLink)
                    price = 0
                else
                    price = price / quantity
                end
                aura_env.restock.merchantItems[reagentID] = {
                    idx = i,
                    itemLink = itemLink,
                    stackSize = stackSize,
                    price = price,
                }
            end
        end
    end
    if next(aura_env.restock.merchantItems) then
        WeakAuras.ScanEvents("MERCHANT_TABLE_BUILT")
    else
        aura_env:DebugPrint("BuildMerchantTable: merchant table empty")
    end
end

function aura_env.restock:AddPoisonReagents(poisonID, quantity)
    -- Check if there are any poisons left in inventory
    local restock = quantity - C_Item.GetItemCount(poisonID)
    aura_env:DebugPrint("AddPoisonReagents: poisonID=" .. poisonID ..
        " desired=" .. quantity .. " restock=" .. restock)
    if restock <= 0 then return end
    for reagentID, quant in pairs(aura_env.restock.poisons[poisonID]) do
        if type(quant) == "number" then
            if aura_env.restock.poisonReagents[reagentID] then
                aura_env.restock.poisonReagents[reagentID] = aura_env.restock.poisonReagents[reagentID] + restock * quant
            else
                aura_env.restock.poisonReagents[reagentID] = restock * quant
            end
            aura_env:DebugPrint("AddPoisonReagents: reagentID=" ..
                reagentID .. " add=" .. (restock * quant) .. " total=" .. aura_env.restock.poisonReagents[reagentID])
        end
    end
end

function aura_env.restock:BuyPoisonReagents()
    aura_env:DebugPrint("BuyPoisonReagents: start")
    for reagentID, quantity in pairs(aura_env.restock.poisonReagents) do
        if aura_env.restock.merchantItems[reagentID] then
            aura_env.restock:Restock(reagentID, quantity, true)
        else
            aura_env:DebugPrint("BuyPoisonReagents: missing merchant item for reagentID=" .. reagentID)
        end
        -- Clear the table after restocking
        aura_env.restock.poisonReagents = {}
    end
    aura_env:DebugPrint("BuyPoisonReagents: done")
end

function aura_env.restock:Restock(reagentID, quantity, check)
    local merchantItems = aura_env.restock.merchantItems
    local check = check or false
    local have = 0
    local restock = quantity
    local price = 0
    aura_env:DebugPrint("reagentID=" .. reagentID ..
        " quantity=" .. quantity .. " check=" .. tostring(check))
    if check then
        if not merchantItems[reagentID] then
            aura_env:DebugPrint("missing merchantItems for reagentID=" .. reagentID)
            return
        end
        have = C_Item.GetItemCount(merchantItems[reagentID].itemLink)
        restock = quantity - have
    end
    local totalPurchase = restock
    aura_env:DebugPrint("have=" .. have .. " restock=" .. restock)
    if restock <= 0 then return end
    -- Need to buy in batches of max allowed stacks, e.g. 20
    while restock >= merchantItems[reagentID].stackSize do
        BuyMerchantItem(merchantItems[reagentID].idx,
            merchantItems[reagentID].stackSize)
        restock = restock - merchantItems[reagentID].stackSize
        C_Timer.After(0.1, function() end)
    end
    if restock > 0 then
        BuyMerchantItem(merchantItems[reagentID].idx, restock)
    end
    price = totalPurchase * merchantItems[reagentID].price
    aura_env.restock.totalSpent = aura_env.restock.totalSpent + price
    aura_env:Print("purchased " ..
        totalPurchase ..
        " " ..
        merchantItems[reagentID].itemLink ..
        " for: " .. C_CurrencyInfo.GetCoinTextureString(price))
end
