---@class Queue
---@field config QueueConfig
---@field enqueued_players Player[]
local Queue = {}
Queue.__index = Queue

---@param o table|nil
function Queue:new(o)
    o = o or {}
    o.enqueued_players = o.enqueued_players or {}
    return setmetatable(o, Queue)
end

function Queue:enqueue(player)
    if self:is_in_queue(player) then
        error("already in queue")
    end

    local result = { found = false, teams = {} }
    if #self.enqueued_players + 1 < self.config.criteria:total_players() then
        table.insert(self.enqueued_players, player)
    else
        result.found = true
        local participants = { table.unpack(self.enqueued_players) }
        table.insert(participants, player)
        result.teams = self.config.criteria:distribute(participants)
        self.enqueued_players = {}
    end

    return result
end

function Queue:dequeue(player)
    if not self:is_in_queue(player) then
        error("not in queue")
    end

    for k, v in pairs(self.enqueued_players) do
        if v == player then
            table.remove(self.enqueued_players, k)
            return true
        end
    end
end

function Queue:is_in_queue(player)
    for _, v in pairs(self.enqueued_players) do
        if v == player then
            return true
        end
    end
    return false
end

return Queue
