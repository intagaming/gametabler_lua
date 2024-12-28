local Queue = require("gametabler.Queue")
local Player = require("gametabler.Player")
local QueueCriteria = require("gametabler.QueueCriteria")
local QueueConfig = require("gametabler.QueueConfig")

describe("Queue", function()
    it("enqueues correctly", function()
        local criteria = QueueCriteria:new {
            players_per_team = 2,
            number_of_teams = 2,
        }
        local config = QueueConfig:new { criteria = criteria }
        local queue = Queue:new { config = config }
        local player1 = Player:new("player1")
        local player2 = Player:new("player2")
        local player3 = Player:new("player3")
        local player4 = Player:new("player4")

        local result = queue:enqueue(player1)

        assert.is_true(queue:is_in_queue(player1))
        assert.are.same({ found = false, teams = {} }, result)

        result = queue:enqueue(player2)

        assert.is_true(queue:is_in_queue(player1))
        assert.is_true(queue:is_in_queue(player2))
        assert.are.same({ found = false, teams = {} }, result)

        result = queue:enqueue(player3)

        assert.is_true(queue:is_in_queue(player1))
        assert.is_true(queue:is_in_queue(player2))
        assert.is_true(queue:is_in_queue(player3))
        assert.are.same({ found = false, teams = {} }, result)

        result = queue:enqueue(player4)

        assert.is_false(queue:is_in_queue(player1))
        assert.is_false(queue:is_in_queue(player2))
        assert.is_false(queue:is_in_queue(player3))
        assert.is_false(queue:is_in_queue(player4))
        assert.are.same({ found = true, teams = criteria:distribute({ player1, player2, player3, player4 }) }, result)
    end)

    it("dequeues correctly", function()
        local criteria = QueueCriteria:new {
            players_per_team = 2,
            number_of_teams = 2,
        }
        local config = QueueConfig:new { criteria = criteria }
        local queue = Queue:new { config = config }
        local player1 = Player:new("player1")

        queue:enqueue(player1)
        assert.is_true(queue:is_in_queue(player1))

        local dequeued = queue:dequeue(player1)
        assert.is_true(dequeued)
    end)

    it("won't dequeue unknown player", function()
        local criteria = QueueCriteria:new {
            players_per_team = 2,
            number_of_teams = 2,
        }
        local config = QueueConfig:new { criteria = criteria }
        local queue = Queue:new { config = config }
        local player1 = Player:new("player1")

        assert.has_error(function()
            queue:dequeue(player1)
        end, "not in queue")
    end)

    it("won't enqueue a player twice", function()
        local criteria = QueueCriteria:new {
            players_per_team = 2,
            number_of_teams = 2,
        }
        local config = QueueConfig:new { criteria = criteria }
        local queue = Queue:new { config = config }
        local player1 = Player:new("player1")

        queue:enqueue(player1)
        assert.is_true(queue:is_in_queue(player1))

        assert.has_error(function()
            queue:enqueue(player1)
        end, "already in queue")

        -- With a new Player instance
        assert.has_error(function()
            queue:enqueue(Player:new("player1"))
        end, "already in queue")
    end)
end)
