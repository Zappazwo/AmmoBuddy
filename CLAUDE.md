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
- No embedded libraries. QuestieDB is the only (required) dependency. Keep it small.
- All code, comments, in-game text and docs are in English. Keep `README.md` (also used as the CurseForge description) and `CHANGELOG.md` up to date with every user-facing change.
- In-game texts go through `ns.L["English text"]` (`AmmoBuddy/Locales.lua`): add every new text to the deDE, esES and frFR tables. Item, zone and standing names come from the game API, NPC and quest names from QuestieDB.
- Addon files live in `AmmoBuddy/`. Load order is in `AmmoBuddy/AmmoBuddy.toc`.

## Data and tests
- **QuestieDB is a hard dependency** (`## Dependencies: QuestieDB`). `Database.lua` reads vendors, spawns, quests and drops through `LibQuestieDB` (`ItemDB`/`NpcDB`/`QuestDB`, see QuestieDB `docs/api.md`) at load time and builds `ns.Data.vendors` and each item's `sources`. Without QuestieDB only craft/rep sources exist.
- `AmmoBuddy/Data.lua` holds only item stats (cmangos classic-db) and is generated, never edit it by hand. The item list still comes from a QuestieDB checkout. Regenerate:
  ```
  python3 -I tools/data/extract.py <QuestieDB checkout> <cmangos ClassicDB .sql.gz> raw.json
  python3 -I tools/data/gen_data.py raw.json AmmoBuddy/Data.lua
  python3 -I tools/test/gen_questiedb_mock.py raw.json tools/test/questiedb_mock.lua
  ```
  The parsers only read literals; never execute downloaded Lua.
- Smoke tests with a mocked WoW API and LibQuestieDB (needs `pip install lupa`): `python3 tools/test/run_tests.py AmmoBuddy tools/test/harness.lua [locale]`; `NO_QUESTIEDB=1` tests the fallback without QuestieDB.

## Releases
- Bump `## Version` in `AmmoBuddy/AmmoBuddy.toc` and add a `## <version>` section to `CHANGELOG.md`.
- After merging to `Main`, start the Release workflow on `Main` (Actions -> Release -> Run workflow; it creates the tag `v<version>`), or push that tag yourself. `.github/workflows/release.yml` checks the tag against the TOC, zips only `AmmoBuddy/` and publishes a GitHub release with the changelog section as notes.
