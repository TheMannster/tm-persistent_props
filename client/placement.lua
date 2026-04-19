local placing = false

local function showHelp()
    lib.showTextUI(
        '[Scroll] Rotate  \n[PgUp/PgDn] Height  \n[LAlt] Free Z  \n[E] Place  \n[Backspace] Cancel',
        { position = 'right-center' }
    )
end

local function startPlacement(modelName)
    if placing then return end
    placing = true

    local hash = joaat(modelName)
    if not lib.requestModel(hash, 5000) then
        lib.notify({ type = 'error', description = 'Failed to load prop model' })
        placing = false
        return
    end

    local ped     = PlayerPedId()
    local pcoords = GetEntityCoords(ped)
    local fwd     = GetEntityForwardVector(ped)
    local startPos = pcoords + fwd * (Config.Placement.Distance or 2.5)

    local ghost = CreateObjectNoOffset(hash, startPos.x, startPos.y, startPos.z, false, false, false)
    SetEntityAlpha(ghost, 160, false)
    SetEntityCollision(ghost, false, false)
    FreezeEntityPosition(ghost, true)
    SetEntityInvincible(ghost, true)

    local heading       = GetEntityHeading(ped)
    local heightOffset  = 0.0
    local snapToGround  = Config.Placement.SnapToGround
    local rotateStep    = Config.Placement.RotateStep or 5.0
    local heightStep    = Config.Placement.HeightStep or 0.05
    local maxRange      = Config.Placement.MaxPlaceRange or 150.0

    showHelp()

    local placed, cancelled = false, false

    while placing do
        local ply = PlayerPedId()
        local pcrd = GetEntityCoords(ply)
        local fv = GetEntityForwardVector(ply)
        local target = pcrd + fv * (Config.Placement.Distance or 2.5)

        local zOut = target.z
        if snapToGround then
            local found, gz = GetGroundZFor_3dCoord(target.x, target.y, target.z + 2.0, false)
            if found then zOut = gz end
        end
        zOut = zOut + heightOffset

        SetEntityCoordsNoOffset(ghost, target.x, target.y, zOut, false, false, false)
        SetEntityHeading(ghost, heading)

        DisableControlAction(0, 14,  true)
        DisableControlAction(0, 15,  true)
        DisableControlAction(0, 24,  true)
        DisableControlAction(0, 25,  true)
        DisableControlAction(0, 257, true)
        DisablePlayerFiring(PlayerId(), true)

        if IsDisabledControlJustPressed(0, 14) then
            heading = (heading + rotateStep) % 360
        elseif IsDisabledControlJustPressed(0, 15) then
            heading = (heading - rotateStep) % 360
        end

        if IsControlPressed(0, 10) then
            heightOffset = heightOffset + heightStep
        elseif IsControlPressed(0, 11) then
            heightOffset = heightOffset - heightStep
        end

        if IsControlJustPressed(0, 19) then
            snapToGround = not snapToGround
            if snapToGround then heightOffset = 0.0 end
            lib.notify({
                type = 'inform',
                description = 'Snap to ground: ' .. (snapToGround and 'ON' or 'OFF'),
                duration = 1500,
            })
        end

        if IsControlJustPressed(0, 38) then
            if #(pcrd - vector3(target.x, target.y, zOut)) > maxRange then
                lib.notify({ type = 'error', description = 'Too far to place here' })
            else
                TriggerServerEvent('tm-props:place', modelName, vec4(target.x, target.y, zOut, heading))
                placed = true
                placing = false
            end
        end

        if IsControlJustPressed(0, 177) then
            cancelled = true
            placing = false
        end

        Wait(0)
    end

    DeleteEntity(ghost)
    SetModelAsNoLongerNeeded(hash)
    lib.hideTextUI()

    if placed then
        lib.notify({ type = 'success', description = 'Prop placed' })
    elseif cancelled then
        lib.notify({ type = 'inform', description = 'Cancelled' })
    end
