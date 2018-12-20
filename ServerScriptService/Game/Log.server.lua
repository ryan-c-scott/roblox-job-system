-- TESTING:  Remote logging
local Log = require(game.ReplicatedStorage.Libraries.Log)

Log.Warn.testing("Starting server log pump")

while true do
	Log.ProcessQueue('http://localhost:9900')
	wait(1)
end
