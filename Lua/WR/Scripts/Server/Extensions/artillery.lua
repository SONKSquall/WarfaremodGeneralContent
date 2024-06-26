if CLIENT then return end

local base = require "WR.Scripts.Server.Extensions.base"
local class = dofile(WR.Path .. "/Lua/singleton.lua")

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Items.Components.Turret"], "minRotation")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Items.Components.Turret"], "maxRotation")

-- not the right term, i know
local function normalizeAngle(angle)
    return math.abs(angle) % 90
end

WR.shellPrefabs = {
    railgun = ItemPrefab.GetItemPrefab("WR_bigshell"),
    flakcannon = ItemPrefab.GetItemPrefab("WR_shell")
}

local artillery = class(base)

artillery.name = "Artillery"
artillery.guns = {}
function artillery:onStart()
    self.guns = WR.Set.new(WR.GetItemsByTag("wr_artillery"))
    Hook.Patch("WR.artillery", "Barotrauma.Items.Components.Turret", "Launch", function(instance, ptable)
        if not self.guns[instance.Item] then return end
        if not self.enabled then return end
        Entity.Spawner.AddEntityToRemoveQueue(ptable["projectile"])
        local hullTop = instance.Item.CurrentHull.WorldPosition.y + (instance.Item.CurrentHull.rect.height / 2)
        local angle = normalizeAngle(instance.rotation * 57)
        -- the lower the angle, the higher the range
        local maxAngle = math.min(normalizeAngle(instance.maxRotation * 57), normalizeAngle(instance.minRotation * 57))
        local minAngle = math.max(normalizeAngle(instance.maxRotation * 57), normalizeAngle(instance.minRotation * 57))
        print(angle)
        print(maxAngle)
        print(minAngle)
        local tagVars = WR.getStringVariables(instance.Item.Tags)
        local maxRange = tonumber(tagVars["maxrange"]) * 100 or 20000
        local minRange = tonumber(tagVars["minrange"]) * 100 or 2500
        local spread = tonumber(tagVars["spread"]) * 100 or 1000
        local range = WR.Lerp(WR.InvLerp(angle,minAngle,maxAngle), minRange, maxRange)
        if instance.Item.FlippedX then range = range * -1 end
        local shellPrefab = WR.shellPrefabs[tostring(instance.Item.Prefab.Identifier)]
        Timer.Wait(function()
            Entity.Spawner.AddItemToSpawnQueue(shellPrefab, Vector2((instance.Item.WorldPosition.X + range) + ((math.random(spread * -1,spread)) * (1 + WR.InvLerp(angle,minAngle,maxAngle))),hullTop), nil, nil, function(shell)
                local proj = shell.GetComponentString("Projectile")
                proj.Use()
            end)
        end,5000 * (1 + (WR.InvLerp(angle,minAngle,maxAngle))))
    end, Hook.HookMethodType.Before)
end
function artillery:onEnd()
    self.guns = {}
    Hook.RemovePatch("WR.artillery", "Barotrauma.Items.Components.Turret", "Launch", Hook.HookMethodType.Before)
end

return artillery