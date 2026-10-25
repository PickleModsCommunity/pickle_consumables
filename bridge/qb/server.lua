if GetResourceState('qb-core') ~= 'started' then return end

Framework = "QB"
QBCore = exports['qb-core']:GetCoreObject()

function ShowNotification(target, text)
	TriggerClientEvent(GetCurrentResourceName()..":showNotification", target, text)
end

function GetIdentifier(source)
    local xPlayer = QBCore.Functions.GetPlayer(source).PlayerData
    return xPlayer.citizenid 
end

function SetPlayerMetadata(source, key, data)
    QBCore.Functions.GetPlayer(source).Functions.SetMetaData(key, data)
end

function AddMoney(source, count)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    xPlayer.Functions.AddMoney('cash',count)
end

function RemoveMoney(source, count)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    xPlayer.Functions.RemoveMoney('cash',count)
end

function GetMoney(source)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    return xPlayer.PlayerData.money.cash
end

function CheckPermission(source, permission)
    local xPlayer = QBCore.Functions.GetPlayer(source).PlayerData
    local name = xPlayer.job.name
    local rank = xPlayer.job.grade.level
    if permission.jobs[name] and permission.jobs[name] <= rank then 
        return true
    end
    for i=1, #permission.groups do 
        if QBCore.Functions.HasPermission(source, permission.groups[i]) then 
            return true 
        end
    end
end

-- Status

function ExecuteStatus(source, statuses)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    for k,v in pairs(statuses) do 
        if Config.MaxValues[k] then
            local value = (0.01 * v) * Config.MaxValues[k]
            if xPlayer.PlayerData.metadata[k] then
                xPlayer.PlayerData.metadata[k] = ((xPlayer.PlayerData.metadata[k] + value < 0) and 0 or (xPlayer.PlayerData.metadata[k] + value))
            else
                xPlayer.PlayerData.metadata[k] = (value > 0 and value or 0)
            end
            xPlayer.Functions.SetMetaData(k, xPlayer.PlayerData.metadata[k])
        else
            Config.ExternalStatus(source, k, v)
        end
    end
end

-- Inventory Fallback

CreateThread(function()
    Wait(100)
    
    if not RegisterUsableItem then
        function RegisterUsableItem(name, cb)
            QBCore.Functions.CreateUseableItem(name, function(source, data)
                local item = data
                if item.info then
                    item.metadata = data.info
                    item.info = nil
                end
                cb(source, item.metadata, item.slot)
            end)
        end
    end

    if InitializeInventory then return InitializeInventory() end -- Already loaded through inventory folder.
    
    Inventory = {}

    Inventory.Items = {}
    
    Inventory.Ready = false

    Inventory.CanCarryItem = function(source, name, count)
        local slots = 40 -- Change this if higher / lower.
        local items = Inventory.GetInventory(source)
        return (#items + count < slots)
    end

    Inventory.GetInventory = function(source)
        local xPlayer = QBCore.Functions.GetPlayer(source)
        local items = {}
        local data = xPlayer.PlayerData.items
        for slot, item in pairs(data) do 
            items[#items + 1] = {
                name = item.name,
                label = item.label,
                count = item.amount,
                weight = item.weight,
                slot = item.slot,
                metadata = item.info
            }
        end
        return items
    end

    Inventory.AddItem = function(source, name, count, metadata, slot) -- Metadata is not required.
        local xPlayer = QBCore.Functions.GetPlayer(source)
        if not xPlayer then return false end
        return xPlayer.Functions.AddItem(name, count, slot, metadata)
    end

    Inventory.RemoveItem = function(source, name, count, slot)
        local xPlayer = QBCore.Functions.GetPlayer(source)
        if not xPlayer then return false end
        return xPlayer.Functions.RemoveItem(name, count, slot)
    end
    
    Inventory.SetMetadata = function(source, slot, metadata)
        local xPlayer = QBCore.Functions.GetPlayer(source)
        local Inventory = xPlayer.PlayerData.items
        Inventory[slot].info = metadata
        xPlayer.Functions.SetInventory(Inventory, true)
    end
    
    Inventory.GetItemCount = function(source, name)
        local xPlayer = QBCore.Functions.GetPlayer(source)
        local item = xPlayer.Functions.GetItemByName(name)
        return item and item.amount or 0
    end

    lib.callback.register("pickle_consumables:getInventory", function(source)
        return Inventory.GetInventory(source)
    end)

    for item, data in pairs(QBCore.Shared.Items) do
        Inventory.Items[item] = {label = data.label}
    end

    Inventory.Ready = true
end)