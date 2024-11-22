if CLIENT then return end

WR.teamSpawnBlackList = {}

WR.defaultRespawnInterval = 120*60
WR.respawnTime = WR.defaultRespawnInterval -- time till respawn in ticks

WR.respawnEnabled = true

function WR.thinkFunctions.respawn()

    WR.respawnTime = WR.respawnTime - 1

    if WR.respawnTime == 900 then -- 15 seconds before respawn
        WR.SendMessageToAllClients("15 seconds before respawn.",{type = ChatMessageType.Default})
    end

    if WR.respawnTime > 0 or not WR.respawnEnabled then return end

    WR.respawnTime = WR.defaultRespawnInterval * 1 -- planning on changing respawn time depending on battle conditions

    WR.AssignBalanceJobs()
    WR.SendMessageToAllClients("Respawning...",{type = ChatMessageType.Default})
    for client in WR.GetDeadPlayers() do
        local jobid = client.AssignedJob.Prefab.Identifier.value
        if not WR.teamSpawnBlackList[jobid] then
            local spawnPoint = WR.getRandomWaypointByJob(jobid)
            WR.spawnHuman(client,jobid,spawnPoint.WorldPosition)
        end
    end

end