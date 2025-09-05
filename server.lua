ESX = exports["es_extended"]:getSharedObject()

local function hasAccessToVehicle(identifier, plate)
    local hasAccess = false
    local result = MySQL.query.await('SELECT owner FROM owned_vehicles WHERE plate = ?', {plate})
    if result and result[1] and result[1].owner == identifier then
        hasAccess = true
    end
    
    return hasAccess
end

ESX.RegisterServerCallback('parking:depositVehicle', function(source, cb, vehicleProps, parkingId, engineHealth, wheelHealth)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.identifier
    
    local allowStolen = Config.Parkings[parkingId].allowStolen or false
    
    if not allowStolen and not hasAccessToVehicle(identifier, vehicleProps.plate) then
        TriggerClientEvent('esx:showNotification', source, 'Vous n\'avez pas les clés de ce véhicule')
        cb(false)
        return
    end

    if xPlayer.getMoney() >= Config.Parkings[parkingId].price.deposit then
        xPlayer.removeMoney(Config.Parkings[parkingId].price.deposit)
        
        local vehicleData = {
            vehicle = vehicleProps,
            engine_health = engineHealth,
            wheel_health = wheelHealth
        }
        
        if allowStolen then
            local existingVehicle = MySQL.query.await('SELECT * FROM owned_vehicles WHERE plate = ?', {vehicleProps.plate})
            if existingVehicle and existingVehicle[1] then
                if existingVehicle[1].owner and existingVehicle[1].owner ~= identifier then
                    TriggerClientEvent('esx:showNotification', source, 'Ce véhicule appartient à quelqu\'un d\'autre')
                    cb(false)
                    return
                end
                MySQL.update('UPDATE owned_vehicles SET stored = ?, parking = ?, vehicle = ? WHERE plate = ?', 
                {1, 'parking_' .. parkingId, json.encode(vehicleData), vehicleProps.plate}, function()
                    cb(true)
                end)
            else
                MySQL.insert('INSERT INTO owned_vehicles (owner, plate, vehicle, type, stored, parking) VALUES (?, ?, ?, ?, ?, ?)', 
                {identifier, vehicleProps.plate, json.encode(vehicleData), 'car', 1, 'parking_' .. parkingId}, function()
                    cb(true)
                end)
            end
        else
            MySQL.update('UPDATE owned_vehicles SET stored = ?, parking = ?, vehicle = ? WHERE plate = ?', 
            {1, 'parking_' .. parkingId, json.encode(vehicleData), vehicleProps.plate}, function()
                cb(true)
            end)
        end
    else
        cb(false)
        TriggerClientEvent('esx:showNotification', source, 'Vous n\'avez pas assez d\'argent')
    end
end)

ESX.RegisterServerCallback('parking:getVehicles', function(source, cb, parkingId)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.identifier
    
    local allowStolen = Config.Parkings[parkingId].allowStolen or false
    
    if allowStolen then
        MySQL.query('SELECT * FROM owned_vehicles WHERE parking = ? AND (owner = ? OR owner IS NULL)',
        {'parking_' .. parkingId, identifier}, function(vehicles)
            cb(vehicles or {})
        end)
    else
        MySQL.query('SELECT * FROM owned_vehicles WHERE parking = ? AND owner = ?',
        {'parking_' .. parkingId, identifier}, function(vehicles)
            cb(vehicles or {})
        end)
    end
end)

