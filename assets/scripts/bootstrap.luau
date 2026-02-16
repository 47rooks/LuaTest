--[[
  This is the main entry point for the Lua code. It initializes the game and
  sets up any necessary state.
  The Game object is created here and can be accessed globally when needed.
]]

local utils = require("./utils")
game = {
    utils = utils,
    Game = require("./game"),
    FlxG = {
        width = 800,
        height = 600
    },
    state = {
    }
}
