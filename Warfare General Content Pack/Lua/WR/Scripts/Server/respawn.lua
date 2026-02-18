if CLIENT then return end

function WR.getPlayersByJob(clients,id)
    local filteredClients = {}

    for client in clients do
        if WR.id(client,{"Character","Info","Job"}) == id or
        not client.Character and WR.id(client,{"AssignedJob"}) == id then
            table.insert(filteredClients,client)
        end
    end

    return filteredClients
end
--[[
WR.respawnEnabled = true

WR.teamSpawnBlackList = {}

WR.defaultRespawnInterval = 180*60

WR.respawns = {
    renegadeteam = {
        time = WR.defaultRespawnInterval,
        multiplier = 1
    },
    coalitionteam = {
        time = WR.defaultRespawnInterval,
        multiplier = 1
    }
}

function WR.thinkFunctions.respawn()

    if not WR.respawnEnabled then return end

    for job,timer in pairs(WR.respawns) do
        timer.time = timer.time - 1

        if timer.time % 1800 == 0 and timer.time > 1 then
            local message = WR.FormatTime(timer.time/60).." before respawn."
            local format = WR.messagesFormats.default
            local clients = WR.getPlayersByJob(WR.GetDeadPlayers(),job)
            if timer.time <= 1800 then
                clients = WR.getPlayersByJob(Client.ClientList,job)
                format = WR.messagesFormats.info
            end
            if WR.teamSpawnBlackList[job] then
                message = WR.FormatTime(timer.time/60).." before next cycle (no respawn)."
            end
            for client in clients do
                WR.SendMessagetoClient(message,client,format)
            end
        end

        if timer.time <= 0 then
            timer.time = math.floor(WR.Lerp(WR.InvLerp(WR.tick,0,WR.tickmax),30*60,WR.defaultRespawnInterval * timer.multiplier))


            local message = "Respawning..."
            if WR.teamSpawnBlackList[job] then
                message = "Respawn interuped by enemy presence last cycle!"
            end
            for client in WR.getPlayersByJob(Client.ClientList,job) do
                WR.SendMessagetoClient(message,client,WR.messagesFormats.info)
            end

            WR.AssignBalanceJobs()

            for client in WR.getPlayersByJob(WR.GetDeadPlayers(),job) do
                if not WR.teamSpawnBlackList[job] then
                    local spawnPoint = WR.getRandomWaypointByJob(job)
                    WR.spawnHuman(client,job,spawnPoint.WorldPosition)
                end
            end

            -- teams with captured objectives can spawn once
            local basesOccupied = 0
            for area in WR.objectives do
                if area.captured then basesOccupied = basesOccupied + 1 end
                if area.defender == job then
                    WR.teamSpawnBlackList[job] = area.captured
                end
                WR.teamSpawnBlackList[job] = WR.teamSpawnBlackList[job] and basesOccupied < 2
            end
        end
    end
end

function WR.roundStartFunctions.respawn()
    WR.respawnEnabled = true
    for timer in WR.respawns do
        timer.time = WR.defaultRespawnInterval
        timer.multiplier = 1
    end
end
]]
WR.defaultRespawnInterval = 125*60

WR.lastRespawnTime = 0
WR.respawnTime = 0

function WR.respawnClient(client,job,fliter)
    fliter = fliter or function (c,j)
        return true
    end

    if fliter(client,job) then
        local spawnPoint = WR.getRandomWaypointByJob(job)
        WR.spawnHuman(client,job,spawnPoint.WorldPosition)
    end
end

function WR.respawnClients(clients,job,fliter)
    for client in clients do
        WR.respawnClient(client,job,fliter)
    end
end

function WR.defaultRespawnFilter(client,job)
    if client.SpectateOnly then return false end
    if client.Character then
        if not client.Character.IsDead then
            return false
        end
    end
    for tbl in WR.objectives do
        if tbl.defender == WR.defender(job) then
            WR.SendMessagetoClient("You can't respawn because there's enemies in your base!",client,WR.messagesFormats.block)
            if tbl.captured then return false end
        end
    end
    return true
end

function WR.thinkFunctions.respawn()
    if not Game.RoundStarted or WR.Game.ending then return end

    if WR.tick % 6 ~= 0 then return end
    if WR.respawnTime > WR.tick then return end

    WR.respawnTime = WR.tick + WR.defaultRespawnInterval
    WR.lastRespawnTime = WR.tick
    print("Time till respawn: ",WR.respawnTime)
    print("Current time: ",WR.tick)

    print("Respawning!")
    WR.SendMessageToAllClients("Respawning!",WR.messagesFormats.info)

    WR.AssignBalanceJobs()
    for client in Client.ClientList do
        local job = WR.id(client,{"Character","Info","Job"}) or WR.id(client,{"AssignedJob"})
        if job then
            WR.respawnClient(client,job,WR.defaultRespawnFilter)
        else
            print("Was not able to spawn: ",client, ", job was nill.")
        end
    end

end

function WR.thinkFunctions.respawnMessage()
    if not Game.RoundStarted or WR.Game.ending then return end

    if WR.respawnTime - WR.tick - 60*60 == 0 then
        WR.SendMessageToAllClients("1 minute till respawn.",WR.messagesFormats.info)
    end
end


function WR.thinkFunctions.despawnMonstersAndCorpses()
    if WR.tick % (60*60) ~= 0 then return end

    print("Removing corpses & monsters...")
    for char in Character.CharacterList do
        if not char.Removed and (char.IsDead or not char.IsHuman) then
            print("Removed: ",char)
            char.DespawnNow()
        end
    end
end

function WR.characterDeathFunctions.respawnSoonAfterDeath(char)
    if not char.IsHuman then return end
    local client = Util.FindClientCharacter(char)
    if client then
        if WR.tick - WR.lastRespawnTime < (WR.defaultRespawnInterval*0.2) then -- within 20% of the respawn interval
            local job = WR.id(client,{"Character","Info","Job"})
            if job then
                WR.respawnClient(client,job,WR.defaultRespawnFilter)
            else
                print("Was not able to spawn: ",client, ", job was nill.")
            end
        end
    end
end