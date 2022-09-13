local husky = 0
local gllorymeta = 0

RegisterCommand("seat", function(_, args)
    local seatIndex = unpack(args)
    seatIndex       = tonumber(seatIndex) - 1

    if seatIndex < -1 or seatIndex >= 4 then
        print("Nav tadas vietas cmon")
    else
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        if veh ~= nil and veh > 0 then
            CreateThread(function()
                disabled = true
                SetPedIntoVehicle(PlayerPedId(), veh, seatIndex)
                Wait(50)
                disabled = false
            end)
        end
    end
end)
TriggerEvent('chat:addSuggestion', '/seat', 'Samainit sedvietas',
{ { name = 'seat', help = "Maini sēdvietas. 0 = braucējs, 1 = pasažieris, 2-3 = aizmugurejas vietas" } })

RegisterCommand('propstuck', function()
    for k, v in pairs(GetGamePool('CObject')) do
        if IsEntityAttachedToEntity(PlayerPedId(), v) then
            SetEntityAsMissionEntity(v, true, true)
            DeleteObject(v)
            DeleteEntity(v)
        end
    end
end)

-- Roll Prevention
CreateThread(function()
    while true do
        if (not IsPedInAnyVehicle(PlayerPedId(),false)) then
            Wait(4)
            if IsPlayerFreeAiming(PlayerPedId()) then
                DisableControlAction(0, 22, 1)
            else
                Wait(100)
            end
        else
            Wait(500)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        local ped = GetPlayerPed(-1)
        local currentWeaponHash = GetSelectedPedWeapon(ped)
        if currentWeaponHash == -1569615261 then
            if not IsControlPressed(0, 25) then
                DisablePlayerFiring(ped,true)
                DisableControlAction(0, 140, true)
            end
        end
    end
end)


-- QBCore Backitems
local QBCore = exports['qb-core']:GetCoreObject()

AddEventHandler('onResourceStart', function(resourceName)
	if (GetCurrentResourceName() ~= resourceName) then return end
    BackLoop()
end)

AddEventHandler('onResourceStop', function(resourceName)
	if (GetCurrentResourceName() ~= resourceName) then return end
    resetItems()
end)

RegisterNetEvent("QBCore:Client:OnPlayerUnload", function()
    resetItems()
end)
BackItems = {
    ["tavakaklarota"] = {
        model="tavakaklarota",

        back_bone = 39317,
        x = -0.4,
        y = -0.17,
        z = -0.12,
        x_rotation = 0.0,
        y_rotation = 90.0,
        z_rotation = 0.0,
    },
    ["metamfetamins"] = {
        model="hei_prop_pill_bag_01", 
        back_bone = 24818,
        x = -0.1,
        y = -0.17,
        z = 0.12,
        x_rotation = 0.0,
        y_rotation = 90.0,
        z_rotation = 0.0,
    },
    ["weapon_ierocis"] = {
        model="w_ar_ierocis",
        back_bone = 24818,
        x = 0.0,
        y = -0.17,
        z = 0.1,
        x_rotation = 180.0,
        y_rotation = -180.0,
        z_rotation = 180.0,
    },
}

RegisterNetEvent("backitems:start", function()
    Wait(10000)
    BackLoop()
end)

RegisterNetEvent("backitems:displayItems", function(toggle)
    if toggle then 
        for k,v in pairs(TempBackItems) do 
            createBackItem(k)
        end
        BackLoop()
    else 
        TempBackItems = CurrentBackItems
        checking = false
        for k,v in pairs(CurrentBackItems) do
            removeBackItem(k)
        end
        CurrentBackItems = {}
    end
end)

function resetItems()
    removeAllBackItems()
    CurrentBackItems = {}
    TempBackItems = {}
    currentWeapon = nil
    s = {}
    checking = false
end

function BackLoop()
 --   print("[Backitems]: Starting Loop")
    checking = true
    CreateThread(function()
        while checking do
            local player = GSMC.Functions.GetPlayerData()
            while player == nil do 
                player = GSMC.Functions.GetPlayerData()
                Wait(500)
            end
            for i = 1, slots do
                s[i] = player.items[i]
            end
            check()
            Wait(1000)
        end
    end)
end

function check()
    for i = 1, slots do
        if s[i] ~= nil then
            local name = s[i].name
            if BackItems[name] then
                if name ~= currentWeapon then
                    createBackItem(name)
                end
            end
        end
    end

    for k,v in pairs(CurrentBackItems) do 
        local hasItem = false
        for j = 1, slots do
            if s[j] ~= nil then
                local name = s[j].name
                if name == k then 
                    hasItem = true
                end
            end
        end
        if not hasItem then 
            removeBackItem(k)
        end
    end
end


function createBackItem(item)
    if not CurrentBackItems[item] then
        if BackItems[item] then 
            local i = BackItems[item]
            local model = i["model"]
            local ped = PlayerPedId()
            local bone = GetPedBoneIndex(ped, i["back_bone"])
            RequestModel(model)
            while not HasModelLoaded(model) do
                Wait(10)
            end
            SetModelAsNoLongerNeeded(model)
            CurrentBackItems[item] = CreateObject(GetHashKey(model), 1.0, 1.0, 1.0, true, true, false)   
            AttachEntityToEntity(CurrentBackItems[item], ped, bone, i["x"], i["y"], i["z"], i["x_rotation"], i["y_rotation"], i["z_rotation"], false, false, false, false, 2, true)
        end
    end
end

function removeBackItem(item)
    if CurrentBackItems[item] then
        DeleteEntity(CurrentBackItems[item])
        CurrentBackItems[item] = nil
    end
end

function removeAllBackItems()
    for k,v in pairs(CurrentBackItems) do 
        removeBackItem(k)
    end
end

RegisterNetEvent('weapons:client:SetCurrentWeapon', function(weap, shootbool)
    if weap == nil then
        createBackItem(currentWeapon)
        currentWeapon = nil
    else
        if currentWeapon ~= nil then  
            createBackItem(currentWeapon)
            currentWeapon = nil
        end
        currentWeapon = tostring(weap.name)
        removeBackItem(currentWeapon)
    end
end)

RegisterCommand('livery', function(source, args, raw)
	local PlayerData = QBCore.Functions.GetPlayerData()
	local coords = GetEntityCoords(GetPlayerPed(-1))
	local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1))
	if tonumber(args[1]) ~= nil and PlayerData.job.name == "police" or PlayerData.job.name == "ambulance" or PlayerData.job.name == "catcafe" and GetVehicleLiveryCount(vehicle) - 1 >= tonumber(args[1]) then
		SetVehicleLivery(vehicle, tonumber(args[1]))
	end
end)

-- END OF SMALL SNIPPETS