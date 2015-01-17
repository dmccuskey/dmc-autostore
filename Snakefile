# dmc-autostore

try:
	if not gSTARTED: print( gSTARTED )
except:
	MODULE = "dmc-autostore"
	include: "../DMC-Corona-Library/snakemake/Snakefile"

module_config = {
	"name": "dmc-autostore",
	"module": {
		"dir": "dmc_corona",
		"files": [
			"dmc_autostore.lua"
		],
		"requires": [
			"DMC-Lua-Library",
			"dmc-files",
			"dmc-objects"
		]
	},
	"examples": [
		{
			"dir": "examples/DMC-autostore-basic",
			"requires": []
		},
		{
			"dir": "examples/DMC-autostore-plugins",
			"requires": []
		}
	],
	"tests": {
		"files": [
		],
		"requires": [
		]
	}
}

register( "dmc-autostore", module_config )

