if CLIENT and Game.IsMultiplayer then return end

-- This code is made off of Jerry Misc References,
-- special thanks to Jerry for letting me use it's code

local specialitemfunctions = {}

local gifts = {"fuelrod","oxygentank","batterycell","assaultriflemagazine","fraggrenade","boardingaxe","flakcannonammoboxphysicorium","hyperzine","meth","steroids","antidama2","liquidoxygenite","cyanide","combatstimulantsyringe","WR_raspberryskinsealant","syringegun","guitar","harmonica","accordion","WR_dynamite","WR_landmine","WR_currency","WR_rifleammobox","WR_shotgunammobox","WR_revolverammobox"}
local uniquegifts = {"nuclearshell","exosuit","WR_germanshoulderstrap","WR_flyboyboots","autoshotgun","assaultrifle","thermalgoggles","nucleargun","radiojammer"}


specialitemfunctions["WR_present"] = function(item, callingPlayer)
    local israre = (math.random(1, 10) > 9)

    if #uniquegifts == 0 then israre = false end

    local index
    if (israre) then
        index = math.random(1, #uniquegifts)
    else
        index = math.random(1, #gifts)
    end

    local itemPrefab
    if (israre) then
        itemPrefab = ItemPrefab.GetItemPrefab(uniquegifts[index])
        -- prevents multiple of the same 'unique' gift 
        table.remove(uniquegifts, index)
    else
        itemPrefab = ItemPrefab.GetItemPrefab(gifts[index])
    end


    local playerPos = callingPlayer.worldPosition

    Entity.Spawner.AddItemToSpawnQueue(itemPrefab, playerPos, nil, nil, nil)
    Entity.Spawner.AddEntityToRemoveQueue(item)
end

Hook.Add("item.equip", "funnyItem", function(item, callingPlayer)

	if specialitemfunctions[item.Prefab.Identifier.Value] then
		specialitemfunctions[item.Prefab.Identifier.Value](item, callingPlayer)
	end
end)

Hook.add("roundStart", "WR.ResetUniquegifts", function()
    uniquegifts = {"nuclearshell","exosuit","WR_germanshoulderstrap","WR_flyboyboots","autoshotgun","assaultrifle","thermalgoggles","nucleargun","radiojammer"}
end)


-------------
--Halloween--
-------------

if not WR.HalloweenMode then return end

local periods = {
    Color(232, 186, 67, 255), -- evening
    Color(239, 129, 12, 180), -- dusk
    Color(3, 55, 82, 90), -- twilight
    Color(0, 26, 38, 10) -- night
}

-- 15 minutes - 60 secs per minute - 60 ticks per sec - 15 * 60 * 60 = 54000
local periodInterval = 54000/#periods
local currentPeriod = 1
local currentLightIndex = 1
local skyLights = {}

function WR.roundStartFunctions.dayReset()
    skyLights = {}
    currentPeriod = 1
    currentLightIndex = 1

    for item in Submarine.MainSub.GetItems(true) do

		if item.HasTag("skylight") then
			table.insert(skyLights, item)

			local lightComp = item.GetComponentString("LightComponent")
			lightComp.LightColor = periods[1]

			if SERVER then
			    local prop = lightComp.SerializableProperties[Identifier("LightColor")]
			    Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(prop, lightComp))
			end

		end
	end
end

function WR.thinkFunctions.dayCycle()

    if not Game.RoundStarted then return end
    if #skyLights <= 0 then return end
    if currentPeriod >= #periods then return end

    if WR.tick % 2 == 0 then

        currentPeriod = math.min(math.ceil(WR.tick / periodInterval),#periods)

        if currentPeriod >= #periods then
            WR.SendMessageToAllClients("Night has fallen...",{type = ChatMessageType.Server,color = Color(255, 0, 0, 255),sender = "..."})
            return
        end

        local light = skyLights[currentLightIndex]
        local lightComp = light.GetComponentString("LightComponent")

        local ratio = (WR.tick % periodInterval) / periodInterval
        local color = Color.Lerp(periods[currentPeriod], periods[currentPeriod+1], ratio)

        lightComp.LightColor = color

        if SERVER then
            local prop = lightComp.SerializableProperties[Identifier("LightColor")]
            Networking.CreateEntityEvent(light, Item.ChangePropertyEventData(prop, lightComp))
        end

        currentLightIndex = (currentLightIndex % #skyLights) + 1

    end
end