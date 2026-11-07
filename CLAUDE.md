# AmmoBuddy – notes for Claude

## Git
- Before the first commit in a session, set the commit identity:
  ```
  git config user.name "Patrick Sonderegger"
  git config user.email "patrick@psonderegger.at"
  ```
- Work on the `Dev` branch. `Main` is the default branch; only merge or push to it when Patrick asks.
- Write commit messages in English.

## Project
- Lightweight WoW addon for Hunters. Target: **WoW Forever** (interface `16001`), also Classic Era / TBC.
- WoW Forever uses Midnight's addon restrictions: values can be "secret" during combat. Never compare or do arithmetic on them (check with `issecretvalue`).
- No external libraries. Keep it small.
- All code, comments, in-game text and docs are in English. Keep `README.md` (also used as the CurseForge description) and `CHANGELOG.md` up to date with every user-facing change.
- Addon files live in `AmmoBuddy/`. Load order is in `AmmoBuddy/AmmoBuddy.toc`.
