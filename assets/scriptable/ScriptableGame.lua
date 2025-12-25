local ScriptableGame = {}
ScriptableGame.__index = ScriptableGame

type ScriptableGameData = {
    name: string,
    replicatedInHaxe: boolean
}

export type ScriptableGame = typeof(setmetatable({} :: ScriptableGameData, ScriptableGame))

function ScriptableGame.new(name): ScriptableGame
    local self = {}
    self.name = name
    self.replicatedInHaxe = false

    return setmetatable(self, ScriptableGame)
end