if CLIENT then return end

WR.staticContainers = {}
WR.lootSpawners = {}

local allowedContainers = {
    "suppliescabinet",
    "mediumsteelcabinet",
    "mediumwindowedsteelcabinet",
    "steelcabinet",
    "securesteelcabinet",
    "medcabinet",
    "toxcabinet",
    "suppliescabinetwrecked",
    "mediumsteelcabinetwrecked",
    "mediumwindowedsteelcabinetwrecked",
    "steelcabinetwrecked",
    "securesteelcabinetwrecked",
    "medcabinetwrecked",
    "toxcabinetwrecked",
    "railgunshellrack",
    "coilgunammoshelf"
}
--[[
local lootTables = {
    wr_medical = {
        {"antibleeding1", 1},
        {"antibloodloss1", 0.25},
        {"antidama3", 0.1}
    },
    wr_armory = {
        {"riflebullet", 1},
        {"shotgunshell", 1},
        {"rifle", 0.1},
        {"shotgun", 0.1},
        {"smgmagazine", 0.05},
        {"smg", 0.01}
    }
}
]]
function WR.thinkFunctions.loot()

    for spawner in WR.lootSpawners do
        if WR.tick % spawner.rate == 0 then
            local loot = WR.weightedRandom(spawner.loot,spawner.weights)
            if not spawner.item.OwnInventory.IsFull(true) then
                Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab(loot), spawner.item.OwnInventory, nil, nil, function(item)
                    -- randomize the slot the item spawns in
                    spawner.item.OwnInventory.TryPutItem(item, math.random(0,spawner.item.OwnInventory.Capacity), true, true, nil, true, true)
                end, false)
            end
        end
    end
end

function WR.roundStartFunctions.containers()

    WR.staticContainers = {}
    WR.lootSpawners = {}
    for id in allowedContainers do
        if Util.GetItemsById(id) then
            for item in Util.GetItemsById(id) do
                WR.staticContainers[item] = true
            end
        end
    end

    for item in pairs(WR.staticContainers) do
        local tags = WR.getStringVariables(item.tags)
        if tags and tags.loottable then
            local loot = WR.stringSplit(tags.loottable,";")
            local weights = WR.stringSplit(tags.lootweights,";") or {}
            local rate = math.ceil((tonumber(tags.spawnrate) or 60)*60)

            for key in pairs(loot) do
                weights[key] = tonumber(weights[key]) or 1
            end

            table.insert(WR.lootSpawners, {item = item,loot = loot,weights = weights,rate = rate})
        end
    end

end

WR.objectives = {}

function WR.roundStartFunctions.objectives()
    WR.objectives = {}
    for area in WR.getAreas(function(item) return item.HasTag("wr_objective") end) do
        local tags = WR.getStringVariables(area.tags)
        table.insert(WR.objectives,
        {
            attacker = WR.attacker(tags.team or tags.defender) or "renegadeteam",
            defender = WR.defender(tags.team or tags.defender) or "coalitionteam",
            rect = area.WorldRect,
            captured = false
        })
    end
end

WR.buildings = {}

do

    local function getDamage(tbl)
        local damage = 0
        for wall in tbl do
            for n=0,wall.SectionCount do
                damage = damage + (wall.SectionDamage(n))
            end
        end
        return damage
    end

    local function getHealth(tbl)
        local health = 0
        for wall in tbl do
            for n=1,wall.SectionCount do
                health = health + wall.MaxHealth
            end
        end
        return health
    end


    function WR.roundStartFunctions.buildings()
        WR.buildings = {}
        for area in WR.getAreas(function(item) return item.HasTag("wr_building") end) do
            local walls = {}

            for wall in Structure.WallList do
                if wall.MaxHealth < 1000 and not wall.Indestructible and not wall.IsPlatform then
                    if WR.isPointInRect(wall.WorldPosition,area.WorldRect) then
                        table.insert(walls,wall)
                    end
                end
            end

            local threshold = tonumber(WR.getStringVariables(area.tags).threshold) or 0.75

            table.insert(WR.buildings,
            {
                item = area,
                walls = walls,
                threshold = threshold,
                getHealth = getHealth,
                getDamage = getDamage
            })
        end
    end

end

function WR.thinkFunctions.buildings()
    if WR.tick % 60 ~= 0 then return end

    for building in WR.buildings do
        if building.getDamage(building.walls)/building.getHealth(building.walls) > building.threshold then
            for wall in building.walls do
                if building.getDamage{wall}/building.getHealth{wall} == 1 then
                    wall.Indestructible = true
                end
            end
        end
    end
end
--[[
function WR.getRandomContainer()
    return WR.staticContainers[math.random(#WR.staticContainers)]
end
]]