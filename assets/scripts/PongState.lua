function update(elapsed)
    if (FlxG.keyPressed('W')) then
        PongState.leftPaddleMove(0, -200 * elapsed)
    end
    if (FlxG.keyPressed('S')) then
        PongState.leftPaddleMove(0, 200 * elapsed)
    end
    if (FlxG.keyPressed('O')) then
        PongState.rightPaddleMove(0, -200 * elapsed)
    end
    if (FlxG.keyPressed('K')) then
        PongState.rightPaddleMove(0, 200 * elapsed)
    end
    if (FlxG.keyPressed('T')) then
        PongState.serve((game.FlxG.width) / 2.0, 0, 200, 135)
    end
end
