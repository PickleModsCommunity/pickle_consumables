if GetResourceState('ox_inventory') ~= 'started' then return end

Inventory = {}

Inventory.Items = {}

Inventory.Ready = false

Inventory.CanCarryItem = function(source, name, count)
    return exports.ox_inventory:CanCarryItem(source, name, count)
end

Inventory.GetInventory = function(source)
    local items = {}
    local data = exports.ox_inventory:GetInventoryItems(source)
    for slot, item in pairs(data) do 
        items[#items + 1] = {
            name = item.name,
            label = item.label,
            count = item.count,
            weight = item.weight,
            slot = item.slot,
            metadata = item.metadata
        }
    end
    return items
end

Inventory.AddItem = function(source, name, count, metadata, slot) -- Metadata is not required.
    return exports.ox_inventory:AddItem(source, name, count, metadata, slot)
end

Inventory.RemoveItem = function(source, name, count, slot)
    return exports.ox_inventory:RemoveItem(source, name, count, nil, slot)
end

Inventory.SetMetadata = function(source, slot, metadata)
    exports.ox_inventory:SetMetadata(source, slot, metadata)
end

Inventory.GetItemCount = function(source, name)
    return exports.ox_inventory:Search(source, "count", name) or 0
end

function InitializeInventory()
    lib.callback.register("pickle_consumables:getInventory", function(source)
        return Inventory.GetInventory(source)
    end)
    
    for item, data in pairs(exports.ox_inventory:Items()) do
        Inventory.Items[item] = {label = data.label}
    end
    
    Inventory.Ready = true
end