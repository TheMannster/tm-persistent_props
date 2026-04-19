TM = TM or {}
TM.Props = TM.Props or {}

local known   = {}    -- [id] = prop data from server
local spawned = {}    -- [id] = local entity handle
local lights  = {}    -- [id] = light render data

local hashCache = setmetatable({}, { __index = function(t, k)
    local h = joaat(k)
    rawset(t, k, h)
    return h
end })

local me = { cid = nil, isAdmin = false }

local function canRemoveProp(prop)
    if not prop then return false end
    if me.isAdmin then return true end
    return me.cid and prop.owner == me.cid
end

local function targetEnabled()
    return Config.UseOxTarget and GetResourceState('ox_target') == 'started'
end

local function applyLockFlags(obj)
    if not Config.LockProps then return end
    FreezeEntityPosition(obj, true)
    SetEntityInvincible(obj, true)
    SetEntityCanBeDamaged(obj, false)
    SetEntityCollision(obj, true, true)
    SetEntityProofs(obj, true, true, true, true, true, true, 1, true)
    SetEntityDynamic(obj, false)
end

local function attachLight(prop)
    local def = Config.Lights and Config.Lights[prop.model]
    if not def then return end

    lights[prop.id] = {
        propId     = prop.id,
        type       = def.type or 'point',
        offset     = def.offset    or vec3(0.0, 0.0, 1.0),
        direction  = def.direction or vec3(0.0, 0.0, -1.0),
        baseX      = prop.x,
        baseY      = prop.y,
        baseZ      = prop.z,
        baseHead   = prop.heading or 0.0,
        r          = def.color and def.color[1] or 255,
        g          = def.color and def.color[2] or 220,
        b          = def.color and def.color[3] or 170,
        shadows    = def.shadows == true,
        distance   = def.distance   or 25.0,
        brightness = def.brightness or 8.0,
        hardness   = def.hardness   or 0.0,
        radius     = def.radius     or 13.0,
        falloff    = def.falloff    or 25.0,
        range      = def.range      or 18.0,
        intensity  = def.intensity  or 5.0,
    }
end

local function detachLight(id)
    lights[id] = nil
end

-- world-space position + direction for a light each frame; uses the entity's
-- full rotation matrix so lights track tipped/rolled props
local function lightTransform(l)
    local off = l.offset
    local d   = l.direction
    local entity = spawned[l.propId]

    if entity and DoesEntityExist(entity) then
        local fwd, right, up, pos = GetEntityMatrix(entity)
        local x  = pos.x + right.x * off.x + fwd.x * off.y + up.x * off.z
        local y  = pos.y + right.y * off.x + fwd.y * off.y + up.y * off.z
        local z  = pos.z + right.z * off.x + fwd.z * off.y + up.z * off.z
        local dx = right.x * d.x + fwd.x * d.y + up.x * d.z
        local dy = right.y * d.x + fwd.y * d.y + up.y * d.z
        local dz = right.z * d.x + fwd.z * d.y + up.z * d.z
        local mag = math.sqrt(dx * dx + dy * dy + dz * dz)
        if mag > 0 then dx, dy, dz = dx / mag, dy / mag, dz / mag end
        return x, y, z, dx, dy, dz
    end

    local rad  = math.rad(l.baseHead)
    local cosH = math.cos(rad)
    local sinH = math.sin(rad)
    local x = l.baseX + (off.x * cosH - off.y * sinH)
    local y = l.baseY + (off.x * sinH + off.y * cosH)
    local z = l.baseZ + off.z
    local dx = d.x * cosH - d.y * sinH
    local dy = d.x * sinH + d.y * cosH
    local dz = d.z
    local mag = math.sqrt(dx * dx + dy * dy + dz * dz)
    if mag > 0 then dx, dy, dz = dx / mag, dy / mag, dz / mag end
    return x, y, z, dx, dy, dz
end

