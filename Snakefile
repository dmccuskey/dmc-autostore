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
			"dmc-corona-boot",
			"DMC-Lua-Library",
			"dmc-files",
			"dmc-objects"
		]
	},
	"examples": {
		"base_dir": "examples",
		"apps": [
			{
				"exp_dir": "DMC-autostore-basic",
				"requires": [
					"dmc-utils"
				]
			},
			{
				"exp_dir": "DMC-autostore-plugins",
				"requires": [
					"dmc-utils"
				]
			}
		]
	},
	"tests": {
		"files": [],
		"requires": []
	}
}

register( "dmc-autostore", module_config )

