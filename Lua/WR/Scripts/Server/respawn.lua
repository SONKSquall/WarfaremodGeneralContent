if CLIENT then return end

WR.teamSpawnBlackList = {}

WR.defaultRespawnInterval = 60
WR.respawnTime = WR.defaultRespawnInterval -- time till respawn in seconds

WR.respawnEnabled = true

function WR.thinkFunctions.respawn()

    WR.respawnTime = WR.respawnTime - 1 * WR.DeltaTime

    if WR.respawnTime > 0 or not WR.respawnEnabled then return end

    WR.respawnTime = WR.defaultRespawnInterval * 1

    WR.AssignBalanceJobs()
    for client in WR.GetDeadPlayers() do
        local jobid = client.AssignedJob.Prefab.Identifier.value
        if not WR.teamSpawnBlackList[jobid] then
            local spawnPoint = WR.getRandomWaypointByJob(jobid)
            WR.spawnHuman(client,jobid,spawnPoint.WorldPosition)
        end
    end

end