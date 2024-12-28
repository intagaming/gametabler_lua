local QueueCriteria = require("gametabler.QueueCriteria")
local Player        = require("gametabler.Player")
local Party         = require("gametabler.Party")

describe("QueueCriteria", function()
    it("makes correct id", function()
        local c = QueueCriteria:new {
            players_per_team = 1,
            number_of_teams = 2,
        }
        assert.are.equals("1vs1", c:id())

        c = QueueCriteria:new {
            players_per_team = 1,
            number_of_teams = 4,
        }
        assert.are.equals("1vs1vs1vs1", c:id())

        c = QueueCriteria:new {
            players_per_team = 4,
            number_of_teams = 1,
        }
        assert.are.equals("4", c:id())
    end)

    describe("distribute", function()
        it("distributes 1vs1vs1vs1", function()
            local c = QueueCriteria:new {
                players_per_team = 1,
                number_of_teams = 4,
            }
            local participants = { Player:new("0"), Player:new("1"), Player:new("2"), Player:new("3") }
            local teams = c:distribute(participants)
            assert.are.same({
                { participants[1] },
                { participants[2] },
                { participants[3] },
                { participants[4] },
            }, teams)
        end)

        it("distributes table of 4", function()
            local c = QueueCriteria:new {
                players_per_team = 4,
                number_of_teams = 1,
            }
            local participants = { Player:new("0"), Player:new("1"), Player:new("2"), Player:new("3") }
            local teams = c:distribute(participants)
            assert.are.same({
                { participants[1], participants[2], participants[3], participants[4] },
            }, teams)
        end)

        it("distributes underpopulated parties and players", function()
            local c = QueueCriteria:new {
                players_per_team = 3,
                number_of_teams = 2,
            }
            local party1 = Party:new { players = { Player:new("party1-p1"), Player:new("party1-p2") } }
            local party2 = Party:new { players = { Player:new("party2-p1"), Player:new("party2-p2") } }
            local player1 = Player:new("player1")
            local player2 = Player:new("player2")
            local participants = { party1, party2, player1, player2 }

            local teams = c:distribute(participants)
            assert.are.same({
                { party1.players[1], party1.players[2], player1 },
                { party2.players[1], party2.players[2], player2 },
            }, teams)
        end)

        it("distributes properly populated parties and players", function()
            local c = QueueCriteria:new {
                players_per_team = 2,
                number_of_teams = 2,
            }
            local party1 = Party:new { players = { Player:new("party1-p1"), Player:new("party1-p2") } }
            local player1 = Player:new("player1")
            local player2 = Player:new("player2")
            local participants = { party1, player1, player2 }

            local teams = c:distribute(participants)
            assert.are.same({
                { party1.players[1], party1.players[2] },
                { player1,           player2 },
            }, teams)
        end)

        it("distributes overpopulated party comes before properly populated party", function()
            local c = QueueCriteria:new {
                players_per_team = 2,
                number_of_teams = 3,
            }
            local party1 = Party:new { players = { Player:new("party1-p1"), Player:new("party1-p2"), Player:new("party1-p3") } }
            local party2 = Party:new { players = { Player:new("party2-p1"), Player:new("party2-p2") } }
            local player1 = Player:new("player1")
            local participants = { party1, party2, player1 }

            local teams = c:distribute(participants)
            assert.are.same({
                { party2.players[1], party2.players[2] },
                { party1.players[1], party1.players[2] },
                { player1,           party1.players[3] },
            }, teams)
        end)

        it("distributes overpopulated parties and players", function()
            local c = QueueCriteria:new {
                players_per_team = 2,
                number_of_teams = 2,
            }
            local party1 = Party:new { players = { Player:new("party1-p1"), Player:new("party1-p2"), Player:new("party1-p3") } }
            local player1 = Player:new("player1")
            local participants = { party1, player1 }

            local teams = c:distribute(participants)
            assert.are.same({
                { party1.players[1], party1.players[2] },
                { player1,           party1.players[3] },
            }, teams)
        end)

        it("distributes double underpopulated parties and players", function()
            local c = QueueCriteria:new {
                players_per_team = 5,
                number_of_teams = 2,
            }
            local party1 = Party:new { players = { Player:new("party1-p1"), Player:new("party1-p2") } }
            local party2 = Party:new { players = { Player:new("party2-p1"), Player:new("party2-p2") } }
            local party3 = Party:new { players = { Player:new("party3-p1"), Player:new("party3-p2") } }
            local party4 = Party:new { players = { Player:new("party4-p1"), Player:new("party4-p2") } }
            local player1 = Player:new("player1")
            local player2 = Player:new("player2")
            local participants = { party1, party2, party3, party4, player1, player2 }

            local teams = c:distribute(participants)
            assert.are.same({
                { party1.players[1], party1.players[2], party3.players[1], party3.players[2], player1 },
                { party2.players[1], party2.players[2], party4.players[1], party4.players[2], player2 },
            }, teams)
        end)

        it("throws when not enough players to distribute", function()
            local c = QueueCriteria:new {
                players_per_team = 1,
                number_of_teams = 4,
            }
            local player1 = Player:new("player1")
            local player2 = Player:new("player2")
            local player3 = Player:new("player3")
            local participants = { player1, player2, player3 }

            assert.has_error(function()
                c:distribute(participants)
            end, "not enough players")
        end)
    end)
end)
