---@class QueueCriteria
---@field players_per_team number
---@field number_of_teams number
local QueueCriteria = {
    players_per_team = 0,
    number_of_teams = 0,
}
QueueCriteria.__index = QueueCriteria

---@generic T: QueueCriteria
---@param self T
---@param o T|nil
---@return T
function QueueCriteria:new(o)
    o = o or {}
    return setmetatable(o, QueueCriteria)
end

function QueueCriteria:total_players()
    return self.players_per_team * self.number_of_teams
end

function QueueCriteria:id()
    local buf = {}
    for i = 1, self.number_of_teams do
        table.insert(buf, tostring(self.players_per_team))
        if i ~= self.number_of_teams then
            table.insert(buf, "vs")
        end
    end
    return table.concat(buf)
end

return QueueCriteria
