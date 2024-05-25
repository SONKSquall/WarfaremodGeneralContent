function WR.GetPrefabsByTag(tag)
    local prefabs = {}

    for prefab in ItemPrefab.Prefabs do
        for fabtag in prefab.Tags do
            if fabtag == tag then table.insert(prefabs,prefab) break end
        end
    end

    return prefabs
end

function WR.GetItemsByTag(searchTag)
    local items = {}

    for item in Item.ItemList do
        for tag in item.GetTags() do
            if tag == searchTag then table.insert(items,item) break end
        end
    end

    return items
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
    if text == "" then text = "0 seconds" end
    return text

end

-- written by Sharp-Shark
function WR.GiveAfflictionCharacter (character, identifier, amount)
    character.CharacterHealth.ApplyAffliction(character.AnimController.MainLimb, AfflictionPrefab.Prefabs[identifier].Instantiate(amount))
end

function WR.ConcatTables(a, b)

    for key,value in pairs(b) do
        a[#a+1] = b[#b]
        table.remove(b, #b)
    end

    return a
end

function WR.GivePreferedJob(client)

    if not client.PreferredJob then return end
    client.AssignedJob = JobVariant(JobPrefab.Get(client.PreferredJob), 0)

end

function WR.GetDeadPlayers()

    local players = {}

    for key,player in pairs(Client.ClientList) do
        if (not player.Character and not player.SpectateOnly) or player.Character.IsDead then
            players[#players+1] = player
        end
    end

    return players
end

function WR.TableSize(t)
    local size = 1
    for k in pairs(t) do size = size + 1 end
    return size
end

-- set magic
WR.Set = {}
WR.Set.mt = {}

function WR.Set.new(t)
    local set = {}
    setmetatable(set, WR.Set.mt)
    for _, l in pairs(t) do set[l] = true end
    return set
end

function WR.Set.union(a,b)
    local res = WR.Set.new{}
    for k in pairs(a) do res[k] = true end
    for k in pairs(b) do res[k] = true end
    return res
end

function WR.Set.intersection(a,b)
    local res = WR.Set.new{}
    for k in pairs(a) do
      res[k] = b[k]
    end
    return res
end

function WR.Set.sub(a,b)
    for k in pairs(a) do
        if a[k] == b[k] then a[k] = nil end
    end
    return a
end

function WR.Set.tostring(set)
    local s = "{"
    local sep = ""
    for e in pairs(set) do
      s = s .. sep .. tostring(e)
      sep = ", "
    end
    return s .. "}"
end

WR.Set.mt.__tostring = WR.Set.tostring

function WR.stringSplit(s,sep)
    local tbl = {}

    if not sep then
        sep = ","
    end

    for v in string.gmatch(s, '([^'..sep..']+)') do
        table.insert(tbl,v)
    end

    return WR.Set.new(tbl)
end

function WR.stringKeyVar(s)
    if type(s) ~= "string" then return nil end

    local _, _, key, value = string.find(s, "(.+):(.+)")

    if key and value then
        return key, value
    else
        return nil
    end

end

function WR.getStringVariables(s)
    local input = WR.stringSplit(s)
    local output = {}
    for k in pairs(input) do
        local key, value = WR.stringKeyVar(k)
        if key then output[key] = value end
    end
    return output
end

function WR.switchTeam(player,team)
    local newInfo = player.CharacterInfo
    newInfo.TeamID = CharacterTeamType[team] or CharacterTeamType.None

    Entity.Spawner.AddCharacterToSpawnQueue("Human", player.Character.WorldPosition, newInfo, function(character)
        player.SetClientCharacter(character)
        newInfo.Job.GiveJobItems(character)
    end)

    -- prevents issues were a item drops to the floor
    for item in player.Character.Inventory.AllItems do
        Entity.Spawner.AddEntityToRemoveQueue(item)
    end
    Entity.Spawner.AddEntityToRemoveQueue(player.Character)
end

function WR.weightedRandom(tbl,weights)
    local weightSum = 0
    for i=1,#tbl,1 do
        weightSum = weightSum + weights[i]
    end
    local rng = math.random() * weightSum
    for i=1,#tbl,1 do
        if rng <= weights[i] then
            return tbl[i]
        end
        rng = rng - weights[i]
    end
end