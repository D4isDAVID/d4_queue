API.queue = {}

local SECOND = 1000
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
---@field position integer
---@field moveBy integer

---@param options MoveInternalOptions
local function move(options)
    for i = options.position, queueSize do
        local data = positionToData[i]
        positionToData[i] = nil

        data.position += options.moveBy
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
        position = position,
        moveBy = 1,
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
---@field startPosition integer
---@field removeCount integer?
---@field afterRemoving fun(data: PlayerQueueData)?

---@param options RemoveInternalOptions
local function remove(options)
    local startPosition = options.startPosition
    local removeCount = options.removeCount or 1
    local afterRemoving = options.afterRemoving

    local endPosition = math.min(startPosition + removeCount - 1, queueSize)

    for i = startPosition, endPosition do
        local data = positionToData[i]
        positionToData[i] = nil
        data.deferrals.done()

        if afterRemoving ~= nil then
            afterRemoving(data)
        end
    end

    move({
        position = startPosition + removeCount,
        moveBy = -removeCount,
    })

    queueSize -= removeCount
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
            startPosition = 1,
            removeCount = emptySlots,
            afterRemoving = function(data)
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
            startPosition = disconnected[i],
            afterRemoving = function(data)
                print(('%s has left the queue'):format(data.name))
            end,
        })
    end

    return queueSize > 0
end
