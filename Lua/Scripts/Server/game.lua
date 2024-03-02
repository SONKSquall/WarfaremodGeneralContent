if not Game.IsMultiplayer or (Game.IsMultiplayer and CLIENT) then return end

WR.Game = {}
WR.Game.ending = false
WR.Game.roundtick = 0
WR.Game.roundtickmax = 30*60*60

WR.Game.Data = dofile(WR.Path .. "/Lua/Scripts/Server/data.lua")
WR.Game.Data.Gamemode.Buildings = {}
local building = dofile(WR.Path .. "/Lua/Scripts/Server/building.lua")

-- register teams
for v in JobPrefab.Prefabs do
    if not v.HiddenJob then
        WR.Game.Data.Stats[tostring(v.Identifier)] = WR.Game.Data.SetDefault{}
        WR.Game.Data.Gamemode[tostring(v.Identifier)] = {Shops = {}}
    end
end
-- incase of reloadlua
if Game.RoundStarted then
    for shop in Util.GetItemsById("WR_strategicexchange") do
        local _, _, shopteam = string.find(shop.tags, "team='(.-)'")
        if shopteam then
            table.insert(WR.Game.Data.Gamemode[shopteam].Shops, shop)
        end
    end
    for item in Util.GetItemsById("label") do
        if item.HasTag("wr_building") then
            local walls = {}
            local rect = item.WorldRect
            for key,wall in pairs(Structure.WallList) do
                if wall.MaxHealth < 1000 then
                    if (math.abs(wall.WorldPosition.X - rect.X - rect.Width/2) <= rect.Width/2 and math.abs(wall.WorldPosition.Y - rect.Y + rect.Height/2) <= rect.Height/2) then
                        table.insert(walls,wall)
                    end
                end
            end
            WR.Game.Data.Gamemode.Buildings[item.ID] = building:New({Walls = walls})
            print(WR.Game.Data.Gamemode.Buildings[item.ID])
        end
    end
end

function WR.Game.endgame()
    if WR.Game.ending or not Game.RoundStarted then return end

    WR.Game.ending = true

    local winnermessage = WR.Game.getwinner() or "ERROR"
    WR.SendMessageToAllClients(winnermessage,nil)
    for n=1,15 do
        Timer.Wait(function()
            WR.SendMessageToAllClients("Round ending in "..15-n.." seconds.",{["type"] = ChatMessageType.Server, ["color"] = Color(255, 0, 0, 255), ["sender"] = "Server"})
        end,n*1000)
    end

    Timer.Wait(function()
        Game.EndGame()
    end,15*1000)
end

function WR.Game.getwinner()
    local victorytypes = {"Stalemate."," minor victory."," major victory!"," decisive victory!"," pyrrhic victory."}
    local victorytype
    local coalitiondeaths = WR.Game.Data.Stats.coalitionteam.Deaths or 1
    local renegadedeaths = WR.Game.Data.Stats.renegadeteam.Deaths or 1
    if WR.Game.Data.Stats.coalitionteam.Winbycap == true then
        local ratio = renegadedeaths/coalitiondeaths
        if ratio <= 1 then
            victorytype = victorytypes[5]
        elseif ratio >= 1.5 then
            victorytype = victorytypes[4]
        elseif ratio >= 1.25 then
            victorytype = victorytypes[3]
        elseif ratio >= 1 then
            victorytype = victorytypes[2]
        end
        return "Coalition"..victorytype
    elseif WR.Game.Data.Stats.renegadeteam.Winbycap == true then
        local ratio = coalitiondeaths/renegadedeaths
        if ratio <= 1 then
            victorytype = victorytypes[5]
        elseif ratio >= 1.5 then
            victorytype = victorytypes[4]
        elseif ratio >= 1.25 then
            victorytype = victorytypes[3]
        elseif ratio >= 1 then
            victorytype = victorytypes[2]
        end
        return "Renegade"..victorytype
    else
        if renegadedeaths/coalitiondeaths > 0.9 and renegadedeaths/coalitiondeaths < 1.1 then
            return victorytypes[1]
        elseif renegadedeaths==coalitiondeaths then
            return victorytypes[1]
        end
        local winner
        local ratio
        if renegadedeaths/coalitiondeaths > 1 then
            winner = "Coalition"
            ratio = renegadedeaths/coalitiondeaths
        elseif coalitiondeaths/renegadedeaths > 1 then
            winner = "Renegade"
            ratio = coalitiondeaths/renegadedeaths
        end
        if ratio >= 1.5 then
            victorytype = victorytypes[4]
        elseif ratio >= 1.25 then
            victorytype = victorytypes[3]
        elseif ratio >= 1 then
            victorytype = victorytypes[2]
        end
        return winner..victorytype
    end
