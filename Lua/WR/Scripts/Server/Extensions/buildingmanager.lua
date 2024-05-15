if CLIENT then return end

require "WR.Scripts.Server.Extensions.base"

local destructionPresets = {
    small = {
        sfx = {
            wallRatio = 0.2,
            particle = ItemPrefab.GetItemPrefab("WR_destructionsmall_sfx")
        },
        dps = 20,
        threshold = 0.8,
        duration = 4
    },
    medium = {
        sfx = {
            wallRatio = 0.2,
            particle = ItemPrefab.GetItemPrefab("WR_destructionmedium_sfx")
        },
        dps = 12,
        threshold = 0.5,
        duration = 6
    },
    large = {
        sfx = {
            wallRatio = 0.2,
            particle = ItemPrefab.GetItemPrefab("WR_destructionlarge_sfx")
        },
        dps = 10,
        threshold = 0.5,
        duration = 10
    },
    super = {
        sfx = {
            wallRatio = 0.2,
            particle = ItemPrefab.GetItemPrefab("WR_destructionsuper_sfx")
        },
        dps = 4,
        threshold = 0.4,
        duration = 20
    }
}
local building = {}
building.walls = {}
building.destroyed = false
building.destructionPreset = destructionPresets.small

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
    if damageRatio > self.destructionPreset.threshold then
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

        -- sfx
        for wall in self.walls do
            for i=wall.SectionCount,1,-1 do
                if math.random() > self.destructionPreset.sfx.wallRatio then
                    Timer.Wait(function() Entity.Spawner.AddItemToSpawnQueue(self.destructionPreset.sfx.particle, wall.SectionPosition(i,true), nil, nil, nil) end,3000*math.random())
                end
            end
        end
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
                print(destructionPresets.small)
                -- each building is its own object
                table.insert(self.buildings, building:new{
                    walls = areaWalls,
                    destructionPreset = destructionPresets[WR.getStringVariables(item.Tags).size]
                })
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
                        obj:Destroy(obj.destructionPreset.dps,obj.destructionPreset.duration)
                    end
                end
            end
        end
    end,
    onEnd = function(self)
        self.buildings = {}
    end
})