WR.extensionBase = {}
WR.extensionBase.enabled = false
WR.extensionBase.name = "Name"
WR.extensionBase.seed = 12345
WR.extensionBase.tick = 0

function WR.extensionBase:Start()
    self.enabled = true
    self:onStart()

    WR.thinkFunctions[self.name .. self.seed] = function() self:Think() end
    WR.roundEndFunctions[self.name .. self.seed] = function() self:End() end
    WR.characterDeathFunctions[self.name .. self.seed] = function(char) self:onCharacterDeath(char) end
end

function WR.extensionBase:Think()
    if self.enabled then
        self.tick = self.tick + 1
    end
    self:End()
end

function WR.extensionBase:End()
    self.enabled = false
    self.tick = 0
    self:onEnd()

    WR.thinkFunctions[self.name .. self.seed] = nil
    WR.roundEndFunctions[self.name .. self.seed] = nil
    WR.characterDeathFunctions[self.name .. self.seed] = nil
end

function WR.extensionBase:onStart()

end

function WR.extensionBase:onEnd()

end

function WR.extensionBase:onCharacterDeath(char)

end

function WR.extensionBase:new(o)
    self.seed = math.random(99999, 00001)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end