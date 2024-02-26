if CLIENT then return end

local json = dofile(WR.Path .. "/Lua/Scripts/json.lua")
local data = {}
data.Stats = {} -- strings, intergers, booleans, arrays
data.Gamemode = {} -- data thats used by the server (items, players, ect)
data.Default = {
    Deaths = 0,
    Captures = 0,
    Winbycap = false
}

function data.SetStat(team,stat,value)
    if not data.Stats[team] then data.Stats[team] = data.SetDefault{} end
    data.Stats[team][stat] = value
end

function data.AddStat(team,stat,value)
    if not data.Stats[team] then data.Stats[team] = data.SetDefault{} end
    local oldvalue = data.Stats[team][stat] or 0
    data.SetStat(team,stat,oldvalue+value)
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

function data.SetDefault(table)
    for k in pairs(data.Default) do
        table[k] = data.Default[k]
    end
    -- remove extra values
    for k in pairs(table) do
        table[k] = data.Default[k]
    end
    return table
end

function data.Reset()
    print("Reseting Stats.")
    for v in data.Stats do
        data.SetDefault(v)
    end
end

return data