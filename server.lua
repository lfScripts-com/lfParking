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
			if existingVehicle and existingVehicle[1] and (not existingVehicle[1].owner or existingVehicle[1].owner == identifier) then
				MySQL.update('UPDATE owned_vehicles SET stored = ?, parking = ?, vehicle = ? WHERE plate = ?', 
				{1, 'parking_' .. parkingId, json.encode(vehicleData), vehicleProps.plate}, function()
					cb(true)
				end)
			else
				MySQL.query.await('DELETE FROM parking_vehicles WHERE plate = ? AND parking_id = ?', {vehicleProps.plate, parkingId})
				MySQL.insert('INSERT INTO parking_vehicles (plate, vehicle, parking_id, engine_health, wheel_health_1, wheel_health_2, wheel_health_3, wheel_health_4) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', 
				{vehicleProps.plate, json.encode(vehicleProps), parkingId, engineHealth or 1000.0, wheelHealth and wheelHealth[1] or 1000.0, wheelHealth and wheelHealth[2] or 1000.0, wheelHealth and wheelHealth[3] or 1000.0, wheelHealth and wheelHealth[4] or 1000.0}, function()
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
		MySQL.query('SELECT * FROM owned_vehicles WHERE parking = ? AND owner = ?',
		{'parking_' .. parkingId, identifier}, function(owned)
			local ownedList = owned or {}
			MySQL.query('SELECT plate, vehicle FROM parking_vehicles WHERE parking_id = ?', {parkingId}, function(stolen)
				local result = {}
				for _, v in ipairs(ownedList) do table.insert(result, v) end
				for _, s in ipairs(stolen or {}) do table.insert(result, s) end
				cb(result)
			end)
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
			local allowStolen = Config.Parkings[parkingId].allowStolen or false
			if not allowStolen then
				TriggerClientEvent('esx:showNotification', source, 'Véhicule introuvable')
				return
			end
			local stolen = MySQL.query.await('SELECT * FROM parking_vehicles WHERE plate = ? AND parking_id = ?', {plate, parkingId})
			if stolen and stolen[1] then
				xPlayer.removeMoney(Config.Parkings[parkingId].price.retrieve)
				local vehicleProps = json.decode(stolen[1].vehicle)
				local engineHealth = tonumber(stolen[1].engine_health) or 1000.0
				local wheelHealth = {
					tonumber(stolen[1].wheel_health_1) or 1000.0,
					tonumber(stolen[1].wheel_health_2) or 1000.0,
					tonumber(stolen[1].wheel_health_3) or 1000.0,
					tonumber(stolen[1].wheel_health_4) or 1000.0
				}
				MySQL.query.await('DELETE FROM parking_vehicles WHERE id = ?', {stolen[1].id})
				TriggerClientEvent('parking:spawnVehicle', source, vehicleProps, engineHealth, wheelHealth)
				TriggerClientEvent('esx:showNotification', source, 'Véhicule récupéré pour ' .. Config.Parkings[parkingId].price.retrieve .. '$')
			else
				TriggerClientEvent('esx:showNotification', source, 'Véhicule introuvable')
			end
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
