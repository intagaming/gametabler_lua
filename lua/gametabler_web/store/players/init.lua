local cjson = require("cjson")

local M = {}

---@param player_id string
---@param info PlayerInfo
function M.set_player_info(player_id, info)
    local players = ngx.shared.players
    ngx.log(ngx.DEBUG, 'set_player_info player_id=' .. player_id .. ' info=' .. cjson.encode(info))
    players:set(player_id, cjson.encode(info))
end

---@param player_id string
---@return PlayerInfo|nil
function M.get_player_info(player_id)
    local players = ngx.shared.players
    local info = players:get(player_id)
    if info == nil then
        return nil
    end
    return cjson.decode(info)
end

return M
