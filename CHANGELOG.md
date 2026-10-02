# Changelog

## 2.2.0 (2026-10-01)

### Fixed

- The module loads with the current dmc-objects: `__init__()` and `__initComplete__()` call their superclass.
- Assigning a stored table to another key (`data.b = data.a`), or inserting it into a list, stores a copy of it. Before, both keys broke: `data.a` read as empty and `data.b` was saved as `[]`.
- A table added through a stored table (not through its stand-in) is wrapped when it is read, instead of raising `attempt to index a nil value`. `t:pairs()` returns the values themselves, also for keys named like the table methods.
- A data file that can't be read or decoded is moved aside to `dmc_autostore.bad.json`, with a warning, instead of being overwritten by the next save.
- An error while saving (for example from a plugin's `preSaveFunction()`) is printed and the changes stay unsaved, for the next save, instead of raising an error from the timer.
- `DEBUG_ACTIVE` in `dmc_corona.cfg` turns on debug output, from the start: what was loaded, each save.
- The module no longer sets the globals `_extend` and `p`; it uses lua_utils from DMC-Lua-Library instead of its own copy of `Utils.extend()`, and no longer sets lua-error's globals `try`, `catch` and `finally`.

### Added

- `AutoStore:save()`, to write unsaved changes at once.
- Unsaved changes are saved when the app is suspended or quits (the `applicationSuspend` and `applicationExit` system events).
- `AutoStore.VERSION`.
- Unit tests (stand-in system, timer and Runtime), and `tests/run_unit.sh` to run them with plain Lua 5.1.

### Changed

- Removed the unused `AutoStore.CONFIG_FILE`.
- Rebuilt against the current dmc-corona-boot, DMC-Lua-Library, dmc-files and dmc-objects.
