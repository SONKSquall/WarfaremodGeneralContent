if Game.IsMultiplayer and CLIENT then return end

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.CharacterHealth"], "oxygenLowAffliction")

Hook.Patch("Barotrauma.CharacterHealth", "UpdateOxygen", function(instance, ptable)

    ptable.PreventExecution = true

    if not instance.Character.NeedsOxygen then
        instance.oxygenLowAffliction.Strength = 0
    end

    local oxygenlowResistance = instance.GetResistance(instance.oxygenLowAffliction.Prefab, LimbType.None)

    local decreaseSpeed = -5.0 * (1 - oxygenlowResistance)
    local increaseSpeed = 10.0 * (1 + oxygenlowResistance)

    if (instance.Character.OxygenAvailable > instance.InsufficientOxygenThreshold) then
        if instance.IsUnconscious then
            instance.ApplyAffliction(instance.Character.AnimController.MainLimb, AfflictionPrefab.Prefabs["WR_cardiacarrest"].Instantiate(1 * ptable["deltaTime"]))
            instance.OxygenAmount = math.clamp(instance.OxygenAmount + ptable["deltaTime"] * increaseSpeed, -100, 100)
        else
            instance.OxygenAmount = math.clamp(instance.OxygenAmount + ptable["deltaTime"] * increaseSpeed, -100, 100)
        end
    else
        instance.OxygenAmount = math.clamp(instance.OxygenAmount + ptable["deltaTime"] * decreaseSpeed, -100, 100)
    end

end, Hook.HookMethodType.Before)

Hook.Add("human.CPRSuccess", "WR.cardiacarrestcprreductionhighskill", function(animController)

    local medic = animController.Character
    local medicskill = math.ceil(medic.GetSkillLevel("Medical")+0.5)
    local patient = animController.Character.SelectedCharacter
    local cardiacarrest = patient.CharacterHealth.GetAffliction("WR_cardiacarrest", false)
    if not cardiacarrest then return end

    cardiacarrest.SetStrength(cardiacarrest.Strength -0.9*WR.InvLerp(medicskill,0,100))

end)

Hook.Add("human.CPRFailed", "WR.cardiacarrestcprreduction", function(animController)

    local medic = animController.Character
    local medicskill = math.ceil(medic.GetSkillLevel("Medical")+0.5)
    local patient = animController.Character.SelectedCharacter
    local cardiacarrest = patient.CharacterHealth.GetAffliction("WR_cardiacarrest", false)
    if not cardiacarrest then return end

    cardiacarrest.SetStrength(cardiacarrest.Strength -0.5*WR.InvLerp(medicskill,0,100))

end)

-- modified code from the no give in mod

local ignorekill = false

Hook.Patch("Barotrauma.Character", "ServerEventRead", function(instance, ptable)
    -- if the event is not for the give in button then return
    if ptable["msg"].PeekByte() ~= 2 then return end

    local cardiacarrest = instance.CharacterHealth.GetAffliction("WR_cardiacarrest", false)
    local client = ptable["c"]

    if not client then return end
    if not cardiacarrest then ignorekill = true return end
    if instance.IsDead then return end
    if not instance.IsUnconscious then return end

    if cardiacarrest.Strength < 60 then
        ignorekill = true
        local s = "You may not give in. Please wait: " .. math.ceil(60-cardiacarrest.Strength) .. " Seconds."
        WR.SendMessagetoClient(s,client)
    end
end, Hook.HookMethodType.Before)

Hook.Patch("Barotrauma.Character", "ServerEventRead", function()
   ignorekill = false
end, Hook.HookMethodType.After)

Hook.Patch("Barotrauma.Character", "Kill", function(instance, ptable)
   if ignorekill then
       ptable.PreventExecution = true
   end
end, Hook.HookMethodType.Before)