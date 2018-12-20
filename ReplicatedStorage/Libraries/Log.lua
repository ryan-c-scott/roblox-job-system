local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LogService = game:GetService("LogService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Log = {}
local _EVENT_NAME = 'ClientLogging'
local _messageQueue = {}
local _remotefilterfunc
local _consolefilterfunc
local _remoteEvent

Log._Level = {}
Log._LevelName = {}

function Log.SetupLevel(name, id)
	if Log[name] then
		Log(Log._LevelName.Warning, nil, 'Attempt to setup existing logging level')
		return false
	end
	
	Log._Level[name] = id
	Log._LevelName[id] = name

	local level = setmetatable({}, {
			__call = function(this, ...)
				-- Normal, vanilla logging; no channel.
				Log.Log(id, nil, ...)
			end;

			__index = function(tbl, key)
				-- TODO:  Determine how to not create a function every time
				-- .Maybe cache them?

				return function(...)
					Log.Log(id, key, ...)
				end
				
			end;
	})

	Log[name] = level

	return true
end

-- Setup the default levels
Log.SetupLevel('Info', 1)
Log.SetupLevel('Debug', 2)
Log.SetupLevel('Warn', 3)
Log.SetupLevel('Error', 4)

function Log.Log(level, chan, ...)
	local msg = string.format(...)
	local levelName = Log._LevelName[level]
	
	if _messageQueue then
		if not _remotefilterfunc or not _remotefilterfunc(level, levelName, chan, msg) then
			table.insert(_messageQueue, {tick(), level, chan, msg})
		end
	end

	if _remotefilterfunc and _remotefilterfunc(level, levelName, chan, msg) then
		return;
	end
		
	if chan then
		print(string.format("[%s][%s]", levelName, chan), msg)
	else
		print(string.format("[%s]", levelName), msg)
	end
end

Log.Data =
	setmetatable({}, {
			__index = function(tbl, key)
				return function(...)
					Log.LogData(key, ...)
				end
			end;
	})

function Log.LogData(chan, data)
	if _messageQueue then
		table.insert(_messageQueue, {tick(), 'data', chan, data})
	end
end

function Log.ProcessQueue(remote)
	if not _messageQueue then
		return
	end
	
	-- As a naive first pass, let's just send all of it at once.

	if RunService:IsClient() then
		_remoteEvent:FireServer(_messageQueue)

	elseif remote and #_messageQueue > 0 then
		-- TODO:  Count connection errors and stop attempting remote connections if it can't be reached
		-- .Experiment with compression
		local data = {
			place = game.PlaceId,
			game = game.GameId,
			job = game.JobId,
			messages = _messageQueue,
		}
		
		HttpService:PostAsync(remote,
							  HttpService:JSONEncode(data),
							  Enum.HttpContentType.ApplicationJson,
							  false)
	end
	
	Log.ClearQueue()
end

local function onClientLogging(player, messages)
	if _messageQueue and #messages > 0 then
		table.insert(_messageQueue, {player = player.UserId, messages = messages })
	end
end

LogService.MessageOut:connect(function(msg, msgType)
		-- HACK:  Have to detect our logging messages vs. system level ones
		if string.match(msg, '^%[[^%]]+%]') then
			return
		end
		
		-- NOTE:  +1 more or less automatically maps to the current built-in log levels
		Log.Log(msgType.Value + 1, 'SYSTEM', "%s", msg)
end)

function Log.EnableQueue(state)
	if state and not _messageQueue then
		_messageQueue = {}
	end

	if not state then
		_messageQueue = nil
	end
end

function Log.ClearQueue()
	for k,v in pairs(_messageQueue) do
		_messageQueue[k] = nil
	end
end

function Log.SetRemoteFilterFunc(func)
	_RemoteFilterFunc = func
end

function Log.SetConsoleFilterFunc(func)
	_ConsoleFilterFunc = func
end

---------
if RunService:IsClient() then
	_remoteEvent = ReplicatedStorage:WaitForChild(_EVENT_NAME)
else
	_remoteEvent = Instance.new('RemoteEvent', ReplicatedStorage)
	_remoteEvent.Name = _EVENT_NAME
	_remoteEvent.OnServerEvent:Connect(onClientLogging)
end

---------
return Log
