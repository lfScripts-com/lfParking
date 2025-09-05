Config = {}

Config.lfPersistence = true

Config.Parkings = {
    {
        id = 4,
        name = "Parking Bateaux",
        depositPoint = vector3(-931.72, 6482.40, 1.10),
        retrievePoint = vector3(-939.66, 6491.27, 1.89),
        spawnPoint = {
            coords = vector3(-947.46, 6504.06, 2.95),
            heading = 170.0
        },
        price = {
            deposit = 100,
            retrieve = 100
        },
        type = "boat"
    },
    {
        id = 5,
        name = "Parking Bateaux",
        depositPoint = vector3(4938.16, -5134.88, 1.22),
        retrievePoint = vector3(4931.25, -5146.31, 2.48),
        spawnPoint = {
            coords = vector3(4928.28, -5158.88, 1.58),
            heading = 56.14
        },
        price = {
            deposit = 50,
            retrieve = 50
        },
        type = "boat"
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
        job = "police"
    }
}

Config.BoatModels = {
    "dinghy", "dinghy2", "dinghy3", "dinghy4", "jetmax", 
    "marquis", "seashark", "seashark2", "seashark3", 
    "speeder", "speeder2", "squalo", "submersible", 
    "submersible2", "suntrap", "toro", "toro2", "tropic", 
    "tropic2", "tug"
} 