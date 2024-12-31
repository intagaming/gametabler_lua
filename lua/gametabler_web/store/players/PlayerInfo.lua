---@class PlayerInfo
---@field id string
---@field current_queue_name string|nil
local PlayerInfo = {}
PlayerInfo.__index = PlayerInfo

function PlayerInfo:new(o)
    o = o or {}
    return setmetatable(o, PlayerInfo)
end

return PlayerInfo
