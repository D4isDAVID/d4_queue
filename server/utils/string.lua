---@param waitingSeconds number
function Utils.createDisplayTime(waitingSeconds)
    local minutes = math.floor(waitingSeconds / 60)
    local seconds = waitingSeconds % 60
    return ('%02d:%02d'):format(minutes, seconds)
end

---@param message string
---@param parameters table<string, string | number | function | table>
---@return string
function Utils.replaceParams(message, parameters)
    local result = message

    for key, value in pairs(parameters) do
        result = result:gsub('{' .. key .. '}', value)
    end

    return result
end
