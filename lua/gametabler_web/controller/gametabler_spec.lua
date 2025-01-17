---@diagnostic disable: duplicate-set-field
local cjson = require("cjson")
local gametabler = require("gametabler_web.controller.gametabler")
local queues_store = require("gametabler_web.store.queues")
local players_store = require("gametabler_web.store.players")
local Player = require("gametabler.Player")
local NgxQueue = require("gametabler_web.utils.NgxQueue")

describe("gametabler", function()
    local ngx_mock

    before_each(function()
        ngx_mock = {
            status = 200,
            req = {
                get_method = function() return "POST" end,
                get_body_data = function() return '{"playerId":"player1","queueId":"queue1"}' end,
                get_uri_args = function() return { playerId = "player1" } end,
                read_body = function() end
            },
            say = function(msg) ngx_mock.response = msg end,
            HTTP_BAD_REQUEST = 400,
            HTTP_NOT_FOUND = 404,
            HTTP_METHOD_NOT_ALLOWED = 405,
            HTTP_INTERNAL_SERVER_ERROR = 500,
            log = function(level, message)
                -- Mock log function to do nothing
            end,
        }
        _G.ngx = ngx_mock

        -- Mock queues_store
        local queue1 = NgxQueue:new()
        queue1.enqueue = function(_, _)
            return { found = true, teams = { { Player:new("player1") } } }
        end
        queue1.dequeue = function(_)
            return true
        end
        queues_store.queues = {
            queue1 = queue1,
        }

        -- Mock players_store
        players_store.get_player_info = function() return nil end
    end)

    after_each(function()
        _G.ngx = nil
        queues_store.queues = {}
        players_store.get_player_info = nil
    end)

    describe("enqueue", function()
        it("should return 400 if the request body contains invalid JSON", function()
            ngx_mock.req.get_body_data = function() return 'invalid json' end
            gametabler.enqueue()
            assert.are.equal(400, ngx_mock.status)
            assert.are.same({ message = "Bad request data" }, cjson.decode(ngx_mock.response))
        end)

        it("should return 405 if the request method is not POST", function()
            ngx_mock.req.get_method = function() return "GET" end
            gametabler.enqueue()
            assert.are.equal(405, ngx_mock.status)
            assert.are.same({ message = "Method not allowed" }, cjson.decode(ngx_mock.response))
        end)

        it("should return 400 if playerId or queueId is missing or invalid", function()
            ngx_mock.req.get_body_data = function() return '{"playerId":"","queueId":"queue1"}' end
            gametabler.enqueue()
            assert.are.equal(400, ngx_mock.status)
            assert.are.same({ message = "Bad request data" }, cjson.decode(ngx_mock.response))

            ngx_mock.req.get_body_data = function() return '{"playerId":"player1","queueId":""}' end
            gametabler.enqueue()
            assert.are.equal(400, ngx_mock.status)
            assert.are.same({ message = "Bad request data" }, cjson.decode(ngx_mock.response))

            ngx_mock.req.get_body_data = function() return '{"playerId":"player1@","queueId":"queue1"}' end
            gametabler.enqueue()
            assert.are.equal(400, ngx_mock.status)
            assert.are.same({ message = "Bad request data" }, cjson.decode(ngx_mock.response))

            ngx_mock.req.get_body_data = function() return '{"playerId":"player1","queueId":"queue1@"}' end
            gametabler.enqueue()
            assert.are.equal(400, ngx_mock.status)
            assert.are.same({ message = "Bad request data" }, cjson.decode(ngx_mock.response))
        end)

        it("should return 404 if queue is not found", function()
            queues_store.queues = {}
            gametabler.enqueue()
            assert.are.equal(404, ngx_mock.status)
            assert.are.same({ message = "queue not found" }, cjson.decode(ngx_mock.response))
        end)

        it("should return 500 if enqueue fails", function()
            queues_store.queues = {
                queue1 = {
                    enqueue = function() error("enqueue failed", 0) end
                }
            }
            gametabler.enqueue()
            assert.are.equal(500, ngx_mock.status)
            assert.are.same({ message = "Internal server error." }, cjson.decode(ngx_mock.response))
        end)

        it("should return 200 and teams if enqueue is successful", function()
            queues_store.queues = {
                queue1 = {
                    enqueue = function()
                        return {
                            found = true,
                            teams = { { Player:new("player1") } }
                        }
                    end
                }
            }
            gametabler.enqueue()
            assert.are.equal(200, ngx_mock.status)
            assert.are.same({ found = true, teams = { { "player1" } } }, cjson.decode(ngx_mock.response))
        end)

        -- New test case for nil body data
        it("should return 400 if the request body is nil", function()
            ngx_mock.req.get_body_data = function() return nil end
            gametabler.enqueue()
            assert.are.equal(400, ngx_mock.status)
            assert.are.same({ message = "Bad request data" }, cjson.decode(ngx_mock.response))
        end)
    end)

    describe("player_info", function()
        it("should return 405 if the request method is not GET", function()
            ngx_mock.req.get_method = function() return "POST" end
            gametabler.player_info()
            assert.are.equal(405, ngx_mock.status)
            assert.are.same({ message = "Method not allowed" }, cjson.decode(ngx_mock.response))
        end)

        it("should return 400 if playerId is missing or invalid", function()
            ngx_mock.req.get_method = function() return "GET" end
            ngx_mock.req.get_uri_args = function() return { playerId = "" } end
            gametabler.player_info()
            assert.are.equal(400, ngx_mock.status)
            assert.are.same({ message = "Bad request data" }, cjson.decode(ngx_mock.response))
        end)

        it("should return 200 and player info if player is found", function()
            ngx_mock.req.get_method = function() return "GET" end
            players_store.get_player_info = function() return { current_queue_name = "queue1" } end
            gametabler.player_info()
            assert.are.equal(200, ngx_mock.status)
            assert.are.same({ id = "player1", currentQueueName = "queue1" }, cjson.decode(ngx_mock.response))
        end)

        it("should return 200 and null currentQueueName if player is not in any queue", function()
            ngx_mock.req.get_method = function() return "GET" end
            players_store.get_player_info = function() return nil end
            gametabler.player_info()
            assert.are.equal(200, ngx_mock.status)
            assert.are.same({ id = "player1", currentQueueName = cjson.null }, cjson.decode(ngx_mock.response))
        end)
    end)

    describe("queue_info", function()
        it("should return 405 if the request method is not GET", function()
            ngx_mock.req.get_method = function() return "POST" end
            gametabler.queue_info()
            assert.are.equal(405, ngx_mock.status)
            assert.are.same({ message = "Method not allowed" }, cjson.decode(ngx_mock.response))
        end)

        it("should return 400 if queueId is missing or invalid", function()
            ngx_mock.req.get_method = function() return "GET" end
            ngx_mock.req.get_uri_args = function() return { queueId = "" } end
            gametabler.queue_info()
            assert.are.equal(400, ngx_mock.status)
            assert.are.same({ message = "Bad request data" }, cjson.decode(ngx_mock.response))

            ngx_mock.req.get_uri_args = function() return { queueId = "queue1@" } end
            gametabler.queue_info()
            assert.are.equal(400, ngx_mock.status)
            assert.are.same({ message = "Bad request data" }, cjson.decode(ngx_mock.response))
        end)

        it("should return 404 if queue is not found", function()
            ngx_mock.req.get_method = function() return "GET" end
            ngx_mock.req.get_uri_args = function() return { queueId = "queue1" } end
            queues_store.queues = {}
            gametabler.queue_info()
            assert.are.equal(404, ngx_mock.status)
            assert.are.same({ message = "queue not found" }, cjson.decode(ngx_mock.response))
        end)

        it("should return 200 and queue info if queue is found", function()
            ngx_mock.req.get_method = function() return "GET" end
            ngx_mock.req.get_uri_args = function() return { queueId = "queue1" } end
            queues_store.queues = {
                queue1 = {
                    queue_name = "Test Queue"
                }
            }
            gametabler.queue_info()
            assert.are.equal(200, ngx_mock.status)
            assert.are.same({
                id = "queue1",
                description = "Test Queue"
            }, cjson.decode(ngx_mock.response))
        end)
    end)

    describe("dequeue", function()
        it("should return 405 if the request method is not POST", function()
            ngx_mock.req.get_method = function() return "GET" end
            gametabler.dequeue()
            assert.are.equal(405, ngx_mock.status)
            assert.are.same({ message = "Method not allowed" }, cjson.decode(ngx_mock.response))
        end)
    
        it("should return 400 if the request body contains invalid JSON", function()
            ngx_mock.req.get_body_data = function() return 'invalid json' end
            gametabler.dequeue()
            assert.are.equal(400, ngx_mock.status)
            assert.are.same({ message = "Bad request data" }, cjson.decode(ngx_mock.response))
        end)
    
        it("should return 400 if playerId is missing or invalid", function()
            ngx_mock.req.get_body_data = function() return '{"playerId":""}' end
            gametabler.dequeue()
            assert.are.equal(400, ngx_mock.status)
            assert.are.same({ message = "Bad request data" }, cjson.decode(ngx_mock.response))
    
            ngx_mock.req.get_body_data = function() return '{"playerId":"player1@"}' end
            gametabler.dequeue()
            assert.are.equal(400, ngx_mock.status)
            assert.are.same({ message = "Bad request data" }, cjson.decode(ngx_mock.response))
        end)
    
        it("should return 404 if player is not in any queue", function()
            players_store.get_player_info = function() return nil end
            gametabler.dequeue()
            assert.are.equal(404, ngx_mock.status)
            assert.are.same({ message = "No player with the id player1 was found currently in any queue." },
                cjson.decode(ngx_mock.response))
        end)
    
        it("should return 200 if dequeue is successful", function()
            -- Mock that the player is already in a queue
            players_store.get_player_info = function() return { current_queue_name = "queue1" } end
            gametabler.dequeue()
            assert.are.equal(200, ngx_mock.status)
            assert.are.same({ playerId = "player1" }, cjson.decode(ngx_mock.response))
        end)
    
        -- New test case for nil body data
        it("should return 400 if the request body is nil", function()
            ngx_mock.req.get_body_data = function() return nil end
            gametabler.dequeue()
            assert.are.equal(400, ngx_mock.status)
            assert.are.same({ message = "Bad request data" }, cjson.decode(ngx_mock.response))
        end)
    end)
end)
