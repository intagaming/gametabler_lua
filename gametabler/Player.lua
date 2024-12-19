---@class Player
---@field id string
local Player = {}
Player.__index = Player

---@param id string
---@param o table|nil
function Player:new(id, o)
    o = o or {}
    o.id = id
    return setmetatable(o, Player)
end

return Player
