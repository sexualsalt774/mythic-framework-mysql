local _ranStartup = false
JOB_CACHE = {}
JOB_COUNT = 0

_loaded = false

AddEventHandler('Jobs:Shared:DependencyUpdate', RetrieveComponents)
function RetrieveComponents()
	Database = exports['mythic-base']:FetchComponent('Database')
	Middleware = exports['mythic-base']:FetchComponent('Middleware')
	Callbacks = exports['mythic-base']:FetchComponent('Callbacks')
	Logger = exports['mythic-base']:FetchComponent('Logger')
	Utils = exports['mythic-base']:FetchComponent('Utils')
	Fetch = exports['mythic-base']:FetchComponent('Fetch')
	Chat = exports['mythic-base']:FetchComponent('Chat')
	Execute = exports['mythic-base']:FetchComponent('Execute')
	Sequence = exports['mythic-base']:FetchComponent('Sequence')
	Generator = exports['mythic-base']:FetchComponent('Generator')
	Phone = exports['mythic-base']:FetchComponent('Phone')
	Jobs = exports['mythic-base']:FetchComponent('Jobs')
end

AddEventHandler('Core:Shared:Ready', function()
	exports['mythic-base']:RequestDependencies('Jobs', {
		'Database',
		'Middleware',
		'Callbacks',
		'Logger',
		'Utils',
		'Fetch',
		'Execute',
		'Sequence',
		'Generator',
		'Chat',
		'Jobs',
		'Phone'
	}, function(error)
		if #error > 0 then return; end
		RetrieveComponents()
		RegisterJobMiddleware()
		RegisterJobCallbacks()
		RegisterJobChatCommands()

		_loaded = true

		RunStartup()

		TriggerEvent('Jobs:Server:Startup')
	end)
end)

function FindAllJobs()
	local p = promise.new()

	MySQL.query('SELECT * FROM jobs', {}, function(success, results)
		if success and results and #results > 0 then
			-- Decode JSON fields for each result
			for k, v in pairs(results) do
				if v then
					if v.Grades then
						v.Grades = json.decode(v.Grades)
					end
					if v.Workplaces then
						v.Workplaces = json.decode(v.Workplaces)
					end
					if v.Data then
						v.Data = json.decode(v.Data)
					end
				end
			end
			p:resolve(results)
		else
			p:resolve({})
		end
	end)

	local res = Citizen.Await(p)
	return res
end

function RefreshAllJobData(job)
	local jobsFetch = FindAllJobs()
	JOB_COUNT = #jobsFetch
	
	-- Clear and rebuild cache
	JOB_CACHE = {}
	for k, v in ipairs(jobsFetch) do
		if v and v.Id then
			JOB_CACHE[v.Id] = v
		end
	end

	TriggerEvent('Jobs:Server:UpdatedCache', job or -1)

	-- Process government jobs
	local govPromise = promise.new()
	MySQL.query('SELECT Type, Id, Name, Workplaces FROM jobs WHERE Type = "Government"', {}, function(success, results)
		if success and results and #results > 0 then
			for k, v in pairs(results) do
				if v and v.Id and v.Workplaces then
					local workplaces = json.decode(v.Workplaces)
					if workplaces then
						for _, workplace in pairs(workplaces) do
							if workplace and workplace.Grades then
								for _, grade in pairs(workplace.Grades) do
									if grade and grade.Id and grade.Permissions then
										local key = string.format('JobPerms:%s:%s:%s', v.Id, workplace.Id or 'default', grade.Id)
										GlobalState[key] = grade.Permissions
									end
								end
							end
						end
					end
				end
			end
		end
		govPromise:resolve(true)
	end)

	-- Process company jobs
	local companyPromise = promise.new()
	MySQL.query('SELECT Type, Id, Name, Grades FROM jobs WHERE Type = "Company"', {}, function(success, results)
		if success and results and #results > 0 then
			for k, v in pairs(results) do
				if v and v.Id and v.Grades then
					local grades = json.decode(v.Grades)
					if grades then
						for _, grade in pairs(grades) do
							if grade and grade.Id and grade.Permissions then
								local key = string.format('JobPerms:%s:false:%s', v.Id, grade.Id)
								GlobalState[key] = grade.Permissions
							end
						end
					end
				end
			end
		end
		companyPromise:resolve(true)
	end)

	return Citizen.Await(promise.all({
		govPromise,
		companyPromise,
	}))
end

function RunStartup()
    if _ranStartup then return; end
    _ranStartup = true

	-- Simple function to insert or update a job using ON DUPLICATE KEY UPDATE
	local function upsertJob(document)
		local p = promise.new()
		
		-- Ensure all required fields have safe defaults
		local jobData = {
			Type = document.Type or 'Company',
			Id = document.Id,
			Name = document.Name or 'Unknown Job',
			Salary = document.Salary or 0,
			SalaryTier = document.SalaryTier or 1,
			Grades = json.encode(document.Grades or {}),
			Workplaces = json.encode(document.Workplaces or {}),
			Data = json.encode(document.Data or {}),
			Owner = document.Owner or nil,
			LastUpdated = document.LastUpdated or os.time()
		}
		
		MySQL.insert('INSERT INTO jobs (Type, Id, Name, Salary, SalaryTier, Grades, Workplaces, Data, Owner, LastUpdated) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE Name = VALUES(Name), Salary = VALUES(Salary), SalaryTier = VALUES(SalaryTier), Grades = VALUES(Grades), Workplaces = VALUES(Workplaces), Data = VALUES(Data), Owner = VALUES(Owner), LastUpdated = VALUES(LastUpdated)', {
			jobData.Type,
			jobData.Id,
			jobData.Name,
			jobData.Salary,
			jobData.SalaryTier,
			jobData.Grades,
			jobData.Workplaces,
			jobData.Data,
			jobData.Owner,
			jobData.LastUpdated
		}, function(success, inserted)
			if success then
				p:resolve(true)
			else
				Logger:Error('Jobs', 'Error upserting job: ' .. tostring(document.Id))
				p:resolve(false)
			end
		end)
		
		return p
	end

	-- Process all default jobs
	local awaitingPromises = {}
	for k, v in ipairs(_defaultJobData) do
		if v and v.Id then
			table.insert(awaitingPromises, upsertJob(v))
		else
			Logger:Error('Jobs', 'Invalid job data found at index ' .. k)
		end
	end

	-- Wait for all jobs to be processed
	if #awaitingPromises > 0 then
		Citizen.Await(promise.all(awaitingPromises))
		Logger:Info('Jobs', 'Processed ^2' .. #awaitingPromises .. '^7 Default Jobs')
	end

	-- Refresh job data
	RefreshAllJobData()
	Logger:Trace('Jobs', string.format('Loaded ^2%s^7 Jobs', JOB_COUNT))
	TriggerEvent('Jobs:Server:CompleteStartup')
end