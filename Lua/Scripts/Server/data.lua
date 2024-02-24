if CLIENT then return end

local json = dofile(WR.Path .. "/Lua/Scripts/json.lua")
local data = {}
data.Stats = {} -- strings, intergers, booleans, arrays
data.Gamemode = {} -- data thats used by the server (items, players, ect)
--[[
data.GmDefault = {
    Shops = {}
}
]]

function data.AddStat(team,stat,value)
    data.Stats[team][stat] = data.Stats[team][stat] + value or value
end

function data.SubStat(team,stat,value)
    data.Stats[team][stat] = math.min(data.Stats[team][stat] - value, 0) or 0
end

function data.Save(index)
    if not index then
        math.randomseed(os.time())
        index = math.random(10000,99999)
    end
    index = tostring(index)
    local filedata = json.decode(File.Read(WR.Path .. "/Lua/data.json"))
    filedata[index] = data.Stats
    File.Write(WR.Path .. "/Lua/data.json", json.encode(filedata))
end

function data.Load(index)
    index = tostring(index)
    if not json.decode(File.Read(WR.Path .. "/Lua/data.json"))[index] then error("Data does not exist. Index: " .. index,2) return end
    return json.decode(File.Read(WR.Path .. "/Lua/data.json"))[index]
end

function data.GetStat(team,stat)
    return data.Stats[team][stat]
end

function data.Reset()
    print("Reseting Stats.")
    for k,v in pairs(data.Stats) do
        v = {
            Deaths = 0,
            Captures = 0,
            Winbycap = false
        }
        print(k," reseted")
    end
    --[[
    print("Reseting Gamemode data.")
    for k,v in pairs(data.Gamemode) do
        v = data.GmDefault
        print(k," reseted")
    end
    ]]
end

function data.ResetStats()
    print("Reseting Stats.")
    for k,v in pairs(data.Stats) do
        v = data.Default
        print(k," reseted")
    end
end

return data