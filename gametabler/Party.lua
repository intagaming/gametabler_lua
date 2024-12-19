---@class Party
---@field players Player[]
local Party = {}
Party.__index = Party

function Party:new(o)
    o = o or {}
    o.players = o.players or {}
    return setmetatable(o, Party)
end

return Party
