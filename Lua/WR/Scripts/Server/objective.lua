if CLIENT then return end

function WR.thinkFunctions.objective()

    if WR.tick % 60 ~= 0 then return end

    -- if theres an attacker in the base then that team can't respawn otherwise they can
    for area in WR.objectives do
        local enemyAlreadyPresent = area.captured
        local enemyPresent = false
        for client in Client.ClientList do
            if client.Character and WR.isPointInRect(client.Character.WorldPosition, area.rect) then
                if not (client.Character.IsUnconscious or WR.IsEnemyPOW(client.Character, area.defender)) and client.Character.JobIdentifier.value == area.attacker then
                    enemyPresent = true
                end
            end
        end

        -- send message when theres a state change
        if not enemyAlreadyPresent and enemyPresent then
            WR.SendMessageToAllClients(WR.teamWinner[area.defender] .. " team will not be able to respawn after this cycle due to enemy presence in their base!")
        elseif enemyAlreadyPresent and not enemyPresent then
            WR.SendMessageToAllClients(WR.teamWinner[area.defender] .. " team can now respawn.")
        end

        area.captured = enemyPresent
    end
end