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

function SpawnInventoryItems(Items, TargetInventory)
    for Item in Items do
        local ItemPrefab = Item.Prefab
        local ItemInventory = Item.OwnInventory
        -- Spawn items inside inventory of its container
        Entity.Spawner.AddItemToSpawnQueue(ItemPrefab, TargetInventory, nil, nil, function(WorldItem)
            -- Spawn item inside other items
            if ItemInventory ~= nil then
                ItemsInInventory = Item.OwnInventory.FindAllItems(predicate, false, list)
                SpawnInventoryItems(ItemsInInventory, WorldItem.OwnInventory)
            end
        end)
    end
end
-- Function list end
-- Var list start
local POW_Press_FrendlyTeam
-- Var list end

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

Hook.Add("pow_frendlyteam", "powpress", function(effect, deltaTime, item, targets, worldPosition)
    for character in targets do
        POW_Press_FrendlyTeam = character.JobIdentifier 
    end
end)

Hook.Add("pow_handle", "despawnpow", function(effect, deltaTime, item, targets, worldPosition)
    for character in targets do
        if IsEnemyPOW(character, POW_Press_FrendlyTeam) == true then
            local Footlocker = ItemPrefab.GetItemPrefab("WR_footlocker")
            local AllItems = character.Inventory.FindAllItems(predicate, false, list)
            Entity.Spawner.AddItemToSpawnQueue(Footlocker, character.WorldPosition, nil, nil, function(Container)
                SpawnInventoryItems(AllItems, Container.OwnInventory)
            end)
            Entity.Spawner.AddEntityToRemoveQueue(character)
        end
    end
end)