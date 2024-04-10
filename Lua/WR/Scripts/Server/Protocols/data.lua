if CLIENT then return end

require "WR.Scripts.Server.Protocols.base"

local json = dofile(WR.Path .. "/Lua/json.lua")
WR.data = WR.protocolBase:new({
    stats = {}, -- data gathered during the round
    info = {}, -- data gathered at the end of the round
    name = "Data",
    onStart = function(self)
        -- register teams
        for v in JobPrefab.Prefabs do
            if WR.teamKeys[v.Identifier.Value] then
                self.stats[tostring(v.Identifier.Value)] = {}
            end
        end
    end,
    Think = function(self)
        if self.enabled then
            self.tick = WR.tick
        end
    end,
    onEnd = function(self)
        self.info.roundLength = WR.FormatTime(self.tick / 60)
        self.info.roundWinner = tostring(WR.Game.winner)

        self:save(tostring(os.date()))
        self.stats = {}
        self.info = {}
    end,
    onCharacterDeath = function(self,char)
        if not char.IsHuman then return end
        self:addStat(tostring(char.Info.Job.Prefab.Identifier.Value),"deaths",1)
    end,
    End = function(self)
        self.enabled = false
        self:onEnd() -- make sure that the tick is available to the onEnd function
        self.tick = 0

        WR.thinkFunctions[self.name .. self.seed] = nil
        WR.roundEndFunctions[self.name .. self.seed] = nil
        WR.characterDeathFunctions[self.name .. self.seed] = nil
    end,
    setStat = function(self,team,stat,value)
        if not self.stats[team] then self.stats[team] = {} end
        self.stats[team][stat] = value
    end,
    addStat = function(self,team,stat,value)
        if not self.stats[team] then self.stats[team] = {} end
        local oldvalue = self.stats[team][stat] or 0
        self:setStat(team,stat,oldvalue+value)
    end,
    save = function(self,index)
        if not index then
            index = math.random(10000,99999)
        end
        index = tostring(index)
        local filedata = json.decode(File.Read(WR.Path .. "/Lua/WR/data.json"))
        local roundData = {["stats"] = self.stats, ["info"] = self.info}
        filedata[index] = roundData
        File.Write(WR.Path .. "/Lua/WR/data.json", json.encode(filedata))
    end,
    load = function(self,index)
        index = tostring(index)
        if not json.decode(File.Read(WR.Path .. "/Lua/WR/data.json"))[index] then error("Data does not exist. Index: " .. index,2) return end
        return json.decode(File.Read(WR.Path .. "/Lua/WR/data.json"))[index]
    end,
    getStat = function(self,team,stat)
        return self.stats[team][stat]
    end
})