# dmc-autostore

Automatic JSON storage for Solar2D (formerly Corona SDK): change your app's data and it is saved, with no save calls.

AutoStore gives your app one Lua table. Anything you put in it, at any depth, is written to a JSON file a moment after it changes, and is there again the next time the app starts:

```lua
local AutoStore = require 'dmc_corona.dmc_autostore'

local data = AutoStore.data

data.player = { name='Ann', level=1 }
data.player.level = 2    -- saved; no save() call anywhere
```

## Features

- No API for saving: assign to the table and the change is saved
- Works at any depth: every nested table watches for changes
- Pass a branch of the data to an object, and it reads and writes its own part of the data
- One JSON file in the app's Documents folder, loaded when the app starts
- Batched writes: many changes in a row are saved together, after a short pause (1 s by default, at most 4 s)
- `is_new_file` tells your app it is on its first launch, so it can set up the data
- Events when a save is scheduled and when it is done
- Plugins can transform the file on save and on load, for example to encode it
- Pure Lua, no plugins needed; MIT licensed

## Quick Start

This stores a launch counter and the dots you tap, and shows them again after a relaunch, in about 10 minutes, in the Solar2D Simulator on macOS or Windows.

Prerequisites: the [Solar2D](https://solar2d.com/) Simulator and a copy of this repository (`git clone https://github.com/dmccuskey/dmc-autostore.git`, or download the ZIP from GitHub).

### 1. Copy the Library into Your Project

Copy these from this repository into the root of your project folder:

```text
dmc_corona_boot.lua     loader for the DMC libraries
dmc_corona.cfg          configuration
dmc_corona/             dmc-autostore and the libraries it uses
```

**Going further:** keep the libraries in a subfolder, or combine several DMC libraries ([dmc-corona-boot Configuration](https://github.com/dmccuskey/dmc-corona-boot/blob/master/docs/configuration.md)).

### 2. Count the Launches

Create `main.lua` in the project folder:

```lua
local AutoStore = require 'dmc_corona.dmc_autostore'

local data = AutoStore.data

-- first launch: there is no data file yet
if AutoStore.is_new_file then
	data.launches = 0
	data.dots = {}
end

data.launches = data.launches + 1
print( 'launch', data.launches )
```

Open the project in the Simulator. The console shows:

```text
launch	1
```

A second later AutoStore writes the data file. Relaunch the app (**File > Relaunch**, or Cmd+R / Ctrl+R): the console shows `launch	2`. The count was saved without a save call.

If the console shows `module 'dmc_corona.dmc_autostore' not found` instead, `dmc_corona/` is missing from the root of the project folder. `The module 'lib.dmc_lua.lua_error' not found` means `dmc_corona.cfg` is missing there.

**Going further:** the file is `Documents/dmc_autostore.json` in the project sandbox (**File > Show Project Sandbox**). To start again from a first launch, delete it, or use **File > Clear Project Sandbox**.

### 3. Save What You Tap

Add this to the end of `main.lua`:

```lua
local function drawDot( dot )
	local circle = display.newCircle( dot.x, dot.y, 30 )
	circle:setFillColor( 0.2, 0.5, 0.9 )
end

-- draw the dots saved by earlier launches
for i, dot in data.dots:ipairs() do
	drawDot( dot )
end

-- tap to add a dot
Runtime:addEventListener( 'tap', function( event )
	local dot = { x=event.x, y=event.y }
	data.dots:insert( dot )
	drawDot( dot )
end )

AutoStore:addEventListener( AutoStore.EVENT, function( event )
	if event.type == AutoStore.DATA_SAVED then
		print( 'saved', data.dots:len(), 'dots' )
	end
end )
```

The Simulator restarts the app when the file is saved. Tap the screen a few times: a dot appears at each tap, and a second after the last one the console shows `saved	4	dots` (for four taps). Relaunch the app: the dots are drawn again where you left them.

<img src="docs/images/quick-start-dots.png" width="160" alt="Four blue dots, redrawn from the saved data after a relaunch">

`data.dots` is a list, and the loop uses `data.dots:ipairs()`, `insert()` and `len()` instead of Lua's `ipairs()`, `table.insert()` and `#`. Lua's own functions see an empty table here, because AutoStore stands between your code and the data to watch for changes ([Working with the Data](docs/using-autostore.md#working-with-the-data)).

**Going further:** give each object in your app its own branch of the data ([Using AutoStore](docs/using-autostore.md)), or see complete apps in [examples](examples/).

To update, copy `dmc_corona_boot.lua` and `dmc_corona/` again from the newer version. Keep your own `dmc_corona.cfg` if you have changed it.

## Documentation

- [Using AutoStore](docs/using-autostore.md): how saving works, first launch, the table methods, objects with their own branch, what can be stored, events, plugins
- [API reference](docs/api.md): the `AutoStore` module, the table methods, events, configuration, known issues
- [Examples](examples/): two apps with UFOs you can place, drag and recolor, one with a plugin that encodes the file

Everything else is listed on the [documentation home](docs/README.md).

## License

dmc-autostore is released under the [MIT License](LICENSE).
