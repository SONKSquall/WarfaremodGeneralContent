if CLIENT then return end -- stops this from running on the client
-- Function list start
function IsEnemyPOW(character, FriendlyTeam)
    if character.isHuman == true
    and character.IsDead == false
    and character.JobIdentifier ~= FriendlyTeam
    and character.LockHands == true
    then
        return true
    else
        return false
    end
end
-- Function list end

Hook.Add("baton_attack", "batonhit", function(effect, deltaTime, item, targets, worldPosition)
    local limb = targets[1]
    local character = limb.character
    local blunttrauma = AfflictionPrefab.Prefabs["blunttrauma"]
    local stun = AfflictionPrefab.Prefabs["incrementalstun"]
    -- TODO: make this use damagemodifiers
    if character.LockHands == true then
        limb.character.CharacterHealth.ApplyAffliction(limb, stun.Instantiate(40))
    else
        limb.character.CharacterHealth.ApplyAffliction(limb, blunttrauma.Instantiate(30))
    end
end)

--TODO: rewrite with functions
--To anyone reading, DO NOT COPY this is REALLY bad code
Hook.Add("pow_frendlyteam", "powpress", function(effect, deltaTime, item, targets, worldPosition)
    for character in targets do
        POW_Press_FrendlyTeam = character.JobIdentifier 
    end
end)

Hook.Add("pow_handle", "despawnpow", function(effect, deltaTime, item, targets, worldPosition)
    for character in targets do
        if IsEnemyPOW(character, POW_Press_FrendlyTeam) == true then
            local CratePrefab = ItemPrefab.GetItemPrefab("metalcrate")
            local AllItems = character.Inventory.FindAllItems(predicate, false, list)
            Entity.Spawner.AddItemToSpawnQueue(CratePrefab, character.WorldPosition, nil, nil, function(Container)
                for Item in AllItems do
                    local ItemPrefab = Item.Prefab
                    Entity.Spawner.AddItemToSpawnQueue(ItemPrefab, Container.OwnInventory, nil, nil, function(item)
                        local ItemInventory = Item.OwnInventory
                        if ItemInventory ~= nil then
                            local ItemInventory = Item.OwnInventory.FindAllItems(predicate, false, list)
                            for Item in ItemInventory do
                                local ItemPrefab = Item.Prefab
                                Entity.Spawner.AddItemToSpawnQueue(ItemPrefab, item.OwnInventory, nil, nil, function(item3)
                                end)
                            end
                        end
                    end)
                end
            end)
            Entity.Spawner.AddEntityToRemoveQueue(character)
        end
    end
end)