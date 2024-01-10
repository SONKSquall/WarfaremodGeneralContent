if not Game.IsMultiplayer or (Game.IsMultiplayer and CLIENT) then return end

WR.Game = {}
WR.Game.roundwinner = "..."
WR.Game.roundending = false
WR.Game.roundtick = 0
WR.Game.roundtickmax = 0

Game.AddCommand("setroundlength", "Use to set a custom round length in minutes. (Works for one round)", function(args)
    WR.Game.roundtickmax = tonumber(args[1])*60*60
    print("NEW ROUND LENGTH: ",tonumber(args[1]))
end, nil, true)

Game.AddCommand("forceend", "Ends the round with a optional winner.", function(args)
    WR.Game.roundending = true
    WR.Game.roundwinner = string.gsub(args[1], "_", " ") or "Unknown winner"
end, nil, true)

Hook.add("roundStart", "WR.GameStart", function()

    WR.Game.roundtick = 0
    if WR.Game.roundtickmax == 0 then WR.Game.roundtickmax = 30*60*60 end
    WR.Game.roundending = false
    WR.Game.roundwinner = "..."

end)

Hook.add("think", "WR.GameManager", function()

    if WR.Game.roundtickmax == 0 or not Game.RoundStarted then return end

    WR.Game.roundtick = WR.Game.roundtick+1
    -- checks for round end or if the timer is up
    if WR.Game.roundending or WR.Game.roundtick >= WR.Game.roundtickmax then
        WR.Game.roundending = false

        local winnermessage = WR.Game.roundwinner .. " is the winner!"
        WR.SendMessageToAllClients(winnermessage,nil)
        WR.Game.roundwinner = "..."
        for n=1,15 do
            Timer.Wait(function()
                WR.SendMessageToAllClients("Round ending in "..15-n.." seconds.",{["type"] = ChatMessageType.Server, ["color"] = Color(150, 150, 150, 255), ["sender"] = "Server"})
            end,n*1000)
        end

        Timer.Wait(function()
            Game.EndGame()
        end,15*1000)
    end

end)

Hook.add("roundEnd", "WR.GameEnd", function()

    WR.Game.roundtickmax = 0

end)

Hook.add("WR.gameobjective.xmlhook", "WR.gameobjective", function(effect, deltaTime, item, targets, worldPosition)

    if WR.Game.roundending == true then return end

    local tags = item.Tags
    local rect = item.WorldRect
    local Teams = {}
    Teams.attacker = {}
    Teams.attackerteam = {}
    Teams.defender = {}
    -- gets the defender & attacker strings from tags placed in the sub editor
    -- the first two '_' are dummy vars
    local _, _, defendertag = string.find(tags, 'defender="(.-)"')
    local _, _, attackertag = string.find(tags, 'attacker="(.-)"')
    local _, _, winnertag = string.find(tags, 'winnerifcaptured="(.-)"')

    -- gets the total number of attackers on the team
    for key,player in pairs(Client.ClientList) do
        if player.Character and (player.Character.JobIdentifier == attackertag and not player.Character.IsDead) then
            Teams.attackerteam[#Teams.attackerteam+1] = player
        end
    end
    if #Teams.attackerteam <= 0 then return end
    -- gets the number of players present
    for key,player in pairs(Client.ClientList) do
        if player.Character and (math.abs(player.Character.WorldPosition.X - rect.X - rect.Width/2) <= rect.Width/2 and math.abs(player.Character.WorldPosition.Y - rect.Y + rect.Height/2) <= rect.Height/2) then
            if player and (player.Character.JobIdentifier == defendertag and not (player.Character.IsDead or player.Character.IsUnconscious)) then
                Teams.defender[#Teams.defender+1] = player
            elseif player and (player.Character.JobIdentifier == attackertag and not (player.Character.IsDead or player.Character.IsUnconscious)) then
                Teams.attacker[#Teams.attacker+1] = player
            end
        end
    end
    -- if there is more then 50% of the alive attacker team present and no defender then the round ends with attacker victory
    if math.abs(#Teams.attacker/#Teams.attackerteam) > 0.5 and #Teams.defender == 0 then
        WR.Game.roundwinner = string.gsub(winnertag, "_", " ") or "Unknown winner"
        WR.Game.roundending = true
    end

end)