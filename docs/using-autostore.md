# Using AutoStore

How AutoStore saves your data, and how to write an app around it. The [Quick Start](../README.md#quick-start) shows the basics in 10 minutes; the [API reference](api.md) lists every property, method and setting.

## How It Works

When the module is first required, AutoStore reads its data file (`dmc_autostore.json` in `system.DocumentsDirectory`), decodes the JSON, and wraps it: `AutoStore.data` is a stand-in for the top of your data, and every table inside it gets a stand-in too. A stand-in has no contents of its own. Lua asks it for every read and every assignment, and it passes them on to the real table, so AutoStore sees each change.

A change doesn't write the file right away: it starts two timers.

- `TIMER_MIN` (1000 ms): restarted by every change. When the changes stop for this long, the data is saved.
- `TIMER_MAX` (4000 ms): started by the first change after a save, and not restarted. It saves the data even while changes keep coming, for example while the player drags something.

Whichever fires first saves the whole data table as JSON and stops the other. A burst of changes (a loop that updates 100 values, a drag that updates `x` and `y` every frame) is one write.

Why this design: one file, because apps rarely need more and one file keeps the API empty; JSON, because it holds any structure an app needs, where a key/value store gets unwieldy; and a table that watches itself, so no code ever has to remember to save.

## First Launch

On the first launch there is no data file: `AutoStore.data` is an empty table and `AutoStore.is_new_file` is `true`. The file is only created when the data first changes.

Set up the structure of your data first, before the rest of the app uses it:

```lua
local AutoStore = require 'dmc_corona.dmc_autostore'

local function initializeAutoStore()
	if not AutoStore.is_new_file then return end

	local data = AutoStore.data

	-- a container for each part of the app
	data.ufos = {}
	data.user = {}

	-- the format of this data, in case it changes in a later version of the app
	data.app_info = { data_version='1.0' }
end

initializeAutoStore()
```

`is_new_file` is also `true` when the file exists but can't be read or decoded (see [Known Issues](api.md#known-issues)). It becomes `false` after the first save.

A version number in the data, like `data_version` above, lets a later version of your app see which format it has loaded and convert it.

## Working with the Data

Read and assign as with any Lua table, at any depth:

```lua
AutoStore.data.app_info.data_version = '1.5'

local user = AutoStore.data.user   -- a branch of the data
user.name = 'Ann'                   -- saved, like any other change
user.scores = { 10, 20 }            -- tables are wrapped when stored
user.name = nil                     -- removing a key is a change too
```

Lua 5.1, which Solar2D uses, has no way to make `#`, `pairs()`, `ipairs()` or the `table` library see through a stand-in: on a table from AutoStore they see an empty table. Use the table's methods instead:

| instead of | use |
|---|---|
| `for k, v in pairs( t )` | `for k, v in t:pairs()` |
| `for i, v in ipairs( t )` | `for i, v in t:ipairs()` |
| `#t` | `t:len()` |
| `table.insert( t, v )`, `table.insert( t, pos, v )` | `t:insert( v )`, `t:insert( v, pos )` |
| `table.remove( t )`, `table.remove( t, pos )` | `t:remove()`, `t:remove( pos )` |
| a copy of `t` | `t:clone()`: a plain Lua table, deep copied, not watched |

For example:

```lua
local data = AutoStore.data
data.list = { 'bread', 'butter', 'jam' }

local list = data.list
list:insert( 'honey' )
list:remove( 1 )             -- returns 'bread'
for i, v in list:ipairs() do
	print( i, v )            -- 1 butter, 2 jam, 3 honey
end
print( list:len() )          -- 3
```

Because these names are methods, don't use `pairs`, `ipairs`, `len`, `insert`, `remove` or `clone` as keys in your data: `t.insert` returns the method, not your value.

## Store a Table, Then Use the Stored One

When you store a table, AutoStore keeps it and gives you a stand-in for it when you read it back. The table you stored is not the stand-in:

```lua
local ufos = AutoStore.data.ufos

local ufo = { x=160, y=240, temperature='cool' }
ufos['1'] = ufo

ufo.x = 100          -- in the data, but no save is scheduled
ufo = ufos['1']      -- get the stand-in
ufo.x = 100          -- saved
```

Your data is safe either way: the stored table *is* the data, so a change through it is in the data and goes into the file with the next save. What it misses is the timer: AutoStore doesn't see the change, so it doesn't schedule a save, and if nothing else changes, the file isn't updated. So after storing a table, read it back and use that.

To put the same data under a second key, store a copy: `data.backup = data.settings:clone()`. Assigning one stored table to another key (`data.backup = data.settings`) breaks both ([Known Issues](api.md#known-issues)).

## Objects with Their Own Branch

A stand-in behaves like the table it stands for, wherever it goes. Give each object in your app its own branch of the data: the object reads and writes its part, and AutoStore saves it. The object doesn't need to know about AutoStore.

`main.lua` creates each object with its branch:

```lua
local AutoStore = require 'dmc_corona.dmc_autostore'
local UFO = require 'ufo'

-- a new UFO: store its data, then pass the stored branch to the object
local function createNewUFO( x, y )
	local ufos = AutoStore.data.ufos
	local id = tostring( system.getTimer() )
	ufos[ id ] = { x=x, y=y, temperature='cool' }
	return UFO.new( id, ufos[ id ] )
end

-- on launch: recreate the UFOs from the saved data
for id, ufo_data in AutoStore.data.ufos:pairs() do
	UFO.new( id, ufo_data )
end
```

and the object keeps its branch and changes it:

```lua
-- ufo.lua
local UFO = {}

function UFO.new( id, data )
	local ufo = { id=id, _data=data }
	-- ... create the display objects at data.x, data.y ...
	function ufo:heatUp()
		self._data.temperature = 'hot'   -- saved
	end
	return ufo
end

return UFO
```

To remove an object's data, set its key to `nil`: `AutoStore.data.ufos[ id ] = nil`.

The [examples](../examples/) are complete apps built this way, with [dmc-objects](https://github.com/dmccuskey/dmc-objects) classes; AutoStore doesn't need them.

## What Can Be Stored

The data is saved as JSON, so store only what JSON can hold: strings, numbers, booleans and tables of them. Anything else, such as a function or a display object, is saved as a string like `<type 'function' is not supported by JSON.>`, and comes back as that string.

JSON has two kinds of table, lists and maps, and each Lua table is saved as one of them. Keep each of your tables clearly one or the other:

- **A list**: keys `1`, `2`, `3`, ... with no gaps. Use `t:insert()` and `t:remove()` to keep it that way.
- **A map**: string keys.

Other tables are saved too, but their number keys may change type. A table with number keys that aren't a list (`[3]`, `[7]`, `[100]`, or `system.getTimer()` values such as `50.68`), or with both list entries and string keys, is saved as a map: after a relaunch, `t[7]` is `t['7']`. So use string keys from the start, as the example above does with `tostring( system.getTimer() )`: the key is then the same before and after a relaunch.

An empty table is saved as an empty list (`[]`) and comes back as an empty table.

Storing a table replaces its metatable, so store plain data, not objects with methods.

## When Data Is Saved

Changes reach the file `TIMER_MIN` after the last change, and at most `TIMER_MAX` after the first unsaved one. If the app is closed in that window, those changes are lost. AutoStore has no public "save now" method ([Known Issues](api.md#known-issues)). Shorter timers make the window smaller, at the cost of more frequent writes.

Change the timers, or the file's name, in `dmc_corona.cfg` ([Configuration](api.md#configuration)):

```ini
[DMC_AUTOSTORE]
TIMER_MIN:INT = 500
TIMER_MAX:INT = 2000
DATA_FILENAME = gamedata
```

## Events

AutoStore sends an event when a timer starts or stops, and when the data has been saved. Listen for `AutoStore.EVENT` and check `event.type`:

```lua
AutoStore:addEventListener( AutoStore.EVENT, function( event )
	if event.type == AutoStore.DATA_SAVED then
		print( 'saved' )
	elseif event.type == AutoStore.START_MIN_TIMER then
		print( 'saving in', event.time, 'ms' )
	end
end )
```

The event types are listed in the [API reference](api.md#events). The examples use them to draw the two timers as progress bars.

## Plugins

A plugin changes the file's contents on the way to and from the disk, for example to encode or encrypt it. It is a Lua module that returns a table with one or both of these functions:

- `preSaveFunction( json )`: receives the JSON string before it is written, returns the string to write.
- `postReadFunction( contents )`: receives the file's contents after they are read, returns the JSON string to decode.

Name the module in `dmc_corona.cfg`, as you would in `require()` (a dotted name, from the project root):

```ini
[DMC_AUTOSTORE]
PLUGIN_FILE = dmc_autostore_plugins
```

This plugin stores the file as base64. It is a shorter version of the one in the [DMC-autostore-plugins](../examples/DMC-autostore-plugins/) example:

```lua
-- dmc_autostore_plugins.lua
local mime = require 'mime'

local Plugins = {}

function Plugins.preSaveFunction( json )
	return ( mime.b64( json ) )
end

function Plugins.postReadFunction( contents )
	return ( mime.unb64( contents ) )
end

return Plugins
```

Add a plugin before the app is released, or convert existing files: a file that the plugin can't decode is treated as a new file, and the first save replaces it.
