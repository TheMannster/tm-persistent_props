TM = TM or {}
TM.DB = {}

local TABLE = 'tm_persistent_props'

function TM.DB.loadAll()
    return MySQL.query.await(('SELECT * FROM %s ORDER BY id ASC'):format(TABLE)) or {}
end

function TM.DB.insert(prop)
    return MySQL.insert.await(
        ('INSERT INTO %s (owner_cid, owner_name, model, x, y, z, heading) VALUES (?, ?, ?, ?, ?, ?, ?)'):format(TABLE),
        {
            prop.owner_cid,
            prop.owner_name,
            prop.model,
            prop.x,
            prop.y,
            prop.z,
            prop.heading,
        }
    )
end

function TM.DB.delete(id)
    return MySQL.update.await(('DELETE FROM %s WHERE id = ?'):format(TABLE), { id }) or 0
end

function TM.DB.listByOwner(cid)
    return MySQL.query.await(('SELECT * FROM %s WHERE owner_cid = ? ORDER BY id ASC'):format(TABLE), { cid }) or {}
end
