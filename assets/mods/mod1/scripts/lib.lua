function update(elapsed)
    if (PongState.keyPressed('W')) then
        PongState.leftPaddleMove(0, -200 * elapsed)
    end
    if (PongState.keyPressed('S')) then
        PongState.leftPaddleMove(0, 200 * elapsed)
    end
    if (PongState.keyPressed('O')) then
        PongState.rightPaddleMove(0, -200 * elapsed)
    end
    if (PongState.keyPressed('K')) then
        PongState.rightPaddleMove(0, 200 * elapsed)
    end
    if (PongState.keyPressed('T')) then
        PongState.serve((FlxG.width) / 2.0, 0, 200, 135)
    end
end
