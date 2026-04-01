---@generic T : table
---@param name string
---@param default T
---@return T
local function getConvarTable(name, default)
    local raw = GetConvar(name, json.encode(default))
    local tbl = json.decode(raw)

    if type(tbl) ~= 'table' then
        return default
    end

    return tbl
end

---@generic T
---@param name string
---@param default T
---@param func fun(name: string, default: T): T
---@return fun(): T
local function createConvarHandler(name, default, func)
    local value = func(name, default)

    AddConvarChangeListener(name, function()
        value = func(name, default)
    end)

    return function()
        return value
    end
end

Convars = {
    waitingEmoji = createConvarHandler(
        'd4_queue:waitingEmoji',
        { '🕛', '🕒', '🕕', '🕘' } --[[@as string[] ]],
        getConvarTable
    ),
    deferralMessage = createConvarHandler(
        'd4_queue:deferralMessage',
        '🐌 You are {queue_position}/{queue_size} in queue. {waiting_time} {waiting_emoji} ({points} points)',
        GetConvar
    ),
    startingPriorityPoints = createConvarHandler(
        'd4_queue:startingPriorityPoints',
        {} --[[@as table<string, integer>]],
        getConvarTable
    ),
    priorityPointsPerSecond = createConvarHandler(
        'd4_queue:priorityPointsPerSecond',
        1,
        GetConvarInt
    ),
    disableHardcap = createConvarHandler(
        'd4_queue:disableHardcap',
        true,
        GetConvarBool
    ),
    maxClients = createConvarHandler(
        'sv_maxClients',
        30,
        GetConvarInt
    ),
}
