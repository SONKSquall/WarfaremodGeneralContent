if Game.IsMultiplayer and CLIENT then return end

local POW_Press_FrendlyTeam = ""

Hook.Add("pow_frendlyteam", "WR_GetFrendlyTeam", function(effect, deltaTime, item, targets, worldPosition)
    for character in targets do
        POW_Press_FrendlyTeam = character.JobIdentifier 
    end
end)

Hook.Add("pow_handle", "WR_DespawnPOW", function(effect, deltaTime, item, targets, worldPosition)
    for character in targets do
        if WR.IsEnemyPOW(character, POW_Press_FrendlyTeam) == true then
            local Footlocker = ItemPrefab.GetItemPrefab("WR_footlocker")
            local AllItems = character.Inventory.FindAllItems(predicate, false, list)
            Entity.Spawner.AddItemToSpawnQueue(Footlocker, character.WorldPosition, nil, nil, function(Container)
                WR.SpawnInventoryItems(AllItems, Container.OwnInventory)
            end)
            Entity.Spawner.AddEntityToRemoveQueue(character)
        end
    end
end)