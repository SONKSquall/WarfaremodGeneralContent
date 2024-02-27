if Game.IsMultiplayer and CLIENT then return end

local function spawncoins(shop,spawnamount)
    if spawnamount <= 0 then return end
    if not shop then return end
    local coin= ItemPrefab.GetItemPrefab("WR_currency")
    for i=1,spawnamount do
        Entity.Spawner.AddItemToSpawnQueue(coin, shop.OwnInventory, nil, nil, nil)
    end
end

local function powhandle(targets, frendlyteam)
    -- removes pows and places their items in a footlocker
    local shop = WR.Game.Data.GetStat(tostring(frendlyteam),"Shops",WR.Game.Data.Gamemode)[1]
    local capturecount = 0
    for character in targets do
        if WR.IsEnemyPOW(character, frendlyteam) == true then
            local footlocker = ItemPrefab.GetItemPrefab("WR_footlocker")
            local allItems = character.Inventory.FindAllItems(nil, false, nil)
            Entity.Spawner.AddItemToSpawnQueue(footlocker, character.WorldPosition, nil, nil, function(container)
                WR.SpawnInventoryItems(allItems, container.OwnInventory)
            end)
            -- spawn coins in the frendlyteam's shop
            WR.Game.Data.AddStat(tostring(frendlyteam),"Captures",1)
            WR.Game.Data.AddStat(tostring(character.JobIdentifier),"Deaths",1)
            capturecount = capturecount+1
            Entity.Spawner.AddEntityToRemoveQueue(character)
        end
    end
    spawncoins(shop,capturecount)
end

local frendlyteam = ""

Hook.Add("WR.powteamgrabber.xmlhook", "WR.teamgrabber", function(effect, deltaTime, item, targets, worldPosition)
    frendlyteam = targets[1].JobIdentifier
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