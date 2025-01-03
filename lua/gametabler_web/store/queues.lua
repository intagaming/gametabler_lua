local cjson         = require("cjson")
local NgxQueue      = require("gametabler_web.utils.NgxQueue")
local QueueConfig   = require("gametabler.QueueConfig")
local QueueCriteria = require("gametabler.QueueCriteria")
local Queue         = require("gametabler.Queue")

local M             = {
    ---@type NgxQueue[]
    queues = {}
}

-- Function to validate the queue configuration
local function validate_queue_config(queue_config)
    if type(queue_config) ~= "table" then
        return false, "Queue configuration must be a table"
    end

    if queue_config.criteria == nil then
        return false, "Missing required field: criteria"
    end

    if type(queue_config.criteria) ~= "table" then
        return false, "Criteria must be a table"
    end

    if queue_config.criteria.playersPerTeam == nil or type(queue_config.criteria.playersPerTeam) ~= "number" then
        return false, "playersPerTeam must be a number"
    end

    if queue_config.criteria.numberOfTeams == nil or type(queue_config.criteria.numberOfTeams) ~= "number" then
        return false, "numberOfTeams must be a number"
    end

    return true
end

function M:init()
    local queues_config_file, err = io.open("/app_config/queues.json") -- TODO: move path to config
    if queues_config_file == nil then
        error(err)
    end
    local queues_config_json = queues_config_file:read("*a")
    queues_config_file:close()
    local queues_config = cjson.decode(queues_config_json)

    for queue_name, queue_config in pairs(queues_config) do
        print("queue_name = " .. queue_name)
        
        -- Validate the queue configuration
        local is_valid, err_msg = validate_queue_config(queue_config)
        if not is_valid then
            error("Invalid configuration for queue '" .. queue_name .. "': " .. err_msg)
        end

        local queue = NgxQueue:new {
            queue_name = queue_name,
            queue = Queue:new {
                config = QueueConfig:new {
                    criteria = QueueCriteria:new {
                        players_per_team = queue_config.criteria.playersPerTeam,
                        number_of_teams = queue_config.criteria.numberOfTeams
                    }
                }
            },
        }
        self.queues[queue_name] = queue
    end

    ngx.log(ngx.INFO, "Queues initialized.")
end

return M