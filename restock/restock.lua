function(event)
    if event == "MERCHANT_SHOW" then
        
        local poisons = {
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
        }
        
        local merchantItems = {}
        
        -- Recursive table print function for debugging
        local function printTable(input)
            for k, v in pairs(input) do
                if type(v) == "table" then
                    print("(" .. type(k) .. ")" .. k .. ":")
                    printTable(v)    
                else
                    print("_" .. "(" .. type(k) .. ")" .. k .. ":" .. v)
                end
            end
        end
        
        -- Function to check if inventory has enough reagents for poison
        local function checkPoison(poisonID, quantity)
            -- Fast return if not a poison
            if not poisons[poisonID] then return end
            -- Check if inventory already has this poison, exit if true
            local restock_quantity = quantity - GetItemCount(poisonID)
            if restock_quantity <= 0 then return end
            local restock_reagents = {}
            for reagentID, quant in pairs(poisons[poisonID]) do
                local stock = GetItemCount(reagentID)
                if stock < quant * restock_quantity then
                    restock_reagents[reagentID] = (quant * restock_quantity) - stock
                end
            end
            return restock_reagents
        end
        
        local function buildMerchantTable()
            for i = 1, GetMerchantNumItems() do
                local itemLink = GetMerchantItemLink(i)
                if itemLink then
                    local linkParse = {strsplit(":", itemLink)}
                    local reagentID = linkParse[2]
                    local stackSize = select(8, GetItemInfo(reagentID))
                    local price = select(3, GetMerchantItemInfo(i))
                    if reagentID == "21177" then
                        price = price / 20
                    end
                    merchantItems[reagentID] = { idx = i, itemLink = itemLink, stackSize = stackSize, price = price }
                end
            end
        end
        
        local function restock(reagentID, quantity, check)
            local check = check or false
            local have = 0
            local restock = quantity
            if check then
                have = GetItemCount(merchantItems[reagentID].itemLink)
                restock = quantity - have
            end
            local totalPurchase = restock
            if restock <= 0 then return end
            -- Need to buy in batches of max allowed stacks, e.g. 20
            while restock >= merchantItems[reagentID].stackSize do
                BuyMerchantItem(merchantItems[reagentID].idx, merchantItems[reagentID].stackSize)
                restock = restock - merchantItems[reagentID].stackSize
            end
            if restock > 0 then
                BuyMerchantItem(merchantItems[reagentID].idx, restock)
            end
            print("\124cFF85e5ccRestock\124r purchased: " .. totalPurchase .. " " .. merchantItems[reagentID].itemLink .. " for: " .. GetCoinTextureString(totalPurchase * merchantItems[reagentID].price))
        end
        
        buildMerchantTable()
        
        if merchantItems then
            for class, items in pairs(aura_env.config) do
                if class == aura_env.restock.className then
                    for itemID, quantity in pairs(items) do
                        if quantity > 0 and merchantItems[itemID] then
                            restock(itemID, quantity, true)
                        end
                        if quantity > 0 and poisons[itemID] then
                            local poison_restock = checkPoison(itemID, quantity)
                            if poison_restock then
                                for id, quant in pairs(poison_restock) do
                                    if merchantItems[id] then
                                        restock(id, quant, false)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        -- return true
    end
end

-- On Init section
local className, classFilename, classId = UnitClass("player")
if not aura_env.restock then
    aura_env.restock = {}
end
aura_env.restock.className = className:lower()