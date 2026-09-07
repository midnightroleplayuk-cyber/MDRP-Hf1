CREATE TABLE IF NOT EXISTS `hf1_signs` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `owner` VARCHAR(80) NOT NULL,
  `label` VARCHAR(100) NOT NULL DEFAULT 'Custom Sign',
  `image_url` VARCHAR(2048) NOT NULL,
  `x` DOUBLE NOT NULL,
  `y` DOUBLE NOT NULL,
  `z` DOUBLE NOT NULL,
  `width` DOUBLE NOT NULL,
  `height` DOUBLE NOT NULL,
  `heading` DOUBLE NOT NULL DEFAULT 0,
  `normal_x` DOUBLE NOT NULL DEFAULT 0,
  `normal_y` DOUBLE NOT NULL DEFAULT 1,
  `normal_z` DOUBLE NOT NULL DEFAULT 0,
  `view_distance` DOUBLE NOT NULL DEFAULT 50,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_owner` (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- If you already have an older qbox_signs table and want to migrate it,
-- run the following manually after backing up your database:
--
-- RENAME TABLE `qbox_signs` TO `hf1_signs`;
-- ALTER TABLE `hf1_signs`
--   ADD COLUMN `normal_x` DOUBLE NOT NULL DEFAULT 0 AFTER `heading`,
--   ADD COLUMN `normal_y` DOUBLE NOT NULL DEFAULT 1 AFTER `normal_x`,
--   ADD COLUMN `normal_z` DOUBLE NOT NULL DEFAULT 0 AFTER `normal_y`;
-- ALTER TABLE `hf1_signs` MODIFY `view_distance` DOUBLE NOT NULL DEFAULT 50;
