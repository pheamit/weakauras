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