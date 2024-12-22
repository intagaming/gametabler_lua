local http_helper = require "gametabler_web.utils.http_helper"
local M = {}

function M.enqueue()
    if not http_helper.ensure_http_method("POST") then
        return
    end

    local body = http_helper.get_body_data()
    ngx.say(body)
end

return M
