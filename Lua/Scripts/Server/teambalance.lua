WR.renegade_job = JobVariant(JobPrefab.Get("renegadeteam"), 0)
WR.coalition_job = JobVariant(JobPrefab.Get("coalitionteam"), 0)

Hook.Add('jobsAssigned', 'WR.jobbalance', function()
    local amountCoalition = 0
    local amountRenegade = 0
    for key, player in pairs(Client.ClientList) do
        if not player.SpectateOnly then
            if player.AssignedJob.Prefab.Identifier == 'renegadeteam' then
                amountRenegade = amountRenegade + 1
            elseif player.AssignedJob.Prefab.Identifier == 'coalitionteam' then
                amountCoalition = amountCoalition + 1
            else
                if key % 2 == 0 then
                    player.AssignedJob = WR.coalition_job
                    amountCoalition = amountCoalition + 1
                else
                    player.AssignedJob = WR.renegade_job
                    amountRenegade = amountRenegade + 1
                end
            end
        end
    end

    local difference = amountCoalition - amountRenegade

    print("difference is ", difference)

    if difference > 1 then
        local amount = math.abs(difference) - 2
        local deadPlayers = WR.GetDeadPlayers()
        for key, player in pairs(deadPlayers) do
            if player.AssignedJob.Prefab.Identifier == 'coalitionteam' then
                player.AssignedJob = WR.renegade_job
                amount = amount - 1
                if amount <= 0 then
                    break
                end
            end
        end
    elseif difference < -1 then
        local amount = math.abs(difference) - 2
        local deadPlayers = WR.GetDeadPlayers()
        for key, player in pairs(deadPlayers) do
            if player.AssignedJob.Prefab.Identifier == 'renegadeteam' then
                player.AssignedJob = WR.coalition_job
                amount = amount - 1
                if amount <= 0 then
                    break
                end
            end
        end
    end
end)