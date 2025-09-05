ESX = exports["es_extended"]:getSharedObject()
local CurrentActionData = {}
local HasAlreadyEnteredMarker = false
local CurrentAction = nil
local nearMarker = false

local PlayerData = {}

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

Citizen.CreateThread(function()
    while ESX == nil do
        Citizen.Wait(10)
    end
    
    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(10)
    end
    
    PlayerData = ESX.GetPlayerData()
    
    for k,v in pairs(Config.Parkings) do
        if v.job == nil or v.job == PlayerData.job.name then
            local blip = AddBlipForCoord(v.depositPoint)
            local blipSprite = (v.type == "boat") and 356 or 357
            
            SetBlipSprite(blip, blipSprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, 0.6)
            SetBlipColour(blip, 3)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(v.name)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local isNear = false

        for k,v in pairs(Config.Parkings) do
            local distanceToRetrieve = #(playerCoords - v.retrievePoint)
            local distanceToDeposit = #(playerCoords - v.depositPoint)
            
            if distanceToRetrieve < 30.0 or distanceToDeposit < 30.0 then
                isNear = true
                break
            end
        end

        nearMarker = isNear
        Citizen.Wait(nearMarker and 500 or 1000)
    end
end)

Citizen.CreateThread(function()
    while true do
        if nearMarker then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local isInVehicle = IsPedInAnyVehicle(playerPed, false)
            local isInMarkerZone = false
            local currentZone = nil
            local currentParkingId = nil

            for k,v in pairs(Config.Parkings) do
                if v.job == nil or v.job == PlayerData.job.name then
                    local distanceToRetrieve = #(playerCoords - v.retrievePoint)
                    local retrieveMarkerSize = (v.type == "boat") and 2.0 or 1.5
                    local retrieveInteractionDistance = (v.type == "boat") and 3.0 or 2.0
                    
                    if distanceToRetrieve < 5.0 then
                        DrawMarker(25, v.retrievePoint.x, v.retrievePoint.y, v.retrievePoint.z - 0.98, 
                            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                            retrieveMarkerSize, retrieveMarkerSize, retrieveMarkerSize, 255, 0, 0, 100, 
                            false, true, 2, false, nil, nil, false)
                            
                        if distanceToRetrieve < retrieveInteractionDistance then
                            isInMarkerZone = true
                            currentZone = 'retrieve'
                            currentParkingId = k
                        end
                    end

                    if isInVehicle then
                        local distanceToDeposit = #(playerCoords - v.depositPoint)
                        local interactionDistance = (v.type == "boat") and 3.0 or 2.0
                        
                        if distanceToDeposit < 30.0 then
                            local markerType = (v.type == "boat") and 35 or 36
                            
                            local markerSize = (v.type == "boat") and 2.0 or 1.0
                            
                            DrawMarker(markerType, v.depositPoint.x, v.depositPoint.y, v.depositPoint.z, 
                                0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                                markerSize, markerSize, markerSize, 0, 255, 0, 100, 
                                false, true, 2, false, nil, nil, false)
                                
                            if distanceToDeposit < interactionDistance then
                                isInMarkerZone = true
                                currentZone = 'deposit'
                                currentParkingId = k
                            end
                        end
                    end
                end
            end

            if isInMarkerZone and not HasAlreadyEnteredMarker then
                HasAlreadyEnteredMarker = true
                CurrentAction = currentZone
                CurrentActionData = {parkingId = currentParkingId}
                
                local isBoatParking = Config.Parkings[currentParkingId].type == "boat"
                local vehicleType = isBoatParking and "bateau" or "véhicule"
                
                ESX.ShowHelpNotification('Appuyez sur ~INPUT_CONTEXT~ pour ' .. (currentZone == 'deposit' and 'déposer' or 'retirer') .. ' un ' .. vehicleType)
            end

            if not isInMarkerZone and HasAlreadyEnteredMarker then
                HasAlreadyEnteredMarker = false
                CurrentAction = nil
                RageUI.CloseAll()
            end

            if CurrentAction and IsControlJustReleased(0, 38) then
                if CurrentAction == 'deposit' then
                    DepositVehicle(CurrentActionData.parkingId)
                elseif CurrentAction == 'retrieve' then
                    OpenRetrieveMenu(CurrentActionData.parkingId)
                end
            end
            Citizen.Wait(0)
        else
            Citizen.Wait(500)
        end
    end
end)

