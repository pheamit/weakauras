function(exp)
    local sec = exp - GetTime()
    local days, _ = math.modf(sec / 86400)
    local hours, _ = math.modf(sec / 3600)
    local min, _ = math.modf(sec / 60)
    if days > 0 then
        hours = hours - days * 24
        min = min - hours * 60 - days * 1440
        sec = sec - min * 60 - hours * 3600 - days * 86400
        return string.format("%dd:%dh:%dm:%ds", days, hours, min, sec)
    elseif hours > 0 then
        min = min - hours * 60
        sec = sec - min * 60 - hours * 3600
        return string.format("%dh:%dm:%ds", hours, min, sec)
    elseif min > 0 then
        sec = sec - min * 60
        return string.format("%dm:%ds", min, sec)
    elseif sec > 0 then
        return string.format("%ds", sec)        
    end
    return "Ready!"
end

