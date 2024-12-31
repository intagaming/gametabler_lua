local Queue = require("gametabler.Queue")

---@class NgxQueue: Queue
---@field queue_name string
local NgxQueue = Queue:new()

function NgxQueue:enqueue(player)
    local queues = ngx.shared.queues
    self.enqueued_players = {}
    for _, v in string.gmatch(queues:get(self.queue_name), ",") do
        self.enqueued_players[#self.enqueued_players + 1] = v
    end
    local result = Queue.enqueue(self, player)
    queues:set(self.queue_name, table.concat(self.enqueued_players, ","))
    return result
end

return NgxQueue
