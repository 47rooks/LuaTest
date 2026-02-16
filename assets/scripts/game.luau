local ScriptableGame = require("../scriptable/ScriptableGame")

-- local game = {
--     FlxG = {
--         width = 800,
--         height = 600
--     }
-- }
local Game = {}
Game.__index = Game


function Game.new(name)
    local self = {}
    -- Additional initialization if needed
    return setmetatable(self, ScriptableGame.new(name))
end

return Game
