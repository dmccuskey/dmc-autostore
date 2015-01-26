--====================================================================--
-- AutoStore Plugins
--
-- Shows use of AutoStore plugins\
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2013-2015 David McCuskey. All Rights Reserved.
--====================================================================--



print( '\n\n##############################################\n\n' )



--===================================================================--
--== Imports


local AutoStore = require 'dmc_corona.dmc_autostore'
local ProgressBar = require 'component.progress_bar'
local UFO = require 'component.ufo'



--===================================================================--
--== Setup, Constants

AutoStore.debug=true

display.setStatusBar( display.HiddenStatusBar )

-- forward declares
local min_bar, max_bar, saved_text
local dg_bg, dg_ufo, dg_fg
local doDataSavedDisplay



--====================================================================--
--== Support Functions


--[[

Anything in this area has something to do with AutoStore.
You'll find examples to initialize a new, empty AutoStore data structure,
or adding new items, or looping through existing data

--]]


--[[
our complete data structure is going to look like this:

AutoStore.data = {
	ufos = {
		<ufo id> = { x=22, y=55, temperature='cool' },
		<ufo id> = { x=30, y=100, temperature='hot' },
		...
	}

}
--]]

-- initializeAutoStore()
--
-- check if a we have a new file (first app launch)
-- initialize data structure
-- return true/false if initialized
--
local function initializeAutoStore()
	--print( "initializeAutoStore" )

	-- check if autostore needs initialized
	if not AutoStore.is_new_file then return false end

	-- let's initialize it

	-- get a reference to the root of the data structure
	-- right now 'data' is an empty, "magic" table, eg {}
	local data = AutoStore.data

	-- add empty container to the tree in which to store our UFO objects
	data[ 'ufos' ] = {}

	return true

end


-- createNewUFO
--
-- create a new UFO object based on the data parameter
-- @param data table: coordinates for UFO location, eg { x=33, y=209 }
--
local function createNewUFO( ufo_data )
	--print( "createNewUFO" )

	local ufos = AutoStore.data.ufos -- get small branch of storage tree
	local id = system.getTimer() -- key for our new UFO
	local o -- obj ref


	--== AutoStore functionality ==--

	--[[
	IMPORTANT !!:
	1. save "raw" data into autostore
	2. retrieve the autostore version to update/read from
	--]]

	-- 1. add in our new data to autostore
	-- autostore changes it to "magic" version
	ufos[ id ] = ufo_data

	-- 2. retrieve the "magic" data branch
	ufo_data = ufos[ id ]

	-- now create our new UFO object
	-- passing in our "magic" data branch
	o = UFO:new( id, ufo_data )
	dg_ufo:insert( o.view )

end


-- destroyUFO
--
-- create a new UFO object based on the data parameter
-- @param data table: coordinates for UFO location, eg { x=33, y=209 }
--
local function destroyUFO( ufo )
	-- print( "destroyUFO", ufo )

	local ufos = AutoStore.data.ufos
	local id = ufo.id

	--== Reverse of Create !! ==--

	-- remove visual object
	ufo:removeSelf()

	-- remove from data store
	ufos[ id ]=nil

end


-- createExistingUFOs()
--
-- app start, get our stored data and create any UFOs
--
local function createExistingUFOs()
	--print( "createExistingUFOs" )

	local ufos -- data reference
	local o -- ufo object reference

	--== AutoStore functionality ==--

	-- get the UFO branch from the data tree
	ufos = AutoStore.data.ufos -- get small branch of storage tree

	-- loop through 'ufos' table and create objects
	-- Note: we're calling pairs() as a method ON our branch
	--
	for id, data in ufos:pairs() do

		-- data is a reference to a "magic" part of the storage tree
		-- we are passing THAT into the object
		-- the object will keep a reference to it and use this ref
		-- to read or update its values whenever it wants
		--
		o = UFO:new( id, data )
		dg_ufo:insert( o.view )

	end

end


