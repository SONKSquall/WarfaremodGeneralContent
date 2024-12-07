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
    if damage > 25 and math.random() < 0.05 then

        for affliction in attackResult.Afflictions do
            Timer.NextFrame(function()
                charHealth.ReduceAfflictionOnLimb(hitLimb,affliction.Identifier,affliction.Strength*0.9)
                charHealth.ReduceAfflictionOnAllLimbs("stun",100)
            end)
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
                WR.data["userdata.drills."..drillID] = table.insert(WR.data["userdata.drills."..drillID] or {},drill)
            else
                WR.data["userdata.drills.unassigned"] = table.insert(WR.data["userdata.drills.unassigned"] or {},drill)
            end
        end
    end
end

function WR.thinkFunctions.antiSpam()

    if WR.tick % 60 ~= 0 then return end

    local spamables = {
        WR_sandbag = {
            range = 200,
            remove = function(item)
                Entity.Spawner.AddItemToRemoveQueue(item)
                Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab"WR_sandbag_setup", item.WorldPosition, nil, nil, nil)
                return item
            end
        },
        WR_barbedwire = {
            range = 100,
            remove = function(item)
                Entity.Spawner.AddItemToRemoveQueue(item)
                Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab"WR_barbedwire_setup", item.WorldPosition, nil, nil, nil)
                return item
            end
        }
    }

    for id,obj in pairs(spamables) do
        local items = Util.GetItemsById(id)
        if items then
            for key,instance in pairs(items) do
                for otherKey,otherInstance in pairs(items) do
                    if instance.WorldPosition.Distance(instance.WorldPosition,otherInstance.WorldPosition) < obj.range
                    and key ~= otherKey
                    and (instance.body and otherInstance.body) -- item objects still exist after deleting
                    then
                        if instance.SpawnTime > otherInstance.SpawnTime then
                            table.remove(items,key) -- do this so the it does not do the remove the function twice
                            obj.remove(instance)
                        else
                            table.remove(items,otherKey)
                            obj.remove(otherInstance)
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

function WR.spawnItemFunctions.WR_coalitionhelmet(item)
    if not WR.HalloweenMode then return end
    local prefab = ItemPrefab.GetItemPrefab("WR_halcoalitionhelmet" .. math.random(1,2))

    Timer.NextFrame(function()
        Entity.Spawner.AddEntityToRemoveQueue(item)
        Entity.Spawner.AddItemToSpawnQueue(prefab, item.ParentInventory, nil, nil, nil, true, false, InvSlotType.Head)
    end)
end

function WR.spawnItemFunctions.WR_coalitionmedhelmet(item)
    if not WR.HalloweenMode then return end
    local prefab = ItemPrefab.GetItemPrefab("WR_halcoalitionmedhelmet1")

    Timer.NextFrame(function()
        Entity.Spawner.AddEntityToRemoveQueue(item)
        Entity.Spawner.AddItemToSpawnQueue(prefab, item.ParentInventory, nil, nil, nil, true, false, InvSlotType.Head)
    end)
end

function WR.spawnItemFunctions.WR_renegadehelmet(item)
    if not WR.HalloweenMode then return end
    local prefab = ItemPrefab.GetItemPrefab("WR_halrenegadehelmet" .. math.random(1,2))

    Timer.NextFrame(function()
        Entity.Spawner.AddEntityToRemoveQueue(item)
        Entity.Spawner.AddItemToSpawnQueue(prefab, item.ParentInventory, nil, nil, nil, true, false, InvSlotType.Head)
    end)
end

function WR.spawnItemFunctions.WR_renegademedhelmet(item)
    if not WR.HalloweenMode then return end
    local prefab = ItemPrefab.GetItemPrefab("WR_halrenegademedhelmet1")

    Timer.NextFrame(function()
        Entity.Spawner.AddEntityToRemoveQueue(item)
        Entity.Spawner.AddItemToSpawnQueue(prefab, item.ParentInventory, nil, nil, nil, true, false, InvSlotType.Head)
    end)
end

function WR.spawnItemFunctions.metalcrate(item)
    if WR.tick < 1 then
        Entity.Spawner.AddEntityToRemoveQueue(item)
    end
end
function WR.spawnItemFunctions.machinepistol(item)
    if WR.tick < 1 then
        Entity.Spawner.AddEntityToRemoveQueue(item)
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
--[[
Hook.Add("meleeWeapon.handleImpact", "WR.constructionTool", function(meleeComponent, targetBody)
    if meleeComponent.Item.Prefab.Identifier ~= "WR_constructiontool" then return end
    local item = meleeComponent.Item

    if LuaUserData.IsTargetType(targetBody.UserData, "Barotrauma.Structure") then
        item.Condition = item.Condition - 5
    end
end)
]]
Hook.Add("WR.stretcher.xmlhook", "WR.stretcher", function(effect, deltaTime, item, targets, worldPosition)

    local character = targets[1]

    if character.SelectedCharacter then
        WR.GiveAfflictionCharacter(character.SelectedCharacter, "WR_stabilize", 100)
    end
end)