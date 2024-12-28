local utils = require("gametabler.utils")
local Party = require("gametabler.Party")
local Player = require("gametabler.Player")

describe("utils", function()
    it("counts participants correctly", function()
        local party1 = Party:new { players = { Player:new("party1-p1"), Player:new("party1-p2") } }
        local player1 = Player:new("player1")
        assert.are.equals(3, utils.count_participants({ party1, player1 }))
    end)

    it("errors when encountering unknown participant type", function()
        local player1 = Player:new("player1")
        local unknown_participant = {}
        assert.has_error(function()
            utils.count_participants({ player1, unknown_participant })
        end, "unknown participant at index 2")
    end)
end)
