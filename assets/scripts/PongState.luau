local ScriptableSprite = require("../scriptable/ScriptableSprite")
local ScriptableState = require("../scriptable/ScriptableState")

local PongState = {}
PongState.__index = PongState

type PongStateData = ScriptableState.ScriptableState & {
    leftPaddle: ScriptableSprite.ScriptableSprite,
    rightPaddle: ScriptableSprite.ScriptableSprite,
    ball: ScriptableSprite.ScriptableSprite,
    serve: (number, number, number, number) -> nil
}

export type PongState = typeof(setmetatable({} :: PongStateData, PongState))

function PongState.new(name)
    -- local self = {}
    local self = setmetatable(PongState, {__index = ScriptableState.new(name)})
    -- Additional initialization if needed
    self.leftPaddle = 0
    self.rightPaddle = 12 -- FIXME indicator value for debug only
    self.ball = 0
    return self
end

function PongState:_leftPaddleMove(deltaX, deltaY)
    self.leftPaddle.x = self.leftPaddle.x + deltaX
    self.leftPaddle.y = self.leftPaddle.y + deltaY
end

function PongState:_rightPaddleMove(deltaX, deltaY)
    self.rightPaddle.x = self.rightPaddle.x + deltaX
    self.rightPaddle.y = self.rightPaddle.y + deltaY
end

function PongState:_serve(x, y, speed, degrees)
    self.ball.x = x
    self.ball.y = y
    self.ball.speed = speed
    self.ball.direction = degrees
    self.serve(x, y, speed, degrees)
end

function PongState:update(elapsed)
    -- print("PongState update, elapsed=" .. elapsed)
    if (_G.game.FlxG.keyPressed('W')) then
        self:_leftPaddleMove(0, -200 * elapsed)
    end
    if (_G.game.FlxG.keyPressed('S')) then
        self:_leftPaddleMove(0, 200 * elapsed)
    end
    if (_G.game.FlxG.keyPressed('O')) then
        self:_rightPaddleMove(0, -200 * elapsed)
    end
    if (_G.game.FlxG.keyPressed('K')) then
        self:_rightPaddleMove(0, 200 * elapsed)
    end
    if (_G.game.FlxG.keyPressed('T')) then
        self:_serve((_G.game.FlxG.width) / 2.0, 0, 200, 135)
    end
end

return PongState