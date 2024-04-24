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

Hook.Add("WR.productionCrate.xmlhook", "WR.productionCrate", function(effect, deltaTime, item, targets, worldPosition)
    local tagVars = WR.getStringVariables(item.tags)
    if not (tagVars.spawncount and tagVars.spawnid) then return end
    local itemSpawned = false
    if item.OwnInventory.IsEmpty() and item.Condition >= 1 then
        for i=tonumber(tagVars.spawncount),1,-1 do
            Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab(tagVars.spawnid), item.OwnInventory, nil, nil, function(worldItem) end)
        end
        itemSpawned = true
        item.Condition = item.Condition - 1
    end
    if not itemSpawned and item.OwnInventory.IsEmpty() and item.Condition == 0 then
        Entity.Spawner.AddEntityToRemoveQueue(item)
    end
end)