local NgxQueue = require("gametabler_web.utils.NgxQueue")
local Player = require("gametabler.Player")
local PlayerInfo = require("gametabler_web.store.players.PlayerInfo")
local cjson = require("cjson")

-- Mock players_store
local players_store = require("gametabler_web.store.players")

describe("NgxQueue", function()
    local ngx_mock = {
        shared = {
            queues = {
                get = function(self, key)
                    return "player1,player2"
                end,
                set = function(self, key, value)
                    -- Do nothing
                end
            },
            players = {
                get = function(self, key)
                    return cjson.encode({ id = key, current_queue_name = "queue1" })
                end,
                set = function(self, key, value)
                    -- Do nothing
                end
            }
        },
        log = function(level, message)
            -- Mock log function to do nothing
        end,
        DEBUG = 1 -- Mock DEBUG level
    }

    before_each(function()
        _G.ngx = ngx_mock
        -- Spy on the players_store functions
        spy.on(players_store, "set_player_info")
        spy.on(players_store, "get_player_info")
    end)

    it("should enqueue a player and update the queue", function()
        local queue_mock = {
            enqueue = function()
                return { found = false, teams = {} }
            end,
            enqueued_players = {}
        }
        local ngx_queue = NgxQueue:new { queue_name = "queue1", queue = queue_mock }
        local player = Player:new("player3")
        local result = ngx_queue:enqueue(player)

        assert.are.equal(false, result.found)
        assert.are.same({}, result.teams)
        assert.spy(players_store.set_player_info).was.called_with("player3",
            PlayerInfo:new { id = "player3", current_queue_name = "queue1" })
    end)

    it("should enqueue a player and form a team", function()
        local queue_mock = {
            enqueue = function()
                return { found = true, teams = { { Player:new("player1"), Player:new("player2") } } }
            end,
            enqueued_players = {}
        }
        local ngx_queue = NgxQueue:new { queue_name = "queue1", queue = queue_mock }
        local player = Player:new("player3")
        local result = ngx_queue:enqueue(player)

        assert.are.equal(true, result.found)
        assert.are.same({ { Player:new("player1"), Player:new("player2") } }, result.teams)
        assert.spy(players_store.set_player_info).was.called_with("player1",
            PlayerInfo:new { id = "player1", current_queue_name = nil })
        assert.spy(players_store.set_player_info).was.called_with("player2",
            PlayerInfo:new { id = "player2", current_queue_name = nil })
    end)

    it("should update player info when enqueueing", function()
        local queue_mock = {
            enqueue = function()
                return { found = false, teams = {} }
            end,
            enqueued_players = {}
        }
        local ngx_queue = NgxQueue:new { queue_name = "queue1", queue = queue_mock }
        local player = Player:new("player3")
        ngx_queue:enqueue(player)

        assert.spy(players_store.set_player_info).was.called_with("player3",
            PlayerInfo:new { id = "player3", current_queue_name = "queue1" })
    end)

    it("should update player info when forming a team", function()
        local queue_mock = {
            enqueue = function()
                return { found = true, teams = { { Player:new("player1"), Player:new("player2") } } }
            end,
            enqueued_players = {}
        }
        local ngx_queue = NgxQueue:new { queue_name = "queue1", queue = queue_mock }
        local player = Player:new("player2")
        ngx_queue:enqueue(player)

        assert.spy(players_store.set_player_info).was.called_with("player1",
            PlayerInfo:new { id = "player1", current_queue_name = nil })
        assert.spy(players_store.set_player_info).was.called_with("player2",
            PlayerInfo:new { id = "player2", current_queue_name = nil })
    end)
end)