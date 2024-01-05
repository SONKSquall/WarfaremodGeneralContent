if Game.IsMultiplayer and CLIENT then return end

Hook.Add("afflictionUpdate", "WR.unconsciousbreathing", function(affliction, characterHealth, limb)

    if affliction.Identifier ~= "oxygenlow" then return end

    local canbreathe = true

    if characterHealth.character.HullOxygenPercentage <= 30 then
        canbreathe = false
    end

    if canbreathe and characterHealth.character.IsUnconscious then
        affliction.SetStrength(affliction.Strength + (-1 * WR.DeltaTime))
        -- gives cardiac arrest if not already
        if not characterHealth.GetAffliction("WR_cardiacarrest", false) then
            WR.GiveAfflictionCharacter(characterHealth.Character, "WR_cardiacarrest", 1.1)
        end
    else
        return
    end

end)

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

Hook.Patch("Barotrauma.Character", "ServerEventRead", function(instance)
    local cardiacarrest = instance.CharacterHealth.GetAffliction("WR_cardiacarrest", false)
    local client

    for k,v in pairs(Client.ClientList) do
        if v.character == instance then
            client = v
        end
    end

    if not client then return end
    if not cardiacarrest then ignorekill = true return end

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