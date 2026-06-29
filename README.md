# BLASPHEMY

**Gods won't save them.**

A lightweight Roblox client script hub with a bundled GUI library loader.

## Loadstring

Copy and execute this:

```lua
loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/sinmirka/BLASPHEMY@51b1147/roblox_rage_hub_client.lua"))()
```

## Files

- `roblox_rage_hub_client.lua` - main BLASPHEMY client loader and feature script.
- `roblox_prism_gui_library.lua` - bundled GUI library.

## Current Tabs

- `Rage` - target selector, target bind, low-health targeting, orbit/smart orbit, camera lock, anti-void, target highlight customization, combat automation, and timing controls.
- `AutoFarm` - reserved for future features.
- `Alt` - reserved for future features.
- `Settings` - config save/load/delete, GUI themes, hide-GUI bind, reset controls, and advanced timing/anti-void tuning.

## Requirements

- Your environment must support `loadstring` and `game:HttpGet`.
- Access to `cdn.jsdelivr.net` is required.
- Config saving requires executor file APIs such as `writefile`, `readfile`, and `isfile`.
- Some input features require `VirtualInputManager` support.
- Background modes use `Tool:Activate()` where possible.

## Notes

- The loadstring is pinned to a tested commit to avoid stale CDN cache.
- If the GUI does not appear, check that the loadstring URL and bundled GUI library URL return `200 OK`.
- Use at your own risk.
