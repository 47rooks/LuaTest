--[[
  This is the main entry point for the Lua code. It initializes the game and
  sets up any necessary state.
  The Game object is created here and can be accessed globally when needed.
  Strictly this should only be used from the Haxe side. In Luau scripts
  `require("./game")` should be used.
]]

game = require("./game")