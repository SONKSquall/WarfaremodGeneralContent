if Game.IsMultiplayer and CLIENT then return end

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

local playerrecoil = {}

Hook.Add("WR.gunrecoilgain.xmlhook", "WR.gunrecoilgain", function(effect, deltaTime, item, targets, worldPosition)
    if item.HasTag("gun") then
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

local recoiltimerdelay = 15
local recoiltimertick = 15

Hook.add("think", "WR.gunrecoillose", function()

    recoiltimertick = recoiltimertick - 1

    if recoiltimertick > 0 then return elseif recoiltimertick <= 0 then recoiltimertick = recoiltimerdelay end

    for key,character in pairs(Character.CharacterList) do
        for item in character.HeldItems do
            -- the id for objects in the json config is the identifier of the item in question
            local id = tostring(item.Prefab.Identifier)
            if item.HasTag("gun") and WR.Config.WeaponRecoil[id] then
                playerrecoil[character.Inventory] = playerrecoil[character.Inventory] or 1
                local maxspread = WR.Config.WeaponRecoil[id].maxspread
                local minspread = WR.Config.WeaponRecoil[id].minspread
                local spreadloss = WR.Config.WeaponRecoil[id].spreaddecreasepersecond
                local rangedweapon = item.GetComponentString("RangedWeapon")

                playerrecoil[character.Inventory] = math.max(0, WR.InvLerp(WR.Lerp(playerrecoil[character.Inventory], minspread, maxspread) - spreadloss * WR.DeltaTime * recoiltimerdelay, minspread, maxspread))

                rangedweapon.Spread = math.max(maxspread * playerrecoil[item.ParentInventory], minspread)
            end
        end
    end
end)