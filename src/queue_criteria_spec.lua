local QueueCriteria = require("queue_criteria")

describe("QueueCriteria", function()
    it("makes correct id", function()
        local c = QueueCriteria:new {
            players_per_team = 1,
            number_of_teams = 2,
        }
        assert.are.equals("1vs1", c:id())
    end)
end)
