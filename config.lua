Config = {}

-- =============================================================================
-- 1. GENERAL
-- =============================================================================

Config.Commands = {
    Open = 'props',          -- /props opens the main menu
}

-- Server console boot banner. Errors and warnings still print regardless.
Config.ShowStartupBanner = true

-- Light-debug overlay: red source marker + cyan cone wireframe on every
-- spawned light. Tweak light offsets / cones with this on, then turn it back
-- off in production.
Config.Debug = true

-- =============================================================================
-- 2. PERMISSIONS
-- =============================================================================
-- Pick ONE mode. AllowEveryone bypasses everything (don't ship with this on).
--
--   'ace'        - IsPlayerAceAllowed(src, Config.AcePermission)
--   'identifier' - matches against Config.AllowedIdentifiers
--   'job'        - matches against Config.AllowedJobs (qbx job name)

Config.PermissionMode = 'job'
Config.AllowEveryone  = false

-- ace mode --------------------------------------------------------------------
Config.AcePermission      = 'tm.props'
Config.AdminAcePermission = 'tm.props.admin'

-- identifier mode -------------------------------------------------------------
-- Full identifiers, any of:  license:  discord:  steam:  fivem:  citizenid:
Config.AllowedIdentifiers = {
    -- 'license:abcdef0123456789...',
}
Config.AdminIdentifiers = {
    -- 'license:abcdef0123456789...',
}

-- job mode --------------------------------------------------------------------
-- Internal qbx job names (NOT labels). RequireOnDuty applies to both lists.
Config.AllowedJobs = {
    'police',
    'mechanic',
    'doa',
    'lscso',
}
Config.AdminJobs = {
    'police',
}
Config.RequireOnDuty = false

-- =============================================================================
-- 3. PLACEMENT PREVIEW
-- =============================================================================

Config.Placement = {
    Distance      = 2.5,    -- meters in front of the player the preview floats
    RotateStep    = 5.0,    -- degrees per scroll tick
    HeightStep    = 0.05,   -- meters per PgUp/PgDn tick
    MaxPlaceRange = 150.0,  -- hard cap from player, server-enforced
    SnapToGround  = true,   -- toggle in-world with Left Alt
}

-- =============================================================================
-- 4. INTERACTION (ox_target)
-- =============================================================================
-- "Remove Prop" target option. Owner-only by default; admins see it on every
-- prop. Auto-disables if ox_target isn't running.

Config.UseOxTarget    = true
Config.TargetDistance = 2.5
Config.TargetIcon     = 'fas fa-trash'
Config.TargetLabel    = 'Remove Prop'

-- =============================================================================
-- 5. PERFORMANCE
-- =============================================================================

-- Each client only spawns props within RenderDistance, despawns past
-- (RenderDistance + RenderHysteresis). RenderTick is the proximity-loop period
-- in ms.
Config.RenderDistance   = 80.0
Config.RenderHysteresis = 15.0
Config.RenderTick       = 750

-- Freeze + invincible at spawn. Recommended ON for static scenery; turning it
-- OFF lets players push props around. Note: each client renders its own local
-- copy, so movement is NOT synced between players. The database position is
-- always the "home" that props respawn to on script restart.
Config.LockProps = true

-- =============================================================================
-- 6. PROPS  -  catalogue shown in /props -> Place Prop
-- =============================================================================
-- Organized into categories. Each category appears as its own page in the menu.
-- See README.md ("Adding more props") for a step-by-step example.
--
-- Category fields:
--   category : page title shown in the menu
--   icon     : FontAwesome icon for the category tile (no "fa-" prefix)
--   items    : list of props in this category
--
-- Item fields:
--   label : menu title
--   model : exact prop model (validated server-side)
--   desc  : optional sub-text
--   icon  : optional FontAwesome icon (no "fa-" prefix)

Config.Props = {
    {
        category = 'Construction Lighting',
        icon     = 'lightbulb',
        items    = {
            {
                label = 'Construction Light (Tripod)',
                model = 'prop_worklight_03b',
                desc  = 'Tall yellow tripod work lamp',
                icon  = 'lightbulb',
            },
            {
                label = 'Construction Light (Small)',
                model = 'prop_worklight_02a',
                desc  = 'Smaller folding work lamp',
                icon  = 'lightbulb',
            },
            {
                label = 'Construction Light (Portable)',
                model = 'prop_worklight_04a',
                desc  = 'Portable battery work light',
                icon  = 'lightbulb',
            },
            {
                label = 'Floodlight (Studio)',
                model = 'prop_studio_light_02',
                desc  = 'Bright studio floodlight on stand',
                icon  = 'sun',
            },
        },
    },

    {
        category = 'Power',
        icon     = 'plug',
        items    = {
            {
                label = 'Generator',
                model = 'prop_generator_03b',
                desc  = 'Yellow construction generator (also lights the area)',
                icon  = 'plug',
            },
        },
    },
}

-- =============================================================================
-- 7. LIGHTS  -  per-model emission
-- =============================================================================
-- Keyed by exact prop model. Models not listed emit no light.
--
-- Common fields:
--   type    : 'point' (default) or 'spot'
--   offset  : light origin, local-space, rotates with prop heading (vec3)
--   color   : { r, g, b }
--   shadows : soft shadows (more expensive, use sparingly)
--
-- type = 'point':
--   range     : falloff distance in meters
--   intensity : brightness multiplier (1.0 - 10.0 typical)
--
-- type = 'spot':
--   direction  : aim vector, local-space (vec3, auto-normalized)
--   distance   : how far the cone reaches (meters)
--   brightness : intensity multiplier
--   radius     : cone wideness at distance
--   falloff    : light decay over distance
--   hardness   : 0.0 = soft edges, higher = harder edges

Config.Lights = {
    ['prop_worklight_03b'] = {
        type       = 'spot',
        offset     = vec3(0.0, 0.0, 100.55),
        direction  = vec3(0.0, 0.4, -1.0),
        color      = { 255, 226, 175 },
        distance   = 25.0,
        brightness = 8.0,
        radius     = 13.0,
        falloff    = 22.0,
        hardness   = 0.0,
        shadows    = false,
    },
    ['prop_worklight_02a'] = {
        type       = 'spot',
        offset     = vec3(0.0, 0.0, 100.0),
        direction  = vec3(0.0, 0.4, -1.0),
        color      = { 255, 226, 175 },
        distance   = 18.0,
        brightness = 6.0,
        radius     = 11.0,
        falloff    = 18.0,
        hardness   = 0.0,
        shadows    = false,
    },
    ['prop_worklight_04a'] = {
        type       = 'spot',
        offset     = vec3(0.0, 0.0, 100.6),
        direction  = vec3(0.0, 0.0, -1.0),
        color      = { 255, 230, 180 },
        distance   = 14.0,
        brightness = 5.0,
        radius     = 14.0,
        falloff    = 14.0,
        hardness   = 0.0,
        shadows    = false,
    },
    ['prop_studio_light_02'] = {
        type       = 'spot',
        offset     = vec3(0.0, 0.0, 100.7),
        direction  = vec3(0.0, 1.0, -0.3),
        color      = { 255, 250, 235 },
        distance   = 30.0,
        brightness = 10.0,
        radius     = 16.0,
        falloff    = 28.0,
        hardness   = 0.0,
        shadows    = false,
    },
    ['prop_generator_03b'] = {
        type       = 'spot',
        offset     = vec3(0.0, -1.5, 3.8),
        direction  = vec3(0.0, 5.0, -0.2),
        color      = { 255, 235, 195 },
        distance   = 100.0,
        brightness = 35.0,
        radius     = 65.0,
        falloff    = 95.0,
        hardness   = 0.0,
        shadows    = true,
    },
}
