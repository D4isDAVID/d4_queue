local TICK = 0

---@class Deferrals
---@field defer fun()
---@field update fun(message: string)
---@field done fun(failureReason?: string)

---@param deferrals Deferrals
AddEventHandler('playerConnecting', function(_, _, deferrals)
    local source = source

    deferrals.defer()
    Wait(TICK)

    if Utils.getEmptyPlayerSlots() > 0 then
        deferrals.done()
        return
    end

    API.queue.add(source, deferrals)
end)
