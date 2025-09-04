CREATE TABLE IF NOT EXISTS `parking_vehicles` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `plate` varchar(8) NOT NULL,
    `vehicle` longtext NOT NULL,
    `parking_id` int(11) NOT NULL,
    `engine_health` float NOT NULL,
    `wheel_health_1` float NOT NULL,
    `wheel_health_2` float NOT NULL,
    `wheel_health_3` float NOT NULL,
    `wheel_health_4` float NOT NULL,
    PRIMARY KEY (`id`)
); 