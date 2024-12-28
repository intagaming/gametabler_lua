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

        queue:enqueue(player1)

        assert.is_true(queue:is_in_queue(player1))

        queue:enqueue(player2)

        assert.is_true(queue:is_in_queue(player2))
    end)

    -- TODO:
end)
