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

Hook.Add("WR.removecardiacarrest.xmlhook", "WR.removecardiacarrest", function(effect, deltaTime, item, character, worldPosition)

    character[1].CharacterHealth.GetAffliction("WR_cardiacarrest", false).SetStrength(0.5)

end)