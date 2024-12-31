local http_helper = require "gametabler_web.utils.http_helper"
local cjson = require("cjson")

local M = {}

function M.enqueue()
    if not http_helper.ensure_http_method("POST") then
        return
    end

    local body_json = http_helper.get_body_data()
    local body = cjson.decode(body_json)

    for k, _ in pairs(ngx.shared.queues:get_keys()) do
        print("k = " .. k)
    end
    local queue = ngx.shared.queues:get(body.queueId)
    if queue == nil then
        ngx.status = ngx.HTTP_NOT_FOUND
        http_helper.respond_json({ message = "queue not found" })
        return
    end

    http_helper.respond_json(body)
end

return M
