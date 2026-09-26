# API Reference

Everything dmc-autostore provides. [Using AutoStore](using-autostore.md) explains how to use it.

## Quick Reference

| Name | In short |
|---|---|
| [`AutoStore.data`](#autostoredata) | the top of your data; changes to it are saved |
| [`AutoStore.is_new_file`](#autostoreis_new_file) | `true` until there is a data file |
| [`t:pairs()`](#tpairs), [`t:ipairs()`](#tipairs) | iterate over a table in the data |
| [`t:len()`](#tlen) | the length of a list |
| [`t:insert()`](#tinsert-value--pos-), [`t:remove()`](#tremove-pos-) | add to or remove from a list |
| [`t:clone()`](#tclone) | a plain, unwatched deep copy |
| [Events](#events) | `AutoStore.EVENT`: timers started and stopped, data saved |
| [Configuration](#configuration) | `TIMER_MIN`, `TIMER_MAX`, `DATA_FILENAME`, `PLUGIN_FILE` |

## The Module

```lua
local AutoStore = require 'dmc_corona.dmc_autostore'
```

The module is the AutoStore object itself, created when it is first required. At that point it reads the configuration, loads the plugin file if one is set, and loads the data file. The data is saved in `system.DocumentsDirectory`, as `dmc_autostore.json` unless `DATA_FILENAME` says otherwise.

### AutoStore.data

The top of your data, a table. Read and change it, and anything in it, like any Lua table; every change is saved.

```lua
local data = AutoStore.data
data.score = 10
```

Tables read from `data` are stand-ins which watch for changes: use their methods, below, instead of `#`, `pairs()`, `ipairs()` and the `table` library.

### AutoStore.is_new_file

`true` if there was no data file to load (the first launch), or it couldn't be read or decoded; `false` once there is one. Becomes `false` after the first save.

```lua
if AutoStore.is_new_file then
	AutoStore.data.settings = { sound=true }
end
```

## Table Methods

Every table in the data (including `AutoStore.data`) has these methods.

### t:pairs()

Iterates over all keys and values, like `pairs( t )`. Table values are returned as stand-ins, so they can be changed.

```lua
for k, v in AutoStore.data.person:pairs() do print( k, v ) end
```

### t:ipairs()

Iterates over a list from `1` up to the first missing index, like `ipairs( t )`.

```lua
for i, v in AutoStore.data.list:ipairs() do print( i, v ) end
```

### t:len()

The length of a list, like `#t`.

### t:insert( value [, pos] )

Inserts `value` into a list at position `pos`, moving the later values up, like `table.insert()`. Without `pos`, appends to the end. Saved.

### t:remove( [pos] )

Removes the value at position `pos` from a list and returns it, moving the later values down, like `table.remove()`. Without `pos`, removes the last value. Saved.

### t:clone()

Returns a deep copy of the table as plain Lua tables. The copy isn't watched: changes to it aren't saved, until you store it somewhere in the data.

```lua
AutoStore.data.backup = AutoStore.data.settings:clone()
```

## Events

AutoStore dispatches its events with the name `AutoStore.EVENT` (`'autostore_event'`). Listen with `AutoStore:addEventListener( AutoStore.EVENT, listener )`; `event.type` is one of:

| `event.type` | When | Also in the event |
|---|---|---|
| `AutoStore.START_MIN_TIMER` | a change (re)started the `TIMER_MIN` timer | `event.time`: `TIMER_MIN`, in ms |
| `AutoStore.STOP_MIN_TIMER` | that timer was stopped, by a new change or a save | |
| `AutoStore.START_MAX_TIMER` | the first change after a save started the `TIMER_MAX` timer | `event.time`: `TIMER_MAX`, in ms |
| `AutoStore.STOP_MAX_TIMER` | that timer was stopped, by a save | |
| `AutoStore.DATA_SAVED` | the data file was written | |

## Configuration

dmc-autostore reads the `[DMC_AUTOSTORE]` section of `dmc_corona.cfg` when it is first required. Every setting is optional. The file's format, and the `[DMC_CORONA]` section every DMC library uses, are described in [dmc-corona-boot's Configuration](https://github.com/dmccuskey/dmc-corona-boot/blob/master/docs/configuration.md).

| Setting | Type | Default | Effect |
|---|---|---|---|
| `TIMER_MIN` | `INT` | `1000` | Milliseconds after the last change when the data is saved. Each change restarts this timer. Must be `0` or more. |
| `TIMER_MAX` | `INT` | `4000` | Milliseconds after the first unsaved change when the data is saved at the latest, even while changes keep coming. Must be greater than `TIMER_MIN`. |
| `DATA_FILENAME` | string | `dmc_autostore` | The data file's name in `system.DocumentsDirectory`; `.json` is added. |
| `PLUGIN_FILE` | string | none | A module to `require` (a dotted name, from the project root) that returns a table with `preSaveFunction( json )` and/or `postReadFunction( contents )`. Each receives a string and returns a string ([Plugins](using-autostore.md#plugins)). |

```ini
[DMC_AUTOSTORE]
TIMER_MIN:INT = 1000
TIMER_MAX:INT = 4000
DATA_FILENAME = gamedata
PLUGIN_FILE = dmc_autostore_plugins
```

If the timer values are wrong (not numbers, `TIMER_MIN` below 0, or not less than `TIMER_MAX`), requiring the module stops with an error such as `AutoStore: TIMER MIN > TIMER MAX`.

## Known Issues

- **No "save now".** Changes are written only when a timer fires, so changes made less than `TIMER_MIN` before the app is closed (at most `TIMER_MAX`) are lost. There is no public method to save at once, for example on an `applicationSuspend` or `applicationExit` system event.
- **Assigning a stored table to another key breaks it.** After `data.b = data.a`, `data.a` reads as empty (its values are still saved), and `data.b` is saved as `[]`. To copy, use `data.b = data.a:clone()`.
- **Keys named like the methods** (`pairs`, `ipairs`, `len`, `insert`, `remove`, `clone`, also `NAME`) return the method, not your value. Don't use them as keys.
- **Changes through a table you stored**, rather than through the stand-in read back from the data, don't schedule a save. The data is safe: they are in it, and go into the file with the next save ([Store a Table, Then Use the Stored One](using-autostore.md#store-a-table-then-use-the-stored-one)).
- **A file that can't be read or decoded is replaced.** A damaged file, or one written without the plugin that is now set (or with a different one), loads as a new file: `is_new_file` is `true`, the data is empty, and the next change overwrites the file.
- **No debug output.** `DEBUG_ACTIVE` in the `[DMC_AUTOSTORE]` section (in older copies of `dmc_corona.cfg`) is not read. `AutoStore.debug = true` has no visible effect either: its one message is printed while the module loads, before your code can set it.
- The module doesn't export its version. `AutoStore.CONFIG_FILE` (`'dmc_autostore.cfg'`) is a leftover and isn't used.
