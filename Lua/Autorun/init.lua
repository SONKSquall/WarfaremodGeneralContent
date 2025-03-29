WR = {} -- Warfare General Content Pack

WR.Path = ...
WR.Name = "Warfare (General Content Pack)"
WR.Version = "0.2.10.0"
WR.DeltaTime = 0
local json = dofile(WR.Path .. "/Lua/json.lua")
WR.Config = json.decode(File.Read(WR.Path .. "/config.json"))


-- get delta time here so we don't have to calculate it every time we need it
local currentframe = 0

local function UpdateDeltaTime() 
  local delta = Timer.GetTime() - currentframe
  currentframe = Timer.GetTime()
  return delta
end

Hook.Add('think', 'WR.UpdateDeltaTime', function ()
    WR.DeltaTime = UpdateDeltaTime()
end)

dofile(WR.Path .. "/Lua/WR/Scripts/Server/data.lua")
dofile(WR.Path .. "/Lua/WR/Scripts/helperfunctions.lua")
dofile(WR.Path .. "/Lua/WR/Scripts/Server/pow.lua")
dofile(WR.Path .. "/Lua/WR/Scripts/Server/game.lua")
dofile(WR.Path .. "/Lua/WR/Scripts/Server/chatcommands.lua")
dofile(WR.Path .. "/Lua/WR/Scripts/Server/oxygen.lua")
dofile(WR.Path .. "/Lua/WR/Scripts/Server/teambalance.lua")
dofile(WR.Path .. "/Lua/WR/Scripts/Client/subeditor.lua")

-- for holiday stuff
WR.HalloweenMode = false

dofile(WR.Path .. "/Lua/WR/Scripts/Server/misc.lua")