if CLIENT then return end

local base = require "WR.Scripts.Server.Extensions.base"
local class = dofile(WR.Path .. "/Lua/singleton.lua")

local sizes = {
    small = {
        destruction = {
            particle = ItemPrefab.GetItemPrefab("WR_destructionsmall_sfx"),
            dps = 20,
            threshold = 0.8,
            duration = 4
        },
        fortsRequired = 1,
        lootTable = {
            {id = "antibleeding1", amount = 3, weight = 5},
            {id = "antibloodloss1", amount = 2, weight = 2},
        }
    },
    medium = {
        destruction = {
            particle = ItemPrefab.GetItemPrefab("WR_destructionmedium_sfx"),
            dps = 12,
            threshold = 0.5,
            duration = 6
        },
        fortsRequired = 2,
        lootTable = {
            {id = "antibleeding1", amount = 3, weight = 5},
            {id = "antibloodloss1", amount = 2, weight = 5},
            {id = "WR_sandbag_setup", amount = 1, weight = 2},
            {id = "WR_barbedwire_setup", amount = 1, weight = 2}
        }
    },
    large = {
        destruction = {
            particle = ItemPrefab.GetItemPrefab("WR_destructionlarge_sfx"),
            dps = 10,
            threshold = 0.5,
            duration = 10
        },
        fortsRequired = 3,
        lootTable = {
            {id = "WR_basicmaterial", amount = 1, weight = 1},
            {id = "antibleeding1", amount = 3, weight = 5},
            {id = "antibloodloss1", amount = 2, weight = 5},
            {id = "WR_sandbag_setup", amount = 1, weight = 3},
            {id = "WR_barbedwire_setup", amount = 1, weight = 3}
        }
    },
    super = {
        destruction = {
            particle = ItemPrefab.GetItemPrefab("WR_destructionsuper_sfx"),
            dps = 4,
            threshold = 0.4,
            duration = 20
        },
        fortsRequired = 10,
        lootTable = {
            {id = "antibleeding1", amount = 3, weight = 5},
            {id = "antibloodloss1", amount = 2, weight = 5},
            {id = "WR_sandbag_setup", amount = 1, weight = 3},
            {id = "WR_barbedwire_setup", amount = 1, weight = 3}
        }
    }
}
local building = {}
building.rect = Vector2(0,0)
building.walls = {}
building.containers = {}

building.fortified = false
building.destructible = true
building.destroyed = false
building.size = sizes.small

function building:GetRectClients()
    local clients = {}
    for client in Client.ClientList do
        if client.Character and (math.abs(client.Character.WorldPosition.X - self.rect.X - self.rect.Width/2) <= self.rect.Width/2 and math.abs(client.Character.WorldPosition.Y - self.rect.Y + self.rect.Height/2) <= self.rect.Height/2) then
            table.insert(clients,client)
        end
    end
    return clients
end

function building:GetRectItems(items)
    local rectItems = {}
    for item in items do
        if (math.abs(item.WorldPosition.X - self.rect.X - self.rect.Width/2) <= self.rect.Width/2 and math.abs(item.WorldPosition.Y - self.rect.Y + self.rect.Height/2) <= self.rect.Height/2) then
            table.insert(rectItems,item)
        end
    end
    return rectItems
end


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
    return damageRatio > self.size.destruction.threshold and not self.fortified and self.destructible
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
                if math.random() > 0.2 then
                    Timer.Wait(function() Entity.Spawner.AddItemToSpawnQueue(self.size.destruction.particle, wall.SectionPosition(i,true), nil, nil, nil) end,3000*math.random())
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

function building:SpawnItemContainer(index,itemID,amount)
    index = math.ceil(index)
    if not self.containers[index] then return end
    for i=1,amount do
        Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab(tostring(itemID)), self.containers[index].OwnInventory, nil, nil, nil)
    end
end

function building:IsFortified(defenseCount)
    return defenseCount >= self.size.fortsRequired
end

function building:new(o)
    o = o or {}   -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
end

local buildingManager = class(base)
buildingManager.name = "Building manager"
buildingManager.buildings = {}
function buildingManager:onStart()
    -- registers buildings
    for item in Util.GetItemsById("label") do
        if item.HasTag("wr_building") then
            local walls = {}
            local containers = {}
            local rect = item.WorldRect
            for wall in Structure.WallList do
                if wall.MaxHealth < 1000 and not wall.IsPlatform then
                    if (math.abs(wall.WorldPosition.X - rect.X - rect.Width/2) <= rect.Width/2 and math.abs(wall.WorldPosition.Y - rect.Y + rect.Height/2) <= rect.Height/2) then
                        table.insert(walls,wall)
                    end
                end
            end
            for container in WR.GetItemsByTag("container") do
                if (math.abs(container.WorldPosition.X - rect.X - rect.Width/2) <= rect.Width/2 and math.abs(container.WorldPosition.Y - rect.Y + rect.Height/2) <= rect.Height/2) then
                    table.insert(containers,container)
                end
            end

            -- each building is its own object
            table.insert(self.buildings, building:new{
                walls = walls,
                containers = containers,
                rect = rect,
                size = sizes[WR.getStringVariables(item.Tags).size],
                destructible = WR.getStringVariables(item.Tags).destructible ~= "false"
            })
        end
    end
end
function buildingManager:Think()
    if self.enabled then
        self.tick = self.tick + 1
        if self.tick % 60 == 0 then
            local defenses = WR.GetItemsByTag("defense")
            for obj in self.buildings do
                if obj.destroyed or obj:IsDestroyed() then
                    obj.destroyed = true
                    obj:Destroy(obj.size.destruction.dps,obj.size.destruction.duration)
                else
                    obj.fortified = obj:IsFortified(#obj:GetRectItems(defenses))
                end
                if self.tick % (5*60) == 0 then
                    if obj.fortified and not obj.destroyed then
                        local weights = {}
                        for v in obj.size.lootTable do
                            table.insert(weights,v.weight)
                        end
                        local loot = WR.weightedRandom(obj.size.lootTable,weights)
                        obj:SpawnItemContainer(math.random(1,#obj.containers),loot.id,loot.amount)
                    end
                end
            end
        end
    end
end
function buildingManager:onEnd()
    self.buildings = {}
end

return buildingManager