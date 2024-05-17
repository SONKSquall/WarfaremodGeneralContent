if Game.IsMultiplayer and CLIENT then return end

WR.pointItemFunctions = {}
WR.useItemFunctions = {}
WR.equipItemFunctions = {}
WR.spawnItemFunctions = {}

function WR.pointItemFunctions.WR_minedetector(item, itemUser)

    if WR.tick % 30 ~= 0 then return end

    if not Util.GetItemsById("WR_landmine") then return end -- if theres no landmines then don't do anything
    for landmine in Util.GetItemsById("WR_landmine") do
        if Vector2.Distance(landmine.WorldPosition, item.WorldPosition) < 500 then
            local light = landmine.GetComponentString("LightComponent")
            light.IsOn = true
            -- networking
            if SERVER then
                local property = light.SerializableProperties[Identifier("IsOn")]
                Networking.CreateEntityEvent(landmine, Item.ChangePropertyEventData(property, light))
            end
        end
    end

end

function WR.equipItemFunctions.WR_whistle(item, itemUser)

    local hat = itemUser.Inventory.GetItemInLimbSlot(InvSlotType.Head)

    if not hat then
        item.Condition = 0
        return
    end
    if not hat.HasTag("command") then
        item.Condition = 0
        return
    end

    item.Condition = item.MaxCondition

end

Hook.Add("item.secondaryUse", "WR.pointItem", function(item, itemUser)
    if WR.pointItemFunctions[item.Prefab.Identifier.value] then
        WR.pointItemFunctions[item.Prefab.Identifier.value](item, itemUser)
    end
end)

Hook.Add("item.use", "WR.useItem", function(item, itemUser)
    if WR.useItemFunctions[item.Prefab.Identifier.value] then
        WR.useItemFunctions[item.Prefab.Identifier.value](item, itemUser)
    end
end)

Hook.Add("item.equip", "WR.equip", function(item, itemUser)
    if WR.equipItemFunctions[item.Prefab.Identifier.value] then
        WR.equipItemFunctions[item.Prefab.Identifier.value](item, itemUser)
    end
end)

Hook.Add("item.created", "WR.itemSpawn", function(item)
    if WR.spawnItemFunctions[item.Prefab.Identifier.value] then
        WR.spawnItemFunctions[item.Prefab.Identifier.value](item)
    end
end)

Hook.Add("WR.productionCrate.xmlhook", "WR.productionCrate", function(effect, deltaTime, item, targets, worldPosition, element)
    local spawndata = WR.getStringVariables(element.GetAttributeString("spawndata", "default value"))
    local itemSpawned = false
    if item.OwnInventory.IsEmpty() and item.Condition >= 1 then
        for id,spawnCount in pairs(spawndata) do
            for i=tonumber(spawnCount),1,-1 do
                Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab(id), item.OwnInventory, nil, nil, function(worldItem) end)
            end
        end
        itemSpawned = true
        item.Condition = item.Condition - 1
    end
    if not itemSpawned and item.OwnInventory.IsEmpty() and item.Condition == 0 then
        Entity.Spawner.AddEntityToRemoveQueue(item)
    end
end)

Hook.Add("WR.defenseBuilt.xmlhook", "WR.defenseBuilt", function(effect, deltaTime, item, targets, worldPosition, element)
    local prefab = ItemPrefab.GetItemPrefab(element.GetAttributeString("prefab", "default value") or "WR_sandbag")
    local distance = element.GetAttributeString("distance", "default value")
    local spawnPos = item.WorldPosition

    if item.ParentInventory.Owner.IsFlipped then
        spawnPos.X = spawnPos.X - distance
    else
        spawnPos.X = spawnPos.X + distance
    end

    Entity.Spawner.AddItemToSpawnQueue(prefab, spawnPos, nil, nil, nil)
end)