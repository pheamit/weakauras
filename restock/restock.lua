-- Trigger 1
function(event)
    if event == "MERCHANT_SHOW" then
        aura_env.restock:BuildMerchantTable()

        if aura_env.restock.merchantItems then
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
                        -- Reset poison reagents table after purchase
                        aura_env.restock.poisonReagents = {}
                    end
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
        ["8928"] = {
            ["8924"] = 4,
            ["8925"] = 1,
        },
        ["3776"] = {
            ["8923"] = 3,
            ["8925"] = 1,
        },
        ["9186"] = {
            ["8924"] = 2,
            ["8923"] = 2,
            ["8925"] = 1,
        },
        ["10922"] = {
            ["5173"] = 2,
            ["8923"] = 2,
            ["8925"] = 1,
        },
        ["8985"] = {
            ["5173"] = 5,
            ["8925"] = 1,
        },
        ["20844"] = {
            ["5173"] = 7,
            ["8925"] = 1,
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
                price =
                    price
            }
        end
    end
end

function aura_env.restock:AddPoisonReagents(poisonID, quantity)
    -- Check if there are any poisons left in inventory
    local restock = quantity - C_Item.GetItemCount(poisonID)
    if restock <= 0 then return end
    for reagentID, quant in pairs(aura_env.restock.poisons[poisonID]) do
        if aura_env.restock.poisonReagents[reagentID] then
            aura_env.restock.poisonReagents[reagentID] = aura_env.restock.poisonReagents[reagentID] + restock * quant
        else
            aura_env.restock.poisonReagents[reagentID] = restock * quant
        end
    end
end

function aura_env.restock:BuyPoisonReagents()
    for reagentID, quantity in pairs(aura_env.restock.poisonReagents) do
        if aura_env.restock.merchantItems[reagentID] then
            aura_env.restock:Restock(reagentID, quantity, true)
        end
    end
end

function aura_env.restock:Restock(reagentID, quantity, check)
    local check = check or false
    local have = 0
    local restock = quantity
    if check then
        have = C_Item.GetItemCount(aura_env.restock.merchantItems[reagentID].itemLink)
        restock = quantity - have
    end
    local totalPurchase = restock
    if restock <= 0 then return end
    -- Need to buy in batches of max allowed stacks, e.g. 20
    while restock >= aura_env.restock.merchantItems[reagentID].stackSize do
        BuyMerchantItem(aura_env.restock.merchantItems[reagentID].idx,
            aura_env.restock.merchantItems[reagentID].stackSize)
        restock = restock - aura_env.restock.merchantItems[reagentID].stackSize
    end
    if restock > 0 then
        BuyMerchantItem(aura_env.restock.merchantItems[reagentID].idx, restock)
    end
    print("\124cFF85e5ccRestock\124r: " ..
        totalPurchase ..
        " " ..
        aura_env.restock.merchantItems[reagentID].itemLink ..
        " for: " .. C_CurrencyInfo.GetCoinTextureString(totalPurchase * aura_env.restock.merchantItems[reagentID].price))
end