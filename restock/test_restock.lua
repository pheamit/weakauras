local failures = {}

local function check(condition, message)
  if not condition then
    failures[#failures + 1] = message
  end
end

local function readFile(path)
  local f = assert(io.open(path, "rb"))
  local content = f:read("*a")
  f:close()
  return content
end

local itemInfo = {
  ["2512"] = { stackSize = 200 },
  ["2928"] = { stackSize = 20 },
  ["3371"] = { stackSize = 20 },
  ["5565"] = { stackSize = 10 },
  ["7777"] = { stackSize = nil, pendingStackSize = 50 }, -- uncached at BuildMerchantTable time, resolves once loaded
  ["6666"] = { stackSize = nil, pendingStackSize = nil }, -- never resolves
  ["8888"] = { stackSize = 30 },
}

local merchantStock = {
  { id = "2512", price = 200, quantity = 200 },
  { id = "2928", price = 20, quantity = 20 },
  { id = "3371", price = 20, quantity = 20 },
  { id = "5565", price = 100, quantity = 10 },
  { id = "7777", price = 50, quantity = 50 },
  { id = "6666", price = 15, quantity = 15 },
  { id = "8888", price = 30, quantity = 30 },
}

local buyCalls = {}
local itemCounts = setmetatable({}, { __index = function() return 0 end })

function GetMerchantNumItems()
  return #merchantStock
end

function GetMerchantItemLink(i)
  local id = merchantStock[i].id
  return "item:" .. id .. ":0:0:0:0:0:0:0:0:0"
end

function GetMerchantItemInfo(i)
  local entry = merchantStock[i]
  return "Test Item", "texture", entry.price, entry.quantity, 0, true, false
end

C_Item = {}
function C_Item.GetItemInfo(id)
  local info = itemInfo[id]
  if not info then return nil end
  return "Test Item", "itemLink", 1, 1, 1, "type", "subtype", info.stackSize
end

function C_Item.GetItemCount(key)
  return itemCounts[key]
end

Item = {}
function Item:CreateFromItemID(itemID)
  local id = tostring(itemID)
  return {
    ContinueOnItemLoad = function(self, callback)
      itemInfo[id].stackSize = itemInfo[id].pendingStackSize
      callback()
    end,
  }
end

function strsplit(sep, str)
  local parts = {}
  for part in (str .. sep):gmatch("([^" .. sep .. "]*)" .. sep) do
    parts[#parts + 1] = part
  end
  return unpack(parts)
end

function BuyMerchantItem(idx, quantity)
  buyCalls[#buyCalls + 1] = { idx = idx, quantity = quantity }
end

C_CurrencyInfo = { GetCoinTextureString = function(copper) return tostring(copper) .. "c" end }

COMMON_GRAY_COLOR = { WrapTextInColorCode = function(self, text) return "|cffa8a8a8" .. text .. "|r" end }

WeakAuras = { ScanEvents = function() end }

function UnitClass(unit)
  return "Rogue", "ROGUE", 8
end

function GetBuildInfo()
  return "2.5.1", "50000", "Jan 1 2024", 20504
end

aura_env = {
  config = {
    rogue = {
      ["6947"] = 5,   -- Instant Poison: no direct merchant entry, bought via reagents
      ["5555"] = 3,   -- not sold, not a poison: must be a no-op
    },
    ammo = {
      ["2512"] = 200, -- plain restock
      ["7777"] = 50,  -- uncached at first, resolves via ContinueOnItemLoad
      ["6666"] = 15,  -- uncached and never resolves: must not error or purchase
      ["8888"] = 30,  -- must still be purchased even though 7777/6666 deferred
    },
    misc = {},
    warlock = {
      ["5565"] = 10,  -- sold at merchant, but category doesn't match current class
    },
  },
}

dofile("init.lua")

local triggerFn = assert(loadstring("return " .. readFile("trigger.lua")))()
local untriggerFn = assert(loadstring("return " .. readFile("untrigger.lua")))()

triggerFn("MERCHANT_SHOW")
check(next(aura_env.restock.merchantItems) ~= nil, "BuildMerchantTable populated merchantItems")

triggerFn("MERCHANT_TABLE_BUILT")

local function callFor(id)
  for i, entry in ipairs(merchantStock) do
    if entry.id == id then
      for _, call in ipairs(buyCalls) do
        if call.idx == i then return call end
      end
      return nil
    end
  end
  error("no merchant entry for " .. id)
end

check(callFor("2512") ~= nil and callFor("2512").quantity == 200, "plain ammo item 2512 restocked for 200")
check(callFor("2928") ~= nil and callFor("2928").quantity == 5, "poison reagent 2928 bought for 5")
check(callFor("3371") ~= nil and callFor("3371").quantity == 5, "poison reagent 3371 bought for 5")
check(callFor("8888") ~= nil and callFor("8888").quantity == 30, "item 8888 still restocked despite 7777/6666 deferring")
check(callFor("7777") ~= nil and callFor("7777").quantity == 50, "item 7777 bought once ContinueOnItemLoad resolves it")
check(callFor("6666") == nil, "item 6666 (never resolves) was not purchased and did not error")
check(callFor("5565") == nil, "warlock-only item 5565 not purchased under rogue class")
check(#buyCalls == 5, "exactly 5 purchases were made, got " .. #buyCalls)

check(untriggerFn("MERCHANT_CLOSED") == true, "untrigger returns true on MERCHANT_CLOSED")
check(not untriggerFn("SOME_OTHER_EVENT"), "untrigger returns falsy on unrelated events")

if #failures == 0 then
  print("All checks passed.")
  os.exit(0)
else
  print(#failures .. " check(s) failed:")
  for _, message in ipairs(failures) do
    print("  - " .. message)
  end
  os.exit(1)
end
