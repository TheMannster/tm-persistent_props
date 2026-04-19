<div align="center">

# tm-persistent_props

**Player-placeable, database-backed prop system for QBox / FiveM.**

Drop construction lights inside that pitch-black MLO once and they'll stay
there across restarts until you decide to remove them.

[![FiveM](https://img.shields.io/badge/FiveM-cerulean-F40552?style=flat-square)](https://fivem.net)
[![QBox](https://img.shields.io/badge/framework-QBox-blueviolet?style=flat-square)](https://github.com/Qbox-project/qbx_core)
[![ox_lib](https://img.shields.io/badge/ox__lib-required-blue?style=flat-square)](https://github.com/overextended/ox_lib)
[![Lua](https://img.shields.io/badge/Lua-5.4-2C2D72?style=flat-square&logo=lua)](https://www.lua.org)

</div>

---

## Features

- **One-command UI** &mdash; `/props` opens a clean ox_lib menu with **Place Prop** and **My Props** sections.
- **Persistent** &mdash; every placed prop is saved to MySQL and respawned on script restart at its original coordinates.
- **Placement preview** &mdash; ghost prop with scroll-rotate, height adjust, free-Z toggle, and a server-side range cap.
- **ox_target removal** &mdash; walk up to your prop and click "Remove Prop". Owner-only by default.
- **Real lighting** &mdash; configured props (worklights, floodlights, generator) emit point or spot lights with full control over color, range, intensity, direction, cone, and shadows. Lights track the prop's full rotation, so a tipped worklight tips with it.
- **Three permission modes** &mdash; `ace`, `identifier` whitelist, or qbx `job` (with optional on-duty requirement).
- **Server authoritative** &mdash; model allow-list + distance check on every placement, so the client can't spawn arbitrary objects.
- **Per-client streaming** &mdash; only props within `Config.RenderDistance` are spawned, so hundreds of saved props won't tank performance.
- **Quiet console option** &mdash; toggle the boot banner off if you don't want noise on startup.
- **Light-tuning debug overlay** &mdash; visualize the source point and cone of every light while you dial them in.

---

## Requirements

| Resource    | Required | Purpose                                          |
| ----------- | :------: | ------------------------------------------------ |
| `qbx_core`  |    Yes   | Player / citizenid lookups                       |
| `ox_lib`    |    Yes   | Menus, callbacks, notifications, model loader    |
| `oxmysql`   |    Yes   | Database persistence                             |
| `ox_target` |   Opt.   | Right-click "Remove Prop" on any placed prop     |

---

## Install

**1.** Drop the resource into `resources/[tm]/tm-persistent_props/`.

**2.** Import `sql/install.sql` into your database.

**3.** Add to `server.cfg`:
```cfg
ensure tm-persistent_props
```

**4.** Pick a permission mode in `config.lua`. See [Permissions](#permissions).

**5.** (Optional) Edit `Config.Props` and `Config.Lights` to taste.

---

## Permissions

Set `Config.PermissionMode` to one of `'ace'`, `'identifier'`, or `'job'`.

### `'ace'`
Add to `server.cfg`:
```cfg
add_ace group.admin tm.props       allow
add_ace group.admin tm.props.admin allow
```

| Ace                | Grants                                |
| ------------------ | ------------------------------------- |
| `tm.props`         | Place props, remove your own          |
| `tm.props.admin`   | Remove **any** prop (not just yours)  |

### `'identifier'`
Whitelist by raw identifier &mdash; useful when you don't want to manage groups.
```lua
Config.PermissionMode = 'identifier'

Config.AllowedIdentifiers = {
    'license:abcdef0123456789...',
    'discord:123456789012345678',
}

Config.AdminIdentifiers = {
    'license:abcdef0123456789...',
}
```
Accepted prefixes: `license:` &nbsp;`discord:` &nbsp;`steam:` &nbsp;`fivem:` &nbsp;`citizenid:`

> **Tip:** `citizenid:` is usually the easiest to manage &mdash; it's stable per
> character and visible in qbx admin tools. Use `license:` if you want the
> grant tied to the account regardless of which character is loaded.

### `'job'`
Grant access to entire qbx jobs &mdash; great for letting cops, mechanics, or
medics drop scene props without managing individuals.
```lua
Config.PermissionMode = 'job'

Config.AllowedJobs = {
    'police',
    'mechanic',
    'doa',
}

Config.AdminJobs = {
    'police',
}

Config.RequireOnDuty = false   -- true = on-duty members only
```

Job names must match the **internal** name in `qbx_core/shared/jobs.lua`
(e.g. `'police'`, not `'Los Santos Police Department'`).

---

## Usage

### `/props`

| Section        | What it does                                                              |
| -------------- | ------------------------------------------------------------------------- |
| **Place Prop** | Pick from your configured catalogue and enter the placement preview.      |
| **My Props**   | Lists every prop you've placed &mdash; teleport or delete from the sub-menu.    |

### Placement controls

| Key             | Action                          |
| --------------- | ------------------------------- |
| `Mouse Wheel`   | Rotate                          |
| `PgUp` / `PgDn` | Adjust height                   |
| `Left Alt`      | Toggle snap-to-ground / free-Z  |
| `E`             | Place                           |
| `Backspace`     | Cancel                          |

### ox_target removal
With `ox_target` running, walk up to any placed prop and use **Remove Prop**.
The option only shows for the prop's owner or anyone flagged as admin.

---

## Adding more props

The catalogue in `config.lua` is organized into **categories**. Each category
becomes a page in the `/props` -> Place Prop menu, then opens a sub-menu of
its props. Add as many categories and props as you like.

### Anatomy

```lua
Config.Props = {
    {
        category = 'Category Name',     -- shows in the menu
        icon     = 'folder',            -- FontAwesome icon (no "fa-" prefix)
        items = {
            {
                label = 'Prop Name',         -- menu title
                model = 'prop_model_name',   -- exact model spawn name
                desc  = 'Optional sub-text', -- shows under the title
                icon  = 'cube',              -- optional
            },
            -- more props...
        },
    },
    -- more categories...
}
```

### Step-by-step: add a "Barriers" category

**1.** Open `config.lua` and find `Config.Props`.

**2.** Add a new category block after the existing ones:

```lua
{
    category = 'Barriers',
    icon     = 'road-barrier',
    items = {
        {
            label = 'Traffic Cone',
            model = 'prop_roadcone02a',
            desc  = 'Standard orange traffic cone',
            icon  = 'triangle-exclamation',
        },
        {
            label = 'Police Barrier',
            model = 'prop_barrier_work05',
            desc  = 'Yellow & black road barrier',
            icon  = 'shield-halved',
        },
    },
},
```

**3.** `restart tm-persistent_props` on your server.

**4.** Run `/props` -> **Place Prop** and your new "Barriers" page will be
right there with the cone and barrier inside.

### Want lights on it too?

If the prop should emit light, add a matching entry in `Config.Lights` keyed
by the exact model name. See [Adding more lights](#adding-more-lights) below.

### Notes

- Only models present in `Config.Props` are accepted by the server, so a
  tampered client can't spawn arbitrary objects. Add the model here first,
  then it's placeable.
- FontAwesome icons: just the name without the `fa-` prefix
  (e.g. `'plug'`, `'sun'`, `'road-barrier'`). Browse them at
  [fontawesome.com/icons](https://fontawesome.com/icons).
- Model not sure? Try [Code Walker](https://github.com/dexyfex/CodeWalker)
  or [gtaobjects.xyz](https://gtaobjects.xyz/) to look up object names.

---

## Adding more lights

Append to `Config.Lights` keyed by exact model name. Two light types are
supported.

**Point light** (radiates equally in all directions):
```lua
['prop_my_lamp'] = {
    type      = 'point',
    offset    = vec3(0.0, 0.0, 1.7),  -- local-space, rotates with prop
    color     = { 255, 250, 235 },    -- { r, g, b }
    range     = 25.0,                 -- meters
    intensity = 8.0,                  -- 1.0 - 10.0 sweet spot
    shadows   = false,
},
```

**Spot light** (focused cone, like a real worklight):
```lua
['prop_worklight_03b'] = {
    type       = 'spot',
    offset     = vec3(0.0, 0.0, 2.4),
    direction  = vec3(0.0, 0.4, -1.0),  -- aim, local-space
    color      = { 255, 226, 175 },
    distance   = 25.0,                  -- cone reach in meters
    brightness = 8.0,
    radius     = 13.0,                  -- cone wideness at distance
    falloff    = 22.0,
    hardness   = 0.0,                   -- 0 = soft edges
    shadows    = false,
},
```

Models not in `Config.Lights` simply emit no light &mdash; perfect for cones,
barriers, signage, etc.

> **Tuning tip:** flip `Config.Debug = true` to overlay a red marker on each
> light source and a cyan wireframe of every spot cone. Move the prop around,
> tweak `offset` / `direction`, then turn debug back off.

---

## Exports

```lua
-- server
local all = exports['tm-persistent_props']:GetAllProps()
exports['tm-persistent_props']:RemoveProp(propId)  -- bypasses ownership check
```

---

## How it works

- **Server is the source of truth.** On boot it loads every row from
  `tm_persistent_props` into memory and never trusts the client thereafter.
- **Clients pull a snapshot** via `tm-props:fetchAll` on join, then receive
  `tm-props:added` / `tm-props:removed` deltas as players place / remove
  things.
- **Each client spawns its own local copy** of every prop within
  `Config.RenderDistance` and despawns past
  `Config.RenderDistance + Config.RenderHysteresis`, so entity counts stay
  low no matter how many props are saved globally.
- **Placement is validated server-side**: the model must be in `Config.Props`,
  the player must be within `Config.Placement.MaxPlaceRange` of the coords
  they sent, and they must hold the configured permission.
- **Lights are drawn per-frame** and follow the local entity's full rotation
  matrix when it's spawned, falling back to the saved DB heading when the
  player is out of range.

### A note on movement &amp; networking

Props are **not network-synced** between players. Each client spawns and
renders its own local copy at the saved database coordinates.

- With `Config.LockProps = true` (default) this is invisible &mdash; props are
  frozen + invincible + bulletproof, nothing can move them, every player sees
  the exact same thing.
- With `Config.LockProps = false`, props are pushable and physics-enabled,
  **but only the player who pushed them sees the new position.** Other
  players continue to see the prop at the saved DB coords. When the pusher
  walks far enough away and comes back, their local copy despawns and
  respawns at the original DB position too.

Honestly, I couldn't figure out how to get networked prop movement working
without breaking the rest of the script, so it's not in here. Keep
`LockProps = true` for static scenery and you'll never notice.

---

## Credits

Built by **themannster** as part of the `tm-*` resource family.
