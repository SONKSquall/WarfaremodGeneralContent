if CLIENT and Game.IsMultiplayer then return end

-- This code is made off of Jerry Misc References,
-- special thanks to Jerry for letting me use it's code

local specialitemfunctions = {}

local gifts = {"WR_barbedwire_setup", "WR_sandbag_setup"}
local uniquegifts = {"nuclearshell", "exosuit"}


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
    uniquegifts = {"nuclearshell", "exosuit"}
end)