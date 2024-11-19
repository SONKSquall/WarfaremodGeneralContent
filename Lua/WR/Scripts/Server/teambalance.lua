WR.renegadeJob = JobVariant(JobPrefab.Get("renegadeteam"), 0)
WR.coalitionJob = JobVariant(JobPrefab.Get("coalitionteam"), 0)

function WR.AssignBalanceJobs()
    local amountCoalition = 0
    local amountRenegade = 0
    local deadPlayers = WR.GetDeadPlayers()
    for client in Client.ClientList do
        if not client.SpectateOnly then
            if client.AssignedJob == nil then
                if math.random() > 0.5 then
                    client.AssignedJob = WR.coalitionJob
                    amountCoalition = amountCoalition + 1
                else
                    client.AssignedJob = WR.renegadeJob
                    amountRenegade = amountRenegade + 1
                end
            elseif client.AssignedJob.Prefab.Identifier == 'renegadeteam' then
                amountRenegade = amountRenegade + 1
            elseif client.AssignedJob.Prefab.Identifier == 'coalitionteam' then
                amountCoalition = amountCoalition + 1
            end
        end
    end

    local difference = amountCoalition - amountRenegade

    print("difference is ", difference)

    if difference > 1 then
        local amount = math.abs(difference) - 2
        for client in deadPlayers do
            if client.AssignedJob ~= nil then
                if client.AssignedJob.Prefab.Identifier == 'coalitionteam' then
                    client.AssignedJob = WR.renegadeJob
                    amount = amount - 1
                    if amount <= 0 then
                        break
                    end
                end
            end
        end
    elseif difference < -1 then
        local amount = math.abs(difference) - 2
        for client in deadPlayers do
            if client.AssignedJob ~= nil then
                if client.AssignedJob.Prefab.Identifier == 'renegadeteam' then
                    client.AssignedJob = WR.coalitionJob
                    amount = amount - 1
                    if amount <= 0 then
                        break
                    end
                end
            end
        end
    end
end

Hook.Add('jobsAssigned', 'WR.jobbalance', WR.AssignBalanceJobs)