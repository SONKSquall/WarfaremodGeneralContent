local json = dofile(WR.Path .. "/Lua/json.lua")

local enabled = true
local data = {}

WR.dataManager = {}
WR.dataManager.saveKeys = {
    "teams",
    "round"
}

local function copyTable(t)
    local clone = {}
    for k,v in pairs(t) do
        if type(v) == "table" then
            clone[k] = copyTable(v)
        else
            clone[k] = v
        end
    end
    return clone
end


function WR.dataManager.setData(path,newValue)
    if not enabled then return end
    path = WR.stringSplit(path,"&.")
    local step = data
    for index,key in pairs(path) do
        if index == #path then step[key] = newValue break end -- set value
        if step[key] == nil then step[key] = {} warn("Path to data location not found, new one created at "..key) end -- create path if none is existent
        step = step[key] -- advance step
    end
    return step
end

function WR.dataManager.addData(path,newValue,action)
    local value = WR.dataManager.getData(path)
    value = action(value,newValue)
    WR.dataManager.setData(path,value)
end

function WR.dataManager.getData(path)
    if not enabled then return end
    path = WR.stringSplit(path,"&.")
    local step = copyTable(data) -- get by value
    for key in path do
        if step[key] == nil then return end
        step = step[key]
    end
    return step
end

function WR.dataManager.toggle(bool)
    if bool == nil then
        enabled = not enabled
        return
    else
        enabled = (bool == true)
    end
    return enabled
end

function WR.dataManager.save()
    local filedata = json.decode(File.Read(WR.Path .. "/Lua/WR/data.json"))
    local saveable = {}
    for key in WR.dataManager.saveKeys do
        saveable[key] = WR.dataManager.getData(key)
    end
    filedata[tostring(os.date())] = saveable
    File.Write(WR.Path .. "/Lua/WR/data.json", json.encode(filedata))
end

function WR.dataManager.reset()
    if not File.Exists(WR.Path .. "/Lua/WR/defaultdata.lua") then error("Error: default data file not found!") end
    data = dofile(WR.Path .. "/Lua/WR/defaultdata.lua")
end