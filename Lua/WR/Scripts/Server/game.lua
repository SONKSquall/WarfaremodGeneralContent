if not Game.IsMultiplayer or (Game.IsMultiplayer and CLIENT) then return end

-- use instances to prevent the server from modifying classes     <- the most cursed text ever written
WR.buildingManager = (require"WR.Scripts.Server.Extensions.buildingmanager".new())
WR.objective = (require"WR.Scripts.Server.Extensions.objective".new())
WR.artillery = (require"WR.Scripts.Server.Extensions.artillery".new())

require"WR.Scripts.Server.hooks"
require"WR.Scripts.Server.items"
require"WR.Scripts.Server.weapons"

WR.frontLinePos = Vector2(0,0)
WR.spawnPositions = {}
WR.Game = {}
WR.Game.ending = false
WR.Game.winner = ""
WR.tick = 0
WR.tickmax = 30*60*60

WR.extensions = {
    WR.buildingManager,
    WR.objective,
    WR.artillery
}

function WR.thinkFunctions.main()

    if WR.tick >= WR.tickmax then
        WR.Game.winner = WR.Game.altWinner()
        WR.Game.endGame()
        return
    end

    if WR.tick % 27000 == 0 then
        WR.SendMessageToAllClients("Round ending in"..WR.FormatTime((WR.tickmax-WR.tick)/60)..".",{["type"] = ChatMessageType.Server, ["sender"] = "Server"})
    end

end

function WR.thinkFunctions.winner()

    if WR.tick % 6 == 0 then
        for obj in WR.objective.areas do
            if obj.captured then
                WR.Game.winner = WR.teamKeys[obj.attacker]
                WR.Game.endGame()
                break
            end
        end
    end

end

