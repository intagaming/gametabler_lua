local M = {}

function M.get(queueId)
    local queues = ngx.shared.queues
    return queues:get(queueId)
end

function M.add(queue)
    local queues = ngx.shared.queues
    queues:set(queue.id, queue)
end

function M.delete(queueId)
    local queues = ngx.shared.queues
    queues:delete(queueId)
end

return M
