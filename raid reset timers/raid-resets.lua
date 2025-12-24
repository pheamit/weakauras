local aura_env -- to get rid of the warning
-- Export string: 
-- Do not remove this comment, it is part of this aura: Raids
function()
    aura_env.getLockedRaidInfo()
    return aura_env.getText()
end

-- Do not remove this comment, it is part of this aura: Timers
function()
    local s3  = aura_env.seconds_until_next(aura_env.ANCHOR_3D_7D, aura_env.P3D)
    local s5  = aura_env.seconds_until_next(aura_env.ANCHOR_ONY,   aura_env.P5D)
    local s7  = aura_env.seconds_until_next(aura_env.ANCHOR_3D_7D, aura_env.P7D)
    
    local zgaq = aura_env.green(aura_env.fmt_dhm(s3))
    local ony  = aura_env.green(aura_env.fmt_dhm(s5))
    local wkly = aura_env.green(aura_env.fmt_dhm(s7))
    
    return table.concat({
            wkly,  -- Molten Core
            wkly,  -- Blackwing Lair
            wkly,  -- Ahn'Qiraj (AQ40)
            wkly,  -- Naxxramas
            ony,   -- Onyxia's Lair (5d)
            zgaq,  -- Zul'Gurub (3d)
            zgaq,  -- Ruins of Ahn'Qiraj (AQ20, 3d)
    }, "\n")
end

-- Do not remove this comment, it is part of this aura: Raids
aura_env.raids = {
    ["Molten Core"] = {
        short = "MC",
        locked = false,
    },
    ["Blackwing Lair"] = {
        short = "BWL",
        locked = false,
    },
    ["Ahn'Qiraj"] = {
        short = "AQ40",
        locked = false,
    },
    ["Naxxramas"] = {
        short = "Naxx",
        locked = false,
    },
    ["Onyxia's Lair"] = {
        short = "Onyxia",
        locked = false,
    },
    ["Zul'Gurub"] = {
        short = "ZG",
        locked = false,
    },
    ["Ruins of Ahn'Qiraj"] = {
        short = "AQ20",
        locked = false,
    },
}

aura_env.raidOrder = {
    "Molten Core",
    "Blackwing Lair",
    "Ahn'Qiraj",
    "Naxxramas",
    "Onyxia's Lair",
    "Ruins of Ahn'Qiraj",
    "Zul'Gurub",
}

function aura_env.gold(s) return GOLD_FONT_COLOR:WrapTextInColorCode(s) end
function aura_env.red(s) return RED_FONT_COLOR:WrapTextInColorCode(s) end
function aura_env.gray(s) return GRAY_FONT_COLOR:WrapTextInColorCode(s) end

function aura_env.line(name)
    return (aura_env.raids[name].locked and aura_env.red or aura_env.gold)(aura_env.raids[name].short .. aura_env.gray(" resets in"))
end

function aura_env.getLockedRaidInfo()
    local numInstances = GetNumSavedInstances()
    if numInstances > 0 then
        for i = 1, numInstances do
            local name, _, _, _, locked, _, _, isRaid = GetSavedInstanceInfo(i)
            if locked and isRaid then
                aura_env.raids[name].locked = true
            end
        end
    else 
        for raid in pairs(aura_env.raids) do
            aura_env.raids[raid].locked = false
        end
    end
end

function aura_env.getText()
    local text = {}
    
    for _, name in ipairs(aura_env.raidOrder) do
        local raid = aura_env.raids[name]
        if raid then
            table.insert(text, aura_env.line(name))
        end
    end
    return table.concat(text, "\n")
end

-- Do not remove this comment, it is part of this aura: Timers
-- detect today's server reset time-of-day (handles DST automatically)
local nd   = GetServerTime() + C_DateAndTime.GetSecondsUntilDailyReset()
local dnd  = date("*t", nd)  -- server-local components
local H, M = dnd.hour, dnd.min

-- rebuild anchors with the detected reset hour/minute
aura_env.ANCHOR_3D_7D = time{year=2025, month=8, day=27, hour=H, min=M, sec=0}
aura_env.ANCHOR_ONY   = time{year=2025, month=8, day=25, hour=H, min=M, sec=0}


-- periods
aura_env.P3D = 3*24*60*60
aura_env.P5D = 5*24*60*60
aura_env.P7D = 7*24*60*60

-- helpers
function aura_env.seconds_until_next(anchor, period)
    local now = GetServerTime()
    local delta = (now - anchor) % period
    return (period - delta) % period
end

function aura_env.fmt_dhm(sec)
    if sec < 0 then sec = 0 end
    local d = math.floor(sec/86400); sec = sec % 86400
    local h = math.floor(sec/3600);  sec = sec % 3600
    local m = math.ceil(sec/60)
    return string.format("%2dd-%02dh-%02dm", d, h, m)
end

function aura_env.green(s) return GREEN_FONT_COLOR:WrapTextInColorCode(s) end

