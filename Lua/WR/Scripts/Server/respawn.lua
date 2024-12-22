if CLIENT then return end

WR.teamSpawnBlackList = {}

WR.defaultRespawnInterval = 120*60

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
    local index = 0
    local all = #clients

    return function()
        while true do
            index = index + 1
            if index > all then return end
            if clients[index].Character and clients[index].Character.JobIdentifier.value == id or
            not clients[index].Character and clients[index].AssignedJob and clients[index].AssignedJob.Prefab.Identifier.value == id then
                return clients[index]
            end
        end
    end
end

WR.respawnEnabled = true

function WR.thinkFunctions.respawn()

    if not WR.respawnEnabled then return end

    for job,timer in pairs(WR.respawns) do
        timer.time = timer.time - 1

        if timer.time % 1800 == 0 and timer.time > 1 then
            for client in WR.getPlayersByJob(Client.ClientList,job) do
                if timer.time <= 1800 then
                    WR.SendMessagetoClient(WR.FormatTime(timer.time/60).." before respawn.",client,WR.messagesFormats.info)
                else
                    WR.SendMessagetoClient(WR.FormatTime(timer.time/60).." before respawn.",client)
                end
            end
        end

        if timer.time <= 0 then
            timer.time = math.floor(WR.defaultRespawnInterval * timer.multiplier)

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
    for area in WR.objectives do
        WR.teamSpawnBlackList[area.defender] = area.captured
    end
end

function WR.roundStartFunctions.respawn()
    WR.respawnEnabled = true
    for timer in WR.respawns do
        timer.time = WR.defaultRespawnInterval
        timer.multiplier = 1
    end
end