RMenu.Add('parking', 'main', RageUI.CreateMenu("Parking", "Liste des véhicules"))

function DepositVehicle(parkingId)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then
        ESX.ShowNotification('Vous devez être dans un véhicule')
        return
    end

    if Config.Parkings[parkingId].job ~= nil and Config.Parkings[parkingId].job ~= PlayerData.job.name then
        ESX.ShowNotification('Vous n\'avez pas accès à ce parking')
        return
    end

    local isParkingForBoats = Config.Parkings[parkingId].type == "boat"
    local vehicleModel = GetEntityModel(vehicle)
    local vehicleModelName = GetDisplayNameFromVehicleModel(vehicleModel):lower()
    local vehicleClass = GetVehicleClass(vehicle)
    
    if isParkingForBoats then
        local isBoat = (vehicleClass == 14)
        
        if not isBoat then
            for _, model in ipairs(Config.BoatModels) do
                if vehicleModelName == model then
                    isBoat = true
                    break
                end
            end
        end
        
        if not isBoat then
            ESX.ShowNotification('Vous ne pouvez déposer que des bateaux dans ce parking')
            return
        end
    elseif not isParkingForBoats and vehicleClass == 14 then
        ESX.ShowNotification('Vous ne pouvez pas déposer de bateau dans ce parking')
        return
    end

    local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
    local engineHealth = GetVehicleEngineHealth(vehicle)
    local wheelHealth = {
        GetVehicleWheelHealth(vehicle, 0),
        GetVehicleWheelHealth(vehicle, 1),
        GetVehicleWheelHealth(vehicle, 2),
        GetVehicleWheelHealth(vehicle, 3)
    }

    if Config.Parkings[parkingId].job ~= nil then
        ESX.TriggerServerCallback('parking:depositJobVehicle', function(success)
            if success then
                if Config.lfPersistence then
                    TriggerEvent('Persistance:removeVehicles', vehicle)
                end
                TriggerEvent('ox_inventory:clearVehicle', vehicle)
                SetVehicleHasBeenOwnedByPlayer(vehicle, false)
                SetEntityAsMissionEntity(vehicle, true, true)
                Citizen.Wait(100)
                ESX.Game.DeleteVehicle(vehicle)
                ESX.ShowNotification('Véhicule de service déposé pour ' .. Config.Parkings[parkingId].price.deposit .. '$')
            end
        end, vehicleProps, parkingId)
    else
        ESX.TriggerServerCallback('parking:depositVehicle', function(success)
            if success then
                if Config.lfPersistence then
                    TriggerEvent('Persistance:removeVehicles', vehicle)
                end
                TriggerEvent('ox_inventory:clearVehicle', vehicle)
                SetVehicleHasBeenOwnedByPlayer(vehicle, false)
                SetEntityAsMissionEntity(vehicle, true, true)
                Citizen.Wait(100)
                ESX.Game.DeleteVehicle(vehicle)
                ESX.ShowNotification('Véhicule déposé pour ' .. Config.Parkings[parkingId].price.deposit .. '$')
            end
        end, vehicleProps, parkingId, engineHealth, wheelHealth)
    end
end

