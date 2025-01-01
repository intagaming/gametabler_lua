local cjson = require("cjson")

describe("gametabler_web.controller.gametabler", function()
    local gametabler = require("gametabler_web.controller.gametabler")
    local queues_store = require("gametabler_web.store.queues")
    local players_store = require("gametabler_web.store.players")
    local Player = require("gametabler.Player")

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
            HTTP_METHOD_NOT_ALLOWED = 405
        }
        _G.ngx = ngx_mock
    end)

    after_each(function()
        _G.ngx = nil
    end)

    describe("enqueue", function()
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

        it("should return 400 if enqueue fails", function()
            queues_store.queues = {
                queue1 = {
                    enqueue = function() error("enqueue failed", 0) end
                }
            }
            gametabler.enqueue()
            assert.are.equal(400, ngx_mock.status)
            assert.are.same({ message = "enqueue failed" }, cjson.decode(ngx_mock.response))
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
end)
