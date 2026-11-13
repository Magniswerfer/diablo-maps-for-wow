# Diablo Map for World of Warcraft

A World of Warcraft addon that draws a see-through map in the middle of the
screen, centered on your character, like the automap in Diablo. It does nothing else.

It has two modes:

- **Detail** (default) enlarges the game's own minimap into the overlay. That is
  the most detailed map WoW has: real terrain, buildings, paths, quest areas,
  party members and gathering nodes, and it also works inside dungeons and caves.
  Your minimap moves back to its corner when you close the overlay.
- **Zone** draws the zone map's painted art instead, with fog over unexplored areas.

`/dmap mode detail` or `/dmap mode zone` switches between them. In zone mode:

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

Press **Alt-M** to show or hide the overlay. The addon sets that key the first
time you log in on a character, if Alt-M is not already in use. You can change it
under **Options → Keybindings → AddOns → Diablo Map**, where there are also zoom
in and zoom out bindings.

| Command | What it does |
| --- | --- |
| `/dmap` | Show or hide the overlay |
| `/dmap mode detail` | `detail` (enlarged minimap) or `zone` (zone map art) |
| `/dmap alpha 0.6` | Opacity, 0 to 1 |
| `/dmap zoom 1.5` | Map scale: 0 to 5 in detail mode, 0.4 to 8 in zone mode |
| `/dmap size 0.8` | How much of the screen the overlay may cover, 0.2 to 1 |
| `/dmap fog 0.35` | Zone mode: brightness of unexplored areas; 0 hides them |
| `/dmap style gold` | Zone mode: colors `color`, `gray` or `gold` |
| `/dmap group` | Zone mode: show or hide party and raid members |
| `/dmap reset` | Restore the defaults |
| `/dmap help` | List the commands and current values |

In zone mode, inside dungeons and raids the game does not tell addons where you
are, so the map is shown centered without the arrow there. Detail mode does not
have this problem.

Detail mode keeps your minimap's shape (round by default). Minimap addons that
also move or resize the minimap may fight with it; use zone mode if that happens.
