if CLIENT then return end

local building = {}
building.Walls = {}
building.Destroyed = false

function building:IsDestroyed()
    local maxdamage = 0
    local currentdamage = 0
    for wall in self.Walls do
        for n=0,wall.SectionCount do
            -- for some reason wall.Health is alot larger then the wall max damage
            maxdamage = maxdamage + (wall.Health/4)
            currentdamage = currentdamage + (wall.SectionDamage(n))
        end
    end
    if currentdamage > maxdamage then
        self.Destroyed = true
    end
    -- buildings can not be undestroyed
    return self.Destroyed
end

function building:AddDamage(number)
    for wall in self.Walls do
        for n=0,wall.SectionCount do
            -- add random varation to make sure buildings don't just break all at once
            wall.AddDamage(n, math.random((number*1.5),(number*0.5)), nil, true)
        end
    end
end

function building:New(o)
    o = o or {}   -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
end

return building