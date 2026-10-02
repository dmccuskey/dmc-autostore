# Development

How dmc-autostore is built and tested, and what could change.

## Where the Code Lives

Only `dmc_corona/dmc_autostore.lua` is written in this repository, along with the example apps' own files (`main.lua`, `component/`, the plugin). The rest of `dmc_corona/`, `dmc_corona_boot.lua`, and each example's copy of them are generated: they are copied from the repositories that own them by the build below. Fix a generated file in its own repository, then rebuild:

| file | owner |
|---|---|
| `dmc_files.lua` | [dmc-files](https://github.com/dmccuskey/dmc-files) |
| `dmc_objects.lua` | [dmc-objects](https://github.com/dmccuskey/dmc-objects) |
| `dmc_states_mix.lua` | [dmc-states-mixin](https://github.com/dmccuskey/dmc-states-mixin) |
| `dmc_utils.lua` (examples only) | [dmc-utils](https://github.com/dmccuskey/dmc-utils) |
| `dmc_corona_boot.lua` | [dmc-corona-boot](https://github.com/dmccuskey/dmc-corona-boot) |
| `lib/dmc_lua/` | [DMC-Lua-Library](https://github.com/dmccuskey/DMC-Lua-Library) |

The `dmc_corona.cfg` files, at the root and in each example, aren't generated: edit them here.

## Building

The `Snakefile` lists this library's files, the libraries it requires, and the example apps. The build rules are in [DMC-Corona-Library](https://github.com/dmccuskey/DMC-Corona-Library) (`snakemake/Snakefile`), which expects every required repository checked out next to this one. From this repository:

```sh
snakemake --cores 1 build_all     # dmc_corona/ and every examples/*/dmc_corona/
snakemake --cores 1 -n build_all  # dry run: show what would be copied
```

The build copies the sibling checkouts as they are on disk, on whatever branch each one has checked out.

## Testing

The tests are in `tests/dmc_autostore_spec.lua` ([lunatest](https://github.com/silentbicycle/lunatest)). Run them with plain Lua 5.1, with stand-ins for the Solar2D globals they touch (`system.pathForFile()`, `timer`, `Runtime`); the data files go in a temporary folder. It needs the `dkjson` and `luafilesystem` rocks:

```sh
tests/run_unit.sh                  # uses ../tools/lua51/bin/lua
LUA=lua5.1 tests/run_unit.sh       # or another Lua 5.1
```

The tests run the timers by hand and send system events, and reload the module to check what a relaunch reads back.

Then run both examples in the Solar2D Simulator: place, drag and recolor UFOs, relaunch, and check they come back. The data file is in the project sandbox (**File > Show Project Sandbox**, then `Documents/`); in DMC-autostore-plugins it is base64. To check saving on suspend, use **Hardware > Suspend** (Cmd+Down), or send the event from the app:

```lua
Runtime:dispatchEvent{ name='system', type='applicationSuspend' }
```

## Possible Future Changes

Each needs discussion and a concrete use case before it is worked on. They are also [GitHub issues](https://github.com/dmccuskey/dmc-autostore/issues).

- Keys named like the table methods: let the data win, or keep the methods somewhere a key can't reach ([#1](https://github.com/dmccuskey/dmc-autostore/issues/1)).
- Changes made through a table you stored, rather than through its stand-in, don't schedule a save ([#2](https://github.com/dmccuskey/dmc-autostore/issues/2)).
