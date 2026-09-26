# dmc-autostore Documentation

New here? The [Quick Start](../README.md#quick-start) saves and restores an app's data in about 10 minutes.

## Start

- [Quick Start](../README.md#quick-start): copy the library in, count launches, save what you tap

## Use

- [Using AutoStore](using-autostore.md): how saving works, first launch, the table methods, objects with their own branch, what can be stored, when data is saved, events, plugins
- [API reference](api.md): `AutoStore.data`, `is_new_file`, the table methods, events, configuration, known issues
- [Examples](../examples/): two apps with UFOs you can place, drag and recolor, one with a plugin that encodes the file

## Contribute

- [Development](development.md): which files are generated, building, testing, possible future changes
- [Issues](https://github.com/dmccuskey/dmc-autostore/issues)

## Project Structure

```text
README.md                   landing page and Quick Start
LICENSE
docs/                       this documentation
└── images/                 screenshots for the README
dmc_corona/                 what apps copy
├── dmc_autostore.lua       AutoStore (source)
├── dmc_files.lua           }
├── dmc_objects.lua         } libraries AutoStore uses (generated copies)
├── dmc_states_mix.lua      }
└── lib/dmc_lua/            DMC Lua library (generated copy)
dmc_corona_boot.lua         loader, from dmc-corona-boot (generated copy)
dmc_corona.cfg              library configuration
examples/                   sample apps, each with its own generated dmc_corona/
└── screenshots/            one per app, for examples/README.md
Snakefile                   build rules for the generated copies
```
