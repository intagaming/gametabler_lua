local NgxQueue = require("gametabler_web.utils.NgxQueue")
local Player = require("gametabler.Player")
local PlayerInfo = require("gametabler_web.store.players.PlayerInfo")
local cjson = require("cjson")
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
    end)

    it("should enqueue a player and return no teams when no match is found", function()
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
    end)

    it("should enqueue a player and return a team when a match is found", function()
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
    end)

    it("should update player info with the current queue name when enqueueing", function()
        local queue_mock = {
            enqueue = function()
                return { found = false, teams = {} }
            end,
            enqueued_players = {}
        }
        local ngx_queue = NgxQueue:new { queue_name = "queue1", queue = queue_mock }
        local player = Player:new("player3")
        spy.on(players_store, "set_player_info")
        ngx_queue:enqueue(player)

        assert.spy(players_store.set_player_info).was.called_with("player3",
            PlayerInfo:new { id = "player3", current_queue_name = "queue1" })
    end)

    it("should update player info to remove the queue name when forming a team", function()
        local queue_mock = {
            enqueue = function()
                return { found = true, teams = { { Player:new("player1"), Player:new("player2") } } }
            end,
            enqueued_players = {}
        }
        local ngx_queue = NgxQueue:new { queue_name = "queue1", queue = queue_mock }
        local player = Player:new("player2")
        spy.on(players_store, "set_player_info")
        ngx_queue:enqueue(player)

        assert.spy(players_store.set_player_info).was.called_with("player1",
            PlayerInfo:new { id = "player1", current_queue_name = nil })
        assert.spy(players_store.set_player_info).was.called_with("player2",
            PlayerInfo:new { id = "player2", current_queue_name = nil })
    end)

    it("should correctly update the shared queues storage with enqueued players", function()
        local queue_mock = {
            enqueue = function(self, player)
                -- Simulate adding the player to the enqueued_players list
                self.enqueued_players[#self.enqueued_players + 1] = player
                return { found = false, teams = {} }
            end,
            enqueued_players = {}
        }
        local ngx_queue = NgxQueue:new { queue_name = "queue1", queue = queue_mock }
        local player = Player:new("player3")
        spy.on(ngx.shared.queues, "set")
        ngx_queue:enqueue(player)

        assert.spy(ngx.shared.queues.set).was.called_with(ngx.shared.queues, "queue1", "player1,player2,player3")
    end)
    
    it("should dequeue a player and update the shared queues storage", function()
        local queue_mock = {
            dequeue = function(self, player)
                -- Simulate removing the player from the enqueued_players list
                for k, v in pairs(self.enqueued_players) do
                    if v.id == player.id then
                        table.remove(self.enqueued_players, k)
                        return true
                    end
                end
                return false
            end,
            enqueued_players = { Player:new("player1"), Player:new("player2") }
        }
        local ngx_queue = NgxQueue:new { queue_name = "queue1", queue = queue_mock }
        local player = Player:new("player1")
        spy.on(ngx.shared.queues, "set")
        spy.on(players_store, "set_player_info")
        local result = ngx_queue:dequeue(player)
    
        assert.is_true(result)
        assert.spy(ngx.shared.queues.set).was.called_with(ngx.shared.queues, "queue1", "player2")
        assert.spy(players_store.set_player_info).was.called_with("player1",
            PlayerInfo:new { id = "player1", current_queue_name = nil })
    end)
    
    it("should not dequeue a player not in the queue", function()
        local queue_mock = {
            dequeue = function(self, player)
                -- Simulate trying to remove a player not in the queue
                return false
            end,
            enqueued_players = { Player:new("player1"), Player:new("player2") }
        }
        local ngx_queue = NgxQueue:new { queue_name = "queue1", queue = queue_mock }
        local player = Player:new("player3")
        spy.on(ngx.shared.queues, "set")
        spy.on(players_store, "set_player_info")
        local result = ngx_queue:dequeue(player)
    
        assert.is_false(result)
        assert.spy(ngx.shared.queues.set).was_not_called()
        assert.spy(players_store.set_player_info).was_not_called()
    end)
end)