WR.protocolBase = {}
WR.protocolBase.enabled = false
WR.protocolBase.name = "Name"
WR.protocolBase.seed = 12345
WR.protocolBase.tick = 0

function WR.protocolBase:Start()
    self.enabled = true
    self:onStart()

    WR.thinkFunctions[self.name .. self.seed] = function() self:Think() end
    WR.roundEndFunctions[self.name .. self.seed] = function() self:End() end
    WR.characterDeathFunctions[self.name .. self.seed] = function(char) self:onCharacterDeath(char) end
end

function WR.protocolBase:Think()
    if self.enabled then
        self.tick = self.tick + 1
    end
    self:End()
end

function WR.protocolBase:End()
    self.enabled = false
    self.tick = 0
    self:onEnd()

    WR.thinkFunctions[self.name .. self.seed] = nil
    WR.roundEndFunctions[self.name .. self.seed] = nil
    WR.characterDeathFunctions[self.name .. self.seed] = nil
end

function WR.protocolBase:onStart()

end

function WR.protocolBase:onEnd()

end

function WR.protocolBase:onCharacterDeath(char)

end

function WR.protocolBase:new(o)
    self.seed = math.random(99999, 00001)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end