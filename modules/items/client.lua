EquippedItem = nil
ItemData = nil
local AttachedProp
local PerformingAction
local ProcessingEffect

function DisableControls(denied)
    for i=1, #denied do 
        DisableControlAction(0, denied[i], true)
    end
end

function RemoveAttachedProp()
    if AttachedProp and DoesEntityExist(AttachedProp) then
        DeleteEntity(AttachedProp)
    end
    AttachedProp = nil
end

function AttachProp(name)
    RemoveAttachedProp()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local cfg = Config.Items[name]
    local prop = cfg.prop
    AttachedProp = CreateProp(prop.model, coords.x, coords.y, coords.z, true, true, false)
    SetEntityCollision(AttachedProp, false, true)
    AttachEntityToEntity(AttachedProp, ped, GetPedBoneIndex(ped, prop.boneId), 
    prop.offset.x, prop.offset.y, prop.offset.z, 
    prop.rotation.x, prop.rotation.y, prop.rotation.z, false, false, false, true, 2, true)
end

function ConsumeItem(name)
    if PerformingAction then return end
    local held=ItemData
    if not held then return end
    if not lib.callback.await('pickle_consumables:beginUse',false,held.generation) then return end
    if ItemData~=held then return end
    PerformingAction = "consume"
    local cfg = Config.Items[name]
    local anim = cfg.animation
    local ped = PlayerPedId()
    CreateThread(function()
        local timeLeft = anim.time
        SendNUIMessage({
            type = "holdInteract",
            bool = true
        })
        while PerformingAction == "consume" and timeLeft > 0 do
            if anim.time - timeLeft > 100 and not IsEntityPlayingAnim(ped, anim.dict, anim.anim, 13) then
                timeLeft = timeLeft - 100
                PlayAnim(ped, anim.dict, anim.anim, anim.params[1] or 1.0, anim.params[2] or -1.0, anim.params[3] or -1, anim.params[4] or 1, anim.params[5] or 1, anim.params[6], anim.params[7], anim.params[8])
                Wait(100)
            else
                timeLeft = timeLeft - 10
                Wait(10)
            end
        end
        SendNUIMessage({
            type = "holdInteract",
            bool = false
        })
        ClearPedTasks(ped)
        if timeLeft > 0 and anim.time - timeLeft <= 100 then
            TriggerServerEvent("pickle_consumables:cancelUse",held.generation)
            OptionsMenu()
            PerformingAction = nil
        elseif timeLeft <= 0 then
            lib.callback("pickle_consumables:useItem", "", function(result, uses)
                if ItemData~=held or not result or type(uses)~='number' then PerformingAction=nil; return end
                if result and Config.Effects[cfg.effect?.name or ""] then
                    CreateThread(function()
                        if ProcessingEffect and not Config.Effects[cfg.effect.name].canOverlap then return end
                        ProcessingEffect = true
                        Config.Effects[cfg.effect.name].process(cfg.effect)
                        ProcessingEffect = false
                    end)
                end
                ItemData.uses = uses
                if uses < 1 then
                    return RemoveItem()
                end
                local cfg = Config.Items[name]
                SendNUIMessage({
                    type = "displayApp",
                    data = { quantity = uses, time = cfg.animation.time }
                })
                PerformingAction = nil
            end,held.generation)
        else
            TriggerServerEvent("pickle_consumables:cancelUse",held.generation)
            PerformingAction = nil
        end
    end)
end

function RemoveItem()
    local ped = PlayerPedId()
    SendNUIMessage({
        type = "hideApp",
    })
    RemoveAttachedProp()
    ClearPedTasks(ped)
    EquippedItem = nil
    ItemData = nil
    PerformingAction = nil
end

function ItemThread(name, metadata)
    if EquippedItem then return end
    EquippedItem = name
    ItemData = metadata
    AttachProp(name)
    local cfg = Config.Items[name]
    SendNUIMessage({
        type = "displayApp",
        data = { quantity = ItemData.uses, time = cfg.animation.time }
    })
    CreateThread(function()
        local pressTime = 0
        local holding = false
        while EquippedItem == name and ItemData==metadata do
            local ped = PlayerPedId()
            if IsControlJustPressed(1, 45) then
                TriggerServerEvent("pickle_consumables:returnItem")
            elseif IsControlPressed(1, 191) or IsControlPressed(1, 51) then
                if not PerformingAction then
                    ConsumeItem(name)
                end
            elseif PerformingAction then
                PerformingAction = nil
            end
            if cfg.idle and not PerformingAction then
                local anim = cfg.idle
                if not IsEntityPlayingAnim(ped, anim.dict, anim.anim, 13) then
                    PlayAnim(ped, anim.dict, anim.anim, anim.params[1] or 1.0, anim.params[2] or -1.0, anim.params[3] or -1, anim.params[4] or 1, anim.params[5] or 1, anim.params[6], anim.params[7], anim.params[8])
                    Wait(100)
                end
            end
            if GetEntityHealth(ped) < 1 then 
                local coords = GetEntityCoords(AttachedProp)
                local _, zCoords = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z)
                RemoveItem()
                TriggerServerEvent("pickle_consumables:drop:createDrop", vector3(coords.x, coords.y, zCoords + 1.0))
            end
            if insideMenu then 
                DisableControls({1, 2, 24, 69, 70, 92, 114, 140, 141, 142, 257, 263, 264})
            else
                DisableControls({24, 69, 70, 92, 114, 140, 141, 142, 257, 263, 264})
            end
            Wait(0)
        end
        local ped = PlayerPedId()
        ClearPedTasks(ped)
    end)
end

RegisterNetEvent("pickle_consumables:equipItem", function(name, metadata)
    if not Config.Items[name] then return print("^1ERROR: This item is not configured.^0") end
    if EquippedItem then return ShowNotification(_L("item_active")) end
    ItemThread(name, metadata)
end)

RegisterNetEvent("pickle_consumables:removeItem", function()
    RemoveItem()
end)

AddEventHandler("onResourceStop", function(name)
    if name ~= GetCurrentResourceName() then return end
    RemoveItem()
    local ped=PlayerPedId()
    ClearTimecycleModifier()
    StopGameplayCamShaking(true)
    SetPedIsDrunk(ped,false)
    SetPedMotionBlur(ped,false)
    ResetPedMovementClipset(ped,0.0)
    SetRunSprintMultiplierForPlayer(PlayerId(),1.0)
    TransitionFromBlurred(0)
    RemoveAttachedProp()
end)
RegisterNetEvent('pickle_consumables:restoreItem',function(item)
    if ItemData and ItemData.generation==item.generation then AttachProp(item.itemKey); return end
    RemoveItem()
    ItemThread(item.itemKey,item)
end)
CreateThread(function()
    while true do
        Wait(5000)
        TriggerServerEvent('pickle_consumables:initialize')
        TriggerServerEvent('pickle_consumables:drop:snapshot')
    end
end)