end

Game.AddCommand("setroundlength", "Use to set a custom round length in minutes. (Works for one round)", function(args)
    WR.Game.roundtickmax = tonumber(args[1])*60*60
    print("NEW ROUND LENGTH: ",tonumber(args[1]))
end, nil, true)

Game.AddCommand("forceend", "Ends the round with a optional winner.", function(args)
    WR.Game.endgame()
end, nil, true)

Hook.add("roundStart", "WR.GameStart", function()

    WR.Game.roundtick = 0
    if WR.Game.roundtickmax == 0 then WR.Game.roundtickmax = 30*60*60 end
    WR.Game.ending = false

    for shop in Util.GetItemsById("WR_strategicexchange") do
        local _, _, shopteam = string.find(shop.tags, "team='(.-)'")
        if shopteam then
            table.insert(WR.Game.Data.Gamemode[shopteam].Shops, shop)
        end
    end
    for item in Util.GetItemsById("label") do
        if item and (item.HasTag("wr_building")) then
            local walls = {}
            local rect = item.WorldRect
            for wall in Structure.WallList do
                if wall.MaxHealth < 1000 then
                    if (math.abs(wall.WorldPosition.X - rect.X - rect.Width/2) <= rect.Width/2 and math.abs(wall.WorldPosition.Y - rect.Y + rect.Height/2) <= rect.Height/2) then
                        table.insert(walls,wall)
                    end
                end
            end
            WR.Game.Data.Gamemode.Buildings[item.ID] = building:New({Walls = walls})
            print(WR.Game.Data.Gamemode.Buildings[item.ID])
        end
    end

end)

Hook.add("roundEnd", "WR.GameEnd", function()

    WR.Game.Data.Save(tostring(os.date()))
    WR.Game.Data.Reset()
    for k,v in pairs(WR.Game.Data.Gamemode) do
        v = {Shops = {}}
    end
    WR.Game.Data.Gamemode.Buildings = {}

end)

Hook.add("think", "WR.GameManager", function()

    if WR.Game.roundtickmax == 0 or not Game.RoundStarted then return end

    WR.Game.roundtick = WR.Game.roundtick+1
    -- ends round if the timer is up
    if WR.Game.roundtick >= WR.Game.roundtickmax then
        WR.Game.endgame()
    end

    -- every 7.5 minutes
    if WR.Game.roundtick % 27000 == 0 then
        WR.SendMessageToAllClients("Round ending in"..WR.FormatTime((WR.Game.roundtickmax-WR.Game.roundtick)/60)..".",{["type"] = ChatMessageType.Server, ["sender"] = "Server"})
    end

    if WR.Game.roundtick % 60 == 0 then
        for building in WR.Game.Data.Gamemode.Buildings do
            if building:IsDestroyed() then
                building:AddDamage(5)
            end
        end
    end

end)

Hook.add("WR.gameobjective.xmlhook", "WR.gameobjective", function(effect, deltaTime, item, targets, worldPosition)

    if WR.Game.ending == true then return end

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
        WR.Game.Data.SetStat(attackertag,"Winbycap",true)
        WR.Game.endgame()
    end

end)

Hook.add("character.death", "WR.DeathLog", function(char)
    if WR.Game.ending then return end
    if char.isHuman then
        WR.Game.Data.AddStat(tostring(char.JobIdentifier), "Deaths", 1)
    end
end)