if not Game.IsMultiplayer or (Game.IsMultiplayer and CLIENT) then return end

-- use instances to prevent the server from modifying classes
WR.buildingManager = (require"WR.Scripts.Server.Extensions.buildingmanager".new())
WR.data = (require"WR.Scripts.Server.Extensions.data".new())
WR.objective = (require"WR.Scripts.Server.Extensions.objective".new())
WR.artillery = (require"WR.Scripts.Server.Extensions.artillery".new())


WR.shops = {}
WR.drills = {}
WR.Game = {}
WR.Game.ending = false
WR.Game.winner = ""
WR.tick = 0
WR.tickmax = 30*60*60

WR.extensions = {
    WR.buildingManager,
    WR.data,
    WR.objective,
    WR.artillery
}
WR.thinkFunctions = {}

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

    -- ore spawn rate scales with the amount of players on the server
    if WR.tick % math.floor(15*60 * (Game.ServerSettings.MaxPlayers / #Client.ClientList)) == 0 then
        for drillTable in WR.drills do
            local drill = drillTable[math.random(1,#drillTable)]
            if drill then
                if not drill.OwnInventory.IsFull(true) then
                    Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("WR_ore"), drill.OwnInventory, nil, nil, nil)
                end
            end
        end
    end

end

-- designed to work with two or more teams
function WR.Game.altWinner()

    local winner = ""
    local teams = {}

    -- graps all of the teams, deaths is the value that is compared, id is the value returned
    for k,v in pairs(WR.data.stats) do
        table.insert(teams,{id = k, deaths = v.deaths or 1})
    end

    table.sort(teams, function(k1,k2) return k2.deaths / k1.deaths > 1 end)

    -- if the first team has ten present less then deaths then the second team, then it is the winner
    if teams[2].deaths / teams[1].deaths > 1.1 then
        winner = teams[1].id
    end

    return winner
end

function WR.createEndMessage()

    if WR.Game.winner == "" then return "Stalemate." end

    return WR.teamWinner[WR.Game.winner] .. " " .. WR.getVictoryType((WR.data.stats[WR.teamLoser[WR.Game.winner]].deaths or 1) / (WR.data.stats[WR.Game.winner].deaths or 1))
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

WR.roundEndFunctions = {}

function WR.roundEndFunctions.main()



end

WR.roundStartFunctions = {}

function WR.roundStartFunctions.main()
    WR.tick = 0
    if WR.tickmax == 0 then WR.tickmax = 30*60*60 end
    WR.Game.ending = false
    WR.Game.winner = ""

    for v in WR.teamKeys do
        WR.shops[v] = {}
    end

    if Util.GetItemsById("WR_strategicexchange") then
        for shop in Util.GetItemsById("WR_strategicexchange") do
            local shopteam = WR.getStringVariables(shop.Tags)["team"]
            shopteam = WR.teamKeys[shopteam] -- remove bogus teams
            if shopteam then
                table.insert(WR.shops[shopteam], shop)
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

function WR.roundStartFunctions.ore()
    WR.drills = {}
    WR.drills.unassigned = {}

    if Util.GetItemsById("WR_oredrill") then
        for drill in Util.GetItemsById("WR_oredrill") do
            local drillID = WR.getStringVariables(drill.Tags).id
            if drillID then
                if not WR.drills[drillID] then WR.drills[drillID] = {} end
                table.insert(WR.drills[drillID],drill)
            else
                table.insert(WR.drills.unassigned,drill)
            end
        end
    end
end

WR.characterDeathFunctions = {}

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

-- incase of reloadlua
if Game.RoundStarted then
    for func in WR.roundStartFunctions do
        func()
    end
    for obj in WR.extensions do
        obj:Start()
    end
end

Game.AddCommand("setroundlength", "Use to set a custom round length in minutes. (Works for one round)", function(args)
    WR.tickmax = tonumber(args[1])*60*60
    print("NEW ROUND LENGTH: ",tonumber(args[1]))
end, nil, true)

Game.AddCommand("forceend", "Ends the round with a optional winner.", function(args)
    if args[1] then 
        WR.Game.winner = WR.teamKeys[args[1]]
    else
        WR.Game.winner = WR.Game.altWinner()
    end
    WR.Game.endGame()
end, nil, true)

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