function OpenRetrieveMenu(parkingId)
    if Config.Parkings[parkingId].job ~= nil and Config.Parkings[parkingId].job ~= PlayerData.job.name then
        ESX.ShowNotification('Vous n\'avez pas accès à ce parking')
        return
    end

    local vehicles = nil
    local isBoatParking = Config.Parkings[parkingId].type == "boat"
    
    if Config.Parkings[parkingId].job ~= nil then
        ESX.TriggerServerCallback('parking:getJobVehicles', function(result)
            if isBoatParking and result then
                local boatVehicles = {}
                for _, v in pairs(result) do
                    local vehicleData = json.decode(v.vehicle)
                    local vehicleClass = 0
                    
                    local isBoat = false
                    
                    local actualVehicleData = vehicleData.vehicle or vehicleData
                    
                    if actualVehicleData.model then
                        local vehicleHash = actualVehicleData.model
                        if IsModelInCdimage(vehicleHash) then
                            local modelName = GetDisplayNameFromVehicleModel(vehicleHash):lower()
                            
                            for _, boatModel in ipairs(Config.BoatModels) do
                                if modelName == boatModel then
                                    isBoat = true
                                    break
                                end
                            end
                            
                            if not isBoat then
                                RequestModel(vehicleHash)
                                local timeout = 0
                                while not HasModelLoaded(vehicleHash) and timeout < 100 do
                                    Wait(10)
                                    timeout = timeout + 1
                                end
                                
                                if HasModelLoaded(vehicleHash) then
                                    local dummyVehicle = CreateVehicle(vehicleHash, 0, 0, 0, 0, false, false)
                                    if DoesEntityExist(dummyVehicle) then
                                        vehicleClass = GetVehicleClass(dummyVehicle)
                                        isBoat = (vehicleClass == 14)
                                        DeleteEntity(dummyVehicle)
                                    end
                                end
                                SetModelAsNoLongerNeeded(vehicleHash)
                            end
                        end
                    end
                    
                    if isBoat then
                        table.insert(boatVehicles, v)
                    end
                end
                vehicles = boatVehicles
            else
                vehicles = result
            end
        end, parkingId)
    else
        ESX.TriggerServerCallback('parking:getVehicles', function(result)
            vehicles = result
        end, parkingId)
    end
    
    RageUI.Visible(RMenu:Get('parking', 'main'), true)
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(1)
            
            RageUI.IsVisible(RMenu:Get('parking', 'main'), function()
                if vehicles and #vehicles > 0 then
                    for k,v in pairs(vehicles) do
                        local vehicleData = nil
                        local vehicleName = nil
                        
                        if Config.Parkings[parkingId].job ~= nil then
                            vehicleData = json.decode(v.vehicle)
                            if vehicleData.vehicle then
                                vehicleName = GetDisplayNameFromVehicleModel(vehicleData.vehicle.model)
                            else
                                vehicleName = GetDisplayNameFromVehicleModel(vehicleData.model)
                            end
                        else
                            vehicleData = json.decode(v.vehicle)
                            if vehicleData.vehicle then
                                vehicleName = GetDisplayNameFromVehicleModel(vehicleData.vehicle.model)
                            else
                                vehicleName = GetDisplayNameFromVehicleModel(vehicleData.model)
                            end
                        end
                        
                        RageUI.Button(vehicleName .. ' [' .. v.plate .. ']', "Appuyez pour récupérer le véhicule", {}, true, {
                            onSelected = function()
                                if Config.Parkings[parkingId].job ~= nil then
                                    TriggerServerEvent('parking:retrieveJobVehicle', v.plate, parkingId)
                                else
                                    TriggerServerEvent('parking:retrieveVehicle', v.plate, parkingId)
                                end
                                RageUI.CloseAll()
                            end
                        })
                    end
                else
                    RageUI.Button("Aucun véhicule dans ce parking", nil, {}, true, {})
                end
            end)
            
            if not RageUI.Visible(RMenu:Get('parking', 'main')) then
                vehicles = nil
                break
            end
        end
    end)
end

