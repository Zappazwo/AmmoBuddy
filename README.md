# AmmuBuddy

Schlankes WoW-Addon für Jäger (**WoW Forever**, Classic Era / Anniversary / TBC): zeigt die Anzahl der
ausgerüsteten Munition in einem kleinen, verschiebbaren Fenster und warnt, wenn sie knapp wird.

- Grün = genug, Gelb = unter der Warnschwelle, Rot = leer
- Raidwarnung + Sound beim Unterschreiten der Schwelle (Standard: 200)
- Tooltip der Munition beim Mouseover

## Installation
Den Ordner `AmmuBuddy` nach `World of Warcraft/_forever_/Interface/AddOns/` kopieren
(bei Classic: `_classic_era_` / `_anniversary_` / `_classic_`).

Interface-Version für WoW Forever: `16001`. Im Spiel prüfen mit
`/dump select(4, GetBuildInfo())` – weicht die Zahl ab, in `AmmuBuddy.toc` anpassen.

## Befehle
| Befehl | Wirkung |
|---|---|
| `/ammo lock` / `/ammo unlock` | Fenster sperren / verschiebbar machen |
| `/ammo warn 300` | Warnschwelle setzen |
| `/ammo reset` | Position zurücksetzen |
| `/ammo show` / `/ammo hide` | Fenster ein-/ausblenden |
