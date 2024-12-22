local M = {}

function M.ensure_http_method(method)
    if ngx.req.get_method() == method then
        return true
    end
    ngx.status = 405
    return false
end

function M.get_body_data()
    ngx.req.read_body()
    return ngx.req.get_body_data()
end

return M