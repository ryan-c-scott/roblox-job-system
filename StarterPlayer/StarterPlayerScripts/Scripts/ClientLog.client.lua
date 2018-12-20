-- TESTING:  Remote logging
local Log = require(game.ReplicatedStorage.Libraries.Log)

Log.Warn.testing("Starting client log pump")

while true do
	Log.ProcessQueue()
	wait(1)
end
