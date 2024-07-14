if CLIENT then return end

local base = require "WR.Scripts.Server.Extensions.base"
local class = dofile(WR.Path .. "/Lua/singleton.lua")

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Items.Components.Turret"], "minRotation")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Items.Components.Turret"], "maxRotation")

WR.shellPrefabs = {
    railgunshell = ItemPrefab.GetItemPrefab("WR_largeshell"),
    flakbolt = ItemPrefab.GetItemPrefab("WR_shrapnelshell"),
    flakboltexplosive = ItemPrefab.GetItemPrefab("WR_shell")
}

local artillery = class(base)

artillery.name = "Artillery"
artillery.guns = {}
function artillery:onStart()
    self.guns = WR.Set.new(WR.GetItemsByTag("wr_artillery"))
    self.anchors = {}
    Hook.Patch("WR.artillery", "Barotrauma.Items.Components.Turret", "Launch", function(instance, ptable)
        if not self.guns[instance.Item] then return end
        if not self.enabled then return end

        Entity.Spawner.AddEntityToRemoveQueue(ptable["projectile"])
        local hullTop = instance.Item.CurrentHull.SimPosition.Y + ((instance.Item.CurrentHull.rect.height / 100) / 2)
        local angle = math.deg(instance.rotation)
        local leftFacing = math.cos(math.rad(angle)) < 0
        local maxAngle = math.deg(instance.maxRotation)
        local minAngle = math.deg(instance.minRotation)



        local tagVars = WR.getStringVariables(instance.Item.Tags)
        local maxRange = tonumber(tagVars["maxrange"]) or 200
        local minRange = tonumber(tagVars["minrange"]) or 25
        local spread = tonumber(tagVars["spread"]) or 25
        spread = spread * (math.random() - 0.5)
        local range

        if (math.cos(math.rad(maxAngle)) < 0 and math.cos(math.rad(minAngle)) > 0) or
        (math.cos(math.rad(maxAngle)) > 0 and math.cos(math.rad(minAngle)) < 0) then
            -- can face both ways
            if angle < 271 and angle > 269 then
                leftFacing = math.random() > 0.5
            end
            if leftFacing then
                range = WR.Lerp(WR.InvLerp(angle,270,minAngle), minRange, maxRange) * -1
            else
                range = WR.Lerp(WR.InvLerp(angle,270,maxAngle), minRange, maxRange)
            end
        elseif leftFacing then
            -- facing left
            range = WR.Lerp(WR.InvLerp(angle,maxAngle,minAngle), minRange, maxRange) * -1
        else
            -- facing right
            range = WR.Lerp(WR.InvLerp(angle,minAngle,maxAngle), minRange, maxRange)
        end
        local shellPrefab = WR.shellPrefabs[tostring(ptable["projectile"].Prefab.Identifier)] or ItemPrefab.GetItemPrefab("WR_shell")

        local spawnPos = nil
        Game.World.RayCast(function(fixture, point, normal, fraction)
            spawnPos = point
            return fraction
        end, Vector2(instance.Item.SimPosition.X + (range + spread), hullTop), Vector2(instance.Item.SimPosition.X + (range + spread), hullTop - 100), Physics.CollisionWall)
        spawnPos = WR.simPosToWorldPos(spawnPos + Vector2(0,1),true) -- small vertical buffer to prevent explosion doing no damage


        Timer.Wait(function()
            Entity.Spawner.AddItemToSpawnQueue(shellPrefab, spawnPos, nil, nil, function() end)
        end,2000 * (1 + WR.InvLerp(angle,minAngle,maxAngle)))
    end, Hook.HookMethodType.Before)
end
function artillery:onEnd()
    self.guns = {}
    self.anchors = {}
    Hook.RemovePatch("WR.artillery", "Barotrauma.Items.Components.Turret", "Launch", Hook.HookMethodType.Before)
end

return artillery