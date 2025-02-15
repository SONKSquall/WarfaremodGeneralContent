if CLIENT then return end

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

function WR.getPlayersByJob(clients,id)
    local filteredClients = {}

    for client in clients do
        if client then
            if client.Character and client.Character.Info.Job.Prefab.Identifier.Contains(id) or
            not client.Character and client.AssignedJob and client.AssignedJob.Prefab.Identifier.Contains(id) then
                table.insert(filteredClients,client)
            end
        end
    end

    return filteredClients
end

WR.respawnEnabled = true

function WR.thinkFunctions.respawn()

    if not WR.respawnEnabled then return end

    for job,timer in pairs(WR.respawns) do
        timer.time = timer.time - 1

        if timer.time % 1800 == 0 and timer.time > 1 then
                if timer.time <= 1800 then
                    for client in WR.getPlayersByJob(Client.ClientList,job) do
                        WR.SendMessagetoClient(WR.FormatTime(timer.time/60).." before respawn.",client,WR.messagesFormats.info)
                    end
                else
                    for client in WR.getPlayersByJob(WR.GetDeadPlayers(),job) do
                        WR.SendMessagetoClient(WR.FormatTime(timer.time/60).." before respawn.",client)
                    end
                end
        end

        if timer.time <= 0 then
            timer.time = math.floor(WR.Lerp(WR.defaultRespawnInterval * timer.multiplier,0,WR.InvLerp(WR.tick,0,WR.tickmax) + 0.1))

            for client in WR.getPlayersByJob(Client.ClientList,job) do
                WR.SendMessagetoClient("Respawning...",client,WR.messagesFormats.info)
            end

            WR.AssignBalanceJobs()
            for client in WR.getPlayersByJob(WR.GetDeadPlayers(),job) do
                if not WR.teamSpawnBlackList[job] then
                    local spawnPoint = WR.getRandomWaypointByJob(job)
                    WR.spawnHuman(client,job,spawnPoint.WorldPosition)
                end
            end
        end
    end

    -- teams with captured objectives can spawn once
    local basesOccupied = 0
    for area in WR.objectives do
        if area.captured then basesOccupied = basesOccupied + 1 end
        WR.teamSpawnBlackList[area.defender] = area.captured
    end
    -- if both areas are taken then both teams can respawn
    if basesOccupied >= 2 then
        WR.teamSpawnBlackList = {}
    end
end

function WR.roundStartFunctions.respawn()
    WR.respawnEnabled = true
    for timer in WR.respawns do
        timer.time = WR.defaultRespawnInterval
        timer.multiplier = 1
    end
end