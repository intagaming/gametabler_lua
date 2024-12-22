---@class QueueConfig
---@field criteria QueueCriteria
local QueueConfig = {}
QueueConfig.__index = QueueConfig

---@param o table|nil
function QueueConfig:new(o)
    o = o or {}
    return setmetatable(o, QueueConfig)
end

return QueueConfig
