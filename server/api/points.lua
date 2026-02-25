API.points = {}

---@alias PointsCalculator fun(player: unknown): integer

---@type PointsCalculator[]
local calculators = {}

---@param func PointsCalculator
function API.points.addCalculator(func)
    calculators[#calculators + 1] = func
end

---@param player unknown
---@return integer points
function API.points.calculate(player)
    local points = 0
    local permissions = Convars.startingPriorityPoints()

    for i = 1, #calculators do
        points += calculators[i](player)
    end

    for ace, permPoints in pairs(permissions) do
        if IsPlayerAceAllowed(player, ace) then
            points += permPoints
        end
    end

    return points
end

exports('addPointsCalculator', API.points.addCalculator)
