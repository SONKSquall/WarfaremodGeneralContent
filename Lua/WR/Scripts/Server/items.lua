if Game.IsMultiplayer and CLIENT then return end

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

function WR.characterDamageFunctions.helmet(charHealth, attackResult, hitLimb)
    if hitLimb.type ~= LimbType.Head then return end
    local item = charHealth.Character.Inventory.GetItemInLimbSlot(InvSlotType.Head)

    if not item then return end
    if not item.HasTag("helmet") then return end

    local damage = attackResult.Damage
    if damage > 25 and math.random() < 0.2 then

        for affliction in attackResult.Afflictions do
            Timer.NextFrame(function() charHealth.ReduceAfflictionOnLimb(hitLimb,affliction.Identifier,affliction.Strength*0.9) end)
        end

        local sfxPrefab = ItemPrefab.GetItemPrefab(item.Prefab.Identifier.value.."_sfx")
        if sfxPrefab then
            Entity.Spawner.AddItemToSpawnQueue(sfxPrefab, hitLimb.worldPosition, nil, nil, nil)
        end
        Entity.Spawner.AddEntityToRemoveQueue(item)
    end
end

function WR.roundStartFunctions.ore()

    if Util.GetItemsById("WR_oredrill") then
        for drill in Util.GetItemsById("WR_oredrill") do
            local drillID = WR.getStringVariables(drill.Tags).id
            if drillID then
                WR.dataManager.addData("userdata.drills."..drillID,nil,function(t) if t == nil then t = {} end table.insert(t,drill) end)
            else
                WR.dataManager.addData("userdata.drills.unassigned",nil,function(t) if t == nil then t = {} end table.insert(t,drill) end)
            end
        end
    end
end

function WR.thinkFunctions.antiSpam()

    if WR.tick % 6 ~= 0 then return end

    local spamitems = WR.GetPrefabsByTag("WR_spamable")

    for prefab in spamitems do
        local worldItems = Util.GetItemsById(prefab.Identifier.value)
        if worldItems then
            for key,item in pairs(worldItems) do
                -- compares itself with all other items of the same identifier
                for otherKey,otherItem in pairs(worldItems) do
                    if otherKey ~= key then
                        if Vector2.Distance(item.WorldPosition,otherItem.WorldPosition) < 200 then
                            local removeItem
                            -- grab newer item
                            if item.SpawnTime > otherItem.SpawnTime then
                                removeItem = item
                                table.remove(worldItems,key)
                            else
                                removeItem = otherItem
                                table.remove(worldItems,otherKey)
                            end


                            if WR.getStringVariables(item.Tags).replacementitemid then
                                local replaceItem = ItemPrefab.GetItemPrefab(WR.getStringVariables(item.Tags).replacementitemid)
                                Entity.Spawner.AddItemToSpawnQueue(replaceItem, removeItem.WorldPosition, nil, nil, nil)
                            end

                            Entity.Spawner.AddItemToRemoveQueue(removeItem)
                        end
                    end
                end
            end
        end
    end
end

function WR.characterCreateFunctions.giveRecipes(char)
    if char.JobIdentifier == "coalitionteam" then
        char.GiveTalent("WR_coalitionrecipes",nil)
    elseif char.JobIdentifier == "renegadeteam" then
        char.GiveTalent("WR_renegaderecipes",nil)
    end
end

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

Hook.Add("WR.transmit.xmlhook", "WR.transmit", function(effect, deltaTime, item, targets, worldPosition)
    for radio in item.GetComponentString("WifiComponent").GetReceiversInRange() do
        if radio.Item.HasTag("mobileradio") then
            local owner = radio.Item.GetRootInventoryOwner()
            if owner.Prefab.Identifier == "human" then
                WR.GiveAfflictionCharacter(owner,"WR_callsound",100)
            end
        end
    end
end)

Hook.Add("meleeWeapon.handleImpact", "WR.constructionTool", function(meleeComponent, targetBody)
    if meleeComponent.Item.Prefab.Identifier ~= "WR_constructiontool" then return end
    local item = meleeComponent.Item

    if LuaUserData.IsTargetType(targetBody.UserData, "Barotrauma.Structure") then
        item.Condition = item.Condition - 5
    end
end)