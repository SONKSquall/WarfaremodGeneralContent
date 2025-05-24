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
    if WR.tick % 6 ~= 0 then return end

    local sandbags = Util.GetItemsById("WR_sandbag")
    if not sandbags then return end

    for client in Client.ClientList do
        if client.Character and client.Character.AnimController.IsAiming then
            for item in sandbags do
                if not item.Removed then
                    local angle = math.deg(item.body.Rotation)
                    if (angle < 5 and angle > -5) and Vector2.Distance(client.Character.WorldPosition,item.WorldPosition) < 100 then
                        WR.GiveAfflictionCharacter(client.Character,"WR_forcestand",10.5)
                    end
                end
            end
        end
    end
end

function WR.thinkFunctions.cuffs()
    if WR.tick % 60 ~= 0 then return end 
    for char in Character.CharacterList do
        if char.IsHuman and char.IsKeyDown(InputType.Crouch) then
            local item = char.Inventory.GetItemInLimbSlot(InvSlotType.RightHand)

            if item and not item.Removed and WR.id(item) == "WR_cuffs" then
                item.Condition = item.Condition - 2

                if item.Condition <= 0 then
                    Entity.Spawner.AddEntityToRemoveQueue(item)
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

        local sfxPrefab = ItemPrefab.GetItemPrefab(WR.id(item).."_sfx")
        if sfxPrefab then
            Entity.Spawner.AddItemToSpawnQueue(sfxPrefab, hitLimb.worldPosition, nil, nil, nil)
        end
        Entity.Spawner.AddEntityToRemoveQueue(item)
    end
end

do

function WR.characterDamageFunctions.flametankExpolsion(charHealth, attackResult, hitLimb, attackPos)
    if hitLimb.type ~= LimbType.Torso and hitLimb.type ~= LimbType.Waist then return end
    local item = charHealth.Character.Inventory.GetItemInLimbSlot(InvSlotType.Bag)

    if not item then return end
    if not item.HasTag("flamethrower") then return end

    if not WR.hitAngle(attackPos,hitLimb,{0,180}) then return end


    local damage = attackResult.Damage
    if damage > 25 and math.random() < 0.5 then
        Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("WR_flamethrowerleak_sfx"), hitLimb.worldPosition, nil, nil, nil)
        item.Condition = item.Condition - damage
    elseif damage > 25 and math.random() > 0.5 then
        Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("WR_flameexplosion"), hitLimb.worldPosition, nil, nil, nil)
        Entity.Spawner.AddEntityToRemoveQueue(item)
    end
end

end

local validArmor = {
    WR_renegadearmor = true,
    WR_coalitionarmor = true,
}

local armoredLimbs = {
    [LimbType.Torso] = true,
    [LimbType.LeftArm] = true,
    [LimbType.LeftForearm] = true,
    [LimbType.LeftThigh] = true,
    [LimbType.LeftLeg] = true,
    [LimbType.LeftFoot] = true,
    [LimbType.RightArm] = true,
    [LimbType.RightForearm] = true,
    [LimbType.RightThigh] = true,
    [LimbType.RightLeg] = true,
    [LimbType.RightFoot] = true
}

function WR.characterDamageFunctions.armorDamage(charHealth, attackResult, hitLimb, worldPosition, attacker, originalDamage, penetration)
    if not armoredLimbs[hitLimb.type] then return end
    if not WR.hitAngle(worldPosition,hitLimb,{180,360}) then return end
    if not penetration or originalDamage < 1 then return end

    local item = charHealth.Character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes)

    if not item then return end
    if not validArmor[WR.id(item)] then return end

    local damage = (originalDamage / 2) * math.abs(penetration - 1) -- there is a damage reduction for humans atm so we divide to compensate
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

function WR.roundStartFunctions.clearIllegalItems()
    local crates = {chemicalcrate = true, metalcrate = true, mediccrate = true}
    local set = {exosuit = true, machinepistol = true}
    for i in Item.ItemList do
        if set[WR.id(i)] then
            print("Removed: ",i)
            WR.despawn(i)
        elseif crates[WR.id(i)] and not i.IsContained then -- oil rig has some deco crates that are inside shelfs
            print("Removed: ",i)
            WR.despawn(i)
        end
    end
end

function WR.spawnItemFunctions.WR_smg(item)
    if item.OwnInventory.IsEmpty() then
        WR.spawnItems({{id = "WR_smallroundmag20"}},item.OwnInventory)
    end
end

function WR.spawnItemFunctions.WR_smallroundmag20(item)
    if item.OwnInventory.IsEmpty() then
        WR.spawnItems({{id = "WR_smallround",count = 20}},item.OwnInventory)
    end
end

