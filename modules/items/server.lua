Players = {}
local serial=0
local busy={}
function ConsumableIdentity(src)
    if not GetPlayerName(src) then return end
    local ok,id=pcall(GetIdentifier,src)
    return ok and id or nil
end
function SaveHeld(src)
    local item=Players[src]
    if item and item.owner then SetResourceKvp('held:'..item.owner,json.encode(item)) end
end
function ClearHeld(src)
    local item=Players[src]
    if item and item.owner then DeleteResourceKvp('held:'..item.owner) end
    Players[src]=nil
end
function CurrentHeld(src)
    local item=Players[src]
    if item and item.owner==ConsumableIdentity(src) then return item end
    Players[src]=nil
end
function EquipItem(src,item)
    local owner=ConsumableIdentity(src)
    if not owner or CurrentHeld(src) then return false end
    serial=serial+1
    Players[src]={itemKey=item.itemKey,uses=item.uses,owner=owner,generation=serial}
    SaveHeld(src)
    TriggerClientEvent('pickle_consumables:restoreItem',src,Players[src])
    return true
end
function GiveRewards(src,rewards)
    for _,reward in ipairs(rewards) do
        local amount=type(reward.amount)=='table' and math.random(reward.amount[1],reward.amount[2]) or reward.amount
        if reward.type=='money' then AddMoney(src,amount) else Inventory.AddItem(src,reward.name,amount) end
    end
end
CreateThread(function()
    while not Inventory or not Inventory.Ready or type(RegisterUsableItem)~='function' do Wait(100) end
    for key,cfg in pairs(Config.Items) do
        RegisterUsableItem(key,function(src,metadata,slot)
            if busy[src] or CurrentHeld(src) or not ConsumableIdentity(src) then return end
            metadata=type(metadata)=='table' and metadata or {}
            local uses=metadata.uses or cfg.uses
            if type(uses)~='number' or uses%1~=0 or uses<1 or uses>cfg.uses then return end
            busy[src]=true
            if Inventory.RemoveItem(src,key,1,slot)==true then EquipItem(src,{itemKey=key,uses=uses}) end
            busy[src]=nil
        end)
    end
end)
lib.callback.register('pickle_consumables:beginUse',function(src,generation)
    local item=CurrentHeld(src)
    if not item or item.generation~=generation or item.consuming then return false end
    item.consuming=GetGameTimer()
    return true
end)
lib.callback.register('pickle_consumables:useItem',function(src,generation)
    local item=CurrentHeld(src)
    local cfg=item and Config.Items[item.itemKey]
    if not item or not cfg or item.generation~=generation or not item.consuming
        or GetGameTimer()-item.consuming<cfg.animation.time or item.uses<1 then return false,item and item.uses or 0 end
    item.consuming=nil
    item.uses=item.uses-1
    if item.uses==0 then ClearHeld(src) else SaveHeld(src) end
    if cfg.rewards then GiveRewards(src,cfg.rewards) end
    if cfg.status then ExecuteStatus(src,cfg.status) end
    return true,item.uses
end)
RegisterNetEvent('pickle_consumables:cancelUse',function(generation)
    local item=CurrentHeld(source)
    if item and item.generation==generation then item.consuming=nil end
end)
RegisterNetEvent('pickle_consumables:returnItem',function(destroy)
    local src=source; local item=CurrentHeld(src)
    if not item or busy[src] then return end
    busy[src]=true
    if destroy==true or Inventory.AddItem(src,item.itemKey,1,{itemKey=item.itemKey,uses=item.uses})==true then
        ClearHeld(src)
        TriggerClientEvent('pickle_consumables:removeItem',src)
    else
        item.consuming=nil
        TriggerClientEvent('pickle_consumables:restoreItem',src,item)
    end
    busy[src]=nil
end)
local function unload(src)
    SaveHeld(src)
    Players[src]=nil; busy[src]=nil
end
AddEventHandler('playerDropped',function() unload(source) end)
AddEventHandler('esx:playerLogout',function(src) unload(src or source) end)
AddEventHandler('QBCore:Server:OnPlayerUnload',function(src) unload(src or source) end)
RegisterNetEvent('pickle_consumables:initialize',function()
    local src=source; local owner=ConsumableIdentity(src)
    if not owner or CurrentHeld(src) then return end
    local raw=GetResourceKvpString('held:'..owner)
    if not raw then return end
    local ok,item=pcall(json.decode,raw)
    if ok and type(item)=='table' and Config.Items[item.itemKey] and item.uses>0 then EquipItem(src,item) end
end)
