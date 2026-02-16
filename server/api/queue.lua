API.queue = {}

local SECOND = 1000
local waitThreadRunning = false

---@class PlayerQueueData
---@field player string
---@field name string
---@field deferrals Deferrals
---@field position integer
---@field waitingSeconds integer

---@type table<integer, PlayerQueueData>
local positionToData = {}
local queueSize = 0

---@param player unknown
---@param deferrals Deferrals
function API.queue.add(player, deferrals)
    player = tostring(player)

    queueSize += 1
    local position = queueSize

    local data = {
        player = player,
        name = GetPlayerName(player),
        deferrals = deferrals,
        position = position,
        waitingSeconds = 0,
    }

    positionToData[position] = data

    print(('%s has joined the queue'):format(data.name))

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

    for i = startPosition + removeCount, queueSize do
        local data = positionToData[i]
        positionToData[i] = nil

        data.position -= removeCount
        positionToData[data.position] = data
    end

    queueSize -= removeCount
end

---@return boolean waiting
function API.queue.wait()
    if queueSize == 0 then
        return false
    end

    local message = Convars.deferralMessage()
    local waitingEmoji = Utils.getWaitingEmoji()

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
            })

            data.deferrals.update(formatted)
            data.waitingSeconds += 1
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
