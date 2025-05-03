if CLIENT then return end

-- generic hooks
WR.roundStartFunctions = {}
WR.thinkFunctions = {}
WR.roundEndFunctions = {}

-- character hooks
WR.characterDeathFunctions = {}
WR.characterDamageFunctions = {}
WR.characterCreateFunctions = {}

-- item hooks
WR.pointItemFunctions = {}
WR.useItemFunctions = {}

WR.equipItemFunctions = {}
WR.unequipItemFunctions = {}

WR.spawnItemFunctions = {}
WR.removeItemFunctions = {}
WR.deconItemFunctions = {}



Hook.add("roundStart", "WR.GameStart", function()

    Submarine.LockX = true
    Submarine.LockY = true
    for func in WR.roundStartFunctions do
        func()
    end
    for obj in WR.extensions do
        obj:Start()
    end

end)

Hook.add("roundEnd", "WR.GameEnd", function()

    for func in WR.roundEndFunctions do
        func()
    end

end)

Hook.add("think", "WR.think", function()

    if not Game.RoundStarted or WR.Game.ending then return end

    WR.tick = WR.tick+1

    for func in WR.thinkFunctions do
        func()
    end
end)

Hook.add("character.death", "WR.Death", function(char)
    if WR.Game.ending then return end

    for func in WR.characterDeathFunctions do
        func(char)
    end

end)

do

local addtionalArgs = {}

Hook.add("character.applyDamage", "WR.Damage", function(charHealth, attackResult, hitLimb)
    if WR.Game.ending then return end

    for func in WR.characterDamageFunctions do
        func(charHealth, attackResult, hitLimb, table.unpack(addtionalArgs))
    end

end)

Hook.add("character.damageLimb", "WR.Damage", function(character, worldPosition, hitLimb, afflictions, stun, playSound, attackImpulse, attacker, damageMultiplier, allowingStacking, penetration, shouldImplode)
    local damage = 0
    for a in afflictions do
        damage = damage + a.GetVitalityDecrease(character.CharacterHealth)
    end
    damage = damage * damageMultiplier
    addtionalArgs = {worldPosition,attacker,damage,penetration}
end)

end


Hook.add("character.created", "WR.Spawn", function(char)
    if WR.Game.ending then return end

    for func in WR.characterCreateFunctions do
        func(char)
    end

end)



Hook.Add("item.secondaryUse", "WR.pointItem", function(item, itemUser)
    if WR.pointItemFunctions[item.Prefab.Identifier.value] then
        WR.pointItemFunctions[item.Prefab.Identifier.value](item, itemUser)
    end
end)

Hook.Add("item.use", "WR.useItem", function(item, itemUser, targetLimb)
    if WR.useItemFunctions[item.Prefab.Identifier.value] then
        WR.useItemFunctions[item.Prefab.Identifier.value](item, itemUser, targetLimb)
    end
end)

Hook.Add("item.equip", "WR.equip", function(item, itemUser)
    if WR.equipItemFunctions[item.Prefab.Identifier.value] then
        WR.equipItemFunctions[item.Prefab.Identifier.value](item, itemUser)
    end
end)

Hook.Add("item.created", "WR.itemSpawn", function(item)
    if WR.spawnItemFunctions[item.Prefab.Identifier.value] then
        WR.spawnItemFunctions[item.Prefab.Identifier.value](item)
    end
end)

Hook.Add("item.removed", "WR.itemRemove", function(item)
    if WR.removeItemFunctions[item.Prefab.Identifier.value] then
        WR.removeItemFunctions[item.Prefab.Identifier.value](item)
    end
end)

Hook.Add("item.deconstructed", "WR.itemDecon", function(item, otherItem, userCharacter)
    if WR.deconItemFunctions[item.Prefab.Identifier.value] then
        WR.deconItemFunctions[item.Prefab.Identifier.value](item, otherItem, userCharacter)
    end
end)

Hook.Add("item.unequip", "WR.itemUnequip", function(item, character)
    if WR.unequipItemFunctions[item.Prefab.Identifier.value] then
        WR.unequipItemFunctions[item.Prefab.Identifier.value](item, character)
    end
end)