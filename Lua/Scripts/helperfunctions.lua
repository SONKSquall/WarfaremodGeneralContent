if Game.IsMultiplayer and CLIENT then return end

function WR.IsEnemyPOW(character, FriendlyTeam)
    if character.isHuman == true
    and character.IsDead == false
    and character.JobIdentifier ~= FriendlyTeam
    and character.LockHands == true
    then
        return true
    else
        return false
    end
end

function WR.TableFindBool(table, findval)
    for value in table do
        if value == findval then
            return true
        end
    end
    return false
end

function WR.StringFindBool(string, findstring)
    if string.find(string, "findstring") ~= nil then
        return true
    else
        return false
    end
end

-- Thanks Mellon <3
function WR.SpawnInventoryItems(Items, TargetInventory)
    for Item in Items do
        local ItemPrefab = Item.Prefab
        local ItemInventory = Item.OwnInventory
        -- Spawn items inside inventory of its container
        Entity.Spawner.AddItemToSpawnQueue(ItemPrefab, TargetInventory, nil, nil, function(WorldItem)
            -- Spawn item inside other items
            if ItemInventory ~= nil then
                ItemsInInventory = Item.OwnInventory.FindAllItems(predicate, false, list)
                WR.SpawnInventoryItems(ItemsInInventory, WorldItem.OwnInventory)
            end
        end)
    end
end

function WR.IsValidPlayer(player)
    
    if player == nil then return false end

    if player.InGame and not player.SpectateOnly then
       return true
    else
       return false
    end

end

function WR.GetPointers(valuetable, pointertable, field)
    
    local pointers = {}

    for key,value in pairs(valuetable) do
        for key,pointer in pairs(pointertable) do
            if value.field == pointer.field then
                table.insert(pointers, #pointers+1)
                break
            end
        end
    end

    return pointers

end

function WR.GetDifference(number1, number2)

    if number1 == number2 then return 0 end

    local result = 0

    if number1 > number2 then
        result = math.abs(number2 - number1)
    elseif number2 > number1 then
        result = math.abs(number1 - number2)
    end

    return result

end