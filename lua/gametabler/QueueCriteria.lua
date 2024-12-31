local utils           = require("gametabler.utils")
local Player          = require("gametabler.Player")
local Party           = require("gametabler.Party")

---@class QueueCriteria
---@field players_per_team number
---@field number_of_teams number
local QueueCriteria   = {
    players_per_team = 0,
    number_of_teams = 0,
}
QueueCriteria.__index = QueueCriteria

---@generic T: QueueCriteria
---@param self T
---@param o T|nil
---@return T
function QueueCriteria:new(o)
    o = o or {}
    return setmetatable(o, QueueCriteria)
end

function QueueCriteria:total_players()
    return self.players_per_team * self.number_of_teams
end

function QueueCriteria:id()
    local buf = {}
    for i = 1, self.number_of_teams do
        table.insert(buf, tostring(self.players_per_team))
        if i ~= self.number_of_teams then
            table.insert(buf, "vs")
        end
    end
    return table.concat(buf)
end

function QueueCriteria:distribute(participants)
    local count = utils.count_participants(participants)
    if count < self:total_players() then
        error("not enough players", 0)
    end
    ---@type Player[][]
    local teams = {}
    for i = 1, self.number_of_teams do
        teams[i] = {}
    end

    ---@type Player[]
    local players = {}
    ---@type Party[]
    local parties = {}

    for _, v in pairs(participants) do
        if getmetatable(v) == Player then
            table.insert(players, v)
        elseif getmetatable(v) == Party then
            table.insert(parties, v)
        end
    end

    -- Assign parties fully to teams
    ---@type Party[]
    local leftover_parties = {}
    for _, party in pairs(parties) do
        local least_player_team_index = 1
        for i, team in pairs(teams) do
            if #team < #teams[least_player_team_index] then
                least_player_team_index = i
            end
        end
        if #teams[least_player_team_index] + #party.players > self.players_per_team then
            -- No hope of adding this party fully.
            table.insert(leftover_parties, party)
            goto continue
        end
        for _, party_player in pairs(party.players) do
            table.insert(teams[least_player_team_index], party_player)
        end
        ::continue::
    end
    parties = leftover_parties

    -- Assign parties partially to teams
    while #parties > 0 do
        ---@type Party
        local party = parties[1]
        table.remove(parties, 1)
        local players_to_dist = utils.copy_table(party.players)
        while #players_to_dist > 0 do
            -- If there's only one player left in party to distribute,
            -- consider that player a regular one.
            if #players_to_dist == 1 then
                table.insert(players, players_to_dist[1])
                break
            end
            local least_player_team_index = 1
            for i, team in pairs(teams) do
                if #team < #teams[least_player_team_index] then
                    least_player_team_index = i
                end
            end
            local num_of_players_to_recruit = math.min(#players_to_dist,
                self.players_per_team - #teams[least_player_team_index])
            if num_of_players_to_recruit == 1 then
                -- The team that has the most empty seat only has 1 slot left.
                -- Can't do any more party distribution.
                for _, p in pairs(players_to_dist) do
                    table.insert(players, p)
                end
                goto out
            end

            for _ = 1, num_of_players_to_recruit do
                local p = players_to_dist[1]
                table.remove(players_to_dist, 1)
                table.insert(teams[least_player_team_index], p)
            end
        end
    end
    ::out::

    -- Consider leftover parties as individual players
    for _, party in pairs(parties) do
        for _, player in pairs(party.players) do
            table.insert(players, player)
        end
    end

    for _, team in pairs(teams) do
        if #team >= self.players_per_team then
            goto continue
        end
        local num_of_players_to_recruit = self.players_per_team - #team
        for _ = 1, num_of_players_to_recruit do
            local p = players[1]
            table.remove(players, 1)
            table.insert(team, p)
        end
        ::continue::
    end

    return teams
end

return QueueCriteria
