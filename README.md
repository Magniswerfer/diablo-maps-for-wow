# Diablo Map for World of Warcraft

A World of Warcraft addon that draws the zone map as a see-through overlay in the
middle of the screen, centered on your character, like the automap in Diablo.
It does nothing else.

- The map moves with you. Your arrow stays in the middle and turns with you.
- You can click straight through it, and it sits behind the rest of the UI.
- Areas you have explored are drawn bright. Unexplored areas are dimmed, or hidden
  if you set `/dmap fog 0`.
- Party and raid members show as dots in their class colors.
- It hides itself while the world map is open.

## Install

1. Download this repository (Code → Download ZIP) or the `DiabloMap.zip` from a release.
2. Copy the `DiabloMap` folder into your addons folder, for example
   `World of Warcraft/_retail_/Interface/AddOns/DiabloMap`
   (use `_classic_` or `_classic_era_` for the Classic versions).
3. Restart the game, or type `/reload`.

If the addon shows as out of date after a patch, tick **Load out of date AddOns**
on the character select AddOns screen.

## Use

Bind a key under **Options → Keybindings → AddOns → Diablo Map** (Tab, like
Diablo, works well). There are also zoom in and zoom out bindings.

| Command | What it does |
| --- | --- |
| `/dmap` | Show or hide the overlay |
| `/dmap alpha 0.6` | Opacity, 0 to 1 |
| `/dmap zoom 1.5` | Map scale, 0.4 to 8 |
| `/dmap size 0.8` | How much of the screen the overlay may cover, 0.2 to 1 |
| `/dmap fog 0.35` | Brightness of unexplored areas; 0 hides them |
| `/dmap style gold` | Colors: `color`, `gray` or `gold` |
| `/dmap group` | Show or hide party and raid members |
| `/dmap reset` | Restore the defaults |
| `/dmap help` | List the commands and current values |

Inside dungeons and raids the game does not tell addons where you are, so the
map is shown centered without the arrow there.
