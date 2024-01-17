function WR.GetPrefabsByTag(tag)
    local prefabs = {}

    for prefab in ItemPrefab.Prefabs do
        for fabtag in prefab.Tags do
            if fabtag == tag then table.insert(prefabs,prefab) break end
        end
    end

    return prefabs
end

function WR.GetItemsById(id)
    local items = {}

    for k,v in pairs(Item.ItemList) do
        if tostring(v.Prefab.Identifier) == id then table.insert(items, v) end
    end

    return items
end

function WR.FindItemBigField(item1,item2,field)
    if item1[field] > item2[field] then
        return item1
    else
        return item2
    end
end

function WR.Lerp (n, a, b)
    return a*(1-n) + b*n
end

function WR.InvLerp (n, a, b)
    return (n-a)/(b-a)
end

function WR.IsEnemyPOW(character, TeamIdentifier)
    if character.isHuman == true
    and character.IsDead == false
    and character.JobIdentifier ~= TeamIdentifier
    and character.LockHands == true
    then
        return true
    else
        return false
    end
end
--[[ unused functions
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
]]
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

--[[
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
--]]

function WR.NumberToEqualize(number1, number2)

    if number1 == number2 then return 0 end

    local result = 0

    if number1 > number2 then
        number1 = number1 - number2
        result = number1/2
    elseif number2 > number1 then
        number2 = number2 - number1
        result = number2/2
    end

    return result
end

function WR.CreateDefaultMessageFormat()
    local format = {}
    format.type = ChatMessageType.ServerMessageBox
    format.color = Color(255, 255, 0, 255)
    format.sender = "Server"
    return format
end

function WR.RepairMessageFormat(format)
    local defaultformat = WR.CreateDefaultMessageFormat()

    if format.type == nil then format.type = defaultformat.type end
    if format.color == nil then format.color = defaultformat.color end
    if format.sender == nil then format.sender = defaultformat.sender end

    return format
end

function WR.SendMessageToAllClients(messagestring,format)
    if not format then
        format = WR.CreateDefaultMessageFormat()
    else
        format = WR.RepairMessageFormat(format)
    end
    for key,client in pairs(Client.ClientList) do
        local chatMessage = ChatMessage.Create(format.sender, messagestring, format.type, nil, nil)
        chatMessage.Color = format.color
        Game.SendDirectChatMessage(chatMessage, client)
    end
end

function WR.SendMessagetoClient(messagestring,client,format)
    if not format then
        format = WR.CreateDefaultMessageFormat()
    else
        format = WR.RepairMessageFormat(format)
    end

    local chatMessage = ChatMessage.Create(format.sender, messagestring, format.type, nil, nil)
    chatMessage.Color = format.color
    Game.SendDirectChatMessage(chatMessage, client)
end

function WR.FormatTime(secs)
    local mins = math.floor(secs/60)
    local hours = math.floor(mins/60)
    secs = math.floor(secs - mins * 60 + 0.5)
    mins = mins - hours * 60

    local text = ""
    if hours > 0 then
        text = text .. tostring(hours) .. " hours"
    end
    if mins > 0 then
        text = text .. " " .. tostring(mins) .. " minutes"
    end
    if secs > 0 then
        text = text .. " " .. tostring(secs) .. " seconds"
    end
    if text == "" then text = "seconds: 0" end
    return text

end

-- written by Sharp-Shark
function WR.GiveAfflictionCharacter (character, identifier, amount)
    character.CharacterHealth.ApplyAffliction(character.AnimController.MainLimb, AfflictionPrefab.Prefabs[identifier].Instantiate(amount))
end