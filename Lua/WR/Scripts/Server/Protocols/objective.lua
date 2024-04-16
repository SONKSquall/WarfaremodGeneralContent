if CLIENT then return end

require "WR.Scripts.Server.Protocols.base"

local area = {}
area.rect = {X = 0, Y = 0}
area.attacker = ""
area.defender = ""
area.captured = false

function area:getRectClients()
    local clients = {}
    for client in Client.ClientList do
        if client.Character and (math.abs(client.Character.WorldPosition.X - self.rect.X - self.rect.Width/2) <= self.rect.Width/2 and math.abs(client.Character.WorldPosition.Y - self.rect.Y + self.rect.Height/2) <= self.rect.Height/2) then
            table.insert(clients,client)
        end
    end
    return clients
end

function area:getTeamCount()
    local clients = self:getRectClients()
    local attackers = 0
    local totalAttackers = 0
    local defenders = 0

    for player in Client.ClientList do
        if player.Character and (player.Character.JobIdentifier == self.attacker and not player.Character.IsDead) then
            totalAttackers = totalAttackers + 1
        end
    end
    for player in clients do
        if player.Character then
            if (player.Character.JobIdentifier == self.defender and not (player.Character.IsDead or player.Character.IsUnconscious or WR.IsEnemyPOW(player.Character, self.attacker))) then
                defenders = defenders + 1
            elseif (player.Character.JobIdentifier == self.attacker and not (player.Character.IsDead or player.Character.IsUnconscious or WR.IsEnemyPOW(player.Character, self.defender))) then
                attackers = attackers + 1
            end
        end
    end
    return defenders, attackers, totalAttackers
end

function area:new(o)
    o = o or {}   -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
end

WR.objective = WR.protocolBase:new({
    name = "Objective manager",
    areas = {},
    onStart = function(self)
        -- registers areas
        for item in Util.GetItemsById("label") do
            if item.HasTag("wr_objective") then

                local tagVars = WR.getStringVariables(item.Tags)
                local defender = tagVars["defender"] or ""
                local attacker = tagVars["attacker"] or ""
                -- each area is its own object
                table.insert(self.areas, area:new({
                    rect = item.WorldRect,
                    defender = WR.teamKeys[defender],
                    attacker = WR.teamKeys[attacker]
                }))
            end
        end
    end,
    Think = function(self)
        if self.enabled then
            self.tick = self.tick + 1

            if self.tick % 60 == 0 then
                for obj in self.areas do

                    local defenders, attackers, totalAttackers = obj:getTeamCount()

                    -- avoid 0/0
                    if attackers >= 1 then
                        -- if there is more then 50% of the alive attacker team present and no defenders then the area is captured
                        if math.abs(attackers/totalAttackers) > 0.5 and defenders == 0 then
                            obj.captured = true
                        end
                    end
                end
            end
        end
    end,
    onEnd = function(self)
        self.areas = {}
    end
})