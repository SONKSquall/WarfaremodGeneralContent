if Game.IsMultiplayer and CLIENT then return end

WR.pointItemFunctions = {}
WR.useItemFunctions = {}
WR.equipItemFunctions = {}

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

function WR.equipItemFunctions.WR_whistle(item, itemUser)

    local hat = itemUser.Inventory.GetItemInLimbSlot(InvSlotType.Head)

    if not hat then
        item.Condition = 0
        item.DescriptionTag = "(Can not use right now, please reequip with commander headgear) Small metal whistle, used for issuing offensive orders."
        return
    end
    if not hat.HasTag("command") then
        item.Condition = 0
        item.DescriptionTag = "(Can not use right now, please reequip with commander headgear) Small metal whistle, used for issuing offensive orders."
        return
    end

    item.Condition = item.MaxCondition
    item.DescriptionTag = "Small metal whistle, used for issuing offensive orders."

end

Hook.Add("item.secondaryUse", "WR.pointItem", function(item, itemUser)
    if WR.pointItemFunctions[item.Prefab.Identifier.value] then
        WR.pointItemFunctions[item.Prefab.Identifier.value](item, itemUser)
    end
end)

Hook.Add("item.use", "WR.useItem", function(item, itemUser)
    if WR.useItemFunctions[item.Prefab.Identifier.value] then
        WR.useItemFunctions[item.Prefab.Identifier.value](item, itemUser)
    end
end)

Hook.Add("item.equip", "WR.equip", function(item, itemUser)
    if WR.equipItemFunctions[item.Prefab.Identifier.value] then
        WR.equipItemFunctions[item.Prefab.Identifier.value](item, itemUser)
    end
end)