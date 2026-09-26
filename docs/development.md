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

There are no automated tests. To check a change, run both examples in the Solar2D Simulator: place, drag and recolor UFOs, relaunch, and check they come back. The data file is in the project sandbox (**File > Show Project Sandbox**, then `Documents/`); in DMC-autostore-plugins it is base64.

## Possible Future Changes

Each needs discussion and a concrete use case before it is worked on.

- A public `save()` to write pending changes at once, and saving on `applicationSuspend` and `applicationExit`, so that no changes are lost when the app closes.
- Handle a stored table being assigned to another key (copy it, or report an error), instead of breaking it.
- Read `DEBUG_ACTIVE` from `dmc_corona.cfg`, drop the unused `CONFIG_FILE`, and export the version.
- Remove the accidental globals `_extend` (in the copied `Utils.extend()`) and `p` (in `TableProxy:insert()`).
- Tests that run in plain Lua, with stand-ins for `system` and `timer`, like dmc-sockets' `tests/run_unit.sh`.
