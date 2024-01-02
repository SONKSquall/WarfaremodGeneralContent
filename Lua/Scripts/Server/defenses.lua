if Game.IsMultiplayer and CLIENT then return end

local spamdelay = 30
local spamtick = spamdelay

Hook.add("think", "WR.antidefensespam", function()
    spamtick = spamtick-1

    if spamtick <= 0 then

        spamtick = spamdelay

        local defenseprefabs = WR.GetPrefabsByTag("WR_spamable")

        for prefab in defenseprefabs do
            local defenses = WR.GetItemsById(prefab.Identifier)
            for key,item in pairs(defenses) do
                for relativeitem in defenses do
                    if item.ID ~= relativeitem.ID then
                        local offset = item.WorldPosition - relativeitem.WorldPosition

                        if (math.abs(offset.X) <= 200 and math.abs(offset.Y) <= 200) then
                            local defense = WR.FindItemBigField(item,relativeitem,"SpawnTime")
                            local defenseprefab = ItemPrefab.GetItemPrefab(tostring(defense.Prefab.Identifier) .. "_setup")

                            Entity.Spawner.AddItemToSpawnQueue(defenseprefab, defense.WorldPosition, nil, nil, nil)
                            Entity.Spawner.AddItemToRemoveQueue(defense)

                            table.remove(defenses,key)
                        end
                    end
                end
            end
        end
    end
end)