end

local function buildPlaceMenu()
    local categories = TM.Catalogue.categories()
    local options    = {}

    for i, cat in ipairs(categories) do
        local catId = 'tm_props_cat_' .. i

        options[#options + 1] = {
            title       = cat.name,
            description = ('%d prop%s'):format(#cat.items, #cat.items == 1 and '' or 's'),
            icon        = cat.icon or 'folder',
            menu        = catId,
        }

        local items = {}
        for _, p in ipairs(cat.items) do
            items[#items + 1] = {
                title       = p.label or p.model,
                description = p.desc,
                icon        = p.icon,
                onSelect    = function() startPlacement(p.model) end,
            }
        end

        if #items == 0 then
            items[#items + 1] = { title = 'No props in this category', disabled = true }
        end

        lib.registerContext({
            id      = catId,
            title   = cat.name,
            menu    = 'tm_props_place',
            options = items,
        })
    end

    if #options == 0 then
        options[#options + 1] = {
            title    = 'No props configured',
            disabled = true,
        }
    end

    lib.registerContext({
        id      = 'tm_props_place',
        title   = 'Place Prop',
        menu    = 'tm_props_root',
        options = options,
    })
end

local function buildMineMenu(list)
    local options = {}

    if #list == 0 then
        options[#options + 1] = {
            title       = 'No props placed',
            description = 'Pick something from "Place Prop" to start.',
            disabled    = true,
        }
    end

    for _, prop in ipairs(list) do
        local subId = 'tm_props_mine_' .. prop.id

        options[#options + 1] = {
            title       = ('#%d - %s'):format(prop.id, prop.model),
            description = ('%.1f, %.1f, %.1f'):format(prop.x, prop.y, prop.z),
            icon        = 'cube',
            menu        = subId,
        }

        lib.registerContext({
            id      = subId,
            title   = ('Prop #%d'):format(prop.id),
            menu    = 'tm_props_mine',
            options = {
                {
                    title       = 'Teleport to',
                    description = 'Move yourself to this prop',
                    icon        = 'location-arrow',
                    onSelect    = function()
                        SetEntityCoords(PlayerPedId(), prop.x, prop.y, prop.z + 1.0, false, false, false, false)
                    end,
                },
                {
                    title       = 'Delete',
                    description = 'Remove permanently',
                    icon        = 'trash',
                    onSelect    = function()
                        local ok = lib.alertDialog({
                            header   = 'Delete prop #' .. prop.id .. '?',
                            content  = 'This cannot be undone.',
                            centered = true,
                            cancel   = true,
                            labels   = { confirm = 'Delete', cancel = 'Keep' },
                        })
                        if ok == 'confirm' then
                            TriggerServerEvent('tm-props:remove', prop.id)
                        end
                    end,
                },
            },
        })
    end

    lib.registerContext({
        id      = 'tm_props_mine',
        title   = 'My Props (' .. #list .. ')',
        menu    = 'tm_props_root',
        options = options,
    })
end

local function openRootMenu()
    buildPlaceMenu()

    lib.registerContext({
        id      = 'tm_props_root',
        title   = 'Props',
        options = {
            {
                title       = 'Place Prop',
                description = 'Pick a prop and drop it in the world',
                icon        = 'plus',
                menu        = 'tm_props_place',
            },
            {
                title       = 'My Props',
                description = 'Manage props you have placed',
                icon        = 'list',
                onSelect    = function()
                    local list = lib.callback.await('tm-props:listMine', false) or {}
                    buildMineMenu(list)
                    lib.showContext('tm_props_mine')
                end,
            },
        },
    })

    lib.showContext('tm_props_root')
end

RegisterCommand(Config.Commands.Open or 'props', function()
    if placing then
        lib.notify({ type = 'error', description = 'Already placing a prop' })
        return
    end
    openRootMenu()
end, false)
