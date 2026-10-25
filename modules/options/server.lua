local Drops, locks, last = {}, {}, {}
local function persist() SetResourceKvp('drops',json.encode(Drops)) end
CreateThread(function()
    local ok,saved=pcall(json.decode,GetResourceKvpString('drops') or '{}')
    if ok and type(saved)=='table' then
        for id,d in pairs(saved) do
            if d.expires and d.expires>os.time() then
                d.coords=vector3(d.coords.x,d.coords.y,d.coords.z)
                Drops[id]=d
            end
        end
    end
    while true do
        Wait(1000)
        for id,d in pairs(Drops) do
            if d.expires<=os.time() and not locks[id] then
                Drops[id]=nil
                TriggerClientEvent('pickle_consumables:drop:removeDrop',-1,id)
                persist()
            end
        end
    end
end)
local function nearby(src,coords,bucket)
    local ped=GetPlayerPed(src)
    return ped~=0 and GetPlayerRoutingBucket(src)==bucket and #(GetEntityCoords(ped)-coords)<=3.0
end
local function position(coords)
    if type(coords)~='vector3' and type(coords)~='table' then return end
    for _,k in ipairs({'x','y','z'}) do
        if type(coords[k])~='number' or coords[k]~=coords[k] or math.abs(coords[k])>20000 then return end
    end
    return vector3(coords.x,coords.y,coords.z)
end
local function rate(src)
    local now=GetGameTimer()
    if last[src] and now-last[src]<250 then return false end
    last[src]=now; return true
end
local function remove(id)
    Drops[id]=nil
    persist()
    TriggerClientEvent('pickle_consumables:drop:removeDrop',-1,id)
end
RegisterNetEvent('pickle_consumables:drop:createDrop',function(coords)
    local src=source; local item=CurrentHeld(src); coords=position(coords)
    if not rate(src) or not item or not coords or not nearby(src,coords,GetPlayerRoutingBucket(src)) then
        if item then TriggerClientEvent('pickle_consumables:restoreItem',src,item) end
        return
    end
    local id=tostring(os.time())..'_'..tostring(math.random(1,1000000000))
    local drop={itemKey=item.itemKey,uses=item.uses,coords=coords,heading=0,
        model=Config.Items[item.itemKey].prop.model,bucket=GetPlayerRoutingBucket(src),expires=os.time()+(Config.Options.drop.despawnTime or 120)}
    Drops[id]=drop
    persist()
    ClearHeld(src)
    TriggerClientEvent('pickle_consumables:removeItem',src)
    TriggerClientEvent('pickle_consumables:drop:addDrop',-1,id,drop)
    SetTimeout(1000*(Config.Options.drop.despawnTime or 120),function() if Drops[id]==drop and not locks[id] then remove(id) end end)
end)
RegisterNetEvent('pickle_consumables:drop:collectDrop',function(id)
    local src=source; local drop=Drops[id]
    if not rate(src) or not drop or locks[id] or not nearby(src,drop.coords,drop.bucket) or not ConsumableIdentity(src) then return end
    locks[id]=true
    local success
    if CurrentHeld(src) then
        success=Inventory.AddItem(src,drop.itemKey,1,{itemKey=drop.itemKey,uses=drop.uses})==true
    else success=EquipItem(src,drop) end
    if success then remove(id) end
    locks[id]=nil
end)
RegisterNetEvent('pickle_consumables:giveItem',function(target,amount)
    local src=source; local item=CurrentHeld(src)
    if not rate(src) or not item or locks[src] or type(target)~='number' or target%1~=0 or target==src
        or target<1 or not ConsumableIdentity(target) or locks[target]
        or type(amount)~='number' or amount%1~=0 or amount<1 or amount>item.uses
        or not nearby(src,GetEntityCoords(GetPlayerPed(target)),GetPlayerRoutingBucket(target)) then return end
    locks[src],locks[target]=true,true
    local other=CurrentHeld(target)
    local success=false
    if other and other.itemKey==item.itemKey and other.uses+amount<=Config.Items[item.itemKey].uses then
        other.uses=other.uses+amount; SaveHeld(target)
        TriggerClientEvent('pickle_consumables:updateUses',target,other.uses)
        success=true
    elseif other then
        success=Inventory.AddItem(target,item.itemKey,1,{itemKey=item.itemKey,uses=amount})==true
    else success=EquipItem(target,{itemKey=item.itemKey,uses=amount}) end
    if success then
        item.uses=item.uses-amount
        item.consuming=nil
        if item.uses==0 then ClearHeld(src); TriggerClientEvent('pickle_consumables:removeItem',src)
        else SaveHeld(src); TriggerClientEvent('pickle_consumables:updateUses',src,item.uses) end
    end
    locks[src],locks[target]=nil,nil
end)
RegisterNetEvent('pickle_consumables:drop:snapshot',function()
    local src=source
    if not ConsumableIdentity(src) or not rate(src) then return end
    for id,drop in pairs(Drops) do
        if GetPlayerRoutingBucket(src)==drop.bucket then TriggerClientEvent('pickle_consumables:drop:addDrop',src,id,drop) end
    end
end)
AddEventHandler('playerDropped',function() locks[source]=nil; last[source]=nil end)
-- Throw visuals are local entities. No client can nominate an entity for server deletion.
