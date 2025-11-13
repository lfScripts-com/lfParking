Config = {}

Config.ESXMode = 'new' -- 'old' ou 'new' (compatibilité ESX)

Config.lfPersistence = false

Config.Parkings = {
    {
        id = 1,
        name = "Parking Bateaux",
        depositPoint = vector3(-802.325256, -1500.553834, 1.500000),
        retrievePoint = vector3(-806.505494, -1496.967042, 1.57873),
        spawnPoint = {
            coords = vector3(-806.690124, -1492.364868, 0.112792),
            heading = 110.55
        },
        price = {
            deposit = 100,
            retrieve = 100
        },
        type = "boat",
        allowStolen = true
    },
    {
        id = 2,
        name = "Parking Bateaux",
        depositPoint = vector3(-1613.432984, 5266.958008, 0.180176),
        retrievePoint = vector3(-1605.112060, 5257.516602, 2.067382),
        spawnPoint = {
            coords = vector3(-1602.883544, 5260.562500, 0.112792),
            heading = 22.677164
        },
        price = {
            deposit = 50,
            retrieve = 50
        },
        type = "boat",
        allowStolen = true
    },
    {
        id = 3,
        name = "Parking Public",
        depositPoint = vector3(-333.468140, -1070.439576, 23.01171),
        retrievePoint = vector3(-336.949462, -1067.050538, 23.011718),
        spawnPoint = {
            coords = vector3(-340.404388, -1068.514282, 23.011718),
            heading = 170.078736
        },
        price = {
            deposit = 50,
            retrieve = 50
        },
        type = "car",
        allowStolen = false
    },
    {
        id = 4,
        name = "Parking Public",
        depositPoint = vector3(61.094506, 24.909892, 69.68566),
        retrievePoint = vector3(68.940658, 15.810990, 69.11279),
        spawnPoint = {
            coords = vector3(63.890110, 16.760440, 69.16333),
            heading = 334.488190
        },
        price = {
            deposit = 50,
            retrieve = 50
        },
        type = "car",
        allowStolen = true
    },
    {
        id = 6,
        name = "Parking Bateaux Police",
        depositPoint = vector3(-720.158264, -1361.274780, 0.112792),
        retrievePoint = vector3(-725.314270, -1373.920898, 1.578736),
        spawnPoint = {
            coords = vector3(-730.641784, -1373.037354, 0.112792),
            heading = 136.062988
        },
        price = {
            deposit = 0,
            retrieve = 0
        },
        type = "boat",
        job = "police",
        allowStolen = false
    }
}

Config.BoatModels = {
    "dinghy", "dinghy2", "dinghy3", "dinghy4", "jetmax", 
    "marquis", "seashark", "seashark2", "seashark3", 
    "speeder", "speeder2", "squalo", "submersible", 
    "submersible2", "suntrap", "toro", "toro2", "tropic", 
    "tropic2", "tug"
} 
