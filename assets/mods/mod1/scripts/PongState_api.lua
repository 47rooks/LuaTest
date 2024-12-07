--- @meta

---@class FlxG
--- Read access to global values from Flixel.
FlxG = {
    width = nil, ---@type width number The width of the game window.
    height = nil ---@type height number The height of the game window.
}

--- @class PongState
PongState = {
    --- Check if the specified key is pressed.
    --- @param key string to check, as a quoted character
    --- @return boolean success true if the key is pressed, false otherwise.
    keyPressed = function(key)
    end,

    --- Serve the ball for a new rally.
    --- @param x number the x value of the ball start position
    --- @param y number the y value of the ball start position
    --- @param speed number the speed of the ball
    --- @param degrees number the direction of the ball's travel. Note that
    --- Flixel angles go clockwise rather than the normal counter-clockwise.
    serve = function(x, y, speed, degrees)
    end,

    --- Move the left paddle by the amounts specified.
    --- @param deltaX number the amount to move the paddle in the x axis
    --- @param deltaY number the amount to move the paddle in the y axis
    leftPaddleMove = function(deltaX, deltaY)
    end,

    --- Move the right paddle by the amounts specified.
    --- @param deltaX number the amount to move the paddle in the x axis
    --- @param deltaY number the amount to move the paddle in the y axis
    rightPaddleMove = function(deltaX, deltaY)
    end
}
