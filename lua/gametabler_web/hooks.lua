local queues_store = require("gametabler_web.store.queues")

local M = {}

local function _preload_modules()
    require("cjson")
end

--- This function runs when the server starts up.
function M.on_start()
    _preload_modules()
    queues_store:init()
end

return M
