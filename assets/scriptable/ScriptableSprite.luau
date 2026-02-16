local ScriptableSprite = {}
ScriptableSprite.__index = ScriptableSprite

type ScriptableSpriteData = {
    x: number,
    y: number,
    replicatedInHaxe: boolean
}

export type ScriptableSprite = typeof(setmetatable({} :: ScriptableSpriteData, ScriptableSprite))

function ScriptableSprite.new(): ScriptableSprite
    local self = {}
    self.x = 0
    self.y = 0
    self.replicatedInHaxe = false

    return setmetatable(self, ScriptableSprite)
end

function ScriptableSprite.init(self, x, y)
  self.x = x or 0
  self.y = y or 0
end

function ScriptableSprite.update(self, dt)
  -- Override in subclass
end

function ScriptableSprite.syncToHaxe()
  -- Override in subclass
end

function ScriptableSprite.syncFromHaxe()
  -- Override in subclass
end

return ScriptableSprite