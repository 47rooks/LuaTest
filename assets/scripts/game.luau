local ScriptableSprite = require("../scriptable/ScriptableSprite")
local PongState = require("./PongState")

local game = {
    utils = require("./utils"),
    FlxG = {
        width = 800,
        height = 600
    },
    state = {
    }
}

function game.newPongState(name)
    game.state = PongState.new(name)
end

function game.newPaddle(name)
    game.state[name] = ScriptableSprite.new()
    game.state[name]:init(100, 100)
end

function game.newBall(name)
    game.state[name] = ScriptableSprite.new()
    game.state[name]:init(100, 100)
end

return game
