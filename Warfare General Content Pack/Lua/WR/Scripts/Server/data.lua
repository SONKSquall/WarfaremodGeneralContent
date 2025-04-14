if CLIENT then return end

local json = dofile(WR.Path .. "/Lua/json.lua")

WR.data = {}
local _data = {}


local function read(table,key)
    return WR.getIndex(_data,key)
end

local function write(table,key,value)
    WR.setIndex(_data,key,value)
end

WR.data.saveKeys = {
    "teams",
    "round"
}

function WR.data.save()
    local filedata = json.decode(File.Read(WR.Path .. "/Lua/WR/data.json"))
    local saveable = {}
    for key in WR.data.saveKeys do
        saveable[key] = _data[key]
    end
    filedata[tostring(os.date())] = saveable
    File.Write(WR.Path .. "/Lua/WR/data.json", json.encode(filedata))
    return true
end

function WR.data.reset()
    if not File.Exists(WR.Path .. "/Lua/WR/defaultdata.lua") then return false end
    _data = dofile(WR.Path .. "/Lua/WR/defaultdata.lua")
    return true
end

setmetatable(WR.data,WR.data)

WR.data.__index = read
WR.data.__newindex = write