Config = {}

Config.lfPersistence = true

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
        allowStolen = false
    },
    {
        id = 6,
        name = "Parking Bateaux Police",
        depositPoint = vector3(-1047.08, 6574.72, 1.90),
        retrievePoint = vector3(-1031.92, 6583.56, 1.90),
        spawnPoint = {
            coords = vector3(-1009.85, 6569.02, 1.79),
            heading = 87.01
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