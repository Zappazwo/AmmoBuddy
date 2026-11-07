# AmmoBuddy

**Never run dry mid-pull again.** AmmoBuddy is a tiny, no-nonsense ammo tracker for Hunters. It shows how many arrows or bullets you have left and warns you *before* you run out, not after.

Built for **WoW Forever**, and it also runs on **Classic Era / Anniversary / TBC**.

## Features

- **Live ammo counter**: a small, movable frame with your ammo icon and the total count in your bags.
- **Color-coded at a glance**: green when you're stocked, yellow when you're running low, red when you're empty.
- **Low-ammo alert**: a raid-warning message and sound when you drop below your threshold (default: 200). It fires once and resets after you restock.
- **Ammo tooltip**: hover over the frame to see the tooltip of your equipped ammo.
- **Clean main window**: a modern, dark window with **Ammo**, **Bags** and **Settings** tabs. Open it with `/ammo`, the minimap button, or a right-click on the ammo counter.
- **Minimap button**: drag it anywhere around the minimap, or turn it off completely.
- **Lightweight**: no libraries, no CPU or memory overhead worth mentioning.
- **Combat-safe**: respects WoW Forever's addon restrictions. If a value is protected during combat, AmmoBuddy just shows it and checks again when combat ends.
- **Hunter-only**: it stays completely inactive on your other characters.

## Settings

All settings live in the **Settings** tab of the main window.

| Option | Description |
|---|---|
| Show ammo counter | Show or hide the ammo counter |
| Lock ammo counter | Lock the counter in place; unlock it to drag it around |
| Show minimap button | Show or hide the minimap button |
| Low-ammo warning at | The ammo count that triggers the warning (default: 200) |
| Reset counter position | Move the counter back to its default position |

The *Hide from minimap* button at the bottom of the sidebar toggles the minimap button too.

## Slash Commands

| Command | Description |
|---|---|
| `/ammo` | Open the main window |
| `/ammo help` | List all commands |
| `/ammo unlock` / `/ammo lock` | Unlock or lock the ammo counter |
| `/ammo warn <amount>` | Set the low-ammo threshold, e.g. `/ammo warn 300` |
| `/ammo show` / `/ammo hide` | Show or hide the ammo counter |
| `/ammo minimap` | Toggle the minimap button |
| `/ammo reset` | Reset the ammo counter position |

`/ammobuddy` works as an alias for `/ammo`.

## Installation

1. Download the latest release.
2. Extract the `AmmoBuddy` folder into `World of Warcraft/_forever_/Interface/AddOns/`
   (Classic: `_classic_era_`, `_anniversary_` or `_classic_`).
3. Restart the game or type `/reload`.

## FAQ

**The addon shows as "out of date".**
Check the client's interface version in-game with `/dump select(4, GetBuildInfo())`. Until an update is out, you can tick *Load out of date AddOns* in the AddOns menu.

**The counter shows 0 even though I have ammo.**
Make sure the ammo is equipped in your ammo slot (right-click it in your bags).

**Does it work for Warriors or Rogues?**
Not right now. AmmoBuddy only loads for Hunters.

## Feedback & Bug Reports

Found a bug or have an idea? Please open an issue on GitHub. Include your game version and a short description of what happened.
