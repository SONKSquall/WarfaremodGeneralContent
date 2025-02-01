if Game.IsMultiplayer and CLIENT then return end
-- now using a affliction based system for recoil
--[[
local playerrecoil = {}
Hook.Add("WR.gunrecoilgain.xmlhook", "WR.gunrecoilgain", function(effect, deltaTime, item, targets, worldPosition)
    if item.HasTag("gun") then
        -- failsafe incase theres no value for the recoil yet
        playerrecoil[item.ParentInventory] = playerrecoil[item.ParentInventory] or 1
        local id = tostring(item.Prefab.Identifier)
        local spreadpershot = WR.Config.WeaponRecoil[id].spreadpershot
        local maxspread = WR.Config.WeaponRecoil[id].maxspread
        local minspread = WR.Config.WeaponRecoil[id].minspread
        local rangedweapon = item.GetComponentString("RangedWeapon")

        playerrecoil[item.ParentInventory] = math.min(1, WR.InvLerp(WR.Lerp(playerrecoil[item.ParentInventory], minspread, maxspread) + spreadpershot, minspread, maxspread))

        rangedweapon.Spread = math.max(maxspread * playerrecoil[item.ParentInventory], minspread)
    end
end)

Hook.Add("item.equip", "WR.gunrecoilgainfromequip", function (item, character)
    if character == nil then return end

    playerrecoil[character.Inventory] = 1
end)

local networkingdelay = 30
local networkingtick = networkingdelay

Hook.add("think", "WR.gunrecoillose", function()

    for key,character in pairs(Character.CharacterList) do
        for item in character.HeldItems do
            -- the id for objects in the json config is the identifier of the item in question
            local id = tostring(item.Prefab.Identifier)
            -- if the item has a object in the json then execute       
            if item.HasTag("gun") and WR.Config.WeaponRecoil[id] then
                local movement = character.CurrentSpeed
                local movementmodifier = WR.Config.WeaponRecoil[id].movementspreadmodifier
                local suppression = character.CharacterHealth.GetAfflictionStrengthByIdentifier("WR_suppression", false)
                -- make sure that this modifier stays below 3
                local reductionmodifier = math.max(1, math.min(1 + (WR.InvLerp(movement*movementmodifier, 0, 3) + WR.InvLerp(suppression, 5, 10)), 3))

                playerrecoil[character.Inventory] = playerrecoil[character.Inventory] or 1
                local maxspread = WR.Config.WeaponRecoil[id].maxspread
                local minspread = WR.Config.WeaponRecoil[id].minspread
                local spreadloss = WR.Config.WeaponRecoil[id].spreaddecreasepersecond
                local rangedweapon = item.GetComponentString("RangedWeapon")

                playerrecoil[character.Inventory] = math.max(0, WR.InvLerp(WR.Lerp(playerrecoil[character.Inventory], minspread, maxspread) - (spreadloss*WR.DeltaTime) / reductionmodifier, minspread, maxspread))

                rangedweapon.Spread = math.max(maxspread * playerrecoil[item.ParentInventory], minspread*reductionmodifier) -- minspread is multiplied here so spread is slightly worse when suppressed or moving
            end
        end
    end

    -- networking
    if networkingtick >= 1 then
        networkingtick=networkingtick-1
        return
    else
        networkingtick=networkingdelay
    end

    for key,client in pairs(Client.ClientList) do
        local message = Networking.Start("updaterecoil")
        if client.Character and playerrecoil[client.Character.Inventory] then
            message.WriteDouble(playerrecoil[client.Character.Inventory])
            message.WriteDouble(key)
            Networking.Send(message, client.Connection)
        end
    end

end)
]]
Hook.Add("baton_attack", "WR_BatonImpact", function(effect, deltaTime, item, targets, worldPosition)
    local limb = targets[1]
    local character = limb.character
    local blunttrauma = AfflictionPrefab.Prefabs["blunttrauma"]
    local stun = AfflictionPrefab.Prefabs["incrementalstun"]
    -- Applies stun if the target is handcuffed, otherwise it will apply damage
    if character.LockHands == true then
        local AttackResult = limb.AddDamage(limb.SimPosition, {stun.Instantiate(40)}, true, 1, 0, nil)
        limb.character.CharacterHealth.ApplyDamage(limb, AttackResult, true)
    else
        local AttackResult = limb.AddDamage(limb.SimPosition, {blunttrauma.Instantiate(70)}, true, 1, 0.33, nil)
        limb.character.CharacterHealth.ApplyDamage(limb, AttackResult, true)
    end
end)

function WR.reload(gun,ammo,characterUser)
	if characterUser == nil or gun == nil or characterUser == nil then return end

    local reloadTimes = {
        rifle = 5/6,
        shotgun = 4.5/6,
        revolver = 4/6,
        WR_basicpistol = 4/6,
        smg = 4,
        hmg = 6
    }

    local ammoTypes = {
        riflebullet = "round",
        shotgunshell = "round",
        revolverround = "round",
        smgmagazine = "mag",
        hmgmagazine = "mag"
    }

    local reloadTime = reloadTimes[gun.Prefab.Identifier.value]
    local ammoType = ammoTypes[ammo.Prefab.Identifier.value]

    if ammoType and reloadTime and ((characterUser.CharacterHealth.GetAffliction('WR_reload', true) == nil) or ammoType == "round") then
        local rig = characterUser.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes)
        -- infantry have faster reload
        if rig and (rig.Prefab.Identifier.value == "WR_coalitiongear" or "WR_renegadegear") then
            reloadTime = reloadTime / 1.25
        end

        WR.GiveAfflictionCharacter(characterUser,"WR_reload",reloadTime)
        gun.Condition = 0

        -- did not want to coordinate a function taking in to account bullets loaded or store data
        Timer.NextFrame(function()
            local endTime = math.ceil(characterUser.CharacterHealth.GetAffliction("WR_reload", true).Strength * 1000)
            Timer.Wait(function()
                gun.Condition = gun.MaxCondition
            end,endTime)
        end)
    end
end

Hook.Add("inventoryPutItem", "WR.reloadTime", function (inventory, item, characterUser, index, removeItemBool)
    WR.reload(inventory.owner,item,characterUser)
end)

Hook.Add("item.combine", "WR.reloadTimeCombineFix", function (item, deconstructor, characterUser, allowRemove)
    WR.reload(item.RootContainer,item,characterUser)
end)