function WR.spawnItemFunctions.WR_machinegunmag(item)
    if item.OwnInventory.IsEmpty() then
        WR.spawnItems({{id = "WR_largeround",count = 50}},item.OwnInventory)
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
        count = 5,
        contents = {
            {
                id = "WR_largeround",
                count = 6
            }
        }}
    },
    WR_shotguncrate = {
        {id = "shotgun",
        count = 5,
        contents = {
            {
                id = "WR_shotgunround",
                count = 6
            }
        }}
    },
    WR_smgcrate = {
        {id = "WR_smg",
        count = 2}
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
        count = 60}
    },
    WR_shotgunammocrate = {
        {id = "WR_shotgunround",
        count = 60}
    },
    WR_smgammocrate = {
        {id = "WR_smallroundmag20",
        count = 4},
        {id = "WR_smallround",
        count = 80}
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
        {id = "WR_coalitionarmor",
        count = 2},
        {id = "WR_faceplate",
        count = 2}
    },
    WR_coalitiongasgrenadecrate = {
        {id = "chemgrenade",
        count = 6}
    },
    -- Coaltion crates end --
    -- Renegade crates start --
    WR_renegadeshellcrate = {
        {id = "flakcannonammoboxexplosive"}
    },
    WR_renegadebodyarmorcrate = {
        {id = "WR_renegadearmor",
        count = 2},
        {id = "WR_faceplate",
        count = 2}
    },
    -- Renegade crates end --
}

Hook.Add("WR.productionCrate.xmlhook", "WR.productionCrate", function(effect, deltaTime, item, targets, worldPosition, element)
    local list = WR.cratesLoadouts[WR.id(item)]
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

Hook.Add("character.giveJobItems", "WR.productionCrate", function(character, waypoint)
    Timer.Wait(function()
        if character.JobIdentifier == "coalitionteam" then
            character.GiveTalent("WR_coalitionrecipes",nil)
        elseif character.JobIdentifier == "renegadeteam" then
            character.GiveTalent("WR_renegaderecipes",nil)
        end
    end,1000)
end)

Hook.Add("WR.transmit.xmlhook", "WR.transmit", function(effect, deltaTime, item, targets, worldPosition, element)
    local pingEveryone = element.GetAttributeBool("global",false)
    local callerID = item.GetRootInventoryOwner().JobIdentifier.value
    local radioOwner = item.GetRootInventoryOwner()

    for radio in item.GetComponentString("WifiComponent").GetReceiversInRange() do
        if radio.Item.HasTag("mobileradio") then
            local owner = radio.Item.GetRootInventoryOwner()
            if pingEveryone and WR.id(owner) == "Human" and radioOwner ~= owner then
                WR.GiveAfflictionCharacter(owner,"WR_callsound",100)
            elseif not pingEveryone and WR.id(owner) == "human" and owner.JobIdentifier.value == callerID and owner ~= radio then
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
        WR.GiveAfflictionCharacter(owner.SelectedCharacter, "WR_stabilize", 100)
    end
end)

Hook.Add("WR.slowbody.xmlhook", "WR.slowbody", function(effect, deltaTime, item, targets, worldPosition, element)
    local divisor = element.GetAttributeFloat("factor",2)
    item.body.LinearVelocity = item.body.LinearVelocity / divisor
end)

function WR.roundStartFunctions.artilleryConstraints()
    WR.artilleryConstraints = WR.getLocations(function(item)
        return item.HasTag("wr_artillerynode")
    end)
    table.sort(WR.artilleryConstraints,function(p1,p2)
        return p1.WorldPosition.X < p2.WorldPosition.X
    end)
end

Hook.Add("WR.artillery.xmlhook", "WR.artillery", function(effect, deltaTime, item, targets, worldPosition, element)

    -- Constraints
    local pos = item.WorldPosition
    if #WR.artilleryConstraints >= 2 and (pos.X < WR.artilleryConstraints[1].WorldPosition.X or pos.X > WR.artilleryConstraints[#WR.artilleryConstraints].WorldPosition.X) then
        return
    end

    local prefab = ItemPrefab.GetItemPrefab(element.GetAttributeString("item","WR_shell"))
    local count = element.GetAttributeInt("count",5)
    local spacing = element.GetAttributeFloat("interval",1)

    for i=1,count do
        Timer.Wait(function()
            local random = element.GetAttributeFloat("dispersion",20) * (math.random() - 0.5)
            local position = WR.simPosToWorldPos(WR.raycast(item.SimPosition + Vector2(random,50),item.SimPosition + Vector2(random,-50),Physics.CollisionWall),item.Submarine ~= nil)
            WR.spawn(prefab,position,nil)
        end,(spacing + i) * 1000)
    end
end)

WR.radioChannels = {
    coalitionteam = 1,
    renegadeteam = 2,
    neutral = 0
}

function WR.thinkFunctions.setRadios()
    if WR.tick % 6 ~= 0 then return end

    for client in Client.ClientList do
        if client.Character then
            local channel = WR.radioChannels[client.Character.JobIdentifier.value]
            local items = {client.Character.GetEquippedItem("WR_radio"), client.Character.GetEquippedItem("WR_dogtag"), client.Character.GetEquippedItem("WR_largeradio")}
            for item in items do
                local wifi = item.GetComponentString("WifiComponent")
                wifi.Channel = channel

                local property = wifi.SerializableProperties[Identifier("Channel")]
                Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(property, wifi))
            end
        end
    end
