WR.renegadeJob = JobVariant(JobPrefab.Get("renegadeteam"), 0)
WR.coalitionJob = JobVariant(JobPrefab.Get("coalitionteam"), 0)

Hook.Add('jobsAssigned', 'WR.jobbalance', function()
    local amountCoalition = 0
    local amountRenegade = 0
    local deadPlayers = WR.GetDeadPlayers()
    for key, player in pairs(Client.ClientList) do
        if not player.SpectateOnly then
            if player.AssignedJob == nil then
                if key % 2 == 0 then
                    player.AssignedJob = WR.coalitionJob
                    amountCoalition = amountCoalition + 1
                else
                    player.AssignedJob = WR.renegadeJob
                    amountRenegade = amountRenegade + 1
                end
            elseif player.AssignedJob.Prefab.Identifier == 'renegadeteam' then
                amountRenegade = amountRenegade + 1
            elseif player.AssignedJob.Prefab.Identifier == 'coalitionteam' then
                amountCoalition = amountCoalition + 1
            end
        end
    end

    local difference = amountCoalition - amountRenegade

    print("difference is ", difference)

    if difference > 1 then
        local amount = math.abs(difference) - 2
        for key, player in pairs(deadPlayers) do
            if player.AssignedJob ~= nil then
                if player.AssignedJob.Prefab.Identifier == 'coalitionteam' then
                    player.AssignedJob = WR.renegadeJob
                    amount = amount - 1
                    if amount <= 0 then
                        break
                    end
                end
            end
        end
    elseif difference < -1 then
        local amount = math.abs(difference) - 2
        for key, player in pairs(deadPlayers) do
            if player.AssignedJob ~= nil then
                if player.AssignedJob.Prefab.Identifier == 'renegadeteam' then
                    player.AssignedJob = WR.coalitionJob
                    amount = amount - 1
                    if amount <= 0 then
                        break
                    end
                end
            end
        end
    end

    --[[
    Timer.NextFrame(function()
        for player in deadPlayers do
            if player.CharacterInfo.Job.Prefab.Identifier.value == "coalitionteam" then
                WR.switchTeam(player,"Team1")
            elseif player.CharacterInfo.Job.Prefab.Identifier.value == "renegadeteam"  then
                WR.switchTeam(player,"Team2")
            end
        end
    end)
    ]]
end)