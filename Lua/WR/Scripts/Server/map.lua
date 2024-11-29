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
    "toxcabinet"
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
                Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab(loot), spawner.item.OwnInventory, nil, nil, nil)
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
                table.insert(WR.staticContainers,item)
            end
        end
    end

    for item in WR.staticContainers do
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

function WR.getRandomContainer()
    return WR.staticContainers[math.random(#WR.staticContainers)]
end