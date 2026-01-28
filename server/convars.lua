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
    ---@return string[]
    waitingEmoji = createConvarHandler(
        'd4_queue_waitingEmoji',
        { '🕛', '🕒', '🕕', '🕘' },
        getConvarTable
    ),
    ---@return string
    deferralMessage = createConvarHandler(
        'd4_queue_deferralMessage',
        '🐌 You are {queue_position}/{queue_size} in queue. ({waiting_time}) {waiting_emoji}',
        GetConvar
    ),
    ---@return boolean
    disableHardcap = createConvarHandler(
        'd4_queue_disableHardcap',
        true,
        GetConvarBool
    ),
    ---@return integer
    maxClients = createConvarHandler(
        'sv_maxClients',
        30,
        -- TODO: GetConvarInt
        function(n, d)
            return GetConvarInt(n, d) - 1
        end
    ),
}
