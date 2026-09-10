-- Decodes a WeakAuras export string (as served raw by wago.io, or copied
-- from WeakAuras' own in-game Export button) into JSON.
--
-- Run from inside this directory: luajit decode.lua <in> <out.json>
--
-- Vendored libraries in this folder (LibStub, LibDeflate, LibSerialize,
-- AceSerializer-3.0) are the real upstream sources WeakAuras itself uses to
-- produce these strings - run for real via luajit, not reimplemented - so
-- decoding is byte-exact instead of guesswork. See encode.lua for the
-- reverse direction.

dofile("LibStub.lua")
dofile("LibDeflate.lua")
dofile("AceSerializer-3.0.lua")
dofile("LibSerialize.lua")

local LibDeflate = LibStub:GetLibrary("LibDeflate")
local AceSerializer = LibStub:GetLibrary("AceSerializer-3.0")
local LibSerialize = LibStub:GetLibrary("LibSerialize")

local inPath, outPath = arg[1], arg[2]
assert(inPath and outPath, "usage: decode.lua <in> <out>")

local f = assert(io.open(inPath, "rb"))
local raw = f:read("*a")
f:close()

-- Strip the "!WA:2!" (or similar "!WA:<n>!") marker some export sources add.
local body = raw:match("^!WA:%d+!(.*)$") or raw
body = body:gsub("%s+$", "")

local decoded = assert(LibDeflate:DecodeForPrint(body), "DecodeForPrint failed")
local decompressed = assert(LibDeflate:DecompressDeflate(decoded), "DecompressDeflate failed")

local data
local ok, a, b = pcall(function() return LibSerialize:Deserialize(decompressed) end)
if ok and a then
  data = b
  io.stderr:write("Deserialized with LibSerialize\n")
else
  local ok2, success, result = pcall(function() return AceSerializer:Deserialize(decompressed) end)
  assert(ok2 and success, "Both LibSerialize and AceSerializer failed to deserialize")
  data = result
  io.stderr:write("Deserialized with AceSerializer-3.0\n")
end

-- Minimal, dependency-free Lua -> JSON encoder. Good enough for WeakAuras
-- data: only nil/boolean/number/string/table values are ever present.
local function isArray(t)
  local n = 0
  for _ in pairs(t) do n = n + 1 end
  for i = 1, n do
    if t[i] == nil then return false end
  end
  return n > 0, n
end

local escapes = {
  ['"'] = '\\"', ['\\'] = '\\\\', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t',
  ['\b'] = '\\b', ['\f'] = '\\f',
}
local function encodeString(s)
  local out = s:gsub('[%c"\\]', function(c)
    return escapes[c] or string.format('\\u%04x', c:byte())
  end)
  return '"' .. out .. '"'
end

local function encode(v, buf, indent)
  local t = type(v)
  if t == "nil" then
    buf[#buf + 1] = "null"
  elseif t == "boolean" then
    buf[#buf + 1] = tostring(v)
  elseif t == "number" then
    if v ~= v or v == math.huge or v == -math.huge then
      buf[#buf + 1] = "0"
    elseif math.floor(v) == v and math.abs(v) < 2 ^ 53 then
      buf[#buf + 1] = string.format("%d", v)
    else
      buf[#buf + 1] = string.format("%.17g", v)
    end
  elseif t == "string" then
    buf[#buf + 1] = encodeString(v)
  elseif t == "table" then
    local nextIndent = indent .. "  "
    local arr, n = isArray(v)
    if arr then
      if n == 0 then
        buf[#buf + 1] = "[]"
        return
      end
      buf[#buf + 1] = "[\n"
      for i = 1, n do
        buf[#buf + 1] = nextIndent
        encode(v[i], buf, nextIndent)
        buf[#buf + 1] = (i < n) and ",\n" or "\n"
      end
      buf[#buf + 1] = indent .. "]"
    else
      local keys = {}
      for k in pairs(v) do keys[#keys + 1] = k end
      table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
      if #keys == 0 then
        buf[#buf + 1] = "{}"
        return
      end
      buf[#buf + 1] = "{\n"
      for i, k in ipairs(keys) do
        buf[#buf + 1] = nextIndent
        buf[#buf + 1] = encodeString(tostring(k))
        buf[#buf + 1] = ": "
        encode(v[k], buf, nextIndent)
        buf[#buf + 1] = (i < #keys) and ",\n" or "\n"
      end
      buf[#buf + 1] = indent .. "}"
    end
  else
    error("Cannot encode value of type " .. t)
  end
end

local buf = {}
encode(data, buf, "")
local out = assert(io.open(outPath, "w"))
out:write(table.concat(buf))
out:write("\n")
out:close()
io.stderr:write("Wrote " .. outPath .. "\n")
