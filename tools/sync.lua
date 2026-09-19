-- Syncs edited .lua source files back into a WeakAuras table-data.json's
-- `custom` code fields, then regenerates the import string via encode.lua.
--
-- The JSON is never fully re-parsed and re-dumped for this - each target
-- field's old value is located and swapped for the new one via exact,
-- single-occurrence text substitution, so nothing else in the file (key
-- order, number formatting, ...) gets reformatted as a side effect.
--
-- Run from inside this directory, in one of two ways:
--
-- 1) Manifest mode - the common case:
--      luajit sync.lua <aura-dir>
--    Reads <aura-dir>/sync.json, e.g.:
--      {
--        "json": "table-data.json",
--        "mappings": [
--          { "path": "d.actions.init.custom", "file": "crop-enjoyer.lua" },
--          { "path": "d.triggers.1.trigger.custom",
--            "file": "trigger-conditions.lua", "marker": "-- Trigger 1" },
--          { "path": "d.triggers.2.trigger.custom",
--            "file": "trigger-conditions.lua", "marker": "-- Trigger 2" }
--        ]
--      }
--    "json" and every mapping's "file" are resolved relative to <aura-dir>,
--    so the manifest travels with the aura and never mentions cwd-relative
--    paths.
--
-- 2) Ad hoc mode - for a one-off sync, or an aura with no manifest yet:
--      luajit sync.lua <table-data.json> <path>=<file>[#<marker>] [...]
--
-- In both modes, <path> is a dot-separated path into the JSON (numeric
-- segments allowed, e.g. d.triggers.1.trigger.custom). Without a marker, the
-- file's entire contents are synced verbatim into that field. With a
-- #marker, the file is expected to hold multiple sections headed by lines
-- that are exactly "-- Trigger <N>" (as trigger-conditions.lua does); the
-- marker selects one section, and only the function(...) ... end literal
-- inside it is extracted - the marker line and any pragma/comment lines
-- between it and the function are dropped, matching how WeakAuras' own
-- custom-trigger code boxes store just the function itself.

local json = dofile("json.lua")

assert(arg[1], "usage: sync.lua <aura-dir> | sync.lua <table-data.json> <path>=<file>[#<marker>] [...]")

local function readFile(path)
  local f = assert(io.open(path, "rb"), "cannot open " .. path)
  local content = f:read("*a")
  f:close()
  return content
end

local function joinPath(dir, file)
  return (dir:gsub("/+$", "")) .. "/" .. file
end

local function getPath(t, pathStr)
  local cur = t
  for seg in pathStr:gmatch("[^.]+") do
    local key = tonumber(seg) or seg
    if type(cur) ~= "table" then return nil end
    cur = cur[key]
  end
  return cur
end

local function splitLines(content)
  local lines = {}
  for line in (content .. "\n"):gmatch("(.-)\n") do
    lines[#lines + 1] = line
  end
  return lines
end

local function extractSection(content, marker)
  local lines = splitLines(content)

  local startIdx
  for i, line in ipairs(lines) do
    if line:match("^%s*(.-)%s*$") == marker then
      startIdx = i
      break
    end
  end
  assert(startIdx, "marker not found: " .. marker)

  local funcStart
  for i = startIdx + 1, #lines do
    if lines[i]:match("^%s*function") then
      funcStart = i
      break
    end
  end
  assert(funcStart, "no function found after marker: " .. marker)

  local sectionEnd = #lines
  for i = funcStart + 1, #lines do
    if lines[i]:match("^%-%- Trigger %d+$") then
      sectionEnd = i - 1
      break
    end
  end
  while sectionEnd > funcStart and lines[sectionEnd]:match("^%s*$") do
    sectionEnd = sectionEnd - 1
  end

  return table.concat(lines, "\n", funcStart, sectionEnd)
end

local function countOccurrences(haystack, needle)
  local count, from = 0, 1
  while true do
    local s = haystack:find(needle, from, true)
    if not s then break end
    count = count + 1
    from = s + #needle
  end
  return count
end

local function resolveNewValue(mapping)
  local content = readFile(mapping.file)
  return mapping.marker and extractSection(content, mapping.marker) or content
end

-- Figure out which mode we're in: a single argument that isn't itself a
-- "path=file" spec is an aura directory to read a manifest from; anything
-- else is the ad hoc <table-data.json> <path>=<file>[#<marker>] form.
local jsonPath, mappings

if #arg == 1 and not arg[1]:match("=") then
  local auraDir = arg[1]
  local manifestPath = joinPath(auraDir, "sync.json")
  local manifest = json.parse(readFile(manifestPath))
  assert(manifest.json, manifestPath .. ": missing \"json\" key")
  assert(manifest.mappings and #manifest.mappings > 0, manifestPath .. ": missing/empty \"mappings\"")

  jsonPath = joinPath(auraDir, manifest.json)
  mappings = {}
  for _, m in ipairs(manifest.mappings) do
    assert(m.path and m.file, manifestPath .. ": each mapping needs \"path\" and \"file\"")
    mappings[#mappings + 1] = { path = m.path, file = joinPath(auraDir, m.file), marker = m.marker }
  end
else
  jsonPath = arg[1]
  assert(arg[2], "usage: sync.lua <aura-dir> | sync.lua <table-data.json> <path>=<file>[#<marker>] [...]")
  mappings = {}
  for i = 2, #arg do
    local spec = arg[i]
    local path, rest = spec:match("^(.-)=(.*)$")
    assert(path, "malformed mapping (expected path=file[#marker]): " .. spec)
    local filePath, marker = rest:match("^(.-)#(.*)$")
    mappings[#mappings + 1] = { path = path, file = filePath or rest, marker = marker }
  end
end

local raw = readFile(jsonPath)
local data = json.parse(raw)

for _, mapping in ipairs(mappings) do
  local oldValue = getPath(data, mapping.path)
  assert(type(oldValue) == "string", "path has no string value in JSON: " .. mapping.path)

  local newValue = resolveNewValue(mapping)

  local oldEscaped = json.encodeString(oldValue)
  local newEscaped = json.encodeString(newValue)

  local occurrences = countOccurrences(raw, oldEscaped)
  assert(occurrences == 1,
    ("expected exactly 1 occurrence of %s's current value, found %d"):format(mapping.path, occurrences))

  local s = raw:find(oldEscaped, 1, true)
  raw = raw:sub(1, s - 1) .. newEscaped .. raw:sub(s + #oldEscaped)

  io.stderr:write(("Synced %s <- %s%s\n"):format(
    mapping.path, mapping.file, mapping.marker and ("#" .. mapping.marker) or ""))
end

local outFile = assert(io.open(jsonPath, "w"))
outFile:write(raw)
outFile:close()

-- Sanity check: the file we just wrote must still parse, and every path we
-- touched must now read back exactly what we wrote.
local verify = json.parse(raw)
for _, mapping in ipairs(mappings) do
  local expected = resolveNewValue(mapping)
  assert(getPath(verify, mapping.path) == expected, "post-write verification failed for " .. mapping.path)
end

io.stderr:write("Wrote " .. jsonPath .. "\n")

local encodeCmd = 'luajit encode.lua "' .. jsonPath .. '"'
io.stderr:write("Running: " .. encodeCmd .. "\n")
local ok = os.execute(encodeCmd)
if not ok then
  io.stderr:write("encode.lua failed - import string was not regenerated\n")
  os.exit(1)
end
