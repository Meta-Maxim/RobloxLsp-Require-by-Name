# Roblox LSP Require-by-Name
Adds context-aware require-by-name module linking to Roblox LSP.

![Code_mGZO39ONWF](https://user-images.githubusercontent.com/2924585/162556118-bebe2db1-95ec-4179-9967-d3fc8a96ecad.gif)

When a string argument is passed to any function named `require`, it will attempt to link the most context-relevant file.

⚠️ Can break with Roblox LSP updates. Use at your own risk! ⚠️

Last tested with Roblox LSP 1.5.9

<br/>

## Installation:

1. Install [Roblox LSP Plugin Loader](https://github.com/MaxBorsch/RobloxLsp-plugin-loader).

2. Move this repository folder (**RobloxLsp-Require-by-Name**) into the `plugins` folder (in the same directory as the `plugin-loader.lua`).

<br/>

## Operation:

Contexts: Client, Server, Shared

Context is detected by (most important first):
1. Script type (`Script` vs. `LocalScript`)
2. If script path contains:
  - `/client/`
  - `/shared/`
  - `/server/`
3. Ancestor service of script
