local cjson = require("cjson")
local NgxQueue = require("gametabler_web.utils.NgxQueue")
local QueueConfig = require("gametabler.QueueConfig")
local QueueCriteria = require("gametabler.QueueCriteria")

local M = {
    ---@type NgxQueue[]
    queues = {}
}

function M:init()
    local queues_config_file, err = io.open("/app_config/queues.json") -- TODO: move path to config
    if queues_config_file == nil then
        error(err)
    end
    local queues_config_json = queues_config_file:read("*a")
    queues_config_file:close()
    local queues_config = cjson.decode(queues_config_json)

    for queue_name, queue_config in pairs(queues_config) do
        local queue = NgxQueue:new {
            config = QueueConfig:new {
                criteria = QueueCriteria:new {
                    players_per_team = queue_config.criteria.playersPerTeam,
                    number_of_teams = queue_config.criteria.numberOfTeams
                }
            }
        }
        self.queues[queue_name] = queue
    end

    ngx.log(ngx.INFO, "Queues initialized.")
end

return M
