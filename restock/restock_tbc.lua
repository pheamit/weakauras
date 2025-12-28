-- Trigger 1
---@diagnostic disable-next-line: miss-name
function (event, ...)
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
    end
end

-- On Init section
if not aura_env.restock then
    aura_env.restock = {}
    aura_env.restock.merchantItems = {}
    aura_env.restock.poisonReagents = {}
    aura_env.restock.poisons = {
        ["21835"] = {
            ["2931"] = 1,
            ["5173"] = 1,
            ["8925"] = 1,
            name = "Anesthetic Poison",
        },
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
        ["22053"] = {
            ["2931"] = 1,
            ["8925"] = 1,
            name = "Deadly Poison VI",
        },
        ["22054"] = {
            ["2931"] = 1,
            ["8925"] = 1,
            name = "Deadly Poison VII",
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
        ["21927"] = {
            ["2931"] = 1,
            ["8925"] = 1,
            name = "Instant Poison VII",
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
        ["22055"] = {
            ["8923"] = 2,
            ["8925"] = 1,
            name = "Wound Poison V",
        },
    }
end
local className, classFilename, classId = UnitClass("player")
aura_env.restock.className = className:lower()

function aura_env.restock:BuildMerchantTable()
    -- Clear the table before rebuilding
    aura_env.restock.merchantItems = {}
    for i = 1, GetMerchantNumItems() do
        local itemLink = GetMerchantItemLink(i)
        if itemLink then
            local linkParse = { strsplit(":", itemLink) }
            local reagentID = linkParse[2]
            local stackSize = select(8, C_Item.GetItemInfo(reagentID))
            local price, quantity = select(3, GetMerchantItemInfo(i))
            price = price / quantity
            aura_env.restock.merchantItems[reagentID] = {
                idx = i,
                itemLink = itemLink,
                stackSize = stackSize,
                price = price,
            }
        end
    end
    if next(aura_env.restock.merchantItems) then
        WeakAuras.ScanEvents("MERCHANT_TABLE_BUILT")
    end
end

function aura_env.restock:AddPoisonReagents(poisonID, quantity)
    -- Check if there are any poisons left in inventory
    local restock = quantity - C_Item.GetItemCount(poisonID)
    if restock <= 0 then return end
    for reagentID, quant in pairs(aura_env.restock.poisons[poisonID]) do
        if type(quant) == "number" then
            if aura_env.restock.poisonReagents[reagentID] then
                aura_env.restock.poisonReagents[reagentID] = aura_env.restock.poisonReagents[reagentID] + restock * quant
            else
                aura_env.restock.poisonReagents[reagentID] = restock * quant
            end
        end
    end
end

function aura_env.restock:BuyPoisonReagents()
    for reagentID, quantity in pairs(aura_env.restock.poisonReagents) do
        if aura_env.restock.merchantItems[reagentID] then
            aura_env.restock:Restock(reagentID, quantity, true)
        end
        -- Clear the table after restocking
        aura_env.restock.poisonReagents = {}
    end
end

function aura_env.restock:Restock(reagentID, quantity, check)
    local merchantItems = aura_env.restock.merchantItems
    local check = check or false
    local have = 0
    local restock = quantity
    if check then
        have = C_Item.GetItemCount(merchantItems[reagentID].itemLink)
        restock = quantity - have
    end
    local totalPurchase = restock
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
    print("\124cFF85e5ccRestock\124r: " ..
        totalPurchase ..
        " " ..
        merchantItems[reagentID].itemLink ..
        " for: " .. C_CurrencyInfo.GetCoinTextureString(totalPurchase * merchantItems[reagentID].price))
end
