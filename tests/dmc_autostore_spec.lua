--====================================================================--
-- tests/dmc_autostore_spec.lua
--
-- unit tests for dmc_autostore, with a stand-in timer and Runtime
-- run with tests/run_unit.sh
--====================================================================--


module( ..., package.seeall )


--====================================================================--
--== Setup

local json = require 'json'

-- dmc_objects makes a group for its ComponentBase class at load
_G.display = { newGroup=function() return {} end }

-- timers: started by performWithDelay(), run by fire()
local timers
_G.timer = {
	performWithDelay=function( ms, f )
		local t = { ms=ms, f=f }
		timers[#timers+1] = t
		return t
	end,
	cancel=function( t ) t.cancelled = true end,
}

local function pending()
	local list = {}
	for _, t in ipairs( timers ) do
		if not t.cancelled and not t.fired then list[#list+1] = t end
	end
	return list
end

-- run the pending timer with this delay
local function fire( ms )
	for _, t in ipairs( pending() ) do
		if t.ms==ms then t.fired = true ; t.f() ; return end
	end
	error( 'no pending timer of ' .. ms .. ' ms' )
end

local system_listeners
_G.Runtime = {
	addEventListener=function( self, name, f )
		if name=='system' then system_listeners[#system_listeners+1] = f end
	end,
}

local function systemEvent( kind )
	for _, f in ipairs( system_listeners ) do f{ name='system', type=kind } end
end

local function docPath( name ) return os.getenv( 'AUTOSTORE_DOCS' ) .. '/' .. name end
local DATA_FILE = docPath( 'dmc_autostore.json' )
local BAD_FILE = docPath( 'dmc_autostore.bad.json' )

local function readFile( path )
	local fh = io.open( path, 'r' )
	if not fh then return nil end
	local s = fh:read( '*all' ) ; fh:close()
	return s
end

local function writeFile( path, s )
	local fh = assert( io.open( path, 'w' ) ) ; fh:write( s ) ; fh:close()
end

-- a plugin which stores the JSON reversed
package.preload['reverse_plugin'] = function()
	return {
		preSaveFunction=function( s ) return s:reverse() end,
		postReadFunction=function( s ) return s:reverse() end,
	}
end

-- the boot and dmc_objects set their own globals; snapshot after them
pcall( function() require( 'dmc_corona_boot' ) end )
require 'dmc_objects'
require 'dmc_files'
local globals = {}
for k in pairs( _G ) do globals[k] = true end

local config = _G.__dmc_corona.dmc_autostore
local AutoStore, events, printed

-- (re)load the module, as at app launch
local function load()
	timers, system_listeners, events = {}, {}, {}
	package.loaded['dmc_corona.dmc_autostore'] = nil
	AutoStore = require 'dmc_corona.dmc_autostore'
	AutoStore:addEventListener( AutoStore.EVENT, function( e ) events[#events+1] = e.type end )
	return AutoStore
end

local real_print = print

function setup()
	os.remove( DATA_FILE ) ; os.remove( BAD_FILE )
	config.plugin_file, config.debug_active = nil, nil
	printed = {}
	_G.print = function( ... )
		local args = { ... }
		for i = 1, select( '#', ... ) do args[i] = tostring( args[i] ) end
		printed[#printed+1] = table.concat( args, ' ' )
	end
	load()
end

function teardown()
	_G.print = real_print
end

local function saved() return json.decode( readFile( DATA_FILE ) ) end


--====================================================================--
--== Tests

function test_loadSetsNoGlobals()
	for k in pairs( _G ) do
		assert_true( globals[k] or k=='dmc_autostore_spec', 'new global: ' .. tostring( k ) )
	end
	assert_equal( '2.2.0', AutoStore.VERSION )
	assert_nil( AutoStore.CONFIG_FILE )
end

function test_newFile()
	assert_true( AutoStore.is_new_file )
	assert_equal( 0, AutoStore.data:len() )
	assert_nil( readFile( DATA_FILE ) )
end

function test_readWriteAtDepth()
	local data = AutoStore.data
	data.a = { b={ c=1 } }
	assert_equal( 1, data.a.b.c )
	data.a.b.d = 2
	assert_equal( 2, data.a.b.d )
	assert_equal( 2, #pending() ) -- min and max timer
end

function test_minTimerSaves()
	AutoStore.data.x = 1
	assert_equal( 'start_min_timer start_max_timer', table.concat( events, ' ' ) )
	fire( 1000 )
	assert_equal( 1, saved().x )
	assert_equal( 0, #pending() )
	assert_equal( 'data_saved', events[#events] )
	assert_false( AutoStore.is_new_file )
end

function test_maxTimerSaves()
	AutoStore.data.x = 1
	fire( 4000 )
	assert_equal( 1, saved().x )
	assert_equal( 0, #pending() )
end

function test_saveNow()
	assert_true( AutoStore:save() ) -- nothing to save
	assert_nil( readFile( DATA_FILE ) )
	AutoStore.data.x = 1
	assert_true( AutoStore:save() )
	assert_equal( 1, saved().x )
	assert_equal( 0, #pending() )
end

function test_saveOnSuspendAndExit()
	AutoStore.data.x = 1
	systemEvent( 'applicationSuspend' )
	assert_equal( 1, saved().x )
	assert_equal( 0, #pending() )
	AutoStore.data.x = 2
	systemEvent( 'applicationResume' )
	assert_equal( 1, saved().x )
	systemEvent( 'applicationExit' )
	assert_equal( 2, saved().x )
end

function test_reload()
	local data = AutoStore.data
	data.name = 'Ann'
	data.scores = { 10, 20 }
	AutoStore:save()
	data = load().data
	assert_false( AutoStore.is_new_file )
	assert_equal( 'Ann', data.name )
	assert_equal( 20, data.scores[2] )
	assert_equal( 2, data.scores:len() )
end

function test_assignStoredTableCopies()
	local data = AutoStore.data
	data.a = { x=1, sub={ y=2 } }
	data.b = data.a
	assert_equal( 1, data.a.x ) ; assert_equal( 2, data.a.sub.y )
	assert_equal( 1, data.b.x ) ; assert_equal( 2, data.b.sub.y )
	data.b.x = 5
	assert_equal( 1, data.a.x )
	AutoStore:save()
	assert_equal( 1, saved().a.x )
	assert_equal( 5, saved().b.x )
	assert_equal( 2, saved().b.sub.y )
end

function test_assignToItsOwnKeyKeepsTable()
	local data = AutoStore.data
	data.a = { x=1 }
	local a = data.a
	data.a = a
	a.x = 2
	assert_equal( 2, data.a.x )
end

function test_insertStoredTableCopies()
	local data = AutoStore.data
	data.a = { x=1 }
	data.list = {}
	data.list:insert( data.a )
	assert_equal( 1, data.list[1].x )
	assert_equal( 1, data.a.x )
	AutoStore:save()
	assert_equal( 1, saved().list[1].x )
end

function test_tableAddedThroughStoredTable()
	local t = {}
	AutoStore.data.t = t
	t.child = { y=1 } -- not wrapped when added
	assert_equal( 1, AutoStore.data.t.child.y )
	local found
	for k, v in AutoStore.data.t:pairs() do found = v.y end
	assert_equal( 1, found )
end

function test_tableMethods()
	local list
	AutoStore.data.list = { 'a', 'b' }
	list = AutoStore.data.list
	list:insert( 'd' )
	list:insert( 'c', 3 )
	assert_equal( 4, list:len() )
	local seen = {}
	for i, v in list:ipairs() do seen[i] = v end
	assert_equal( 'a b c d', table.concat( seen, ' ' ) )
	assert_equal( 'd', list:remove() )
	assert_equal( 'a', list:remove( 1 ) )
	assert_equal( 2, list:len() )
	local copy = list:clone()
	assert_nil( getmetatable( copy ) )
	assert_equal( 'b', copy[1] )
	AutoStore.data.map = { k={ v=1 } }
	for k, v in AutoStore.data.map:pairs() do
		assert_equal( 'k', k ) ; assert_equal( 1, v.v )
	end
end

function test_damagedFileMovedAside()
	writeFile( DATA_FILE, 'not json' )
	load()
	assert_true( AutoStore.is_new_file )
	assert_equal( 'not json', readFile( BAD_FILE ) )
	assert_nil( readFile( DATA_FILE ) )
	assert_match( "can't read the data file", printed[#printed] )
	AutoStore.data.x = 1
	AutoStore:save()
	assert_equal( 'not json', readFile( BAD_FILE ) )
end

function test_plugin()
	config.plugin_file = 'reverse_plugin'
	load()
	AutoStore.data.x = 'abc'
	AutoStore:save()
	assert_equal( '}', readFile( DATA_FILE ):sub( 1, 1 ) )
	assert_equal( 'abc', load().data.x )
	assert_false( AutoStore.is_new_file )
end

function test_saveErrorKeepsChanges()
	AutoStore.data.x = 1
	AutoStore._preSave_f = function() error( 'disk full' ) end
	fire( 1000 ) -- no error out of the timer
	assert_nil( readFile( DATA_FILE ) )
	assert_match( 'error saving file', printed[#printed] )
	AutoStore._preSave_f = nil
	assert_true( AutoStore:save() )
	assert_equal( 1, saved().x )
end

function test_debugActive()
	assert_false( AutoStore.__debug_on )
	config.debug_active = true
	load()
	assert_true( AutoStore.__debug_on )
	assert_match( 'Loaded data', printed[#printed] )
end
