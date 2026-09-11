NPCManagerDB = {}

local function decodeMetadata(value)
    if not value or value == '' then return {} end
    local ok, decoded = pcall(json.decode, value)
    if not ok or type(decoded) ~= 'table' then return {} end
    return decoded
end

function NPCManagerDB.RowToNpc(row)
    local metadata = decodeMetadata(row.metadata)

    return {
        id = row.id,
        name = row.name,
        model = row.model,
        coords = {
            x = tonumber(row.x) or 0.0,
            y = tonumber(row.y) or 0.0,
            z = tonumber(row.z) or 0.0,
            w = tonumber(row.heading) or 0.0,
        },
        scenario = row.scenario or '',
        animDict = row.anim_dict or '',
        animName = row.anim_name or '',
        animFlag = tonumber(row.anim_flag) or 1,
        invincible = row.invincible == 1 or row.invincible == true,
        frozen = row.frozen == 1 or row.frozen == true,
        blockEvents = row.block_events == 1 or row.block_events == true,
        canRagdoll = row.can_ragdoll == 1 or row.can_ragdoll == true,
        collision = row.collision == 1 or row.collision == true,
        spawnDistance = tonumber(row.spawn_distance) or Config.Defaults.spawnDistance,
        target = {
            enabled = metadata.targetEnabled == true,
            mode = metadata.targetMode or ((metadata.dialogue and metadata.dialogue.enabled) and 'talk' or 'event'),
            label = metadata.targetLabel or Config.Defaults.targetLabel,
            icon = metadata.targetIcon or Config.Defaults.targetIcon,
            event = metadata.targetEvent or '',
        },
        dialogue = type(metadata.dialogue) == 'table' and metadata.dialogue or { enabled = false, text = '', replies = {} },
        createdBy = row.created_by,
        createdAt = row.created_at,
        updatedAt = row.updated_at,
    }
end

function NPCManagerDB.LoadAll()
    local rows = MySQL.query.await('SELECT * FROM `hf1_npcs` ORDER BY `id` ASC') or {}
    local result = {}
    for i = 1, #rows do
        result[#result + 1] = NPCManagerDB.RowToNpc(rows[i])
    end
    return result
end

function NPCManagerDB.Insert(data, creator)
    local metadata = json.encode({
        targetEnabled = data.target.enabled == true,
        targetMode = data.target.mode or 'event',
        targetLabel = data.target.label or '',
        targetIcon = data.target.icon or '',
        targetEvent = data.target.event or '',
        dialogue = data.dialogue or { enabled = false, text = '', replies = {} },
    })

    return MySQL.insert.await([[
        INSERT INTO `hf1_npcs`
        (`name`, `model`, `x`, `y`, `z`, `heading`, `scenario`, `anim_dict`, `anim_name`, `anim_flag`,
         `invincible`, `frozen`, `block_events`, `can_ragdoll`, `collision`, `spawn_distance`, `metadata`, `created_by`)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.name, data.model,
        data.coords.x, data.coords.y, data.coords.z, data.coords.w,
        data.scenario, data.animDict, data.animName, data.animFlag,
        data.invincible and 1 or 0,
        data.frozen and 1 or 0,
        data.blockEvents and 1 or 0,
        data.canRagdoll and 1 or 0,
        data.collision and 1 or 0,
        data.spawnDistance,
        metadata,
        creator,
    })
end

function NPCManagerDB.Update(data)
    local metadata = json.encode({
        targetEnabled = data.target.enabled == true,
        targetMode = data.target.mode or 'event',
        targetLabel = data.target.label or '',
        targetIcon = data.target.icon or '',
        targetEvent = data.target.event or '',
        dialogue = data.dialogue or { enabled = false, text = '', replies = {} },
    })

    return MySQL.update.await([[
        UPDATE `hf1_npcs`
        SET `name` = ?, `model` = ?, `x` = ?, `y` = ?, `z` = ?, `heading` = ?,
            `scenario` = ?, `anim_dict` = ?, `anim_name` = ?, `anim_flag` = ?,
            `invincible` = ?, `frozen` = ?, `block_events` = ?, `can_ragdoll` = ?,
            `collision` = ?, `spawn_distance` = ?, `metadata` = ?
        WHERE `id` = ?
    ]], {
        data.name, data.model,
        data.coords.x, data.coords.y, data.coords.z, data.coords.w,
        data.scenario, data.animDict, data.animName, data.animFlag,
        data.invincible and 1 or 0,
        data.frozen and 1 or 0,
        data.blockEvents and 1 or 0,
        data.canRagdoll and 1 or 0,
        data.collision and 1 or 0,
        data.spawnDistance,
        metadata,
        data.id,
    })
end

function NPCManagerDB.Delete(id)
    return MySQL.update.await('DELETE FROM `hf1_npcs` WHERE `id` = ?', { id })
end
