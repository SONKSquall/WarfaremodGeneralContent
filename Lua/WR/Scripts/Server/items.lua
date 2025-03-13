if Game.IsMultiplayer and CLIENT then return end

--[[
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
]]

function WR.thinkFunctions.standAimingAroundSandbag()
    if WR.tick % 10 ~= 0 then return end

    local sandbags = Util.GetItemsById("WR_sandbag")
    if not sandbags then return end

    for client in Client.ClientList do
        if client.Character and client.Character.AnimController.IsAiming then
            for item in sandbags do
                local angle = math.deg(item.body.Rotation)
                if not item.Removed and (angle < 5 and angle > -5) and Vector2.Distance(client.Character.WorldPosition,item.WorldPosition) < 100 then
                    WR.GiveAfflictionCharacter(client.Character,"WR_forcestand",18)
                end
            end
        end
    end
end

function WR.equipItemFunctions.WR_minedetector(item, itemUser)
    WR.thinkFunctions[item] = function()

        if WR.tick % 5 ~= 0 then return end

        if not itemUser.HasItem(item, true) then
            WR.thinkFunctions[item] = nil
            return
        end

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

function WR.characterDamageFunctions.flametankExpolsion(charHealth, attackResult, hitLimb)
    if hitLimb.type ~= LimbType.Torso then return end
    local item = charHealth.Character.Inventory.GetItemInLimbSlot(InvSlotType.Bag)

    if not item then return end
    if not item.HasTag("flamethrower") then return end

    local damage = attackResult.Damage
    if damage > 25 and math.random() < 0.25 then
        Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("WR_flamethrowerleak_sfx"), hitLimb.worldPosition, nil, nil, nil)
        item.Condition = item.Condition - damage
    elseif damage > 25 and math.random() > 0.75 then
        Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("WR_flameexplosion"), hitLimb.worldPosition, nil, nil, nil)
        Entity.Spawner.AddEntityToRemoveQueue(item)
    end
end

function WR.characterDamageFunctions.armorDamage(charHealth, attackResult, hitLimb)
    if hitLimb.type ~= LimbType.Torso or hitLimb.type ~= LimbType.RightThigh or hitLimb.type ~= LimbType.LeftThigh then return end
    local item = charHealth.Character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes)

    if not item then return end
    if not item.Prefab.Identifier.value == "WR_renegadearmor" then return end

    local damage = attackResult.Damage / 2
    item.Condition = item.Condition - damage

    if item.Condition <= 0 then
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

--[[ TODO: 
change discriptions to match new workings
new sprite for crates
carryable crates
make sure shell crates are usable
]]

WR.cratesLoadouts = {
    -- Weapon crates start --
    WR_riflecrate = {
        {id = "WR_basicrifle",
        count = 4,
        contents = {
            {
                id = "WR_largeround",
                count = 6
            }
        }}
    },
    WR_shotguncrate = {
        {id = "shotgun",
        count = 4,
        contents = {
            {
                id = "WR_shotgunround",
                count = 6
            }
        }}
    },
    WR_smgcrate = {
        {id = "WR_smg",
        count = 2,
        contents = {
            {
                id = "WR_smallroundmag20",
                count = 1,
                contents = {
                    {
                        id = "WR_smallround",
                        count = 20
                    }
                }
            }
        }}
    },
    WR_hmgcrate = {
        {id = "WR_basicmachinegun",
        count = 1}
    },
    WR_grenadecrate = {
        {id = "fraggrenade",
        count = 4}
    },
    WR_dynamitecrate = {
        {id = "WR_dynamite",
        count = 2}
    },
    WR_flamethrowercrate = {
        {id = "WR_flamethrower",
        count = 2}
    },
    -- Weapon crates end --
    -- Ammo crates start --
    WR_rifleammocrate = {
        {id = "WR_largeround",
        count = 12*4}
    },
    WR_shotgunammocrate = {
        {id = "WR_shotgunround",
        count = 12*4}
    },
    WR_smgammocrate = {
        {id = "WR_smallroundmag20",
        count = 4,
        contents = {
            {
                id = "WR_smallround",
                count = 20
            }
        }}
    },
    WR_hmgammocrate = {
        {id = "WR_machinegunmag",
        count = 4}
    },
    -- Ammo crates end --
    -- Medical crates start --
    WR_medicalcrate = {
        {id = "antibleeding1",
        count = 8},
        {id = "antibleeding3",
        count = 4},
        {id = "antidama1",
        count = 8},
        {id = "antidama2",
        count = 8}
    },
    WR_bloodcrate = {
        {id = "antibloodloss1",
        count = 6},
        {id = "antibloodloss2",
        count = 2}
    },
    -- Medical crates end --
    -- Defense crates start --
    WR_sandbagcrate = {
        {id = "WR_sandbag_setup",
        count = 4}
    },
    WR_barbedwirecrate = {
        {id = "WR_barbedwire_setup",
        count = 4}
    },
    -- Defense crates end --
    -- Coaltion crates start --
    WR_coalitionshellcrate = {
        {id = "railgunshell",
        count = 6}
    },
    WR_coalitionbodyarmorcrate = {
        {id = "bodyarmor",
        count = 2}
    },
    WR_coalitiongasgrenadecrate = {
        {id = "chemgrenade",
        count = 6},
        {id = "40mmchemgrenade",
        count = 3}
    },
    -- Coaltion crates end --
    -- Renegade crates start --
    WR_renegadeshellcrate = {
        {id = "flakcannonammoboxexplosive"}
    },
    WR_renegadebodyarmorcrate = {
        {id = "WR_renegadearmor",
        count = 2}
    },
    -- Renegade crates end --
}

Hook.Add("WR.productionCrate.xmlhook", "WR.productionCrate", function(effect, deltaTime, item, targets, worldPosition, element)
    local list = WR.cratesLoadouts[item.Prefab.Identifier.value]
    local owner = item.GetRootInventoryOwner()

    if list and WR.staticContainers[owner] and not owner.OwnInventory.IsFull(false) then
        Entity.Spawner.AddEntityToRemoveQueue(item)
        -- prevent issues regarding shelfs
        Timer.NextFrame(function() WR.spawnItems(list,owner.OwnInventory) end)
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

    local owner = item.GetRootInventoryOwner()

    if owner.SelectedCharacter then
        WR.GiveAfflictionCharacter(character.SelectedCharacter, "WR_stabilize", 100)
    end
end)