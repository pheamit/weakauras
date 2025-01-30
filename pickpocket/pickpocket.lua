function(allstates, event, ...)
    if event == "UI_ERROR_MESSAGE" and select(2, ...) == ERR_ALREADY_PICKPOCKETED then
        print(...)
    end
    if event == "NAME_PLATE_UNIT_ADDED" then
        local unitGUID = UnitGUID(select(1, ...))
        for k, v in pairs(aura_env.region) do
            print(k, v)
        end
    end
    return true
end

