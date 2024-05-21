local class = dofile(WR.Path .. "/Lua/singleton.lua")

local extensionBase = class()
extensionBase.enabled = false
extensionBase.name = "Name"
extensionBase.tick = 0

function extensionBase:Start()
    self.enabled = true
    self:onStart()

    WR.thinkFunctions[self.name] = function() self:Think() end
    WR.roundEndFunctions[self.name] = function() self:End() end
    WR.characterDeathFunctions[self.name] = function(char) self:onCharacterDeath(char) end
end

function extensionBase:Think()
    if self.enabled then
        self.tick = self.tick + 1
    end
end

function extensionBase:End()
    self.enabled = false
    self.tick = 0
    self:onEnd()

    WR.thinkFunctions[self.name] = nil
    WR.roundEndFunctions[self.name] = nil
    WR.characterDeathFunctions[self.name] = nil
end

function extensionBase:onStart()

end

function extensionBase:onEnd()

end

function extensionBase:onCharacterDeath(char)

end

return extensionBase