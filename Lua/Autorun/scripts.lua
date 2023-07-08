if CLIENT then return end -- stops this from running on the client

Hook.Add("baton_attack", "batonhit", function(effect, deltaTime, item, targets, worldPosition)
    local limb = targets[1]
    local character = limb.character
    local blunttrauma = AfflictionPrefab.Prefabs["blunttrauma"]
    local stun = AfflictionPrefab.Prefabs["incrementalstun"]
    -- TODO: make this use damagemodifiers
    if character.LockHands == true then
        limb.character.CharacterHealth.ApplyAffliction(limb, stun.Instantiate(40))
    else
        limb.character.CharacterHealth.ApplyAffliction(limb, blunttrauma.Instantiate(30))
    end
end)