local function attachTarget(obj, prop)
    if not targetEnabled() then return end

    exports.ox_target:addLocalEntity(obj, {
        {
            name     = 'tm_props_remove_' .. prop.id,
            icon     = Config.TargetIcon or 'fas fa-trash',
            label    = Config.TargetLabel or 'Remove Prop',
            distance = Config.TargetDistance or 2.5,
            canInteract = function()
                return canRemoveProp(known[prop.id])
            end,
            onSelect = function()
                local confirm = lib.alertDialog({
                    header   = 'Remove this prop?',
                    content  = 'This will permanently delete the prop from the database.',
                    centered = true,
                    cancel   = true,
                    labels   = { confirm = 'Delete', cancel = 'Keep' },
                })
                if confirm == 'confirm' then
                    TriggerServerEvent('tm-props:remove', prop.id)
                end
            end,
        },
    })
end

local function detachTarget(obj)
    if not targetEnabled() or not obj then return end
    exports.ox_target:removeLocalEntity(obj, nil)
end

local function spawnProp(prop)
    if spawned[prop.id] then return end

    local hash = hashCache[prop.model]
    if not lib.requestModel(hash, 5000) then return end

    local obj = CreateObjectNoOffset(hash, prop.x, prop.y, prop.z, false, false, false)
    if obj == 0 then
        SetModelAsNoLongerNeeded(hash)
        return
    end

    SetEntityHeading(obj, prop.heading or 0.0)
    SetEntityAsMissionEntity(obj, true, true)
    applyLockFlags(obj)
    SetModelAsNoLongerNeeded(hash)

    spawned[prop.id] = obj
    attachTarget(obj, prop)
end

local function despawnProp(id)
    local obj = spawned[id]
    if obj and DoesEntityExist(obj) then
        detachTarget(obj)
        SetEntityAsMissionEntity(obj, false, false)
        DeleteEntity(obj)
    end
    spawned[id] = nil
end

local function despawnAll()
    for id in pairs(spawned) do despawnProp(id) end
end

local function distSq(ax, ay, az, bx, by, bz)
    local dx, dy, dz = ax - bx, ay - by, az - bz
    return dx * dx + dy * dy + dz * dz
end

CreateThread(function()
    while not TM.Props._loaded do Wait(250) end

    local renderSq = (Config.RenderDistance or 80.0) ^ 2
    local despSq   = ((Config.RenderDistance or 80.0) + (Config.RenderHysteresis or 15.0)) ^ 2

    while true do
        local px, py, pz = table.unpack(GetEntityCoords(PlayerPedId()))

        for id, prop in pairs(known) do
            local d = distSq(px, py, pz, prop.x, prop.y, prop.z)
            if spawned[id] then
                if d > despSq then despawnProp(id) end
            else
                if d <= renderSq then spawnProp(prop) end
            end
        end

        Wait(Config.RenderTick or 750)
    end
end)

CreateThread(function()
    while true do
        if next(lights) then
            for _, l in pairs(lights) do
                local x, y, z, dx, dy, dz = lightTransform(l)
                if l.type == 'spot' then
                    if l.shadows then
                        DrawSpotLightWithShadow(
                            x, y, z, dx, dy, dz,
                            l.r, l.g, l.b,
                            l.distance, l.brightness, l.hardness, l.radius, l.falloff, 0
                        )
                    else
                        DrawSpotLight(
                            x, y, z, dx, dy, dz,
                            l.r, l.g, l.b,
                            l.distance, l.brightness, l.hardness, l.radius, l.falloff
                        )
                    end
                else
                    if l.shadows then
                        DrawLightWithRangeAndShadow(x, y, z, l.r, l.g, l.b, l.range, l.intensity, 8.0)
                    else
                        DrawLightWithRange(x, y, z, l.r, l.g, l.b, l.range, l.intensity)
                    end
                end
            end
        end
        Wait(0)
    end
end)

