---@class Queue
---@field config QueueConfig
local Queue = {}
Queue.__index = Queue

---@param o table|nil
function Queue:new(o)
    o = o or {}
    return setmetatable(o, Queue)
end

function Queue:enqueue(player)
    -- TODO:
end

function Queue:dequeue(player)
    -- TODO:
end

function Queue:is_in_queue(player)
    -- TODO:
end

return Queue
