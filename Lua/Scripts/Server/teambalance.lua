if CLIENT then return end

WR.renegades = WR.Set.new{}
WR.coalition = WR.Set.new{}
WR.renegade_job = JobVariant(JobPrefab.Get("renegadeteam"), 0)
WR.coalition_job = JobVariant(JobPrefab.Get("coalitionteam"), 0)

Hook.Add("jobsAssigned", "WR_JobBalance", function ()

    -- seperate dead from alive
    local deadplayers = WR.Set.new(WR.GetDeadPlayers())
    local deadcoalition = WR.Set.new{}
    local deadrenegades = WR.Set.new{}
    WR.renegades = ((WR.renegades-deadplayers)*Client.ClientList)
    WR.coalition = ((WR.coalition-deadplayers)*Client.ClientList)

    -- gives players their preferred team prior to balancing
    for player in pairs(deadplayers) do
        if player.PreferredJob == "coalitionteam" then
            deadcoalition[player] = true
            WR.GivePreferedJob(player)
        elseif player.PreferredJob == "renegadeteam" then
            deadrenegades[player] = true
            WR.GivePreferedJob(player)
        else
            -- if a player does not have a preferred job then they get assigned randomly
            if (math.random(0,2) % 2 == 0) then
                deadcoalition[player] = true
                player.AssignedJob = WR.coalition_job
            else
                deadrenegades[player] = true
                player.AssignedJob = WR.renegade_job
            end
        end
    end

    -- gets the number to balance if all players get their way
    local amounttobalance = WR.NumberToEqualize(#WR.coalition+#deadcoalition, #WR.renegades+#deadrenegades)
    if amounttobalance < 1 then
        WR.coalition = WR.coalition+deadcoalition
        WR.renegades = WR.renegades+deadrenegades
        return
    elseif amounttobalance > #deadplayers then
        amounttobalance = #deadplayers
    end

    for i=amounttobalance,1,-1 do
        if #WR.coalition+#deadcoalition > #WR.renegades+#deadrenegades then
            local key = WR.Set.randomkey(deadcoalition)
            deadcoalition[key].AssignedJob = WR.renegade_job
            deadrenegades[key] = deadcoalition[key]
            table.remove(deadcoalition, key)
        elseif #WR.renegades+#deadrenegades > #WR.coalition+#deadcoalition then
            local key = WR.Set.randomkey(deadrenegades)
            deadrenegades[key].AssignedJob = WR.coalition_job
            deadcoalition[key] = deadrenegades[key]
            table.remove(deadrenegades, key)
        end
        -- breaks if all players are on the same team
        if #deadcoalition == 0 or #deadrenegades == 0 then break end
    end

    -- Add players to the total after balancing
    WR.coalition = WR.coalition+deadcoalition
    WR.renegades = WR.renegades+deadrenegades
end)