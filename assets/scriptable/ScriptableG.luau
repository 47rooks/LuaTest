local ScriptableG = {}
ScriptableG.__index = ScriptableG

type ScriptableGData = {
    width: number,
    height: number,
    keyPressed: (string) -> boolean
}

export type ScriptableG = typeof(setmetatable({} :: ScriptableGData, ScriptableG))

function ScriptableG.new(): ScriptableG
    local self = {}
    self.width = 0
    self.height = 0
    self.keyPressed = nil

    return setmetatable(self, ScriptableG)
end

return ScriptableG
