if CLIENT then return end

require "WR.Scripts.Server.Extensions.base"

local building = {}
building.walls = {}
building.destroyed = false

function building:GetDamage()
    local damage = 0
    for wall in self.walls do
        for n=0,wall.SectionCount do
            damage = damage + (wall.SectionDamage(n))
        end
    end
    return damage
end

function building:GetHealth()
    local health = 0
    for wall in self.walls do
        for n=1,wall.SectionCount,1 do
            health = health + wall.Health
        end
    end
    return health
end

function building:IsDestroyed()
    local damageRatio = (self:GetDamage()/self:GetHealth())
    if damageRatio > 0.5 then
        return true
    end
    return false
end

function building:Destroy(damage,frames)
    local tick = 0
    local tickMax = frames
    local function main()
        tick = tick + 1
        if tick >= tickMax then return function() end end
        self:AddDamage(damage)
        return function() main() end
    end
    self.Destroy = main()
end

function building:AddDamage(number)
    for wall in self.walls do
        for n=0,wall.SectionCount do
            -- add random varation to make sure buildings don't just break all at once
            wall.AddDamage(n, math.random((number*1.5),(number*0.5)), nil, true)
        end
    end
end

function building:new(o)
    o = o or {}   -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
end

WR.buildingManager = WR.extensionBase:new({
    name = "Building manager",
    buildings = {},
    onStart = function(self)
        -- registers buildings
        for item in Util.GetItemsById("label") do
            if item.HasTag("wr_building") then
                local areaWalls = {}
                local rect = item.WorldRect
                for wall in Structure.WallList do
                    if wall.MaxHealth < 1000 and not wall.IsPlatform then
                        if (math.abs(wall.WorldPosition.X - rect.X - rect.Width/2) <= rect.Width/2 and math.abs(wall.WorldPosition.Y - rect.Y + rect.Height/2) <= rect.Height/2) then
                            table.insert(areaWalls,wall)
                        end
                    end
                end
                -- each building is its own object
                table.insert(self.buildings, building:new({walls = areaWalls}))
            end
        end
    end,
    Think = function(self)
        if self.enabled then
            self.tick = self.tick + 1
            if self.tick % 60 == 0 then
                for obj in self.buildings do
                    if obj.destroyed or obj:IsDestroyed() then
                        obj.destroyed = true
                        obj:Destroy(5,60)
                    end
                end
            end
        end
    end,
    onEnd = function(self)
        self.buildings = {}
    end
})