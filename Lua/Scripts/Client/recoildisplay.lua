if SERVER then return end

Networking.Receive("updaterecoil", function (message, client)

    local recoil = message.ReadDouble()
    local key = message.ReadDouble()
    local client = Client.ClientList[key]

    if not client.Character then return end

    for item in client.Character.HeldItems do
        local id = tostring(item.Prefab.Identifier)
        -- if the item has a object in the json then execute       
        if item.HasTag("gun") and WR.Config.WeaponRecoil[id] then
            local maxspread = WR.Config.WeaponRecoil[id].maxspread
            local minspread = WR.Config.WeaponRecoil[id].minspread
            local rangedweapon = item.GetComponentString("RangedWeapon")

            rangedweapon.Spread = math.max(maxspread * recoil, minspread)
        end
    end
end)