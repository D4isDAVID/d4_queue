local HARDCAP = 'hardcap'
local stopping = ('Stopping %s'):format(HARDCAP)
local preventing = ('Preventing %s from starting'):format(HARDCAP)

---@param resource string
AddEventHandler('onResourceStarting', function(resource)
    if resource ~= HARDCAP or not Convars.disableHardcap() then return end

    print(preventing)
    CancelEvent()
end)

if GetResourceState(HARDCAP):find('start') and Convars.disableHardcap() then
    print(stopping)
    StopResource(HARDCAP)
end
