# Changelog

## [1.0.0]
- Initial release
- Player-placeable persistent props with database backing (oxmysql)
- Categorised catalogue menu via `ox_lib` (`/props`)
- Live placement preview with rotate (scroll), height (PgUp/PgDn), and ground-snap (Left Alt) controls
- Server-side model allowlist + range check on placement to prevent spoofed events
- Per-model emissive lights (`point` / `spot`) with optional shadows and debug overlay
- Proximity-based render loop with hysteresis to keep entity counts low
- Removal via `ox_target` ("Remove Prop") - owner-only, admin-bypass
- Permission modes: `ace`, `identifier`, `job` (with optional on-duty requirement) plus `AllowEveryone` override
- `qbx_core` integration for citizenid resolution and job lookups
- Server exports: `GetAllProps`, `RemoveProp`
- GitHub-based version check on boot (reads remote `fxmanifest.lua`, prints latest changelog section if outdated)
