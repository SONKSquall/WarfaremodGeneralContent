if CLIENT then return end

local base = require "WR.Scripts.Server.Extensions.base"
local class = dofile(WR.Path .. "/Lua/singleton.lua")

local json = dofile(WR.Path .. "/Lua/json.lua")
local data = class(base)
data.stats = {} -- data gathered during the round
data.info = {} -- data gathered at the end of the round
data.name = "Data"

function data:onStart()
    -- register teams
    for v in JobPrefab.Prefabs do
        if WR.teamKeys[v.Identifier.Value] then
            self.stats[tostring(v.Identifier.Value)] = {}
        end
    end
end
function data:Think()
    if self.enabled then
        self.tick = WR.tick
    end
end
function data:onEnd()
    self.info.roundLength = WR.FormatTime(self.tick / 60)
    self.info.roundWinner = tostring(WR.Game.winner)
    self:save(tostring(os.date()))
    self.stats = {}
    self.info = {}
end
function data:onCharacterDeath(char)
    if not char.IsHuman then return end
    self:addStat(tostring(char.Info.Job.Prefab.Identifier.Value),"deaths",1)
end
function data:End()
    self.enabled = false
    self:onEnd() -- make sure that the tick is available to the onEnd function
    self.tick = 0
    WR.thinkFunctions[self.name] = nil
    WR.roundEndFunctions[self.name] = nil
    WR.characterDeathFunctions[self.name] = nil
end
function data:setStat(team,stat,value)
    if not self.stats[team] then self.stats[team] = {} end
    self.stats[team][stat] = value
end
function data:addStat(team,stat,value)
    if not self.stats[team] then self.stats[team] = {} end
    local oldvalue = self.stats[team][stat] or 0
    self:setStat(team,stat,oldvalue+value)
end
function data:save(index)
    if not index then
        index = math.random(10000,99999)
    end
    index = tostring(index)
    local filedata = json.decode(File.Read(WR.Path .. "/Lua/WR/data.json"))
    local roundData = {["stats"] = self.stats, ["info"] = self.info}
    filedata[index] = roundData
    File.Write(WR.Path .. "/Lua/WR/data.json", json.encode(filedata))
end
function data:load(index)
    index = tostring(index)
    if not json.decode(File.Read(WR.Path .. "/Lua/WR/data.json"))[index] then error("Data does not exist. Index: " .. index,2) return end
    return json.decode(File.Read(WR.Path .. "/Lua/WR/data.json"))[index]
end
function data:getStat(team,stat)
    return self.stats[team][stat]
end

return data