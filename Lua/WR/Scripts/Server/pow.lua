if Game.IsMultiplayer and CLIENT then return end

local function spawncoins(shop,amount)
    if amount <= 0 then return end
    if not shop then return end
    local coin= ItemPrefab.GetItemPrefab("WR_currency")
    for i=1,amount do
        Entity.Spawner.AddItemToSpawnQueue(coin, shop.OwnInventory, nil, nil, nil)
    end
end

local function trickOrTreat(picker,amount)
    if not picker then return end
    if amount <= 0 then
        local tricks = {
            ItemPrefab.GetItemPrefab("WR_candyred"),
            ItemPrefab.GetItemPrefab("WR_candygreen"),
            ItemPrefab.GetItemPrefab("WR_candyblue")
        }
        Entity.Spawner.AddItemToSpawnQueue(tricks[math.random(1,3)], picker.Inventory, nil, nil, nil)
        return
    end

    local treats, whights = {
        ItemPrefab.GetItemPrefab("WR_bread"),
        ItemPrefab.GetItemPrefab("WR_beef"),
        ItemPrefab.GetItemPrefab("WR_jam")
    },
    {
        1,
        1,
        0.5
    }
    for i=1,amount do
        Entity.Spawner.AddItemToSpawnQueue(WR.weightedRandom(treats,whights), picker.Inventory, nil, nil, nil)
    end
end

-- removes pows and places their items in a footlocker
local function powhandle(targets,picker)
    local frendlyteam = picker.Info.Job.Prefab.Identifier.Value
    local shop = WR.data["userdata."..WR.teamKeys[frendlyteam].."shop"]
    local capturecount = 0
    for character in targets do
        if WR.IsEnemyPOW(character, frendlyteam) == true then

            -- spawning and despawning
            local footlocker = ItemPrefab.GetItemPrefab("WR_footlocker")
            if WR.HalloweenMode then
                footlocker = ItemPrefab.GetItemPrefab("WR_coffin")
            end
            Entity.Spawner.AddItemToSpawnQueue(footlocker, character.WorldPosition, nil, nil, function(container)
                WR.SpawnInventoryItems(character.Inventory.FindAllItems(nil, false, nil), container.OwnInventory)
            end)
            Entity.Spawner.AddEntityToRemoveQueue(character)

            local prisonerteam = character.Info.Job.Prefab.Identifier.Value
            -- increase spawntime for captured team by 5~ second
            WR.respawns[prisonerteam].multiplier = WR.respawns[prisonerteam].multiplier + 0.05

            -- data handling
            WR.data["teams."..frendlyteam..".captures"] = WR.data["teams."..frendlyteam..".captures"] + 1
            WR.data["teams."..prisonerteam..".deaths"] = WR.data["teams."..prisonerteam..".deaths"] + 1
            capturecount = capturecount+1
        end
    end

    -- halloween
    if WR.HalloweenMode then
        trickOrTreat(picker,capturecount)
    end

    spawncoins(shop,capturecount*5)
end

local picker

Hook.Add("WR.powteamgrabber.xmlhook", "WR.teamgrabber", function(effect, deltaTime, item, targets, worldPosition)
    picker = targets[1]
end)

Hook.Add("WR.powhandle.xmlhook", "WR.powhandle", function(effect, deltaTime, item, targets, worldPosition)
    Timer.NextFrame(function() powhandle(targets,picker) end)
end)

Hook.Add("WR.cuffs.xmlhook", "WR.cuffs", function(effect, deltaTime, item, targets, worldPosition)

    for character in targets do
        local carrierteam = tostring(character.JobIdentifier)

        if character.SelectedCharacter and WR.IsEnemyPOW(character.SelectedCharacter, carrierteam) then
            WR.GiveAfflictionCharacter(character, "WR_normalwalkspeed", 100)
        end
    end
end)