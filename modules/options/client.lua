insideMenu = nil
local Throwables = {}
local Drops = {}
local DropInteracts = {}
local PlacingProp

function OptionsMenu()
    if insideMenu then return end
    insideMenu = true
    local options = {
        {
            title = _L("give_item"),
            description = _L("give_item_desc"),
            onSelect = function()
                insideMenu = nil
                local players = GetPlayersInArea()
                local players_list = {}
                for i=1, #players do
                    local id = GetPlayerServerId(players[i])
                    players_list[#players_list + 1] = {label = _L("give_dialog_player", GetPlayerName(players[i]), id), value = id}
                end
                if #players_list < 1 then return ShowNotification(_L("nobody_near")) end
                local input = lib.inputDialog(_L("give_item"), {
                    {type = 'select', label = _L("give_dialog_player_title"), default = players_list[1].value, required = true, options = players_list},
                    {type = 'slider', label = _L("give_dialog_portion"), default = 1, required = true, min = 1, max = ItemData.uses },
                }) 
                if not input then return end
                local target = input[1]
                local amount = input[2]
                TriggerServerEvent("pickle_consumables:giveItem", target, amount)
            end
        },
        {
            title = _L("place_item"),
            description = _L("place_item_desc"),
            onSelect = function()
                insideMenu = nil
                local item = EquippedItem
                RemoveItem()
                PlaceProp(Config.Items[item].prop.model, function(coords)
                    TriggerServerEvent("pickle_consumables:drop:createDrop", vector3(coords.x, coords.y, coords.z + 1.04))
                end)
            end
        },
        {
            title = _L("throw_item"),
            description = _L("throw_item_desc"),
            onSelect = function()
                insideMenu = nil
                ThrowItem()
            end
        },
        {
            title = _L("cancel_action"),
            description = _L("cancel_action_desc"),
            onSelect = function()
                insideMenu = nil
            end
        },
    } 

    if #options < 1 or not EquippedItem then 
        insideMenu = nil
        return 
    end

    lib.registerContext({
        id = 'pickle_consumables_options',
        title = _L("pickle_consumables_options"),
        options = options,
        onExit = function() 
            insideMenu = nil
        end
    })
    lib.showContext('pickle_consumables_options')
end

-- Throwing

function GetDirectionFromRotation(rotation)
    local dm = (math.pi / 180)
    return vector3(-math.sin(dm * rotation.z) * math.abs(math.cos(dm * rotation.x)), math.cos(dm * rotation.z) * math.abs(math.cos(dm * rotation.x)), math.sin(dm * rotation.x))
end

function PerformPhysics(entity, action)
    local power = 1.0 * Config.Options.throwing.power
    FreezeEntityPosition(entity, false)
    local rot = GetGameplayCamRot(2)
    local dir = GetDirectionFromRotation(rot)
    SetEntityHeading(entity, rot.z + 90.0)
    if not action or action == "throw" then 
        SetEntityVelocity(entity, dir.x * power, dir.y * power, dir.z * power)
    else
        SetEntityVelocity(entity, dir.x * power, dir.y * power, (dir.z * 1.75) * power)
    end
end

function CreateThrowable(model, attach)
    local ped = PlayerPedId()
    local heading = GetEntityHeading(ped)
    local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.0, 0.5)
    local prop = CreateProp(model, coords.x, coords.y, coords.z, false, false, true)
    if not prop then return end
    if attach then 
        local off, rot = vector3(0.05, 0.0, -0.085), vector3(90.0, 90.0, 0.0)
        AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 28422), off.x, off.y, off.z, rot.x, rot.y, rot.z, false, false, false, true, 2, true)
    else 
        local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.0, -0.9)
        SetEntityCoords(prop, coords.x, coords.y, coords.z)
    end
    return prop
end