RegisterNetEvent('parking:spawnVehicle')
AddEventHandler('parking:spawnVehicle', function(vehicleData, engineHealth, wheelHealth)
    if not vehicleData or not vehicleData.model then
        return
    end
    
    if not CurrentActionData or not CurrentActionData.parkingId then
        return
    end
    
    local spawnPoint = Config.Parkings[CurrentActionData.parkingId].spawnPoint
    local isBoatParking = Config.Parkings[CurrentActionData.parkingId].type == "boat"
    
    local spawnFunction = ESX.Game.SpawnVehicle
    if isBoatParking then
        local adjustedCoords = vector3(
            spawnPoint.coords.x,
            spawnPoint.coords.y,
            spawnPoint.coords.z + 0.5
        )
        
        spawnFunction(vehicleData.model, adjustedCoords, spawnPoint.heading, function(vehicle)
            if DoesEntityExist(vehicle) then
                ESX.Game.SetVehicleProperties(vehicle, vehicleData)
                SetVehicleEngineHealth(vehicle, engineHealth)
                for i = 1, 4 do
                    SetVehicleWheelHealth(vehicle, i-1, wheelHealth[i])
                end
                
                SetVehicleFixed(vehicle)
                SetVehicleDeformationFixed(vehicle)
                
                SetBoatAnchor(vehicle, false)
                SetVehicleOnGroundProperly(vehicle)
                
                TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
                SetVehicleEngineOn(vehicle, true, true, false)
                
                if Config.lfPersistence then
                    TriggerEvent('Persistance:addVehicles', vehicle)
                end
                
                ESX.ShowNotification('Bateau récupéré pour ' .. Config.Parkings[CurrentActionData.parkingId].price.retrieve .. '$')
            else
                ESX.ShowNotification('Erreur lors de la récupération du bateau')
            end
        end)
    else
        spawnFunction(vehicleData.model, spawnPoint.coords, spawnPoint.heading, function(vehicle)
            if DoesEntityExist(vehicle) then
                ESX.Game.SetVehicleProperties(vehicle, vehicleData)
                SetVehicleEngineHealth(vehicle, engineHealth)
                for i = 1, 4 do
                    SetVehicleWheelHealth(vehicle, i-1, wheelHealth[i])
                end

                SetVehicleFixed(vehicle)
                SetVehicleDeformationFixed(vehicle)
                TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
                SetVehicleEngineOn(vehicle, true, true, false)
                
                if Config.lfPersistence then
                    TriggerEvent('Persistance:addVehicles', vehicle)
                end
                
                ESX.ShowNotification('Véhicule récupéré pour ' .. Config.Parkings[CurrentActionData.parkingId].price.retrieve .. '$')
            else
                ESX.ShowNotification('Erreur lors de la récupération du véhicule')
            end
        end)
    end
end)

RegisterNetEvent('parking:spawnJobVehicle')
AddEventHandler('parking:spawnJobVehicle', function(vehicleData)
    if not vehicleData or not vehicleData.model then
        return
    end
    
    if not CurrentActionData or not CurrentActionData.parkingId then
        return
    end
    
    local spawnPoint = Config.Parkings[CurrentActionData.parkingId].spawnPoint
    local isBoatParking = Config.Parkings[CurrentActionData.parkingId].type == "boat"
    
    local spawnFunction = ESX.Game.SpawnVehicle
    if isBoatParking then
        local adjustedCoords = vector3(
            spawnPoint.coords.x,
            spawnPoint.coords.y,
            spawnPoint.coords.z + 0.5
        )
        
        spawnFunction(vehicleData.model, adjustedCoords, spawnPoint.heading, function(vehicle)
            if DoesEntityExist(vehicle) then
                ESX.Game.SetVehicleProperties(vehicle, vehicleData)
                
                SetVehicleFixed(vehicle)
                SetVehicleDeformationFixed(vehicle)
                
                SetBoatAnchor(vehicle, false)
                SetVehicleOnGroundProperly(vehicle)
                
                TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
                SetVehicleEngineOn(vehicle, true, true, false)
                
                if Config.lfPersistence then
                    TriggerEvent('Persistance:addVehicles', vehicle)
                end
                
                ESX.ShowNotification('Bateau de service récupéré')
            else
                ESX.ShowNotification('Erreur lors de la récupération du bateau')
            end
        end)
    else
        spawnFunction(vehicleData.model, spawnPoint.coords, spawnPoint.heading, function(vehicle)
            if DoesEntityExist(vehicle) then
                ESX.Game.SetVehicleProperties(vehicle, vehicleData)

                SetVehicleFixed(vehicle)
                SetVehicleDeformationFixed(vehicle)
                TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
                SetVehicleEngineOn(vehicle, true, true, false)
                
                if Config.lfPersistence then
                    TriggerEvent('Persistance:addVehicles', vehicle)
                end
                
                ESX.ShowNotification('Véhicule de service récupéré')
            else
                ESX.ShowNotification('Erreur lors de la récupération du véhicule')
            end
        end)
    end
end) 
