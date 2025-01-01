describe("gametabler_web.controller.gametabler", function()
    local gametabler = require("gametabler_web.controller.gametabler")
    local queues_store = require("gametabler_web.store.queues")
    local players_store = require("gametabler_web.store.players")
    local Player = require("gametabler.Player")

    describe("enqueue", function()
        it("should return 400 if playerId or queueId is missing or invalid", function()
            _G.ngx = {
                status = 200,
                req = {
                    get_method = function() return "POST" end,
                    get_body_data = function() return '{"playerId":"","queueId":"queue1"}' end,
                    read_body = function() end
                },
                say = function() end,
                HTTP_BAD_REQUEST = 400
            }
            gametabler.enqueue()
            assert.are.equal(400, ngx.status)
        end)

        it("should return 404 if queue is not found", function()
            _G.ngx = {
                status = 200,
                req = {
                    get_method = function() return "POST" end,
                    get_body_data = function() return '{"playerId":"player1","queueId":"queue1"}' end,
                    read_body = function() end
                },
                say = function() end,
                HTTP_NOT_FOUND = 404
            }
            queues_store.queues = {}
            gametabler.enqueue()
            assert.are.equal(404, ngx.status)
        end)

        it("should return 400 if enqueue fails", function()
            _G.ngx = {
                status = 200,
                req = {
                    get_method = function() return "POST" end,
                    get_body_data = function() return '{"playerId":"player1","queueId":"queue1"}' end,
                    read_body = function() end
                },
                say = function() end,
                HTTP_BAD_REQUEST = 400
            }
            queues_store.queues = {
                queue1 = {
                    enqueue = function() error("enqueue failed") end
                }
            }
            gametabler.enqueue()
            assert.are.equal(400, ngx.status)
        end)

        it("should return 200 and teams if enqueue is successful", function()
            _G.ngx = {
                status = 200,
                req = {
                    get_method = function() return "POST" end,
                    get_body_data = function() return '{"playerId":"player1","queueId":"queue1"}' end,
                    read_body = function() end
                },
                say = function() end
            }
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
            assert.are.equal(200, ngx.status)
        end)
    end)

    describe("player_info", function()
        it("should return 400 if playerId is missing or invalid", function()
            _G.ngx = {
                status = 200,
                req = {
                    get_method = function() return "GET" end,
                    get_uri_args = function() return { playerId = "" } end,
                    read_body = function() end
                },
                say = function() end,
                HTTP_BAD_REQUEST = 400
            }
            gametabler.player_info()
            assert.are.equal(400, ngx.status)
        end)

        it("should return 200 and player info if player is found", function()
            _G.ngx = {
                status = 200,
                req = {
                    get_method = function() return "GET" end,
                    get_uri_args = function() return { playerId = "player1" } end,
                    read_body = function() end
                },
                say = function() end
            }
            players_store.get_player_info = function() return { current_queue_name = "queue1" } end
            gametabler.player_info()
            assert.are.equal(200, ngx.status)
        end)

        it("should return 200 and null currentQueueName if player is not in any queue", function()
            _G.ngx = {
                status = 200,
                req = {
                    get_method = function() return "GET" end,
                    get_uri_args = function() return { playerId = "player1" } end,
                    read_body = function() end
                },
                say = function() end
            }
            players_store.get_player_info = function() return nil end
            gametabler.player_info()
            assert.are.equal(200, ngx.status)
        end)
    end)
end)