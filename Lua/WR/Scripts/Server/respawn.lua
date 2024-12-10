if CLIENT then return end

WR.teamSpawnBlackList = {}

WR.defaultRespawnInterval = 120*60
WR.respawnTime = WR.defaultRespawnInterval -- time till respawn in ticks

WR.respawnEnabled = true

function WR.thinkFunctions.respawn()

    WR.respawnTime = WR.respawnTime - 1

    if WR.respawnTime % 1800 == 0 and WR.respawnTime > 1 then
        if WR.respawnTime <= 1800 then
            WR.SendMessageToAllClients(WR.FormatTime(WR.respawnTime/60).." before respawn.",WR.messagesFormats.info)
        else
            WR.SendMessageToAllClients(WR.FormatTime(WR.respawnTime/60).." before respawn.")
        end
    end

    if WR.respawnTime > 0 or not WR.respawnEnabled then return end

    WR.respawnTime = WR.defaultRespawnInterval * 1 -- planning on changing respawn time depending on battle conditions

    WR.AssignBalanceJobs()
    WR.SendMessageToAllClients("Respawning...",WR.messagesFormats.info)
    for client in WR.GetDeadPlayers() do
        local jobid = client.AssignedJob.Prefab.Identifier.value
        if not WR.teamSpawnBlackList[jobid] then
            local spawnPoint = WR.getRandomWaypointByJob(jobid)
            WR.spawnHuman(client,jobid,spawnPoint.WorldPosition)
        end
    end

    -- teams with captured objectives can spawn once
    for area in WR.objectives do
        WR.teamSpawnBlackList[area.defender] = area.captured
    end
end