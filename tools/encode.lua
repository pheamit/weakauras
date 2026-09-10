-- Reverse of decode.lua: turns an edited *_table_data.json back into a
-- pasteable WeakAuras import string ("!WA:2!...").
--
-- Run from inside this directory: luajit encode.lua <in.json> <out>

dofile("LibStub.lua")
dofile("LibDeflate.lua")
dofile("AceSerializer-3.0.lua")
dofile("LibSerialize.lua")

local LibDeflate = LibStub:GetLibrary("LibDeflate")
local LibSerialize = LibStub:GetLibrary("LibSerialize")

local inPath, outPath = arg[1], arg[2]
assert(inPath and outPath, "usage: encode.lua <in.json> <out>")

-- Minimal recursive-descent JSON parser, the inverse of decode.lua's
-- encoder. Object keys that look like plain positive integers ("1", "2",
-- ...) are converted back to Lua number keys - decode.lua's encoder always
-- stringifies numeric keys when a table mixes numeric and named keys (e.g.
-- WeakAuras' `triggers` table, which has [1]/[2]/[3] alongside
-- "disjunctive"/"activeTriggerMode"), so this is a faithful inverse, not a
-- guess.
local function parseJSON(str)
  local pos = 1

  local function skipWhitespace()
    local _, e = str:find("^%s*", pos)
    pos = e + 1
  end

  local parseValue

  local function parseString()
    assert(str:sub(pos, pos) == '"', "expected string at " .. pos)
    pos = pos + 1
    local buf = {}
    while true do
      local c = str:sub(pos, pos)
      if c == '"' then
        pos = pos + 1
        break
      elseif c == "\\" then
        local n = str:sub(pos + 1, pos + 1)
        local map = { ['"'] = '"', ["\\"] = "\\", ["/"] = "/", n = "\n", r = "\r", t = "\t", b = "\b", f = "\f" }
        if n == "u" then
          local hex = str:sub(pos + 2, pos + 5)
          buf[#buf + 1] = utf8 and utf8.char(tonumber(hex, 16)) or string.char(tonumber(hex, 16) % 256)
          pos = pos + 6
        else
          buf[#buf + 1] = map[n] or n
          pos = pos + 2
        end
      else
        buf[#buf + 1] = c
        pos = pos + 1
      end
    end
    return table.concat(buf)
  end

  local function parseNumber()
    local s, e, numStr = str:find("^(-?%d+%.?%d*[eE]?[+-]?%d*)", pos)
    assert(s, "expected number at " .. pos)
    pos = e + 1
    return tonumber(numStr)
  end

  local function parseArray()
    pos = pos + 1 -- '['
    local out = {}
    skipWhitespace()
    if str:sub(pos, pos) == "]" then
      pos = pos + 1
      return out
    end
    while true do
      skipWhitespace()
      out[#out + 1] = parseValue()
      skipWhitespace()
      local c = str:sub(pos, pos)
      if c == "," then
        pos = pos + 1
      elseif c == "]" then
        pos = pos + 1
        break
      else
        error("expected , or ] at " .. pos)
      end
    end
    return out
  end

  local function parseObject()
    pos = pos + 1 -- '{'
    local out = {}
    skipWhitespace()
    if str:sub(pos, pos) == "}" then
      pos = pos + 1
      return out
    end
    while true do
      skipWhitespace()
      local key = parseString()
      skipWhitespace()
      assert(str:sub(pos, pos) == ":", "expected : at " .. pos)
      pos = pos + 1
      skipWhitespace()
      local value = parseValue()
      local numericKey = key:match("^%d+$") and tonumber(key)
      out[numericKey or key] = value
      skipWhitespace()
      local c = str:sub(pos, pos)
      if c == "," then
        pos = pos + 1
      elseif c == "}" then
        pos = pos + 1
        break
      else
        error("expected , or } at " .. pos)
      end
    end
    return out
  end

  parseValue = function()
    skipWhitespace()
    local c = str:sub(pos, pos)
    if c == "{" then
      return parseObject()
    elseif c == "[" then
      return parseArray()
    elseif c == '"' then
      return parseString()
    elseif str:sub(pos, pos + 3) == "true" then
      pos = pos + 4
      return true
    elseif str:sub(pos, pos + 4) == "false" then
      pos = pos + 5
      return false
    elseif str:sub(pos, pos + 3) == "null" then
      pos = pos + 4
      return nil
    else
      return parseNumber()
    end
  end

  local result = parseValue()
  return result
end

local f = assert(io.open(inPath, "rb"))
local jsonStr = f:read("*a")
f:close()

local data = parseJSON(jsonStr)

local serialized = LibSerialize:Serialize(data)
local compressed = assert(LibDeflate:CompressDeflate(serialized, { level = 9 }), "CompressDeflate failed")
local encoded = assert(LibDeflate:EncodeForPrint(compressed), "EncodeForPrint failed")

local out = assert(io.open(outPath, "w"))
out:write("!WA:2!" .. encoded)
out:close()
io.stderr:write("Wrote " .. outPath .. " (" .. #encoded .. " chars encoded)\n")
