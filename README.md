# jrmy_tags

Persistent player tags for FiveM servers running Qbox, QBCore or ESX.

Administrators can assign styled tags to online players. Players keep a personal collection, choose which tag to use and decide when it is visible above their character.

Developed by **Jaramiyo**.

## Features

- Personal collection with multiple tags per player.
- Administrative panel for assigning, editing and removing tags.
- Seven configurable style presets.
- Local image and animated backgrounds per style.
- Custom label, subtitle and emoji support.
- Optional expiration dates.
- AFK and voice indicators.
- Distance, line-of-sight and visibility controls.
- Persistent selection and visibility settings.
- Spanish and English interface.
- Server-side permission and ownership validation.
- Qbox, QBCore and ESX support.

## Requirements

- [oxmysql](https://github.com/overextended/oxmysql)
- Qbox, QBCore or ESX

## Installation

1. Copy `jrmy_tags` into your server resources folder.
2. Start it after `oxmysql` and your framework.

```cfg
ensure oxmysql
ensure qbx_core
ensure jrmy_tags
```

Replace `qbx_core` with the framework used by your server.

3. Grant administrative access in `server.cfg`:

```cfg
add_ace group.admin jrmy_tags.admin allow
```

4. Restart the server.

The database tables are created automatically. `sql/install.sql` is also available for manual installation.

## Commands

| Command | Description |
| --- | --- |
| `/tags` | Opens the personal tag collection. |
| `/tag` | Shows or hides the selected tag. |
| `/tagadmin` | Opens the administrative panel. |
| `/afk` | Toggles the AFK status. |

Command names can be changed in `config.lua`.

## Configuration

`config.lua` contains the framework, language, identity scope, permissions, rendering options and tag catalog.

Tags use safe presets. Each preset defines its name, default text, symbol, shape, tone, typography and animation. Add or edit presets in `Config.Styles` and `Config.Tones`.

Choose `Config.IdentityScope` before using the resource in production. `license` shares tags between characters. `character` stores a separate collection for each character.

## Custom backgrounds

Place `.png`, `.jpg`, `.webp` or `.gif` files inside `html/assets/tag-backgrounds`. Register the file in `Config.Backgrounds`, then set its key in the `Background` field of any style.

GIF files are detected automatically. Animated WebP files require `Animated = true`. Add a static `Fallback` so animated backgrounds are replaced for reduced-motion users and large administrative lists. `Fit`, `Position`, `Tint`, `Opacity` and `Motion` control how the background is displayed.

## Administration

Open `/tagadmin`, select an online player and choose a style. The label, subtitle, emoji and duration can be customized before delivery.

Existing assignments can be edited or removed while the owner is online or offline. Administrative actions are validated on the server, and an audit table is included for grants, edits, removals and expirations.

## License

MIT © 2026 Jaramiyo
