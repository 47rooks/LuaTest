local ScriptableG = require("../scriptable/ScriptableG")

local G = {}
G.__index = G

type GData = ScriptableG.ScriptableG & {}

export type G = typeof(setmetatable({} :: GData, ScriptableG))

function G.keyPressed(key: string): boolean
    -- Implement key press detection logic
    return false
end

return G