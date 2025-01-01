local http_helper   = require("gametabler_web.utils.http_helper")
local cjson         = require("cjson")
local queues_store  = require("gametabler_web.store.queues")
local Player        = require("gametabler.Player")
local players_store = require("gametabler_web.store.players")

local M = {}

function M.enqueue()
    if not http_helper.ensure_http_method("POST") then
        return
    end

    local body_data = ngx.req.get_body_data()
    if body_data == nil then
        ngx.status = ngx.HTTP_BAD_REQUEST
        http_helper.respond_json({ message = "Bad request data" })
        return
    end

    local ok, body = pcall(cjson.decode, body_data)
    if not ok then
        ngx.status = ngx.HTTP_BAD_REQUEST
        http_helper.respond_json({ message = "Bad request data" })
        return
    end

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

function M.player_info()
    if not http_helper.ensure_http_method("GET") then
        return
    end

    local params = ngx.req.get_uri_args()

    if params.playerId == nil or params.playerId == "" or string.match(params.playerId, "[^A-Za-z0-9]") then
        ngx.status = ngx.HTTP_BAD_REQUEST
        http_helper.respond_json({ message = "Bad request data" })
        return
    end

    local info = players_store.get_player_info(params.playerId)
    local current_queue_name = cjson.null
    if info ~= nil then
        current_queue_name = info.current_queue_name or cjson.null
    end

    http_helper.respond_json({
        id = params.playerId,
        currentQueueName = current_queue_name,
    })
end

return M