local function refreshWhoami()
    local who = lib.callback.await('tm-props:whoami', false)
    if type(who) == 'table' and who.cid then
        me.cid     = who.cid
        me.isAdmin = who.isAdmin and true or false
        return true
    end
    return false
end

CreateThread(function()
    Wait(500)

    for _ = 1, 30 do
        if refreshWhoami() then break end
        Wait(1000)
    end

    local list = lib.callback.await('tm-props:fetchAll', false)
    if type(list) == 'table' then
        for _, prop in ipairs(list) do
            known[prop.id] = prop
            attachLight(prop)
        end
    end
    TM.Props._loaded = true
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', refreshWhoami)
AddEventHandler('qbx_core:client:playerLoggedIn', refreshWhoami)

RegisterNetEvent('tm-props:added', function(prop)
    if not prop or not prop.id then return end
    known[prop.id] = prop
    attachLight(prop)
end)

RegisterNetEvent('tm-props:removed', function(id)
    if not id then return end
    known[id] = nil
    detachLight(id)
    despawnProp(id)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    despawnAll()
end)

function TM.Props.getKnown(id) return known[id] end
function TM.Props.allKnown() return known end

local function drawConeWireframe(x, y, z, dx, dy, dz, distance, radius)
    local ex = x + dx * distance
    local ey = y + dy * distance
    local ez = z + dz * distance

    local ax, ay, az
    if math.abs(dz) < 0.9 then
        ax, ay, az = -dy, dx, 0.0
    else
        ax, ay, az = 0.0, -dz, dy
    end
    local am = math.sqrt(ax * ax + ay * ay + az * az)
    if am > 0 then ax, ay, az = ax / am, ay / am, az / am end

    local bx = dy * az - dz * ay
    local by = dz * ax - dx * az
    local bz = dx * ay - dy * ax
    local bm = math.sqrt(bx * bx + by * by + bz * bz)
    if bm > 0 then bx, by, bz = bx / bm, by / bm, bz / bm end

    local segments = 16
    local prevX, prevY, prevZ
    for i = 0, segments do
        local theta = (i / segments) * math.pi * 2
        local cs, sn = math.cos(theta), math.sin(theta)
        local px = ex + radius * (ax * cs + bx * sn)
        local py = ey + radius * (ay * cs + by * sn)
        local pz = ez + radius * (az * cs + bz * sn)

        if i % 4 == 0 then
            DrawLine(x, y, z, px, py, pz, 0, 255, 255, 200)
        end

        if prevX then
            DrawLine(prevX, prevY, prevZ, px, py, pz, 0, 255, 255, 200)
        end
        prevX, prevY, prevZ = px, py, pz
    end
end

if Config.Debug then
    CreateThread(function()
        while true do
            for _, l in pairs(lights) do
                local x, y, z, dx, dy, dz = lightTransform(l)
                DrawMarker(
                    28, x, y, z, 0, 0, 0, 0, 0, 0,
                    0.25, 0.25, 0.25, 255, 50, 50, 180,
                    false, false, 2, false, nil, nil, false
                )

                if l.type == 'spot' then
                    drawConeWireframe(x, y, z, dx, dy, dz, l.distance, l.radius)
                end
            end
            Wait(0)
        end
    end)
end

RegisterCommand('propsdebug', function()
    print(('[tm-props] me.cid=%s  me.isAdmin=%s  loaded=%s  targetEnabled=%s')
        :format(tostring(me.cid), tostring(me.isAdmin), tostring(TM.Props._loaded), tostring(targetEnabled())))
    local count = 0
    for id, prop in pairs(known) do
        count = count + 1
        local ent = spawned[id]
        print(('  #%d model=%s owner=%s spawned=%s ownerMatch=%s')
            :format(id, prop.model, tostring(prop.owner),
                    tostring(ent and DoesEntityExist(ent)),
                    tostring(prop.owner == me.cid)))
    end
    print(('[tm-props] %d known prop(s)'):format(count))
end, false)
