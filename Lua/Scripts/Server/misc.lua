if CLIENT and Game.IsMultiplayer then return end

-- This code is made off of Jerry Misc References,
-- special thanks to Jerry for letting me use it's code

local specialitemfunctions = {}

local gifts = {"fuelrod","oxygentank","batterycell","assaultriflemagazine","fraggrenade","boardingaxe","flakcannonammoboxphysicorium","hyperzine","meth","steroids","antidama2","liquidoxygenite","cyanide","combatstimulantsyringe","syringegun","guitar","harmonica","accordion","WR_dynamite","WR_landmine","WR_currency","WR_rifleammobox","WR_shotgunammobox","WR_revolverammobox"}
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