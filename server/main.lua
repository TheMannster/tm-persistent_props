local props      = {}
local validModel = {}

local QBX = exports.qbx_core

local function buildModelAllowList()
    for _, entry in ipairs(TM.Catalogue.iter()) do
        local item = entry.item
        if item and item.model then
            validModel[item.model:lower()] = true
        end
    end
end

local function getPlayerInfo(src)
    local player = QBX:GetPlayer(src)
    if not player then return nil end
    local pd = player.PlayerData or player
    local cid = pd.citizenid
    local name = pd.charinfo
        and (pd.charinfo.firstname .. ' ' .. pd.charinfo.lastname)
        or GetPlayerName(src)
    return cid, name
end

local function matchesIdentifier(src, list)
    if type(list) ~= 'table' or #list == 0 then return false end

    local set = {}
    for _, v in ipairs(list) do
        if type(v) == 'string' then set[v:lower()] = true end
    end

    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and set[id:lower()] then return true end
    end

    local cid = getPlayerInfo(src)
    if cid and set[('citizenid:' .. cid):lower()] then return true end

    return false
end

local function matchesJob(src, list)
    if type(list) ~= 'table' or #list == 0 then return false end

    local player = QBX:GetPlayer(src)
    if not player then return false end
    local job = (player.PlayerData or player).job
    if not job or not job.name then return false end

    if Config.RequireOnDuty and not job.onduty then return false end

    for _, name in ipairs(list) do
        if job.name == name then return true end
    end
    return false
end

local function hasPlacePermission(src)
    if Config.AllowEveryone then return true end
    if Config.PermissionMode == 'identifier' then
        return matchesIdentifier(src, Config.AllowedIdentifiers)
    elseif Config.PermissionMode == 'job' then
        return matchesJob(src, Config.AllowedJobs)
    end
    return IsPlayerAceAllowed(src, Config.AcePermission)
end

local function isAdmin(src)
    if Config.PermissionMode == 'identifier' then
        return matchesIdentifier(src, Config.AdminIdentifiers)
    elseif Config.PermissionMode == 'job' then
        return matchesJob(src, Config.AdminJobs)
    end
    return IsPlayerAceAllowed(src, Config.AdminAcePermission)
end

local function clientPayload(row)
    return {
        id      = row.id,
        model   = row.model,
        x       = row.x,
        y       = row.y,
        z       = row.z,
        heading = row.heading,
        owner   = row.owner_cid,
    }
end

local function snapshot()
    local out = {}
    for _, row in pairs(props) do
        out[#out + 1] = clientPayload(row)
    end
    return out
end

CreateThread(function()
    TM.Log.banner()
    buildModelAllowList()

    local ok, rows = pcall(TM.DB.loadAll)
    if not ok then
        TM.Log.err('db', 'failed to load props: ' .. tostring(rows))
        return
    end

    for _, row in ipairs(rows) do
        props[row.id] = row
    end

    TM.Log.footer(('%d prop(s) loaded, %d allowed model(s)'):format(#rows, TM.Catalogue.count()))
end)

lib.callback.register('tm-props:fetchAll', function(_)
    return snapshot()
end)

lib.callback.register('tm-props:whoami', function(src)
    local cid = getPlayerInfo(src)
    return {
        cid     = cid,
        isAdmin = isAdmin(src),
    }
end)

lib.callback.register('tm-props:listMine', function(src)
    local cid = getPlayerInfo(src)
    if not cid then return {} end

    local mine = {}
    for _, row in pairs(props) do
        if row.owner_cid == cid then
            mine[#mine + 1] = clientPayload(row)
        end
    end
    return mine
end)

RegisterNetEvent('tm-props:place', function(model, coords)
    local src = source

    if not hasPlacePermission(src) then
        TM.Log.warn('place', ('player %s tried to place without permission'):format(src))
        return
    end

    if type(model) ~= 'string' or not validModel[model:lower()] then
        TM.Log.warn('place', ('player %s sent disallowed model %s'):format(src, tostring(model)))
        return
    end

    if type(coords) ~= 'vector4' and type(coords) ~= 'table' then
        return
    end

    local x, y, z, h = coords.x, coords.y, coords.z, coords.w or coords.heading or 0.0
    if type(x) ~= 'number' or type(y) ~= 'number' or type(z) ~= 'number' then
        return
    end

    -- anti-spoof: player must actually be near the coords they sent
    local pcoords = GetEntityCoords(GetPlayerPed(src))
    local dist = #(pcoords - vector3(x, y, z))
    if dist > (Config.Placement.MaxPlaceRange or 150.0) then
        TM.Log.warn('place', ('player %s placement too far (%.1fm)'):format(src, dist))
        return
    end

    local cid, name = getPlayerInfo(src)
    if not cid then return end

    local id = TM.DB.insert({
        owner_cid  = cid,
        owner_name = name,
        model      = model,
        x          = x,
        y          = y,
        z          = z,
        heading    = h,
    })

    if not id then
        TM.Log.err('place', 'database insert returned nil')
        return
    end

    local row = {
        id = id, owner_cid = cid, owner_name = name,
        model = model, x = x, y = y, z = z, heading = h,
    }
    props[id] = row

    TriggerClientEvent('tm-props:added', -1, clientPayload(row))
end)

local function removePropById(src, id)
    local row = props[id]
    if not row then return false, 'not_found' end

    -- src == 0 is a server-side caller (export / console), always allowed
    if src ~= 0 then
        local cid = getPlayerInfo(src)
        if not cid then return false, 'no_player' end

        if row.owner_cid ~= cid and not isAdmin(src) then
            return false, 'not_owner'
        end
    end

    TM.DB.delete(id)
    props[id] = nil
    TriggerClientEvent('tm-props:removed', -1, id)
    return true
end

RegisterNetEvent('tm-props:remove', function(id)
    local src = source
    if type(id) ~= 'number' then return end

    local ok, reason = removePropById(src, id)
    if not ok then
        TM.Log.warn('remove', ('player %s remove id=%s denied: %s'):format(src, id, reason))
    end
end)

exports('GetAllProps', function() return snapshot() end)
exports('RemoveProp',  function(id) return removePropById(0, id) end)