local function autostoreEventHandler( event )
	-- print( 'autostoreEventHandler', event.type )
	local etype = event.type

	if etype == AutoStore.DATA_SAVED then
		doDataSavedDisplay()

	elseif etype == AutoStore.START_MIN_TIMER then
		min_bar:start( event.time )

	elseif etype == AutoStore.STOP_MIN_TIMER then
		min_bar:stop()

	elseif etype == AutoStore.START_MAX_TIMER then
		max_bar:start( event.time )

	elseif etype == AutoStore.STOP_MAX_TIMER then
		max_bar:stop()
	end

end



--===================================================================--
--== Main
--===================================================================--


--[[

Anything below here doesn't have anything to do with AutoStore
the code is just to make the demo look nice

--]]


doDataSavedDisplay = function()
	--print( "doDataSavedDisplay" )
	saved_text.xScale=1 ; saved_text.yScale=1
	saved_text.alpha = 1
	transition.to( saved_text, { xScale=2, yScale=2, alpha=0, time=750 } )
end


-- backgroundTouchHandler
-- captures touches to create a new UFO
--
local function backgroundTouchHandler( e )
	--print( "backgroundTouchHandler" )
	if e.phase == 'ended' then
		createNewUFO( { x=e.x, y=e.y, temperature='cool' } )
	end
	return true
end


local function clearButtonTouchHandler( e )
	-- print( "clearButtonTouchHandler" )
	if e.phase == 'ended' then
		if dg_ufo.numChildren > 0 then
			for i = dg_ufo.numChildren, 1, -1 do
				local o = getDMCObject( dg_ufo[i] )
				destroyUFO( o )
			end
		end
	end
	return true
end


-- initializeApp()
--
--
local function initializeApp()
	--print( "initializeApp" )

	local o

	dg_bg = display.newGroup()
	dg_ufo = display.newGroup()
	dg_fg = display.newGroup()


	o = display.newImageRect( 'assets/space_bg.png', 480, 320 )
	o.x = 240 ; o.y = 160

	o:addEventListener( 'touch', backgroundTouchHandler )
	dg_bg:insert( o )

	--== clear button

	o = display.newRoundedRect( 420, 25, 70, 30, 4 )
	o.strokeWidth = 2
	o:setStrokeColor( 255, 100, 100 )
	o:setFillColor( 200, 200, 200 )
	o:addEventListener( 'touch', clearButtonTouchHandler )

	dg_fg:insert( o )

	o = display.newText( "Clear", 420, 25, nil, 18 )
	o:setTextColor( 0, 0, 0 )
	dg_fg:insert( o )

	--==  MIN label & progress bar

	o = display.newText( "Min", 30, 15, nil, 14 )
	dg_bg:insert( o )

	o = ProgressBar:new( { x=60, y=15, width=310, height=8, color='orange' } )
	min_bar = o
	dg_bg:insert( o._dg )


	-- MAX label & progress bar
	o = display.newText( "Max", 30, 35, nil, 14 )
	dg_bg:insert( o )

	o = ProgressBar:new( { x=60, y=35, width=310, height=8, color='red' } )
	max_bar = o
	dg_bg:insert( o._dg )


	-- "Data Saved" display
	o = display.newText( "Data Saved !!", 240, 100, native.systemFontBold, 24 )
	o:setTextColor(255, 0, 0)
	o.alpha = 0
	saved_text = o
	dg_fg:insert( o )

end



-- main()
-- bootstrap the application
--
local main = function()

	initializeApp()

	--== Init Autostore ==--

	-- listen for autostore events
	AutoStore:addEventListener( AutoStore.EVENT, autostoreEventHandler )

	local is_new = initializeAutoStore()

	if is_new then
		-- create in a single UFO, to start with something
		local ufo = { x=240, y=160, temperature='cool' }
		createNewUFO( ufo )

	else
		createExistingUFOs()

	end

end


-- let's get this party started !
--
main()



