-- Minimal JSON parse/string-escape helpers shared by sync.lua. encode.lua and
-- decode.lua keep their own copies (each predates this file and is already
-- verified via round-trip testing), so this exists only for new tooling.

local json = {}

-- Object keys that look like plain positive integers ("1", "2", ...) are
-- converted back to Lua number keys, matching decode.lua's own JSON encoder,
-- which always stringifies numeric keys when a table mixes numeric and named
-- keys (e.g. WeakAuras' `triggers` table: [1]/[2]/[3] alongside
-- "disjunctive"/"activeTriggerMode").
function json.parse(str)
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

  return parseValue()
end

local escapes = {
  ['"'] = '\\"', ['\\'] = '\\\\', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t',
  ['\b'] = '\\b', ['\f'] = '\\f',
}
function json.encodeString(s)
  local out = s:gsub('[%c"\\]', function(c)
    return escapes[c] or string.format('\\u%04x', c:byte())
  end)
  return '"' .. out .. '"'
end

return json
