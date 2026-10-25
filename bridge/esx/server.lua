if GetResourceState('es_extended') ~= 'started' then return end

RegisterUsableItem = nil
Framework = "ESX"
ESX = exports.es_extended:getSharedObject()

function ShowNotification(target, text)
	TriggerClientEvent(GetCurrentResourceName()..":showNotification", target, text)
end

function GetIdentifier(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    return xPlayer.identifier
end

function SetPlayerMetadata(source, key, data)
    -- No player metadata in ESX.
end

function AddMoney(source, count)
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.addMoney(count)
end

function RemoveMoney(source, count)
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.removeMoney(count)
end

function GetMoney(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    return xPlayer.getMoney()
end

function CheckPermission(source, permission)
    local xPlayer = ESX.GetPlayerFromId(source)
    local name = xPlayer.job.name
    local rank = xPlayer.job.grade
    local group = xPlayer.getGroup()
    if permission.jobs[name] and permission.jobs[name] <= rank then 
        return true
    end
    for i=1, #permission.groups do 
        if group == permission.groups[i] then 
            return true 
        end
    end
end

-- Status

function ExecuteStatus(source, statuses)
    local xPlayer = ESX.GetPlayerFromId(source)
    for k,v in pairs(statuses) do 
        if Config.MaxValues[k] then
            local value = (0.01 * v) * Config.MaxValues[k]
            TriggerClientEvent("pickle_consumables:executeStatus", source, k, value)
        else
            Config.ExternalStatus(source, k, v)
        end
    end
end
-- Inventory Fallback

CreateThread(function()
    Wait(100)
    if not RegisterUsableItem then
        RegisterUsableItem = function(name, cb)
            ESX.RegisterUsableItem(name, function(source, item, data) 
		if not data then data = {} end
                cb(source, data.metadata, data.slot)
            end)
        end
    end
    if InitializeInventory then return InitializeInventory() end -- Already loaded through inventory folder.
end)
