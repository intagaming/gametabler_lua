local http_helper  = require("gametabler_web.utils.http_helper")
local cjson        = require("cjson")
local queues_store = require("gametabler_web.store.queues")
local Player       = require("gametabler.Player")

local M            = {}

function M.enqueue()
    if not http_helper.ensure_http_method("POST") then
        return
    end

    local body_json = http_helper.get_body_data()
    local body = cjson.decode(body_json)
    -- TODO: verify body

    local queue = queues_store.queues[body.queueId]
    if queue == nil then
        ngx.status = ngx.HTTP_NOT_FOUND
        http_helper.respond_json({ message = "queue not found" })
        return
    end

    local ok, result = pcall(function() return queue:enqueue(Player:new(body.playerId)) end)
    if not ok then
        ngx.status = ngx.HTTP_BAD_REQUEST
        http_helper.respond_json({ message = result })
        return
    end

    local teams_string = {}
    for team_number, team in ipairs(result.teams) do
        local team_string = {}
        for k, player in ipairs(team) do
            team_string[k] = player.id
        end
        teams_string[team_number] = team_string
    end

    http_helper.respond_json({
        found = result.found,
        teams = teams_string,
    })
end

return M
