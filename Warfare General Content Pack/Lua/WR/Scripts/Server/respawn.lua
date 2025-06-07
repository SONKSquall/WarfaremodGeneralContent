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
        if WR.id(client,{"Character","Info","Job"}) == id or
        not client.Character and WR.id(client,{"AssignedJob"}) == id then
            table.insert(filteredClients,client)
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
            for char in Character.CharacterList do
                if char.IsDead or not char.IsHuman then
                    char.DespawnNow()
                end
            end

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