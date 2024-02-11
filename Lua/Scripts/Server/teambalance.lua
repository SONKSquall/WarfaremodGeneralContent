if CLIENT then return end

-- var list
WR.renegades = {}
WR.coalition = {}
WR.renegade_job = JobVariant(JobPrefab.Get("renegadeteam"), 0)
WR.coalition_job = JobVariant(JobPrefab.Get("coalitionteam"), 0)

-- function list

function WR.CombineTables(table1, table2)

    for key,value in pairs(table2) do
        table1[#table1+1] = table2[#table2]
        table.remove(table2, #table2)
    end

    return table1
end

function WR.GivePreferedJob(client)

    if not client.PreferredJob then return end
    client.AssignedJob = JobVariant(JobPrefab.Get(client.PreferredJob), 0)

end

function WR.GetDeadPlayers()

    local players = {}

    for key,player in pairs(Client.ClientList) do
        if player and not player.Character or player.Character.IsDead then
            players[#players+1] = player
        end
    end

    return players
end

Hook.Add("jobsAssigned", "WR_JobBalance", function ()

    local deadplayers = WR.GetDeadPlayers()
    local deadcoalition = {}
    local deadrenegades = {}

    -- remove dead players from the teams
    for key,player in pairs(WR.coalition) do
        if not player.Character or player.Character.IsDead then table.remove(WR.coalition, key) end
    end
    for key,player in pairs(WR.renegades) do
        if not player.Character or player.Character.IsDead then table.remove(WR.renegades, key) end
    end

    -- gives players their preferred team prior to balancing
    for key,player in pairs(deadplayers) do
        if player.PreferredJob == "coalitionteam" then
            deadcoalition[#deadcoalition+1] = player
            WR.GivePreferedJob(player)
        elseif player.PreferredJob == "renegadeteam" then
            deadrenegades[#deadrenegades+1] = player
            WR.GivePreferedJob(player)
        else
            -- if a player does not have a preferred job then they get assigned based on if their key is even or not
            if (key % 2 == 0) then
                deadcoalition[#deadcoalition+1] = player
                player.AssignedJob = WR.coalition_job
            else
                deadrenegades[#deadrenegades+1] = player
                player.AssignedJob = WR.renegade_job
            end
        end
    end

    -- gets the number to balance if all players get their way
    local amounttobalance = WR.NumberToEqualize(#WR.coalition+#deadcoalition, #WR.renegades+#deadrenegades)
    if amounttobalance < 1 then
        WR.CombineTables(WR.coalition, deadcoalition)
        WR.CombineTables(WR.renegades, deadrenegades)
        return
    elseif amounttobalance > #deadplayers then
        amounttobalance = #deadplayers
    end

    for i=amounttobalance,1,-1 do
        if #WR.coalition+#deadcoalition > #WR.renegades+#deadrenegades then
            deadcoalition[#deadcoalition].AssignedJob = WR.renegade_job
            deadrenegades[#deadrenegades+1] = deadcoalition[#deadcoalition]
            table.remove(deadcoalition, #deadcoalition)
        elseif #WR.renegades+#deadrenegades > #WR.coalition+#deadcoalition then
            deadrenegades[#deadrenegades].AssignedJob = WR.coalition_job
            deadcoalition[#deadcoalition+1] = deadrenegades[#deadrenegades]
            table.remove(deadrenegades, #deadrenegades)
        end
        -- breaks if all players are on the same team
        if #deadcoalition == 0 or #deadrenegades == 0 then break end
    end

    -- Add players to the total after balancing
    WR.CombineTables(WR.coalition, deadcoalition)
    WR.CombineTables(WR.renegades, deadrenegades)
end)