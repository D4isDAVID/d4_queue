---@return integer
function Utils.getEmptyPlayerSlots()
    return Convars.maxClients() - GetNumPlayerIndices()
end
