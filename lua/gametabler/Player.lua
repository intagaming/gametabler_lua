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

function Player.__eq(a, b)
    return a.id == b.id
end

return Player
