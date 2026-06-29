# BLASPHEMY

**Gods won't save them.**

A lightweight Roblox client script hub with a bundled GUI library loader.

## Loadstring

Copy and execute this:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/sinmirka/BLASPHEMY/main/roblox_rage_hub_client.lua?v=20260629-2"))()
```

## Files

- `roblox_rage_hub_client.lua` - main BLASPHEMY client loader and feature script.
- `roblox_prism_gui_library.lua` - bundled GUI library.

## Current Tabs

- `Rage` - target selector, target bind, low-health targeting, orbit/smart orbit, camera lock, anti-void, target highlight customization, combat automation, and timing controls.
- `AutoFarm` - reserved for future features.
- `Alt` - reserved for future features.

## Requirements

- Your environment must support `loadstring` and `game:HttpGet`.
- Access to `raw.githubusercontent.com` is required.
- Some input features require `VirtualInputManager` support.
- Background modes use `Tool:Activate()` where possible.

## Notes

- The script is loaded directly from the `main` branch, so the loadstring always uses the latest committed version.
- If the GUI does not appear, check that the loadstring URL and bundled GUI library raw URL return `200 OK`.
- Use at your own risk.
