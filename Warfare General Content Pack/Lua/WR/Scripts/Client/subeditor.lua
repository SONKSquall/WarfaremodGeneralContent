Game.AddCommand("wr_replace", "", function(args)
    if #args < 1 then return end
    local itemId = tostring(args[1])
    local replacePrefab = ItemPrefab.GetItemPrefab(args[2])
    local count = args[3] or 1

    for item in Item.ItemList do
        if WR.id(item) == itemId then
            local inventory = item.ParentInventory
            if inventory then
                local index = inventory.FindIndex(item)
                local amount = 0
                for stackedItem in item.GetStackedItems() do
                    amount = amount + 1
                    stackedItem.Remove()
                end
                Timer.NextFrame(function()
                    if replacePrefab then
                        for i=1,(amount*count) do
                            local replacement = Item(replacePrefab,Vector2(0,0),nil,nil)
                            inventory.ForceToSlot(replacement,index)
                        end
                    end
                end)
            else
                local position = item.WorldPosition

                item.Remove()
                if replacePrefab then
                    for i=1,count do
                        Item(replacePrefab,position,nil,nil)
                    end
                end
            end
        end
    end
end, nil, true)

Game.AddCommand("wr_fill", "", function(args)
    if #args < 2 then return end
    local itemId = tostring(args[1])
    local fillPrefab = ItemPrefab.GetItemPrefab(args[2])
    local count = args[3]

    for item in Item.ItemList do
        if WR.id(item) == itemId then
            local inventory = item.OwnInventory
            for i=1,count or 1 do
                local fillItem = Item(fillPrefab,item.WorldPosition,nil,nil)
                local index = inventory.FindAllowedSlot(fillItem, true)

                if index >= 0 then
                    inventory.ForceToSlot(fillItem,index)
                end
            end
        end
    end
end, nil, true)