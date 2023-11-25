WR = {} -- Warfare General Content Pack

WR.Path = ...
WR.Name = "Warfare (General Content Pack)"
WR.Version = "0.1.6.6"
WR.DeltaTime = 0
WR.Config = json.parse(File.Read(WR.Path .. "/config.json"))


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

dofile(WR.Path .. "/Lua/Scripts/helperfunctions.lua")
dofile(WR.Path .. "/Lua/Scripts/Server/weapons.lua")
dofile(WR.Path .. "/Lua/Scripts/Server/pow.lua")
dofile(WR.Path .. "/Lua/Scripts/Server/game.lua")
dofile(WR.Path .. "/Lua/Scripts/Server/welcomemessage.lua")
dofile(WR.Path .. "/Lua/Scripts/Server/oxygen.lua")

if CLIENT then
  dofile(WR.Path .. "/Lua/Scripts/Client/recoildisplay.lua")
end