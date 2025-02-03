-- Trigger 1
function(allstates, event, ...)
    if event == "UI_ERROR_MESSAGE" and select(2, ...) == ERR_ALREADY_PICKPOCKETED then
        -- pass
    end
    if event == "NAME_PLATE_UNIT_ADDED" then
        local unitGUID = UnitGUID(select(1, ...))
        -- add this unitGUID to the state table
        if not allstates[unitGUID] then
            allstates[unitGUID] = {
                show = true,
                changed = true,
                unit = unitGUID,
            }
        end
    end
    return true
end

