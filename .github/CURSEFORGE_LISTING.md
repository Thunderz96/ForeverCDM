# CurseForge listing (paste-ready)

| Field | Value |
|---|---|
| **Name** | Forever Cooldown Manager |
| **URL slug** | `forever-cooldown-manager` |
| **Class** | Addons |
| **Main category** | Combat |
| **Additional categories** | Buffs & Debuffs, Action Bars |
| **License** | MIT License |
| **Source** | https://github.com/Thunderz96/ForeverCDM |
| **Issues** | https://github.com/Thunderz96/ForeverCDM/issues |
| **Logo** | `.github/logo.png` (1024 x 1024, original artwork) |
| **Game version** | WoW Forever 1.60.1 (set automatically by the packager from `## Interface: 16001`) |

## Summary

> Cooldown, utility and buff icon rows for WoW: Forever. Works today, while the built-in Cooldown Manager still has no spell data for Forever classes.

## Description

**Forever Cooldown Manager** puts your cooldowns and buffs on screen as clean rows of icons, on the WoW: Forever beta where Blizzard's own Cooldown Manager is still empty.

Blizzard lists the built-in Cooldown Manager as a work in progress for Forever, so it has no spells to show for most classes, and every addon that reskins it shows nothing either. This addon does not depend on it. It reads your spellbook and your own auras directly.

### What you get
- **Three icon rows:** Cooldowns, Utilities and Buffs. Put any spell in any row.
- **A settings window** (`/fcdm`): your whole spellbook in a list, one tick box per row, reorder with Up and Down, icon size and spacing, lock or unlock.
- **Drag to place.** Unlock, drag each row where you want it, lock again.
- **Charges and swipes** drawn the way the default UI draws them.
- **Buff timers that survive combat.** Buffs you cast yourself are followed by your own cast, so a seal or blessing applied mid-fight still gets a countdown.
- **No libraries, no dependencies.** Two Lua files.

### Works inside the rules
Forever uses the same addon restrictions as Midnight: combat values are hidden from addons. This addon is display only. It never casts, never picks a spell for you, and hands hidden timing values straight to Blizzard's cooldown widget instead of reading them. Nothing here will get flagged or break when restrictions tighten.

### Known limits on the beta
- **Settings reset on a full game restart.** That is a beta client bug affecting every addon: the client saves addon settings and never loads them back. Your setup survives `/reload`. A built-in workaround is planned for the next version.
- A buff someone else puts on you during combat cannot be confirmed until combat ends. The icon shows a "?" rather than guessing.

### Commands
`/fcdm` opens settings. `/fcdm help` lists the rest, including `add`, `addbuff`, `addutility`, `remove`, `auto`, `lock`, `unlock`, `size`, `spacing`, `reset`.

Findings about the Forever client that shaped this addon are public at https://github.com/Thunderz96/forever-addon-kit