function ThrowItem()
    if not EquippedItem then return end
    local item = EquippedItem
    local ped = PlayerPedId()
    TriggerServerEvent("pickle_consumables:returnItem", true)
    RemoveItem()
    ClearPedTasksImmediately(ped)
    local prop = CreateThrowable(Config.Items[item].prop.model,true)
    CreateThread(function()
        PlayAnim(ped, "melee@thrown@streamed_core", "plyr_takedown_front", -8.0, 8.0, -1, 49)
        Wait(600)
        ClearPedTasks(ped)
    end)
    Wait(550)
    DetachEntity(prop, false, true)
    SetEntityCollision(prop, true, true)
    SetEntityRecordsCollisions(prop, true)
    local key=tostring(prop)
    Throwables[key]={entity=prop}
    SetTimeout(1000*Config.Options.throwing.despawnTime,function()
        if DoesEntityExist(prop) then DeleteEntity(prop) end
        Throwables[key]=nil
    end)
    local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, 1.0)
    SetEntityCoords(prop, coords.x, coords.y, coords.z)
    SetEntityHeading(prop, GetEntityHeading(ped) + 90.0)
    PerformPhysics(prop)
end

RegisterNetEvent("pickle_consumables:throwing:setObjectData", function(throwID, data)
    Throwables[throwID] = data
end)

-- Drops

function GetDirectionCoords()
    local range = 1000.0
	local coords = GetGameplayCamCoord()
    local rot = GetGameplayCamRot(2)
    local dir = GetDirectionFromRotation(rot)
	local ecoords = vector3(coords.x + dir.x * range, coords.y + dir.y * range, coords.z + dir.z * range)
    local retval, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(StartShapeTestRay(coords.x, coords.y, coords.z, ecoords.x, ecoords.y, ecoords.z, -1, -1, 1))
	return hit, endCoords, entityHit 
end

function PlaceProp(model, cb)
    if PlacingProp then return cb(nil, true) end 
    if not cb then return end
    PlacingProp = true
    local coords = GetEntityCoords(PlayerPedId())
    local heading = 0.0
    local prop = CreateObject(model, coords.x, coords.y, coords.z, false, true, false)
    FreezeEntityPosition(prop, true)
    SetEntityCollision(prop, false, false)
    CreateThread(function()
        while PlacingProp do
            ShowInteractText(_L("interact_place"))
            local hit, hitCoords, entity = GetDirectionCoords()
            if hit and hitCoords and #(hitCoords-GetEntityCoords(PlayerPedId()))<=3.0 then
                coords = vector3(hitCoords.x, hitCoords.y, hitCoords.z + 0.04)
                heading = GetGameplayCamRot(2).z
                SetEntityCoords(prop, coords.x, coords.y, coords.z)
                SetEntityRotation(prop, 0, 0, heading, 2)
                if IsControlJustPressed(1, 51) then
                    PlacingProp = false
                end
            end
            Wait(0) 
        end
        DeleteEntity(prop)
        if not cb then return end
        cb(coords, heading)
    end)
end

function RemoveDrop(dropID)
    Drops[dropID] = nil
    DeleteInteraction(DropInteracts[dropID])
    DropInteracts[dropID] = nil
end

RegisterNetEvent("pickle_consumables:drop:addDrop", function(dropID, data)
    RemoveDrop(dropID)
    Drops[dropID] = data
    DropInteracts[dropID] = CreateInteraction({
        label = _L("pickup_drop"),
        model = {modelType = "prop", hash = data.model, offset = vector3(0.0, 0.0, 0.0)},
        coords = data.coords,
        heading = data.heading
    }, function(selected)
        local ped = PlayerPedId()
        PlayAnim(ped, "random@domestic", "pickup_low", -8.0, 8.0, -1, 1, 1.0)
        Wait(1500)
        ClearPedTasks(ped)
        TriggerServerEvent("pickle_consumables:drop:collectDrop", dropID)
    end) 
end)

RegisterNetEvent("pickle_consumables:drop:removeDrop", function(dropID)
    RemoveDrop(dropID)
end)

RegisterNetEvent("pickle_consumables:updateUses", function(uses)
    if not ItemData then return end
    ItemData.uses = uses
    if uses < 1 then
        return RemoveItem()
    end
    local cfg = Config.Items[EquippedItem]
    SendNUIMessage({
        type = "displayApp",
        data = { quantity = uses, time = cfg.animation.time }
    })
end)

AddEventHandler("onResourceStop", function(name) 
    if (GetCurrentResourceName() ~= name) then return end
    for k,v in pairs(Throwables) do 
        if v.entity and DoesEntityExist(v.entity) then DeleteEntity(v.entity) end
    end
end)