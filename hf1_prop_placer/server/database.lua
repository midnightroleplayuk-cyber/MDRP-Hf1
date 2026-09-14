HF1PropDatabase = {}

local TABLE_NAME = 'hf1_prop_placer'

function HF1PropDatabase.EnsureTable()
    MySQL.query.await(([[
        CREATE TABLE IF NOT EXISTS `%s` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `name` VARCHAR(100) NOT NULL,
            `model` VARCHAR(120) NOT NULL,
            `x` DOUBLE NOT NULL,
            `y` DOUBLE NOT NULL,
            `z` DOUBLE NOT NULL,
            `rot_x` FLOAT NOT NULL DEFAULT 0,
            `rot_y` FLOAT NOT NULL DEFAULT 0,
            `rot_z` FLOAT NOT NULL DEFAULT 0,
            `frozen` TINYINT(1) NOT NULL DEFAULT 1,
            `collision` TINYINT(1) NOT NULL DEFAULT 1,
            `created_by` VARCHAR(100) NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_hf1_prop_placer_name` (`name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]):format(TABLE_NAME))
end

function HF1PropDatabase.LoadAll()
    return MySQL.query.await(('SELECT * FROM `%s` ORDER BY `id` ASC'):format(TABLE_NAME)) or {}
end

function HF1PropDatabase.Insert(data, creator)
    return MySQL.insert.await(([[
        INSERT INTO `%s`
        (`name`,`model`,`x`,`y`,`z`,`rot_x`,`rot_y`,`rot_z`,`frozen`,`collision`,`created_by`)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]]):format(TABLE_NAME), {
        data.name, data.model,
        data.coords.x, data.coords.y, data.coords.z,
        data.rotation.x, data.rotation.y, data.rotation.z,
        data.frozen and 1 or 0,
        data.collision and 1 or 0,
        creator,
    })
end

function HF1PropDatabase.Update(id, data)
    return MySQL.update.await(([[
        UPDATE `%s` SET
            `name`=?, `model`=?, `x`=?, `y`=?, `z`=?,
            `rot_x`=?, `rot_y`=?, `rot_z`=?, `frozen`=?, `collision`=?
        WHERE `id`=?
    ]]):format(TABLE_NAME), {
        data.name, data.model,
        data.coords.x, data.coords.y, data.coords.z,
        data.rotation.x, data.rotation.y, data.rotation.z,
        data.frozen and 1 or 0,
        data.collision and 1 or 0,
        id,
    })
end

function HF1PropDatabase.Delete(id)
    return MySQL.update.await(('DELETE FROM `%s` WHERE `id`=?'):format(TABLE_NAME), { id })
end
