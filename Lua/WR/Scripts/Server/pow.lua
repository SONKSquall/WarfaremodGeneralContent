if Game.IsMultiplayer and CLIENT then return end

local function spawncoins(shop,spawnamount)
    if spawnamount <= 0 then return end
    if not shop then return end
    local coin= ItemPrefab.GetItemPrefab("WR_currency")
    for i=1,spawnamount do
        Entity.Spawner.AddItemToSpawnQueue(coin, shop.OwnInventory, nil, nil, nil)
    end
end


-- removes pows and places their items in a footlocker
local function powhandle(targets, frendlyteam)
    local shop = WR.dataManager.getData("teams."..WR.teamKeys[frendlyteam]..".shops")[1]
    local capturecount = 0
    for character in targets do
        if WR.IsEnemyPOW(character, frendlyteam) == true then
            local footlocker = ItemPrefab.GetItemPrefab("WR_footlocker")
            local allItems = character.Inventory.FindAllItems(nil, false, nil)
            Entity.Spawner.AddItemToSpawnQueue(footlocker, character.WorldPosition, nil, nil, function(container)
                WR.SpawnInventoryItems(allItems, container.OwnInventory)
            end)
            WR.dataManager.addData("teams."..frendlyteam..".captures",nil,function(n) return n + 1 end)
            WR.dataManager.addData("teams."..character.Info.Job.Prefab.Identifier.Value..".deaths",nil,function(n) return n + 1 end)
            capturecount = capturecount+1
            Entity.Spawner.AddEntityToRemoveQueue(character)
        end
    end
    spawncoins(shop,capturecount*5)
end

local frendlyteam = ""

Hook.Add("WR.powteamgrabber.xmlhook", "WR.teamgrabber", function(effect, deltaTime, item, targets, worldPosition)
    frendlyteam = tostring(targets[1].Info.Job.Prefab.Identifier.Value)
end)

Hook.Add("WR.powhandle.xmlhook", "WR.powhandle", function(effect, deltaTime, item, targets, worldPosition)
    Timer.NextFrame(function() powhandle(targets, frendlyteam) end)
end)

Hook.Add("WR.cuffs.xmlhook", "WR.cuffs", function(effect, deltaTime, item, targets, worldPosition)

    for character in targets do
        local carrierteam = tostring(character.JobIdentifier)

        if character.SelectedCharacter and WR.IsEnemyPOW(character.SelectedCharacter, carrierteam) then
            WR.GiveAfflictionCharacter(character, "WR_normalwalkspeed", 100)
        end
    end
end)