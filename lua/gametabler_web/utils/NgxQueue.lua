local Queue         = require("gametabler.Queue")
local players_store = require("gametabler_web.store.players")
local PlayerInfo    = require("gametabler_web.store.players.PlayerInfo")
local Player        = require("gametabler.Player")

---TODO: test this
---@class NgxQueue: Queue
---@field queue_name string
local NgxQueue      = Queue:new()
NgxQueue.__index    = NgxQueue

---@param o table|nil
---@return NgxQueue
function NgxQueue:new(o)
    o = Queue.new(self, o)
    return setmetatable(o, NgxQueue) --[[@as NgxQueue]]
end

---@param player Player
---@return { found: boolean, teams: Player[][] }
function NgxQueue:enqueue(player)
    local queues = ngx.shared.queues
    ---@type Player[]
    self.enqueued_players = {}
    for existing_player_id in string.gmatch(queues:get(self.queue_name) or "", "([^,]+)") do
        self.enqueued_players[#self.enqueued_players + 1] = Player:new(existing_player_id)
    end

    local result = Queue.enqueue(self, player)
    if result.found then
        for _, team in pairs(result.teams) do
            for _, team_player in pairs(team) do
                players_store.set_player_info(team_player.id,
                    PlayerInfo:new { id = team_player.id, current_queue_name = nil })
            end
        end
    else
        players_store.set_player_info(player.id,
            PlayerInfo:new { id = player.id, current_queue_name = self.queue_name })
    end

    local enqueued_player_ids = {}
    for _, v in pairs(self.enqueued_players) do
        enqueued_player_ids[#enqueued_player_ids + 1] = v.id
    end
    queues:set(self.queue_name, table.concat(enqueued_player_ids, ","))
    print("queues:set " .. self.queue_name .. " " .. table.concat(enqueued_player_ids, ","))
    return result
end

return NgxQueue