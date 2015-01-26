--====================================================================--
-- ufo object library
--
-- part of AutoStore example
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2013 David McCuskey. All Rights Reserved.
--====================================================================--



--====================================================================--
--== Imports


local Objects = require 'dmc_corona.dmc_objects'



--====================================================================--
--== Setup, Constants


-- aliases to make code cleaner
local newClass = Objects.newClass
local ComponentBase = Objects.ComponentBase



--====================================================================--
--== UFO Class
--====================================================================--


local UFO = newClass( ComponentBase, { name="A UFO" } )

--==  Class constants  ==--

UFO.COOL_IMG = 'assets/ufo_cool.png'
UFO.WARM_IMG = 'assets/ufo_warm.png'
UFO.HOT_IMG = 'assets/ufo_hot.png'
UFO.IMG_W = 110
UFO.IMG_H = 65


--======================================================--
-- Start: Setup DMC Objects

-- __init__()
-- called by new()
-- one of the base methods to override for dmc_objects
-- here we save params, initialize basic properties, etc
--
function UFO:__init__( id, data )
	-- print( "UFO:__init__", id, data )
	self:superCall( '__init__', params )
	--==--

	--== Create Properties ==--

	self.id = id

	-- autostore data,
	-- this is the autostore 'magic' branch for this object
	self._as_data = data

	-- flag for movement / color change
	self._has_moved = false

	-- holds the different colors of the UFO
	self._ufo_views = {}

end

-- reverse init() setup
function UFO:__undoInit__()
	-- print( "UFO:__undoInit__" )

	self._ufo_views = nil
	self._has_moved = nil
	self._as_data = nil
	self.id = nil

	--==--
	self:superCall( '__undoInit__' )
end


-- __createView__()
--
-- one of the base methods to override for dmc_objects
-- here we put on our display properties
--
function UFO:__createView__()
	-- print( "UFO:__createView__" )
	self:superCall( '__createView__' )
	--==--

	local uvs = self._ufo_views -- table reference
	local o -- obj ref

	-- create 'cool' view
	o = display.newImageRect( UFO.COOL_IMG, UFO.IMG_W, UFO.IMG_H )
	o.isVisible = false

	self:insert( o )
	uvs.cool = o

	-- create 'warm' view
	o = display.newImageRect( UFO.WARM_IMG, UFO.IMG_W, UFO.IMG_H )
	o.isVisible = false

	self:insert( o )
	uvs.warm = o

	-- create 'hot' view
	o = display.newImageRect( UFO.HOT_IMG, UFO.IMG_W, UFO.IMG_H )
	o.isVisible = false

	self:insert( o )
	uvs.hot = o

end


-- __undoCreateView__()
--
-- one of the base methods to override for dmc_objects
-- remove items added in __createView__()
--
function UFO:__undoCreateView__()
	-- print( "UFO:__undoCreateView__" )
	--==--

	local uvs = self._ufo_views -- table reference
	local o

	o = uvs.hot
	o:removeSelf()
	uvs.hot = nil

	o = uvs.warm
	o:removeSelf()
	uvs.warm = nil

	o = uvs.cool
	o:removeSelf()
	uvs.cool = nil

	--==--
	-- be sure to call this last !
	self:superCall( '__undoCreateView__' )
end



function UFO:__initComplete__()
	-- print( "UFO:__initComplete__" )
	self:superCall( '__initComplete__' )
	--==--

	local data = self._as_data

	-- add some event listeners for those
	-- events we'd like to know about
	self:addEventListener( 'touch', self )

	-- position our UFO on screen
	self:_positionUFO()

	-- select our view from stored data
	self:_selectTempView( data.temperature )

end

function UFO:__undoInitComplete__()
	-- print( "UFO:__undoInitComplete__" )

	self:removeEventListener( 'touch', self )

	--==--
	self:superCall( '__undoInitComplete__' )
end

-- END: Setup DMC Objects
--======================================================--



--====================================================================--
--== Public Methods


-- none



--====================================================================--
--== Private Methods


function UFO:_positionUFO()

	-- grab autostore "magic" reference
	local d = self._as_data

	-- make sure we don't fly into the UI
	if d.y < 50 then d.y = 50 end

	-- use stored data to set our *visual* position
	self.x = d.x
	self.y = d.y

end


-- selectNextTemp
-- cycles through temperatures
--
function UFO:_selectNextTemp()
	-- print( "UFO:_selectNextTemp" )

	-- grab autostore "magic" reference
	local d = self._as_data

	-- changes to d.temperature will trigger an auto-update to storage !!

	if d.temperature == 'cool' then
		d.temperature = 'warm'
	elseif d.temperature == 'warm' then
		d.temperature = 'hot'
	else
		d.temperature = 'cool'
	end

	self:_selectTempView( d.temperature )
end


-- _selectTempView()
-- displays the proper the image based on temperature
--
function UFO:_selectTempView( temp )
	-- print( "UFO:_selectTempView", temp )

	local uvs = self._ufo_views -- view ref

	-- turn them all off
	uvs.cool.isVisible = false
	uvs.warm.isVisible = false
	uvs.hot.isVisible = false

	-- then select the next view to show
	uvs[ temp ].isVisible = true

end


-- touch()
-- basic Corona touch handler
--
function UFO:touch( event )
	-- print( "UFO:touch" )

	if event.phase == 'began' then
		self:toFront()

	elseif event.phase == 'moved' then

		self._has_moved = true

		-- save new position into autostore
		-- changes will trigger an auto-update to storage !!

		local d = self._as_data
		d.x = event.x
		d.y = event.y

		-- now update the visual position
		self:_positionUFO()


	elseif event.phase == 'ended' then

		-- if it was just a 'tap', then change color
		if self._has_moved == false then
			self:_selectNextTemp()
		end
		self._has_moved = false

	end

	return true
end




return UFO
