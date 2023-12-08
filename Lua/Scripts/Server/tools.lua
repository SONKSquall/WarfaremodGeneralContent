if Game.IsMultiplayer and CLIENT then return end

Hook.Add("WR.minedetector.xmlhook", "WR.minedetector", function(effect, deltaTime, item, targets, worldPosition)
    for value in targets do
        if not Util.GetItemsById("WR_landmine") then return end -- if theres no landmines then return
        for landmine in Util.GetItemsById("WR_landmine") do
            if value == landmine then
                local light = value.GetComponentString("LightComponent")
                light.IsOn = true

                -- networking
                local property = light.SerializableProperties[Identifier("IsOn")]
                Networking.CreateEntityEvent(value, Item.ChangePropertyEventData(property, light))

                break
            end
        end
    end
end)