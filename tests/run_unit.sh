#!/bin/sh
#
# Run the lunatest unit specs (stand-in system, timer and Runtime) with plain Lua 5.1.
# The data files go in a temporary folder, removed afterwards.
#
# usage: tests/run_unit.sh
#   override the interpreter with LUA=

set -e

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
LUA=${LUA:-$ROOT/../tools/lua51/bin/lua}

AUTOSTORE_DOCS=$(mktemp -d)
export AUTOSTORE_DOCS
trap 'rm -rf "${AUTOSTORE_DOCS:?}"' EXIT

cd "$ROOT"
LUA_PATH="$ROOT/?.lua;$HERE/?.lua;$($LUA -e 'io.write(package.path)')"
LUA_CPATH="$($LUA -e 'io.write(package.cpath)')"
export LUA_PATH LUA_CPATH

# stand-ins for the Solar2D globals dmc_corona_boot needs
"$LUA" -e "
package.preload.json = package.preload.json or function() return require 'dkjson' end
system = {
	ResourceDirectory='resource', DocumentsDirectory='documents',
	pathForFile=function( f, dir )
		if dir=='documents' then return os.getenv( 'AUTOSTORE_DOCS' ) .. '/' .. f end
		return f
	end,
}
local lunatest = require 'lunatest'
lunatest.suite( 'dmc_autostore_spec' )
lunatest.run()
"
