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

WR.reloadingGuns = {}

function WR.reload(gun,ammo,characterUser)
	if not characterUser or not gun or not characterUser then return end

    local ammoId = ammo.Prefab.Identifier.value
    local gunId = gun.Prefab.Identifier.value

    local isInfantry = false
    local item = characterUser.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes)
    if item then
        isInfantry = item.Prefab.Identifier.value == "WR_coalitiongear" or item.Prefab.Identifier.value == "WR_renegadegear"
    end

    local weapons = {
        rifle = {
            type = "round",
            ammo = {
                riflebullet = 5/6,
                WR_largeround = 5/6,
                ["40mmchemgrenade"] = 3
            }
        },
        WR_basicrifle = {
            type = "round",
            ammo = {
                riflebullet = 3.5/6,
                WR_largeround = 3.5/6
            }
        },
        shotgun = {
            type = "round",
            noSlowDown = true,
            ammo = {
                shotgunshell = 3/6,
                WR_shotgunround = 3/6
            }
        },
        revolver = {
            type = "round",
            ammo = {
                revolverround = 4/6,
                WR_smallround = 4/6
            }
        },
        WR_basicpistol = {
            type = "round",
            ammo = {
                revolverround = 4/6,
                WR_smallround = 4/6
            }
        },
        smg = {
            type = "mag",
            noSlowDown = true,
            ammo = {smgmagazine = 4}
        },
        WR_smg = {
            type = "mag",
            noSlowDown = true,
            ammo = {WR_smallroundmag20 = 4}
        },
        hmg = {
            type = "mag",
            ammo = {hmgmagazine = 6}
        },
        WR_basicmachinegun = {
            type = "mag",
            ammo = {WR_machinegunmag = 6}
        },
    }

    local reloadTime = weapons[gunId] and weapons[gunId].ammo[ammoId]
    --local type = weapons[gunId] and weapons[gunId].type
    local slowDown = weapons[gunId] and not weapons[gunId].noSlowDown

    if reloadTime then
        WR.reloadingGuns[gun.ID] = WR.reloadingGuns[gun.ID] or Timer.GetTime()

        if isInfantry then
            reloadTime = reloadTime / 1.25
        end

        if slowDown then
            WR.GiveAfflictionCharacter(characterUser,"WR_reload",reloadTime)
        end
        gun.Condition = 0

        WR.reloadingGuns[gun.ID] = WR.reloadingGuns[gun.ID] + reloadTime

        local function endReload()
            Timer.Wait(function()
                if not WR.reloadingGuns[gun.ID] then return end
                if WR.reloadingGuns[gun.ID] - Timer.GetTime() > 0.1 then endReload() return end
                gun.Condition = gun.MaxCondition
                WR.reloadingGuns[gun.ID] = nil
            end,(WR.reloadingGuns[gun.ID] - Timer.GetTime()) * 1000)
        end
        Timer.NextFrame(endReload)
    end
end

Hook.Add("inventoryPutItem", "WR.reloadTime", function (inventory, item, characterUser, index, removeItemBool)
    WR.reload(inventory.owner,item,characterUser)
end)

Hook.Add("item.combine", "WR.reloadTimeCombineFix", function (item, deconstructor, characterUser, allowRemove)
    WR.reload(item.RootContainer,item,characterUser)
end)

Hook.Add("WR.suppresion.xmlhook", "WR.suppression", function(effect, deltaTime, item, targets, worldPosition, element)

    local range = element.GetAttributeFloat("range",500)
    local strength = element.GetAttributeFloat("strength",1)
    local user = targets[1]

    for char in Character.CharacterList do
        local distance = Vector2.Distance(char.WorldPosition,item.WorldPosition)
        if distance < range and char ~= user then
            local amount = WR.Lerp(WR.InvLerp(distance,range,0),0,strength)
            WR.GiveAfflictionCharacter(char,"WR_suppression",amount)
        end
    end
end)