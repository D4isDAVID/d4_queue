API.queue = {}

---@class PlayerQueueData
---@field player unknown
---@field deferrals Deferrals
---@field position integer
---@field waitingSeconds integer

---@type table<integer, PlayerQueueData>
local positionToData = {}
---@type table<unknown, PlayerQueueData>
local playerToData = {}
local queueSize = 0

local waitingEmojiIndex = 1

---@param player unknown
---@param deferrals Deferrals
function API.queue.add(player, deferrals)
    queueSize += 1
    local position = queueSize

    local data = {
        player = player,
        deferrals = deferrals,
        position = position,
        waitingSeconds = 0,
    }
    positionToData[position] = data
    playerToData[player] = data

    print(('%s has joined the queue'):format(GetPlayerName(player)))

    API.thread.start()
end

---@param player unknown
function API.queue.remove(player)
    local data = playerToData[player]
    if data == nil then
        return
    end

    for i = data.position + 1, queueSize do
        local otherData = positionToData[i]
        positionToData[i] = nil
        otherData.position -= 1
        positionToData[otherData.position] = otherData
    end

    playerToData[data.player] = nil
    queueSize -= 1

    print(('%s has left the queue'):format(GetPlayerName(player)))
end

---@param data PlayerQueueData
---@param message string
---@param waitingEmoji string
local function waitInternal(data, message, waitingEmoji)
    message = Utils.replaceParams(message, {
        queue_position = data.position,
        queue_size = queueSize,
        waiting_time = Utils.createDisplayTime(data.waitingSeconds),
        waiting_emoji = waitingEmoji,
    })

    data.deferrals.update(message)
    data.waitingSeconds += 1
end

---@return boolean waiting
function API.queue.wait()
    local first = positionToData[1]
    if first == nil then
        return false
    end

    local message = Convars.deferralMessage()
    local waitingEmojiTable = Convars.waitingEmoji()
    waitingEmojiIndex += 1
    if waitingEmojiIndex > #waitingEmojiTable then
        waitingEmojiIndex = 1
    end
    local waitingEmoji = waitingEmojiTable[waitingEmojiIndex]

    local emptySlots = Utils.getEmptyPlayerSlots()
    for i = 1, emptySlots do
        local data = positionToData[i]
        if data ~= nil then
            positionToData[i].deferrals.done()
            playerToData[data.player] = nil
        end
    end

    for i = emptySlots + 1, queueSize do
        local data = positionToData[i]
        positionToData[i] = nil
        data.position -= emptySlots

        if DoesPlayerExist(data.player) then
            positionToData[data.position] = data
            waitInternal(data, message, waitingEmoji)
        else
            playerToData[data.player] = nil
            queueSize -= 1
        end
    end

    queueSize -= emptySlots

    return queueSize == 0
end
