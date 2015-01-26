--====================================================================--
-- plugin file
--
-- part of AutoStore example
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2014-2015 David McCuskey. All Rights Reserved.
--====================================================================--



--===================================================================--
--== Imports


local mime = require 'mime'



--===================================================================--
--== Setup, Constants


local mbase64_decode = mime.unb64
local mbase64_encode = mime.b64



--====================================================================--
--== Support Functions


local function encode( data )
	print("AutoStore Plugin: encoding data")
	local b64, _ = mbase64_encode( data )
	return b64
end

local function decode( data )
	print("AutoStore Plugin: decoding data")
	local unb64, _ = mbase64_decode( data )
	return unb64
end




--===================================================================--
--== Create Plugin Facade
--===================================================================--


local Plugins = {}

Plugins.preSaveFunction = encode
Plugins.postReadFunction = decode

return Plugins
