local aura_env = {} -- error workaround
-- Init
aura_env.streaks = {
    [3] = "3 consecutive dispels!",
    [5] = "5 dispels in a row!",
    [10] = "10 dispels, what?!",
    [15] = "15 dispels, RAMPING!",
    [20] = "20 dispels, is anyone here?",
    [25] = "25 dispels, stop it!",
    [30] = "30 dispels, you're making me dizzy!",
}
aura_env.timer = 5
aura_env.lastDispel = 0
aura_env.streak = 0

--OnShow
local timeStamp = time()
local diff = timeStamp - aura_env.lastDispel
print("Diff: " .. diff)
if diff <= aura_env.timer then
    if aura_env.streak == 0 then
        aura_env.streak = 1
    else
        aura_env.streak = aura_env.streak + 1
    end
else
    aura_env.streak = 1
end

if aura_env.streaks[aura_env.streak] then
    print(aura_env.streaks[aura_env.streak])
end

aura_env.lastDispel = timeStamp
