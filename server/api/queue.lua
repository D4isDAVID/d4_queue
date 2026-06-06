API.queue = {}

local SECOND <const> = 1000
local waitThreadRunning = false

---@class PlayerQueueData
---@field player string
---@field name string
---@field deferrals Deferrals
---@field position integer
---@field waitingSeconds integer
---@field points integer

---@type table<integer, PlayerQueueData>
local positionToData = {}
local queueSize = 0

---@class MoveInternalOptions
---@field from integer
---@field by integer

---@param options MoveInternalOptions
local function move(options)
    local moveBy = options.by

    if moveBy == 0 then
        return
    end

    local fromPosition = options.from

    local step = moveBy < 0 and 1 or -1
    local from = step < 0 and fromPosition or queueSize
    local to = step < 0 and queueSize or fromPosition

    for i = from, to, step do
        local data = positionToData[i]
        positionToData[i] = nil

        data.position += moveBy
        positionToData[data.position] = data
    end
end

---@param player unknown
---@param deferrals Deferrals
function API.queue.add(player, deferrals)
    player = tostring(player)

    local points = API.points.calculate(player)
    local position = queueSize + 1

    for i = queueSize, 1, -1 do
        local data = positionToData[i]

        if data.points >= points then
            break
        end

        position = data.position
    end

    move({
        from = position,
        by = 1,
    })
    queueSize += 1

    local data = {
        player = player,
        name = GetPlayerName(player),
        deferrals = deferrals,
        position = position,
        waitingSeconds = 0,
        points = points,
    }

    positionToData[position] = data

    print(('%s has joined the queue with %d points'):format(data.name, points))

    if waitThreadRunning then
        return
    end

    waitThreadRunning = true
    CreateThread(function()
        print('Queue thread has started')

        while API.queue.wait() do
            Wait(SECOND)
        end

        waitThreadRunning = false

        print('Queue thread has ended')
    end)
end

---@class RemoveInternalOptions
---@field from integer
---@field count integer?
---@field after fun(data: PlayerQueueData)?

---@param options RemoveInternalOptions
local function remove(options)
    local count = options.count or 1

    if count == 0 then
        return
    end

    local from = options.from
    local to = math.min(from + count - 1, queueSize)
    local after = options.after

    for i = from, to do
        local data = positionToData[i]
        positionToData[i] = nil
        data.deferrals.done()

        if after ~= nil then
            after(data)
        end
    end

    move({
        from = from + count,
        by = -count,
    })

    queueSize -= count
end

---@return boolean waiting
function API.queue.wait()
    if queueSize == 0 then
        return false
    end

    local message = Convars.deferralMessage()
    local waitingEmoji = Utils.getWaitingEmoji()
    local points = Convars.priorityPointsPerSecond()

    local emptySlots = Utils.getEmptyPlayerSlots()
    if emptySlots > 0 then
        remove({
            from = 1,
            count = emptySlots,
            after = function(data)
                print(('%s has passed the queue'):format(data.name))
            end,
        })
    end

    local disconnected = {}

    for i = 1, queueSize do
        local data = positionToData[i]

        if DoesPlayerExist(data.player) then
            local formatted = Utils.replaceParams(message, {
                queue_position = data.position,
                queue_size = queueSize,
                waiting_time = Utils.createDisplayTime(data.waitingSeconds),
                waiting_emoji = waitingEmoji,
                points = data.points,
            })

            data.deferrals.update(formatted)
            data.waitingSeconds += 1
            data.points += points
        else
            disconnected[#disconnected + 1] = data.position
        end
    end

    for i = 1, #disconnected do
        remove({
            from = disconnected[i],
            after = function(data)
                print(('%s has left the queue'):format(data.name))
            end,
        })
    end

    return queueSize > 0
end
