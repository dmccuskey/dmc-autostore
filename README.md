### Overview ###

Awesome automatic JSON-based storage for the Corona SDK

`dmc_autostore` is a module which makes saving application and game data painlessly easy, because _**it has NO API**_ ! Here's how to use it:

At the start you are given an empty Lua table. You add and remove data in it as you need. Any modifications which you make _**anywhere in the data structure**_ will save your changes to JSON. Super simple? Yes ! Super awesome? Definitely !!

**Great for OOP**

You can grab a reference to any part of the data structure (eg, another table nested deep deep down) and use that to make changes as well. In this way, `dmc_autostore` is well suited for object oriented programming, as each object can be given a small piece of the data tree to read/write as needed.


```lua
-- import autostore
local AutoStore = require 'dmc_autostore'

-- grab handle to data storage, this is a Lua table
local data = AutoStore.data 

-- make changes and the data is automatically stored
data.config = { file='/path/startup.cfg', count=4 }
data.number = 42 

-- data will be stored again.
data.number = 10
```


#### Examples ####

There are examples located in the example folder.