RegisterServerEvent('parking:retrieveVehicle')
AddEventHandler('parking:retrieveVehicle', function(plate, parkingId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.identifier
    if xPlayer.getMoney() >= Config.Parkings[parkingId].price.retrieve then
        local vehicle = MySQL.query.await('SELECT * FROM owned_vehicles WHERE plate = ? AND parking = ?', {plate, 'parking_' .. parkingId})
        
        if vehicle and vehicle[1] then
            local allowStolen = Config.Parkings[parkingId].allowStolen or false
            
            if not allowStolen then
                local hasAccess = hasAccessToVehicle(identifier, vehicle[1].plate)
                if not hasAccess then
                    TriggerClientEvent('esx:showNotification', source, 'Vous n\'avez pas les clés de ce véhicule')
                    return
                end
            else
                if vehicle[1].owner and vehicle[1].owner ~= identifier then
                    TriggerClientEvent('esx:showNotification', source, 'Ce véhicule appartient à quelqu\'un d\'autre')
                    return
                end
            end

            xPlayer.removeMoney(Config.Parkings[parkingId].price.retrieve)
            
            local vehicleData = json.decode(vehicle[1].vehicle)
            local vehicleProps = vehicleData.vehicle
            local engineHealth = vehicleData.engine_health or 1000.0
            local wheelHealth = vehicleData.wheel_health or {1000.0, 1000.0, 1000.0, 1000.0}
            
            if allowStolen and not vehicle[1].owner then
                MySQL.update.await('UPDATE owned_vehicles SET stored = ?, parking = NULL, vehicle = ?, owner = ? WHERE plate = ?', 
                {0, json.encode(vehicleProps), identifier, plate})
            else
                MySQL.update.await('UPDATE owned_vehicles SET stored = ?, parking = NULL, vehicle = ? WHERE plate = ?', 
                {0, json.encode(vehicleProps), plate})
            end
            
            TriggerClientEvent('parking:spawnVehicle', source, vehicleProps, engineHealth, wheelHealth)
            
            TriggerClientEvent('esx:showNotification', source, 'Véhicule récupéré pour ' .. Config.Parkings[parkingId].price.retrieve .. '$')
        else
            TriggerClientEvent('esx:showNotification', source, 'Véhicule introuvable')
        end
    else
        TriggerClientEvent('esx:showNotification', source, 'Vous n\'avez pas assez d\'argent')
    end
end)

ESX.RegisterServerCallback('parking:getJobVehicles', function(source, cb, parkingId)
    local xPlayer = ESX.GetPlayerFromId(source)
    local jobName = xPlayer.job.name
    
    if Config.Parkings[parkingId].job ~= nil and Config.Parkings[parkingId].job ~= jobName then
        cb({})
        return
    end
    
    MySQL.query('SELECT * FROM owned_vehicles WHERE job = ? AND parking = ? AND stored = 1', 
    {jobName, 'parking_' .. parkingId}, function(vehicles)
        cb(vehicles or {})
    end)
end)

RegisterServerEvent('parking:retrieveJobVehicle')
AddEventHandler('parking:retrieveJobVehicle', function(plate, parkingId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local jobName = xPlayer.job.name
    
    if Config.Parkings[parkingId].job ~= nil and Config.Parkings[parkingId].job ~= jobName then
        TriggerClientEvent('esx:showNotification', source, 'Vous n\'avez pas accès à ce parking')
        return
    end
    
    if xPlayer.getMoney() >= Config.Parkings[parkingId].price.retrieve then
        local vehicle = MySQL.query.await('SELECT * FROM owned_vehicles WHERE plate = ? AND job = ? AND parking = ?', {plate, jobName, 'parking_' .. parkingId})
        
        if vehicle and vehicle[1] then
            xPlayer.removeMoney(Config.Parkings[parkingId].price.retrieve)
            
            local vehicleData = json.decode(vehicle[1].vehicle)
            local vehicleProps = vehicleData.vehicle or vehicleData
            
            MySQL.update.await('UPDATE owned_vehicles SET stored = ?, parking = NULL WHERE plate = ?', {0, plate})
            
            TriggerClientEvent('parking:spawnJobVehicle', source, vehicleProps)
            
            TriggerClientEvent('esx:showNotification', source, 'Véhicule de service récupéré pour ' .. Config.Parkings[parkingId].price.retrieve .. '$')
        else
            TriggerClientEvent('esx:showNotification', source, 'Véhicule introuvable')
        end
    else
        TriggerClientEvent('esx:showNotification', source, 'Vous n\'avez pas assez d\'argent')
    end
end)

ESX.RegisterServerCallback('parking:depositJobVehicle', function(source, cb, vehicleProps, parkingId)
    local xPlayer = ESX.GetPlayerFromId(source)
    local jobName = xPlayer.job.name
    
    if Config.Parkings[parkingId].job ~= nil and Config.Parkings[parkingId].job ~= jobName then
        TriggerClientEvent('esx:showNotification', source, 'Vous n\'avez pas accès à ce parking')
        cb(false)
        return
    end
    
    local vehicle = MySQL.query.await('SELECT * FROM owned_vehicles WHERE plate = ? AND job = ?', {vehicleProps.plate, jobName})
    if not vehicle or not vehicle[1] then
        TriggerClientEvent('esx:showNotification', source, 'Ce véhicule n\'appartient pas à votre service')
        cb(false)
        return
    end
    
    if xPlayer.getMoney() >= Config.Parkings[parkingId].price.deposit then
        xPlayer.removeMoney(Config.Parkings[parkingId].price.deposit)
        
        MySQL.update('UPDATE owned_vehicles SET stored = ?, parking = ?, vehicle = ? WHERE plate = ? AND job = ?', 
            {1, 'parking_' .. parkingId, json.encode(vehicleProps), vehicleProps.plate, jobName}, 
            function()
                cb(true)
            end
        )
    else
        cb(false)
        TriggerClientEvent('esx:showNotification', source, 'Vous n\'avez pas assez d\'argent')
    end
end)