end

WR.staticRadioAreas = {}

function WR.roundStartFunctions.staticRadioArea()
    WR.staticRadioAreas = {}

    local areas = WR.getAreas(function(item) return item.HasTag("wr_radioarea") or item.HasTag("wr_objective") end)
    for area in areas do
        WR.staticRadioAreas[area] = area.WorldRect
    end
end

function WR.radioAreas()
    local largeRadios = Util.GetItemsById("WR_largeradio") or {}

    local size = 500
    for item in largeRadios do
        WR.staticRadioAreas[item] = WR.staticRadioAreas[item] or Rectangle(0,0,size*2,size*2)
        WR.staticRadioAreas[item].X, WR.staticRadioAreas[item].Y = item.WorldPosition.X - size,item.WorldPosition.Y + size
    end
    return WR.staticRadioAreas
end

function WR.thinkFunctions.staticRadio()
    if WR.tick % 6 ~= 0 then return end
    local radioRects = WR.radioAreas()

    for client in Client.ClientList do
        if client.Character then
            local item = client.Character.GetEquippedItem("WR_dogtag")
            if item then
                item.Condition = 10
                for rect in radioRects do
                    if WR.isPointInRect(client.Character.WorldPosition,rect) then
                        item.Condition = 100
                        break
                    end
                end
            end
        end
    end
end

do

local hitsThisTick = {}

Hook.Add("WR.flameprojectiledamage.xmlhook", "WR.flameprojectiledamage", function(effect, deltaTime, item, targets, worldPosition, element)
    if not targets[1] then return end
    for char in targets do
        if (hitsThisTick[char] == nil or hitsThisTick[char] < 5) and not WR.raycast(item.SimPosition,char.SimPosition,Physics.CollisionWall) then -- ray hits nothing
            local damage = element.GetAttributeFloat("damage",25/5)
            WR.GiveAfflictionCharacter(char,"burn",damage*deltaTime)
            WR.GiveAfflictionCharacter(char,"slow",50/5*deltaTime)
            WR.GiveAfflictionCharacter(char,"WR_suppression",10/5*deltaTime)

            hitsThisTick[char] = (hitsThisTick[char] or 0) + 1
        end
    end
end)

function WR.thinkFunctions.resetBurnedChars()
    hitsThisTick = {}
end

end

WR.officerBuffedChars = {}

do
    local set = {
        WR_coalitioncomhat = true,
        WR_renegadecomhat = true
    }

    function WR.thinkFunctions.commanderBuff()
        if WR.tick % 15 ~= 0 then return end
        local officers = {}
        local soldiers = {}

        for char in Character.CharacterList do
            local item = char.Inventory.GetItemInLimbSlot(InvSlotType.Head)
            if char.IsHuman and not char.IsDead and not char.IsUnconscious then
                if item and set[WR.id(item)] then
                    officers[char] = true
                else
                    soldiers[char] = true
                end
            end
        end

        if WR.tableSize(officers) <= 0 then
            WR.officerBuffedChars = {}
            return
        end

        for officer in pairs(officers) do
            WR.officerBuffedChars[officer] = nil
            for char in pairs(soldiers) do
                if Vector2.Distance(officer.WorldPosition,char.WorldPosition) < 750 and not WR.enemy(WR.id(officer,{"Info","Job"}),WR.id(char,{"Info","Job"})) then
                    soldiers[char] = nil
                    WR.officerBuffedChars[char] = true
                else
                    WR.officerBuffedChars[char] = nil
                end
            end
        end
    end

    function WR.thinkFunctions.buffChars()
        if WR.tick % 10 ~= 0 then return end

        for char in Character.CharacterList do
            if WR.officerBuffedChars[char] then
                local affliction = char.CharacterHealth.GetAffliction("haste")
                if affliction then
                    affliction.SetStrength(400)
                else
                    WR.GiveAfflictionCharacter(char,"haste",400)
                end
            else
                local affliction = char.CharacterHealth.GetAffliction("haste")
                if affliction then affliction.SetStrength(0) end
            end
        end
    end
end