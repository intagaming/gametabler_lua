local cjson = require("cjson")
local M = require("gametabler_web.store.queues")

describe("queues.lua", function()
    -- Reset the queues table before each test
    before_each(function()
        M.queues = {}
        _G.ngx = {}
    end)

    -- Restore stubs after each test
    after_each(function()
        -- Restore io.open to its original value
        if io.open.revert then
            io.open:revert()
        end

        -- Restore cjson.decode to its original value
        if cjson.decode.revert then
            cjson.decode:revert()
        end

        -- Restore ngx.log to its original value
        if ngx.log.revert then
            ngx.log:revert()
        end
    end)

    describe("init", function()
        it("should initialize queues with valid configuration", function()
            -- Mock io.open to return valid JSON
            stub(io, "open", function()
                return {
                    read = function() return '{"queue1": {"criteria": {"playersPerTeam": 5, "numberOfTeams": 2}}}' end,
                    close = function() end
                }
            end)

            -- Mock cjson.decode to return a Lua table with valid configuration
            stub(cjson, "decode", function()
                return {
                    queue1 = {
                        criteria = {
                            playersPerTeam = 5,
                            numberOfTeams = 2
                        }
                    }
                }
            end)

            -- Spy on ngx.log to verify logging occurs
            local log_spy = spy.on(ngx, "log")

            -- Call the init function
            M:init()

            -- Assertions
            assert.spy(log_spy).was.called_with(ngx.INFO, "Queues initialized.")
            assert.is_not_nil(M.queues["queue1"])
        end)

        it("should handle missing criteria field", function()
            -- Mock io.open to return JSON with missing criteria field
            stub(io, "open", function()
                return {
                    read = function() return '{"queue1": {}}' end,
                    close = function() end
                }
            end)

            -- Mock cjson.decode to return a Lua table with missing criteria field
            stub(cjson, "decode", function()
                return {
                    queue1 = {}
                }
            end)

            -- Spy on ngx.log to verify no logging occurs
            local log_spy = spy.on(ngx, "log")

            -- Call the init function and expect an error
            assert.has_error(function()
                M:init()
            end, "Invalid configuration for queue 'queue1': Missing required field: criteria")

            -- Assertions
            assert.spy(log_spy).was_not.called()  -- Verify no logging occurred
        end)

        it("should handle invalid playersPerTeam type", function()
            -- Mock io.open to return JSON with invalid playersPerTeam type
            stub(io, "open", function()
                return {
                    read = function() return '{"queue1": {"criteria": {"playersPerTeam": "five", "numberOfTeams": 2}}}' end,
                    close = function() end
                }
            end)

            -- Mock cjson.decode to return a Lua table with invalid playersPerTeam type
            stub(cjson, "decode", function()
                return {
                    queue1 = {
                        criteria = {
                            playersPerTeam = "five",  -- Invalid type
                            numberOfTeams = 2
                        }
                    }
                }
            end)

            -- Spy on ngx.log to verify no logging occurs
            local log_spy = spy.on(ngx, "log")

            -- Call the init function and expect an error
            assert.has_error(function()
                M:init()
            end, "Invalid configuration for queue 'queue1': playersPerTeam must be a number")

            -- Assertions
            assert.spy(log_spy).was_not.called()  -- Verify no logging occurred
        end)

        it("should handle invalid numberOfTeams type", function()
            -- Mock io.open to return JSON with invalid numberOfTeams type
            stub(io, "open", function()
                return {
                    read = function() return '{"queue1": {"criteria": {"playersPerTeam": 5, "numberOfTeams": "two"}}}' end,
                    close = function() end
                }
            end)

            -- Mock cjson.decode to return a Lua table with invalid numberOfTeams type
            stub(cjson, "decode", function()
                return {
                    queue1 = {
                        criteria = {
                            playersPerTeam = 5,
                            numberOfTeams = "two"  -- Invalid type
                        }
                    }
                }
            end)

            -- Spy on ngx.log to verify no logging occurs
            local log_spy = spy.on(ngx, "log")

            -- Call the init function and expect an error
            assert.has_error(function()
                M:init()
            end, "Invalid configuration for queue 'queue1': numberOfTeams must be a number")

            -- Assertions
            assert.spy(log_spy).was_not.called()  -- Verify no logging occurred
        end)

        it("should handle invalid criteria type", function()
            -- Mock io.open to return JSON with invalid criteria type
            stub(io, "open", function()
                return {
                    read = function() return '{"queue1": {"criteria": "invalid"}}' end,
                    close = function() end
                }
            end)

            -- Mock cjson.decode to return a Lua table with invalid criteria type
            stub(cjson, "decode", function()
                return {
                    queue1 = {
                        criteria = "invalid"  -- Invalid type
                    }
                }
            end)

            -- Spy on ngx.log to verify no logging occurs
            local log_spy = spy.on(ngx, "log")

            -- Call the init function and expect an error
            assert.has_error(function()
                M:init()
            end, "Invalid configuration for queue 'queue1': Criteria must be a table")

            -- Assertions
            assert.spy(log_spy).was_not.called()  -- Verify no logging occurred
        end)

        it("should handle invalid queue configuration type", function()
            -- Mock io.open to return JSON with invalid queue configuration type
            stub(io, "open", function()
                return {
                    read = function() return '{"queue1": "invalid"}' end,
                    close = function() end
                }
            end)

            -- Mock cjson.decode to return a Lua table with invalid queue configuration type
            stub(cjson, "decode", function()
                return {
                    queue1 = "invalid"  -- Invalid type
                }
            end)

            -- Spy on ngx.log to verify no logging occurs
            local log_spy = spy.on(ngx, "log")

            -- Call the init function and expect an error
            assert.has_error(function()
                M:init()
            end, "Invalid configuration for queue 'queue1': Queue configuration must be a table")

            -- Assertions
            assert.spy(log_spy).was_not.called()  -- Verify no logging occurred
        end)
    end)
end)