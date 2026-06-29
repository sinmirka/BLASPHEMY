# BLASPHEMY

**Gods won't save them.**

A lightweight Roblox client script hub with a bundled GUI library loader.

## Loadstring

Copy and execute this:

```lua
loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/sinmirka/BLASPHEMY@eb2d20e/roblox_rage_hub_client.lua"))()
```

## Files

- `roblox_rage_hub_client.lua` - main Blasphemy client loader and feature script.
- `roblox_prism_gui_library.lua` - bundled GUI library.

## Current Tabs

- `Rage` - target selector, target/friend lists, target bind, low-health targeting, orbit/smart orbit, camera lock, anti-void, and target highlight customization.
- `Combat` - Auto M1, Background M1, Auto Skills, Auto Ultimate, Auto Burst, Auto Dash/Wall Combo, Auto Evasive, and timing controls.
- `Player` - WalkSpeed, Jump Power, and Fly with selectable implementation methods.
- `Optimizations` - shadows, textures, effects, materials, terrain, lighting, 3D render toggle, and performance presets.
- `AutoFarm` - SetPosition capture, saved CFrame lock, and teleport delay control.
- `Alt` - AutoReset on spawn with reset delay, manual reset, separate SetPosition capture, saved CFrame lock, respawn teleport delay, and teleport interval control.
- `Settings` - config save/load/delete, per-UserId config auto-load, GUI themes, Anti-AFK, Auto Reconnect, hide-GUI bind, reset controls, and advanced timing/anti-void tuning.
- Top-center watermark - always-visible Blasphemy status, ping, and FPS display.

## Requirements

- Your environment must support `loadstring` and `game:HttpGet`.
- Access to `cdn.jsdelivr.net` is required.
- Config saving requires executor file APIs such as `writefile`, `readfile`, and `isfile`.
- Some input features require `VirtualInputManager` support.
- Script queueing after reconnect requires `queue_on_teleport` or an equivalent executor API.
- Background modes use `Tool:Activate()` where possible.

## Notes

- The loadstring is pinned to a tested commit to avoid stale CDN cache.
- If the GUI does not appear, check that the loadstring URL and bundled GUI library URL return `200 OK`.
- Auto Reconnect can attempt to queue the loader on teleport, but Auto Execute is still the most reliable fallback.
- Use at your own risk.