function WR.thinkFunctions.ore()
    -- 1~ ore per player every 3 minutes
    if WR.tick % math.floor(3*60*60 / (#Client.ClientList/2)) == 0 then
        for drillTable in WR.data["userdata.drills"] do
            local drill = drillTable[math.random(1,#drillTable)]
            if drill then
                if not drill.OwnInventory.IsFull(true) then
                    Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("WR_ore"), drill.OwnInventory, nil, nil, nil)
                end
            end
        end
    end
end

function WR.thinkFunctions.calculateFrontLine()

    if WR.tick % 60 == 0 then
        local xCords = {}
        local yCords = {}
        local whights = {}
        for char in Character.CharacterList do
            if WR.teamKeys[char.JobIdentifier.value] then
                local id = char.JobIdentifier.value
                table.insert(xCords,char.WorldPosition.x)
                table.insert(yCords,char.WorldPosition.y)
                -- players who are further away from their spawn will have a greater affect on the front line position
                local whight = Vector2.Distance(char.WorldPosition,WR.spawnPositions[id])/Vector2.Distance(WR.spawnPositions.coalitionteam,WR.spawnPositions.renegadeteam)
                table.insert(whights,whight)
            end
        end
        WR.frontLinePos = Vector2(WR.weightedAverage(xCords,whights), WR.weightedAverage(yCords,whights))
    end

end

function WR.Game.altWinner()
    local winFactor = WR.data["teams.coalitionteam.deaths"]/WR.data["teams.renegadeteam.deaths"]
    -- the more death inbalance between teams, the less territory matters
    winFactor = Vector2.Distance(WR.frontLinePos,WR.spawnPositions.coalitionteam)/Vector2.Distance(WR.spawnPositions.coalitionteam,WR.spawnPositions.renegadeteam) / winFactor
    if winFactor > 0.5 then
        return "coalitionteam"
    else
        return "renegadeteam"
    end
end

function WR.createEndMessage()

    if WR.Game.winner == "" then return "Stalemate." end

    local winner = WR.Game.winner
    local loser = WR.teamLoser[winner]
    return WR.teamWinner[WR.Game.winner] .. " " .. WR.getVictoryType(WR.data["teams."..loser..".deaths"] / WR.data["teams."..winner..".deaths"])
end

function WR.getVictoryType(ratio)
    ratio = math.abs(ratio)

    if ratio < 1 then
        return WR.victoryTypes[1]
    elseif ratio >= 1.5 then
        return WR.victoryTypes[4]
    elseif ratio >= 1.25 then
        return WR.victoryTypes[3]
    elseif ratio >= 1 then
        return WR.victoryTypes[2]
    end

end

function WR.roundEndFunctions.main()



end

function WR.roundEndFunctions.data()
    WR.data["round.roundwinner"] = WR.Game.winner
    WR.data["round.roundlength"] = WR.FormatTime(WR.tick/60)
    WR.data["round.map"] = tostring(Game.GameSession.SubmarineInfo.Name)
    WR.data["round.territory"] = Vector2.Distance(WR.frontLinePos,WR.spawnPositions.coalitionteam)/Vector2.Distance(WR.spawnPositions.coalitionteam,WR.spawnPositions.renegadeteam)
    WR.data.save()
    WR.data.reset()
end

function WR.roundStartFunctions.main()
    WR.tick = 0
    if WR.tickmax == 0 then WR.tickmax = 30*60*60 end
    WR.Game.ending = false
    WR.Game.winner = ""

    NetConfig.MaxHealthUpdateInterval = 0
    NetConfig.LowPrioCharacterPositionUpdateInterval = 0
    NetConfig.MaxEventPacketsPerUpdate = 8

    -- shops
    if Util.GetItemsById("WR_strategicexchange") then
        for shop in Util.GetItemsById("WR_strategicexchange") do
            local shopteam = WR.getStringVariables(shop.Tags)["team"]
            shopteam = WR.teamKeys[shopteam] -- remove bogus teams
            if shopteam then
                WR.data["userdata."..shopteam.."shop"] = shop
            end
        end
    end

    -- grace period
    Timer.Wait(function()
        if Game.RoundStarted then
            for door in WR.GetItemsByTag("wr_graceperiod") do
                Entity.Spawner.AddEntityToRemoveQueue(door)
            end
            WR.SendMessageToAllClients("Grace period ended!",{type = ChatMessageType.Server})
        end
    end, 60*1000)
end

function WR.roundStartFunctions.spawnPositions()

    WR.spawnPositions = {}
    -- collect data
    for spawnPoint in WayPoint.WayPointList do
        if spawnPoint.SpawnType == 1 and spawnPoint.AssignedJob then
            local id = spawnPoint.AssignedJob.Identifier.value
            if not WR.spawnPositions[id] then WR.spawnPositions[id] = {} end
            table.insert(WR.spawnPositions[id],spawnPoint.WorldPosition)
        end
    end
    -- proess data
    for key,data in pairs(WR.spawnPositions) do
        local x = Vector2(0,0)
        for pos in data do
            x = Vector2.Add(x,pos)
        end
        WR.spawnPositions[key] = Vector2.Divide(x,#data)
    end
end

function WR.characterDeathFunctions.log(char)
    if not char.isHuman then return end
    local path = "teams."..char.Info.Job.Prefab.Identifier.Value..".deaths"
    WR.data[path] = WR.data[path] + 1
end

-- for validating and initializing
WR.teamKeys = {
    renegadeteam = "renegadeteam",
    coalitionteam = "coalitionteam",
    Renegade = "renegadeteam",
    Coalition = "coalitionteam"
}

-- strings used in round end messages
WR.teamWinner = {
    renegadeteam = "Renegade",
    coalitionteam = "Coalition",
    Renegade = "Renegade",
    Coalition = "Coalition"
}

-- the same as teamKeys but reverse
WR.teamLoser = {
    renegadeteam = "coalitionteam",
    coalitionteam = "renegadeteam",
    Renegade = "coalitionteam",
    Coalition = "renegadeteam"
}

WR.victoryTypes = {
    "pyrrhic victory",
    "minor victory",
    "major victory",
    "decisive victory"
}

function WR.Game.endGame()
    if WR.Game.ending or not Game.RoundStarted then return end

    WR.Game.ending = true

    WR.SendMessageToAllClients(WR.createEndMessage(),nil)
    for n=1,15 do
        Timer.Wait(function()
            WR.SendMessageToAllClients("Round ending in "..15-n.." seconds.",{["type"] = ChatMessageType.Server, ["color"] = Color(255, 0, 0, 255), ["sender"] = "Server"})
        end,n*1000)
    end

    Timer.Wait(function()
        Game.EndGame()
    end,15*1000)
end

WR.data.reset()

-- incase of reloadlua
if Game.RoundStarted then
    for func in WR.roundStartFunctions do
        func()
    end
    for obj in WR.extensions do
        obj:Start()
    end
end