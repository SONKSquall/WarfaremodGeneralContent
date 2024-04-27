if Game.IsMultiplayer and CLIENT then return end

local spamdelay = 30
local spamtick = spamdelay

Hook.add("think", "WR.antispam", function()
    spamtick = spamtick-1

    if spamtick <= 0 then

        spamtick = spamdelay

        local spamitems = WR.GetPrefabsByTag("WR_spamable")

        for prefab in spamitems do
            local worlditems = WR.GetItemsById(prefab.Identifier)
            for key,item in pairs(worlditems) do
                -- compares itself with all other items of the same identifier
                for relativeitem in worlditems do
                    if item.ID ~= relativeitem.ID then
                        local offset = item.WorldPosition - relativeitem.WorldPosition

                        if (math.abs(offset.X) <= 200 and math.abs(offset.Y) <= 200) then
                            -- the item with the higher spawn time gets despawned (higher spawntimes = newer)
                            local itemtoremove = WR.FindItemBigField(item,relativeitem,"SpawnTime")
                            local replacementitemID = WR.getStringVariables(item.Tags)["replacementitemid"]

                            if replacementitemID then
                                local replacementitemprefab = ItemPrefab.GetItemPrefab(tostring(replacementitemID))
                                Entity.Spawner.AddItemToSpawnQueue(replacementitemprefab, itemtoremove.WorldPosition, nil, nil, nil)
                            end
                            Entity.Spawner.AddItemToRemoveQueue(itemtoremove)

                            -- prevents dupes
                            table.remove(worlditems,key)
                        end
                    end
                end
            end
        end
    end
end)