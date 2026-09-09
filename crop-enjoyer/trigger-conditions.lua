---@diagnostic disable:unreachable-code
-- Trigger 1
-- PLAYER_MOUNT_DISPLAY_CHANGED
---@diagnostic disable-next-line:miss-name
function()
    if not aura_env.trinkets then
        if aura_env.InitState then
            aura_env:InitState()
        end
        if not aura_env.trinkets then
            return IsMounted()
        end
    end

    local mounted = IsMounted()
    if UnitOnTaxi("player") then
        return mounted
    end

    aura_env.trinkets:Enforce()
    return mounted
end

-- Trigger 2
-- TOGGLE_AURA,TOGGLE_PVP,TOGGLE_PROTECTION
---@diagnostic disable-next-line:miss-name
function(event, ...)
    if event == "TOGGLE_AURA" then
        aura_env.trinkets:Toggle()
    elseif event == "TOGGLE_PROTECTION" then
        aura_env.trinkets:ProtectedMode()
    end
end
