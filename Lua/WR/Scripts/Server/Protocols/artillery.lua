if CLIENT then return end

require "WR.Scripts.Server.Protocols.base"

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Items.Components.Turret"], "minRotation")
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Items.Components.Turret"], "maxRotation")

-- not the right term, i know
local function normalizeAngle(angle)
    return math.abs(angle) % 180
end

WR.shellPrefabs = {
    railgun = ItemPrefab.GetItemPrefab("railgunshell"),
    flakcannon = ItemPrefab.GetItemPrefab("flakboltexplosive")
}

WR.artillery = WR.protocolBase:new({
    name = "Artillery",
    guns = {},
    onStart = function(self)
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

            local maxRange = 20000
            local minRange = 2500
            local spread = 1000
            print(angle)
            print(maxAngle)
            print(minAngle)

            for tag in instance.Item.GetTags() do
                local sTag = tostring(tag)
                if WR.stringKeyVar(tostring(sTag))["maxrange"] then
                    maxRange = tonumber(WR.stringKeyVar(sTag)["maxrange"]) * 100
                elseif WR.stringKeyVar(tostring(sTag))["minrange"] then
                    minRange = tonumber(WR.stringKeyVar(sTag)["minrange"]) * 100
                elseif WR.stringKeyVar(tostring(sTag))["spread"] then
                    spread = tonumber(WR.stringKeyVar(sTag)["spread"]) * 100
                end
            end

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
    end,
    Think = function(self)
        if self.enabled then
            self.tick = self.tick + 1

        end
    end,
    onEnd = function(self)
        self.guns = {}
        Hook.RemovePatch("WR.artillery", "Barotrauma.Items.Components.Turret", "Launch", Hook.HookMethodType.Before)
    end
})