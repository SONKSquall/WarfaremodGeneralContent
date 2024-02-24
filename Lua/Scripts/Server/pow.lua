if Game.IsMultiplayer and CLIENT then return end

local function powhandle(targets, frendlyteam)
    -- removes pows and places their items in a footlocker
    for character in targets do
        if WR.IsEnemyPOW(character, frendlyteam) == true then
            local footlocker = ItemPrefab.GetItemPrefab("WR_footlocker")
            local allItems = character.Inventory.FindAllItems(nil, false, nil)
            local coin = ItemPrefab.GetItemPrefab("WR_currency")
            Entity.Spawner.AddItemToSpawnQueue(footlocker, character.WorldPosition, nil, nil, function(container)
                WR.SpawnInventoryItems(allItems, container.OwnInventory)
            end)
            -- spawn coins in the frendlyteam's shop
            for shop in Util.GetItemsById("WR_strategicexchange") do
                local _, _, shopteam = string.find(shop.tags, "team='(.-)'")
                if shopteam and shopteam == frendlyteam then
                    Entity.Spawner.AddItemToSpawnQueue(coin, shop.OwnInventory, nil, nil, nil)
                    break
                end
            end
            print("Frendly team: ",tostring(frendlyteam))
            print("Enemy team: ", tostring(character.JobIdentifier))
            WR.Game.Data.AddStat(tostring(frendlyteam),"Captures",1)
            WR.Game.Data.AddStat(tostring(character.JobIdentifier),"Deaths",1)
            Entity.Spawner.AddEntityToRemoveQueue(character)
        end
    end
end

local frendlyteam = ""

Hook.Add("WR.powteamgrabber.xmlhook", "WR.teamgrabber", function(effect, deltaTime, item, targets, worldPosition)
    frendlyteam = targets[1].JobIdentifier
end)

Hook.Add("WR.powhandle.xmlhook", "WR.powhandle", function(effect, deltaTime, item, targets, worldPosition)
    print(frendlyteam)
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