local _serviceList = {
	RunService = "RunService",
}

local function _PullServiceReferences()
	local services = {}

	for key, serviceName in _serviceList do
		services[key] = game:GetService(serviceName)
	end

	return services
end

local _services = _PullServiceReferences()
local _producers = {
	stepped = {},
	render = {},
	heartbeat = {},
}

-------------
local JobSystem = {}

local function _RegisterProducer(stage, cb)
	local stageProducers = _queues[stage]

	if not stageProducers then
		-- TODO: Warn
		return false
	end

	-- Check for duplicate
	for i,v in ipairs(stageProducers) do
		if v == cb then
			-- TODO:  Warn
			return false
		end
	end

	table.insert(stageProducers, cb)
end

local function _UnregisterProducer(stage, cb)
	local stageProducers = _queues[stage]

	if not stageProducers then
		-- TODO: Warn
		return false
	end
	
	for i,v in ipairs(stageProducers) do
		if v == cb then
			table.remove(stageProducers, cb)
			return true
		end
	end

	-- TODO:  Warn of missing producer

	return false
end

--
local function RegisterProducerStepped(cb)
	_RegisterProducer('stepped', cb)
end

local function UnregisterProducerStepped(cb)
	_UnregisterProducer('stepped', cb)
end

local function RegisterProducerRenderStepped(cb)
	_RegisterProducer('render', cb)
end

local function UnregisterProducerRenderStepped(cb)
	_UnregisterProducer('render', cb)
end

local function RegisterProducerHeartbeat(cb)
	_RegisterProducer('heartbeat', cb)
end

local function UnregisterProducerHeartbeat(cb)
	_UnregisterProducer('heartbeat', cb)
end

--
local function _QueryStageProducers(stage)
	local jobs = {}

	-- Run through all producers and return the list of jobs
	for _, 	producer in ipairs(_producers[stage]) do
		-- TODO:  Evaluate whether producers should directly insert into the jobs table or return their own tables
		-- .There's a performance cost associated with creating new tables
		producer(jobs)
	end	
end

local function _ScheduleJobs(jobs)
	local queue = {}
	local deps = {}

	-- TODO:  Populate queue based on dependencies and build a dependency map
	

	-- TEMP:  No scheduling
	queue = jobs
	
	return queue, deps
end

local function _ExecuteStage(stage, dt)
	-- TODO:  Check global pause state in case it's paused
	
	local jobs = _QueryStageProducers(stage)
	local queue, deps = _ScheduleStage(stage)

	-- Execute each job
	for _, job in ipairs(queue) do
		-- Job Dependencies
		local jobDeps = deps[job.id]
		local jobResources

		if jobDeps then
			-- TODO:  Pull dependencies and inject their data into job.data
		end

		if job.depends_resources then
			-- TODO:  Get any workspace/resource dependency references
			-- .Will need to handle the top level being services, etc.
		end

		-- TODO:  Evaluate pcall or other error capturing mechanisms
		job.result = job.exec(dt, job.data, jobResources)

		-- TODO:  Check execution result
		-- .Maybe pause execution, log error/report, etc.
	end
end

---- Engine callbacks
-- TODO:  Hook into the 3 different update steps
_services.RunService.Stepped:Connect(function(time, dt)
		_ExecuteStage('stepped', dt)
end)

_services.RunService.RenderStepped:Connect(function(dt)
		_ExecuteStage('render', dt)
end)

_services.RunService.Heartbeat:Connect(function(dt)
		_ExecuteStage('heartbeat', dt)
end)

--
return JobSystem
