local Player = require("gametabler.Player")
local Party = require("gametabler.Party")

local M = {}

function M.count_participants(participants)
    local count = 0
    for k, v in pairs(participants) do
        if getmetatable(v) == Player then
            count = count + 1
            goto continue
        end
        if getmetatable(v) == Party then
            count = count + #v.players
            goto continue
        end
        error("unknown participant at index " .. k)
        ::continue::
    end
    return count
end

---@generic T: table
---@param t T
---@return T
function M.copy_table(t)
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
    return copy
end

return M
