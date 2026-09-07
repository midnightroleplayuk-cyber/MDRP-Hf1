CREATE TABLE IF NOT EXISTS `hf1_signs` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `owner` VARCHAR(64) NOT NULL,
    `label` VARCHAR(100) NOT NULL DEFAULT 'Custom Sign',
    `image_url` VARCHAR(2048) NOT NULL,
    `x` DOUBLE NOT NULL,
    `y` DOUBLE NOT NULL,
    `z` DOUBLE NOT NULL,
    `width` DOUBLE NOT NULL DEFAULT 1.0,
    `height` DOUBLE NOT NULL DEFAULT 1.0,
    `heading` DOUBLE NOT NULL DEFAULT 0.0,
    `normal_x` DOUBLE NOT NULL DEFAULT 0.0,
    `normal_y` DOUBLE NOT NULL DEFAULT 1.0,
    `normal_z` DOUBLE NOT NULL DEFAULT 0.0,
    `view_distance` DOUBLE NOT NULL DEFAULT 50.0,
    PRIMARY KEY (`id`),
    KEY `idx_owner` (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
