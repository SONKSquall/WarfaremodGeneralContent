function WR.GetItemsByTag(searchTag)
    local Worlditems = {}

    for item in Item.ItemList do
        if item.HasTag(searchTag) then table.insert(Worlditems,item) end
    end

    return Worlditems
end

function WR.Lerp (n, a, b)
    return a*(1-n) + b*n
end

function WR.InvLerp (n, a, b)
    return (n-a)/(b-a)
end

function WR.IsEnemyPOW(character, TeamIdentifier)
    return character.isHuman == true and character.IsDead == false and character.JobIdentifier ~= TeamIdentifier and character.LockHands == true
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
                local ItemsInInventory = Item.OwnInventory.FindAllItems(predicate, false, list)
                WR.SpawnInventoryItems(ItemsInInventory, WorldItem.OwnInventory)
            end
        end)
    end
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

function WR.GetDeadPlayers()

    local players = {}

    for player in Client.ClientList do
        local charExists = (player.Character ~= nil)
        if not player.SpectateOnly and not charExists then
            table.insert(players,player)
        elseif not player.SpectateOnly and charExists then
            if player.Character.IsDead then
                table.insert(players,player)
            end
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

    return tbl
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
    local input = WR.Set.new(WR.stringSplit(s))
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

function WR.weightedAverage(set,weights)
    local w = 0
    for i=1,#weights,1 do
        w = w + weights[i]
    end
    local n = 0
    for i=1,#set,1 do
        n = n + (weights[i] * set[i])
    end
    return n/w
end

function WR.simPosToWorldPos(position,inSub)
    if inSub then
        return (position * 100) + Submarine.MainSub.Position
    else
        return (position * 100)
    end
end

function WR.getIndex(table,path)
    path = WR.stringSplit(path,"&.")
    local step = table
    for key in path do
        if step[key] == nil then return end
        step = step[key]
    end
    return step
end

function WR.setIndex(table,path,value)
    path = WR.stringSplit(path,"&.")
    local step = table
    for index,key in pairs(path) do
        if index == #path then step[key] = value break end -- set value
        if step[key] == nil then step[key] = {} print("Path to location not found, new one created at "..key) end -- create path if none is existent
        step = step[key] -- advance step
    end
    return step
end

function WR.isPointInRect(point,rect)
    return math.abs(point.X - rect.X - rect.Width/2) <= rect.Width/2 and math.abs(point.Y - rect.Y + rect.Height/2) <= rect.Height/2
end

-- stolen from sharp-shark

function WR.getWaypointsByJob(job)
	local waypoints = {}
	for waypoint in Submarine.MainSub.GetWaypoints(false) do
		if waypoint.AssignedJob ~= nil and waypoint.AssignedJob.Identifier == job then
			table.insert(waypoints, waypoint)
		end
	end
	if job == "" and #waypoints < 1 then
		for waypoint in Submarine.MainSub.GetWaypoints(false) do
			if waypoint.SpawnType == SpawnType.Human then
				table.insert(waypoints, waypoint)
			end
		end
	end
	return waypoints
end

function WR.getRandomWaypointByJob(job)
    local waypoints = WR.getWaypointsByJob(job)
    return waypoints[math.random(#waypoints)]
end

function WR.spawnHuman(client,job,pos)

    local info
    if client then
        info = client.CharacterInfo
	info.TeamID = 0
    else
        info = CharacterInfo("human", "Jerett")
	info.TeamID = 0
    end
    info.Job = Job(JobPrefab.Get(job), false)

    local character = Character.Create(info, pos, info.Name, 0, false, false)

    if client then
        client.SetClientCharacter(character)
    end

    character.GiveJobItems(false)

    return character
end