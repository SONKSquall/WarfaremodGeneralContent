if Game.IsMultiplayer and CLIENT then return end

Hook.Add("WR.powhandle.xmlhook", "WR.powhandle", function(effect, deltaTime, item, targets, worldPosition)
    local frendlyteam = ""
    -- checks if there is a dupe player in the targets (there are two target types), if so then that player's team is the frendly team
    for player in targets do
        local instancesofplayer = 0
        for otherplayer in targets do
            if player.name == otherplayer.name then
                instancesofplayer = instancesofplayer + 1
            end
        end
        if instancesofplayer >= 2 then
            frendlyteam = player.JobIdentifier
            break
        end
    end
    -- removes pows and places their items in a footlocker
    for character in targets do
        if WR.IsEnemyPOW(character, frendlyteam) == true then
            local Footlocker = ItemPrefab.GetItemPrefab("WR_footlocker")
            local AllItems = character.Inventory.FindAllItems(predicate, false, list)
            local coin = ItemPrefab.GetItemPrefab("WR_currency")
            Entity.Spawner.AddItemToSpawnQueue(Footlocker, character.WorldPosition, nil, nil, function(Container)
                WR.SpawnInventoryItems(AllItems, Container.OwnInventory)
            end)
            -- spawn coins in the frendlyteam's shop
            for shop in WR.GetItemsById("WR_strategicexchange") do
                local _, _, shopteam = string.find(shop.tags, "team='(.-)'")
                if shopteam and shopteam == frendlyteam then
                    Entity.Spawner.AddItemToSpawnQueue(coin, shop.OwnInventory, nil, nil, nil)
                    break
                end
            end
            character.Kill(CauseOfDeathType.Unknown,nil,false,false)
            Entity.Spawner.AddEntityToRemoveQueue(character)
        end
    end
end)

Hook.Add("WR.cuffs.xmlhook", "WR.cuffs", function(effect, deltaTime, item, targets, worldPosition)

    for character in targets do
        local carrierteam = tostring(character.JobIdentifier)

        if character.SelectedCharacter and WR.IsEnemyPOW(character.SelectedCharacter, carrierteam) then
            WR.GiveAfflictionCharacter(character, "WR_normalwalkspeed", 100)
        end
    end
end)