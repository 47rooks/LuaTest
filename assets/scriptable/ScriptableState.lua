local ScriptableState = {}
ScriptableState.__index = ScriptableState

type ScriptableStateData = {
    name: string,
    replicatedInHaxe: boolean,
    script: string
}

export type ScriptableState = typeof(setmetatable({} :: ScriptableStateData, ScriptableState))

function ScriptableState.new(name): ScriptableState
    local self = {}
    self.name = name
    self.replicatedInHaxe = false
    self.script = nil

    return setmetatable(self, ScriptableState)
end

function ScriptableState.init(self:ScriptableState)
    --- Add the passed fields to the object
    self.replicatedInHaxe = true
end

function ScriptableState.update(self:ScriptableState, dt:number)
  -- Override in subclass
end

function ScriptableState.syncToHaxe()
  -- Override in subclass
end

function ScriptableState.syncFromHaxe()
  -- Override in subclass
end