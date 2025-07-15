local JOB_CACHE = {}

local function RefreshAllJobData(jobId)
	MySQL.query('SELECT * FROM jobs WHERE Id = ?', { jobId }, function(results)
		if results and results[1] then
			local jobData = results[1]
			jobData.Grades = json.decode(jobData.Grades)
			jobData.Workplaces = json.decode(jobData.Workplaces)
			jobData.Data = json.decode(jobData.Data)
			JOB_CACHE[jobId] = jobData
		end
	end)
end

local function RefreshJobCache()
	MySQL.query('SELECT * FROM jobs', {}, function(results)
		if results then
			for _, jobData in ipairs(results) do
				jobData.Grades = json.decode(jobData.Grades or '[]')
				jobData.Workplaces = json.decode(jobData.Workplaces or '[]')
				jobData.Data = json.decode(jobData.Data or '{}')
				JOB_CACHE[jobData.Id] = jobData
			end
			-- Wait for cache to be populated on first load
			if not _initialLoad then
				_initialLoad = true
			end
		end
	end)
end

AddEventHandler('onResourceStart', function(resourceName)
	if resourceName == GetCurrentResourceName() then
		RefreshJobCache()
	end
end)

_characterDuty = {}
_dutyData = {}

_JOBS = {
	GetAll = function(self)
		return JOB_CACHE
	end,
	Get = function(self, jobId)
		return JOB_CACHE[jobId]
	end,
	DoesExist = function(self, jobId, workplaceId, gradeId)
		local job = Jobs:Get(jobId)
		if job then
			if workplaceId and job.Workplaces then
				for _, workplace in ipairs(job.Workplaces) do
					if workplace.Id == workplaceId then
						if not gradeId then
							return {
								Id = job.Id,
								Name = job.Name,
								Workplace = false,
								Hidden = job.Hidden,
							}
						end

						for _, grade in ipairs(workplace.Grades) do
							if grade.Id == gradeId then
								return {
									Id = job.Id,
									Name = job.Name,
									Workplace = {
										Id = workplace.Id,
										Name = workplace.Name,
									},
									Grade = {
										Id = grade.Id,
										Name = grade.Name,
										Level = grade.Level,
									},
									Hidden = job.Hidden,
								}
							end
						end
					end
				end
			elseif not workplaceId then
				if not gradeId then
					return {
						Id = job.Id,
						Name = job.Name,
						Workplace = false,
						Hidden = job.Hidden,
					}
				elseif gradeId and job.Grades then
					for _, grade in ipairs(job.Grades) do
						if grade.Id == gradeId then
							return {
								Id = job.Id,
								Name = job.Name,
								Workplace = false,
								Grade = {
									Id = grade.Id,
									Name = grade.Name,
									Level = grade.Level,
								},
								Hidden = job.Hidden,
							}
						end
					end
				end
			end
		end
		return false
	end,
	GiveJob = function(self, stateId, jobId, workplaceId, gradeId, noOverride)
		local newJob = Jobs:DoesExist(jobId, workplaceId, gradeId)
		if not newJob or not newJob.Grade then
			return false
		end

		local char = Fetch:SID(stateId)
		if char then 
			char = char:GetData('Character')
		end

		if char then
			local charJobData = char:GetData('Jobs')
			if not charJobData then charJobData = {}; end

			for k, v in ipairs(charJobData) do
				if v.Id == newJob.Id then
					if noOverride then
						return false
					else
						table.remove(charJobData, k)
					end
				end
			end

			table.insert(charJobData, newJob)

			local source = char:GetData('Source')
			char:SetData('Jobs', charJobData)

			Middleware:TriggerEvent('Characters:ForceStore', source)

			Phone:UpdateJobData(source)

			TriggerEvent('Jobs:Server:JobUpdate', source)

			return true
		else
			local p = promise.new()
			MySQL.query('SELECT * FROM characters WHERE SID = ? LIMIT 1', { stateId }, function(results)
				if results and #results > 0 then
					local charData = results[1]
					local charJobData = charData.Jobs
					if not charJobData then charJobData = {}; end

					for k, v in ipairs(charJobData) do
						if v.Id == newJob.Id then
							if noOverride then
								p:resolve(false)
								return
							else
								table.remove(charJobData, k)
							end
						end
					end

					table.insert(charJobData, newJob)

					MySQL.update('UPDATE characters SET Jobs = ? WHERE SID = ?', { json.encode(charJobData), stateId }, function(updated)
						if updated and updated > 0 then
							p:resolve(true)
						else
							p:resolve(false)
						end
					end)
				else
					p:resolve(false)
				end
			end)

			local res = Citizen.Await(p)
			return res
		end
	end,
	RemoveJob = function(self, stateId, jobId)
		local char = Fetch:SID(stateId)
		if char then
			char = char:GetData('Character')
		end

		if char then
			local found = false
			local charJobData = char:GetData('Jobs')
			if not charJobData then charJobData = {}; end
			local removedJobData

			for k, v in ipairs(charJobData) do
				if v.Id == jobId then
					removedJobData = v
					found = true
					table.remove(charJobData, k)
				end
			end
			if #charJobData == 0 then
				charJobData = nil
			end

			if found then
				local source = char:GetData('Source')
				-- print(#charJobData)
				Logger:Trace("SALT-DEBUG", #charJobData)
				char:SetData('Jobs', charJobData)
				Jobs.Duty:Off(source, jobId, true)

				Middleware:TriggerEvent('Characters:ForceStore', source)
				Phone:UpdateJobData(source)
				TriggerEvent('Jobs:Server:JobUpdate', source)

				if removedJobData.Workplace and removedJobData.Workplace.Name then
					Execute:Client(source, 'Notification', 'Info', 'No Longer Employed at '.. removedJobData.Workplace.Name)
				else
					Execute:Client(source, 'Notification', 'Info', 'No Longer Employed at '.. removedJobData.Name)
				end

				return true
			end
		else
			local p = promise.new()
			MySQL.query('SELECT * FROM characters WHERE SID = ? LIMIT 1', { stateId }, function(results)
				if results and #results > 0 then
					local charData = results[1]
					local charJobData = charData.Jobs
					if charJobData then
						for k, v in ipairs(charJobData) do
							if v.Id == jobId then
								found = true
								table.remove(charJobData, k)
							end
						end
						if #charJobData == 0 then
							charJobData = nil
						end -- what

						if found then
							MySQL.update('UPDATE characters SET Jobs = ? WHERE SID = ?', { json.encode(charJobData), stateId }, function(updated)
								if updated and updated > 0 then
									p:resolve(true)
								else
									p:resolve(false)
								end
							end)
						else
							p:resolve(false)
						end
					else
						p:resolve(false)
					end
				else
					p:resolve(false)
				end
			end)

			local res = Citizen.Await(p)
			return res
		end
	end,
	Duty = {
		On = function(self, source, jobId, hideNotify)
			local player = Fetch:Source(source)
			if player then
				local char = player:GetData('Character')
				if char then
					local stateId = char:GetData('SID')
					local charJobs = char:GetData('Jobs')
					local hasJob = false

					for k, v in ipairs(charJobs) do
						if v.Id == jobId then
							hasJob = v
							break
						end
					end

					if hasJob then
						local dutyData = _characterDuty[stateId]
						if dutyData then
							if dutyData.Id == hasJob.Id then
								return true -- Already on duty as that job
							else
								local success = Jobs.Duty:Off(source, false, true)
								if not success then
									return false
								end
							end
						end

						_characterDuty[stateId] = {
							Source = source,
							Id = hasJob.Id,
							StartTime = os.time(),
							Time = os.time(),
							WorkplaceId = (hasJob.Workplace and hasJob.Workplace.Id or false),
							GradeId = hasJob.Grade.Id,
							GradeLevel = hasJob.Grade.Level,
							First = char:GetData('First'),
							Last = char:GetData('Last'),
							Callsign = char:GetData('Callsign'),
						}

						local ply = Player(source)
						if ply and ply.state then
							ply.state.onDuty = _characterDuty[stateId].Id
						end

						local callsign = char:GetData('Callsign')
						TriggerEvent('Job:Server:DutyAdd', _characterDuty[stateId], source, stateId, callsign)
						TriggerClientEvent('Job:Client:DutyChanged', source, _characterDuty[stateId].Id)
						Jobs.Duty:RefreshDutyData(hasJob.Id)

						local lastOnDutyData = char:GetData('LastClockOn') or {}
						lastOnDutyData[hasJob.Id] = os.time()
						char:SetData('LastClockOn', lastOnDutyData)

						if not hideNotify then
							if hasJob.Workplace then
								Execute:Client(source, 'Notification', 'Success', string.format('You\'re Now On Duty as %s - %s', hasJob.Workplace.Name, hasJob.Grade.Name))
							else
								Execute:Client(source, 'Notification', 'Success', string.format('You\'re Now On Duty as %s - %s', hasJob.Name, hasJob.Grade.Name))
							end
						end

						return hasJob
					end
				end
			end

			if not hideNotify then
				Execute:Client(source, 'Notification', 'Error', 'Failed to Go On Duty')
			end

			return false
		end,
		Off = function(self, source, jobId, hideNotify)
			local player = Fetch:Source(source)
			if player then
				local char = player:GetData('Character')
				if char then
					local stateId = char:GetData('SID')
					local dutyData = _characterDuty[stateId]
					if dutyData and (not jobId or (dutyData.Id == jobId)) then
						local dutyId = dutyData.Id
						local ply = Player(source)
						if ply and ply.state then
							ply.state.onDuty = false
						end
						
						local existing = char:GetData("Salary") or {}
						local workedMinutes = math.floor((os.time() - dutyData.Time) / 60)
						local j = Jobs:Get(dutyData.Id)
						local salary = math.ceil((j.Salary * j.SalaryTier) * (workedMinutes / _payPeriod))
						
                        Logger:Info("Jobs", string.format("Adding Salary Data For ^3%s^7 Going Off-Duty (^2%s Minutes^7 - ^3$%s^7)", char:GetData("SID"), workedMinutes, salary))

                        if existing[dutyData.Id] then
                            existing[dutyData.Id] = {
                                date = os.time(),
                                job = dutyData.Id,
                                minutes = (existing[dutyData.Id]?.minutes or 0) + workedMinutes,
                                total = (existing[dutyData.Id]?.total or 0) + salary,
                            }
                        else
                            existing[dutyData.Id] = {
                                date = os.time(),
                                job = dutyData.Id,
                                minutes = workedMinutes,
                                total = salary,
                            }
                        end

                        char:SetData("Salary", existing)

						TriggerEvent('Job:Server:DutyRemove', dutyData, source, stateId)
						TriggerClientEvent('Job:Client:DutyChanged', source, false)
						_characterDuty[stateId] = nil
						Jobs.Duty:RefreshDutyData(dutyId)

						local totalWorkedMinutes = math.floor((os.time() - dutyData.StartTime) / 60)
						local allTimeWorked = char:GetData("TimeClockedOn") or {}
						local jobTimeWorked = allTimeWorked[dutyData.Id] or {}

						if totalWorkedMinutes and totalWorkedMinutes >= 5 then
							table.insert(jobTimeWorked, {
								time = os.time(),
								minutes = totalWorkedMinutes,
							})

							local deleteBefore = os.time() - (60 * 60 * 24 * 14) -- Only Keep Last 14 Days
							for k,v in ipairs(jobTimeWorked) do
								if tonumber(v.time) < deleteBefore then
									table.remove(jobTimeWorked, k)
								end
							end

							allTimeWorked[dutyData.Id] = jobTimeWorked
						end
						char:SetData("TimeClockedOn", allTimeWorked)

						if not hideNotify then
							Execute:Client(source, 'Notification', 'Info', 'You\'re Now Off Duty')
						end

						return true
					end
				end
			end

			if not hideNotify then
				Execute:Client(source, 'Notification', 'Error', 'Failed to Go Off Duty')
			end

			return false
		end,
		Get = function(self, source, jobId)
			local player = Fetch:Source(source)
			if player then
				local char = player:GetData('Character')
				if char then
					local dutyData = _characterDuty[char:GetData('SID')]
					if dutyData and (not jobId or (jobId == dutyData.Id)) then
						return dutyData
					end
				end
			end
			return false
		end,
		GetDutyData = function(self, jobId)
			return _dutyData[jobId]
		end,
		RefreshDutyData = function(self, jobId)
			if not _dutyData[jobId] then
				_dutyData[jobId] = {}
			end

			local onDutyPlayers = {}
			local totalCount = 0
			local workplaceCounts = false

			for k, v in pairs(_characterDuty) do
				if v ~= nil and v.Id == jobId then
					totalCount = totalCount + 1
					table.insert(onDutyPlayers, v.Source)
					if v.WorkplaceId then
						if not workplaceCounts then
							workplaceCounts = {}
						end

						if not workplaceCounts[v.WorkplaceId] then
							workplaceCounts[v.WorkplaceId] = 1
						else
							workplaceCounts[v.WorkplaceId] = workplaceCounts[v.WorkplaceId] + 1
						end
					end
				end
			end

			_dutyData[jobId] = {
				Active = totalCount > 0,
				Count = totalCount,
				WorkplaceCounts = workplaceCounts,
				DutyPlayers = onDutyPlayers,
			}

			GlobalState[string.format('Duty:%s', jobId)] = totalCount
			if workplaceCounts then
				for workplace, count in pairs(workplaceCounts) do
					GlobalState[string.format('Duty:%s:%s', jobId, workplace)] = count
				end
			end
		end,
	},
	Permissions = {
		IsOwner = function(self, source, jobId)
			local player = Fetch:Source(source)
			if player then
				local char = player:GetData('Character')
				if char then
					local jobData = Jobs:Get(jobId)
					if jobData.Owner and jobData.Owner == char:GetData('SID') then
						return true
					end
				end
			end
			return false
		end,
		IsOwnerOfCompany = function(self, source)
			local player = Fetch:Source(source)
			if player then
				local char = player:GetData('Character')
				if char then
					local stateId = char:GetData('SID')
					local jobs = char:GetData('Jobs') or {}
					for k, v in ipairs(jobs) do
						local jobData = Jobs:Get(v.Id)
						if jobData.Owner and jobData.Owner == stateId then
							return true
						end
					end
				end
			end
			return false
		end,
		GetJobs = function(self, source)
			local player = Fetch:Source(source)
			if player then
				local char = player:GetData('Character')
				if char then
					local jobs = char:GetData('Jobs') or {}
					return jobs
				end
			end
			return false
		end,
		HasJob = function(self, source, jobId, workplaceId, gradeId, gradeLevel, checkDuty, permissionKey)
			local jobs = Jobs.Permissions:GetJobs(source)
			if not jobs then
				return false
			end
			if jobId then
				for k, v in ipairs(jobs) do
					if v.Id == jobId then
						if not workplaceId or (v.Workplace and v.Workplace.Id == workplaceId) then
							if not gradeId or (v.Grade.Id == gradeId) then
								if not gradeLevel or (v.Grade.Level and v.Grade.Level >= gradeLevel) then
									if not checkDuty or (checkDuty and Jobs.Duty:Get(source, jobId)) then
										if
											not permissionKey
											or (
												permissionKey
												and Jobs.Permissions:HasPermissionInJob(source, jobId, permissionKey)
											)
										then
											return v
										end
									end
								end
							end
						end
						break
					end
				end
			elseif permissionKey then
				return Jobs.Permissions:HasPermission(source, permissionKey)
			end
			return false
		end,
		GetPermissionsFromJob = function(self, source, jobId, workplaceId)
			local jobData = Jobs.Permissions:HasJob(source, jobId, workplaceId)
			if jobData then
				local perms = GlobalState[string.format('JobPerms:%s:%s:%s', jobData.Id, (jobData.Workplace and jobData.Workplace.Id or false), jobData.Grade.Id)]
				if perms then
					return perms
				end
			end
			return false
		end,
		HasPermissionInJob = function(self, source, jobId, permissionKey)
			local permissionsInJob = Jobs.Permissions:GetPermissionsFromJob(source, jobId)
			if permissionsInJob then
				if permissionsInJob[permissionKey] then
					return true
				end
			end
			return false
		end,
		GetAllPermissions = function(self, source)
			local allPermissions = {}
			local jobs = Jobs.Permissions:GetJobs(source)
			if jobs and #jobs > 0 then
				for k, v in ipairs(jobs) do
					local perms = GlobalState[string.format('JobPerms:%s:%s:%s', v.Id, (v.Workplace and v.Workplace.Id or false), v.Grade.Id)]
					if perms ~= nil then
						for k, v in pairs(perms) do
							if not allPermissions[k] then
								allPermissions[k] = v
							end
						end
					end
				end
			end
			return allPermissions
		end,
		HasPermission = function(self, source, permissionKey)
			local allPermissions = Jobs.Permissions:GetAllPermissions(source)
			return allPermissions[permissionKey]
		end,
	},
	Management = {
		Create = function(self, name, ownerSID) -- For player business creations
			if not name then
				name = Generator:Company()
			end
			local jobId = string.format('Company_%s', Sequence:Get('Company'))
			if jobId and name then
				local existing = Jobs:Get(jobId)
				if not existing then
					local p = promise.new()
					local document = {
						Type = 'Company',
						Custom = true,
						Id = jobId,
						Name = name,
						Owner = ownerSID,
						Salary = 100,
						SalaryTier = 1,
						Grades = {
							{
								Id = 'owner',
								Name = 'Owner',
								Level = 100,
								Permissions = {
									JOB_MANAGEMENT = true,
									JOB_FIRE = true,
									JOB_HIRE = true,
									JOB_MANAGE_EMPLOYEES = true,
								},
							}
						},
					}

					MySQL.insert('INSERT INTO jobs (Name, Owner, Type, Grade, Workplace, Permissions, Settings) VALUES (?, ?, ?, ?, ?, ?, ?)', {
						document.Name, document.Owner, document.Type, document.Grade, document.Workplace, json.encode(document.Permissions), json.encode(document.Settings)
					}, function(insertId)
						if insertId then
							document.id = insertId
							p:resolve(document)
						else
							p:resolve(false)
						end
					end)

					local res = Citizen.Await(p)
					return res
				end
			end
			return false
		end,
		Transfer = function(self, jobId, newOwner)
			-- TODO
			--Middleware:TriggerEvent("Business:Transfer", jobId, source:GetData("SID"), target:GetData("SID"))
		end,
		Upgrades = {
			-- TODO
			Has = function(self, jobId, upgradeKey)

			end,
			Unlock = function(self, jobId, upgradeKey)

			end,
			Lock = function(self, jobId, upgradeKey)

			end,
			Reset = function(self, jobId)

			end,
		},
		Delete = function(self, jobId)
			-- TODO
		end,
		Edit = function(self, jobId, settingData)
			if Jobs:DoesExist(jobId) then
				local p = promise.new()

				-- Flatten the settingData for the SQL query
				local updates = {}
				local values = {}
				for k, v in pairs(settingData) do
					if k ~= 'Grades' and k ~= 'Workplaces' and k ~= 'Id' and v ~= nil then
						table.insert(updates, string.format('`%s` = ?', k))
						table.insert(values, v)
					end
				end

				if #updates == 0 then
					p:resolve(false)
				else
					table.insert(values, jobId)
					local queryString = string.format('UPDATE jobs SET %s WHERE Id = ?', table.concat(updates, ', '))

					MySQL.update(queryString, values, function(affectedRows)
						if affectedRows > 0 then
							RefreshAllJobData(jobId)
							if settingData.Name then
								Jobs.Management.Employees:UpdateAllJob(jobId, settingData.Name)
							end
							p:resolve(true)
						else
							p:resolve(false)
						end
					end)
				end

				local res = Citizen.Await(p)
				return {
					success = res,
					code = res and 'SUCCESS' or 'ERROR',
				}
			else
				return {
					success = false,
					code = 'MISSING_JOB',
				}
			end
		end,
		Workplace = {
			Edit = function(self, jobId, workplaceId, newWorkplaceName)
				if Jobs:DoesExist(jobId, workplaceId) then
					local p = promise.new()
					local job = Jobs:Get(jobId)
					
					if not job or not job.Workplaces then
						p:resolve(false)
					else
						local updated = false
						for i, workplace in ipairs(job.Workplaces) do
							if workplace.Id == workplaceId then
								job.Workplaces[i].Name = newWorkplaceName
								updated = true
								break
							end
						end

						if updated then
							MySQL.update('UPDATE jobs SET Workplaces = ? WHERE Id = ?', { json.encode(job.Workplaces), jobId }, function(affectedRows)
								if affectedRows > 0 then
									RefreshAllJobData(jobId)
									Jobs.Management.Employees:UpdateAllWorkplace(jobId, workplaceId, newWorkplaceName)
									p:resolve(true)
								else
									p:resolve(false)
								end
							end)
						else
							p:resolve(false)
						end
					end

					local res = Citizen.Await(p)
					return {
						success = res,
						code = 'ERROR',
					}
				else
					return {
						success = false,
						code = 'ERROR',
					}
				end
			end,
		},
		Grades = {
			Create = function(self, jobId, workplaceId, gradeName, gradeLevel, gradePermissions)
				if Jobs:DoesExist(jobId, workplaceId) then
					local p = promise.new()
					local job = Jobs:Get(jobId)
					if not job then
						p:resolve(false)
					else
						local gradeId
						if workplaceId then
							gradeId = string.format('Grade_%s', Sequence:Get(string.format('Company:%s:%s:Grades', jobId, workplaceId)))
						else
							gradeId = string.format('Grade_%s', Sequence:Get(string.format('Company:%s:Grades', jobId)))
						end

						local gradeData = {
							Id = gradeId,
							Name = gradeName,
							Level = gradeLevel,
							Permissions = gradePermissions or {},
						}
						
						local updated = false
						if workplaceId then
							if job.Workplaces then
								for i, workplace in ipairs(job.Workplaces) do
									if workplace.Id == workplaceId then
										if not job.Workplaces[i].Grades then
											job.Workplaces[i].Grades = {}
										end
										table.insert(job.Workplaces[i].Grades, gradeData)
										updated = true
										break
									end
								end
							end
						else
							if not job.Grades then
								job.Grades = {}
							end
							table.insert(job.Grades, gradeData)
							updated = true
						end

						if updated then
							local query
							local params
							if workplaceId then
								query = 'UPDATE jobs SET Workplaces = ? WHERE Id = ?'
								params = { json.encode(job.Workplaces), jobId }
							else
								query = 'UPDATE jobs SET Grades = ? WHERE Id = ?'
								params = { json.encode(job.Grades), jobId }
							end
							
							MySQL.update(query, params, function(affectedRows)
								if affectedRows > 0 then
									RefreshAllJobData(jobId)
									p:resolve(true)
								else
									p:resolve(false)
								end
							end)
						else
							p:resolve(false)
						end
					end

					local res = Citizen.Await(p)
					return {
						success = res,
						code = 'ERROR',
					}
				else
					return {
						success = false,
						code = 'MISSING_JOB',
					}
				end
			end,
			Edit = function(self, jobId, workplaceId, gradeId, settingData)
				if Jobs:DoesExist(jobId, workplaceId, gradeId) then
					local p = promise.new()
					local job = Jobs:Get(jobId)
					if not job then
						p:resolve(false)
					else
						local updated = false
						if workplaceId then
							if job.Workplaces then
								for i, workplace in ipairs(job.Workplaces) do
									if workplace.Id == workplaceId and workplace.Grades then
										for j, grade in ipairs(workplace.Grades) do
											if grade.Id == gradeId then
												for k, v in pairs(settingData) do
													if k ~= 'Id' then
														job.Workplaces[i].Grades[j][k] = v
													end
												end
												updated = true
												break
											end
										end
									end
									if updated then break end
								end
							end
						else
							if job.Grades then
								for i, grade in ipairs(job.Grades) do
									if grade.Id == gradeId then
										for k, v in pairs(settingData) do
											if k ~= 'Id' then
												job.Grades[i][k] = v
											end
										end
										updated = true
										break
									end
								end
							end
						end

						if updated then
							local query
							local params
							if workplaceId then
								query = 'UPDATE jobs SET Workplaces = ? WHERE Id = ?'
								params = { json.encode(job.Workplaces), jobId }
							else
								query = 'UPDATE jobs SET Grades = ? WHERE Id = ?'
								params = { json.encode(job.Grades), jobId }
							end

							MySQL.update(query, params, function(affectedRows)
								if affectedRows > 0 then
									RefreshAllJobData(jobId)
									Jobs.Management.Employees:UpdateAllGrade(jobId, workplaceId, gradeId, settingData)
									p:resolve(true)
								else
									p:resolve(false)
								end
							end)
						else
							p:resolve(false)
						end
					end

					local res = Citizen.Await(p)
					return {
						success = res,
						code = 'ERROR',
					}
				else
					return {
						success = false,
						code = 'MISSING_JOB',
					}
				end
			end,
			Delete = function(self, jobId, workplaceId, gradeId)
				local peopleWithJobGrade = Jobs.Management.Employees:GetAll(jobId, workplaceId, gradeId)
				if #peopleWithJobGrade <= 0 then
					if Jobs:DoesExist(jobId, workplaceId, gradeId) then
						local p = promise.new()
						local job = Jobs:Get(jobId)
						if not job then
							p:resolve(false)
						else
							local updated = false
							if workplaceId then
								if job.Workplaces then
									for i, workplace in ipairs(job.Workplaces) do
										if workplace.Id == workplaceId and workplace.Grades then
											for j, grade in ipairs(workplace.Grades) do
												if grade.Id == gradeId then
													table.remove(job.Workplaces[i].Grades, j)
													updated = true
													break
												end
											end
										end
										if updated then break end
									end
								end
							else
								if job.Grades then
									for i, grade in ipairs(job.Grades) do
										if grade.Id == gradeId then
											table.remove(job.Grades, i)
											updated = true
											break
										end
									end
								end
							end

							if updated then
								local query
								local params
								if workplaceId then
									query = 'UPDATE jobs SET Workplaces = ? WHERE Id = ?'
									params = { json.encode(job.Workplaces), jobId }
								else
									query = 'UPDATE jobs SET Grades = ? WHERE Id = ?'
									params = { json.encode(job.Grades), jobId }
								end

								MySQL.update(query, params, function(affectedRows)
									if affectedRows > 0 then
										RefreshAllJobData(jobId)
										p:resolve(true)
									else
										p:resolve(false)
									end
								end)
							else
								p:resolve(false)
							end
						end
						
						local res = Citizen.Await(p)
						return {
							success = res,
							code = 'ERROR',
						}
					else
						return {
							success = false,
							code = 'MISSING_JOB',
						}
					end
				else
					return {
						success = false,
						code = 'JOB_OCCUPIED',
					}
				end
			end,
		},
		Employees = {
			GetAll = function(self, jobId, workplaceId, gradeId)
				local jobCharacters = {}
				local onlineSIDs = {}

				for _, player in pairs(Fetch:All()) do
					local char = player:GetData('Character')
					if char then
						local sid = char:GetData('SID')
						table.insert(onlineSIDs, sid)
						local jobs = char:GetData('Jobs') or {}
						for _, job in ipairs(jobs) do
							if job.Id == jobId and (not workplaceId or (job.Workplace and job.Workplace.Id == workplaceId)) and (not gradeId or (job.Grade.Id == gradeId)) then
								table.insert(jobCharacters, {
									Source = char:GetData('Source'),
									SID = sid,
									First = char:GetData('First'),
									Last = char:GetData('Last'),
									Phone = char:GetData('Phone'),
									JobData = job,
								})
								break
							end
						end
					end
				end

				local p = promise.new()
				local query = 'SELECT SID, First, Last, Phone, Jobs FROM characters WHERE JSON_SEARCH(Jobs, "one", ?, NULL, "$[*].Id") IS NOT NULL'
				local params = { jobId }

				if #onlineSIDs > 0 then
					query = query .. ' AND SID NOT IN (?)'
					table.insert(params, {onlineSIDs})
				end

				MySQL.query(query, params, function(results)
					if results then
						for _, c in ipairs(results) do
							local jobs = json.decode(c.Jobs or '[]')
							for _, job in ipairs(jobs) do
								if job.Id == jobId and (not workplaceId or (job.Workplace and job.Workplace.Id == workplaceId)) and (not gradeId or (job.Grade.Id == gradeId)) then
									table.insert(jobCharacters, {
										Source = false,
										SID = c.SID,
										First = c.First,
										Last = c.Last,
										Phone = c.Phone,
										JobData = job,
									})
									break
								end
							end
						end
					end
					p:resolve(true)
				end)

				Citizen.Await(p)
				return jobCharacters
			end,
			UpdateAllJob = function(self, jobId, newJobName)
                local onlineSIDs = {}
				for _, player in pairs(Fetch:All()) do
					local char = player:GetData('Character')
					if char then
                        table.insert(onlineSIDs, char:GetData('SID'))
						local jobs = char:GetData('Jobs') or {}
						local modified = false
						for i, job in ipairs(jobs) do
							if job.Id == jobId then
								jobs[i].Name = newJobName
								modified = true
							end
						end
						if modified then
							char:SetData('Jobs', jobs)
							Phone:UpdateJobData(char:GetData('Source'))
						end
					end
				end

				local p = promise.new()
				local query = 'SELECT SID, Jobs FROM characters WHERE JSON_SEARCH(Jobs, "one", ?, NULL, "$[*].Id") IS NOT NULL'
                local params = { jobId }
                
				if #onlineSIDs > 0 then
					query = query .. ' AND SID NOT IN (?)'
					table.insert(params, {onlineSIDs})
				end

				MySQL.query(query, params, function(results)
					if results then
						local updatePromises = {}
						for _, c in ipairs(results) do
							local jobs = json.decode(c.Jobs or '[]')
							local modified = false
							for i, job in ipairs(jobs) do
								if job.Id == jobId then
									jobs[i].Name = newJobName
									modified = true
								end
							end
							if modified then
								local innerP = promise.new()
								MySQL.update('UPDATE characters SET Jobs = ? WHERE SID = ?', { json.encode(jobs), c.SID }, function(affectedRows)
									innerP:resolve(affectedRows > 0)
								end)
								table.insert(updatePromises, innerP)
							end
						end
						if #updatePromises > 0 then
							Citizen.Await(promise.all(updatePromises))
						end
					end
					p:resolve(true)
				end)

				return Citizen.Await(p)
			end,
			UpdateAllWorkplace = function(self, jobId, workplaceId, newWorkplaceName)
				local onlineSIDs = {}
				for _, player in pairs(Fetch:All()) do
					local char = player:GetData('Character')
					if char then
						table.insert(onlineSIDs, char:GetData('SID'))
						local jobs = char:GetData('Jobs') or {}
						local modified = false
						for i, job in ipairs(jobs) do
							if job.Id == jobId and job.Workplace and job.Workplace.Id == workplaceId then
								jobs[i].Workplace.Name = newWorkplaceName
								modified = true
							end
						end
						if modified then
							char:SetData('Jobs', jobs)
							Phone:UpdateJobData(char:GetData('Source'))
						end
					end
				end
                
                local p = promise.new()
				local query = 'SELECT SID, Jobs FROM characters WHERE JSON_SEARCH(Jobs, "one", ?, NULL, "$[*].Id") IS NOT NULL AND JSON_SEARCH(Jobs, "one", ?, NULL, "$[*].Workplace.Id") IS NOT NULL'
				local params = { jobId, workplaceId }

				if #onlineSIDs > 0 then
					query = query .. ' AND SID NOT IN (?)'
					table.insert(params, {onlineSIDs})
                end
                
				MySQL.query(query, params, function(results)
					if results then
						local updatePromises = {}
						for _, c in ipairs(results) do
							local jobs = json.decode(c.Jobs or '[]')
							local modified = false
							for i, job in ipairs(jobs) do
								if job.Id == jobId and job.Workplace and job.Workplace.Id == workplaceId then
									jobs[i].Workplace.Name = newWorkplaceName
									modified = true
								end
							end
							if modified then
								local innerP = promise.new()
								MySQL.update('UPDATE characters SET Jobs = ? WHERE SID = ?', { json.encode(jobs), c.SID }, function(affectedRows)
									innerP:resolve(affectedRows > 0)
								end)
								table.insert(updatePromises, innerP)
							end
						end
						if #updatePromises > 0 then
							Citizen.Await(promise.all(updatePromises))
						end
					end
					p:resolve(true)
				end)
				return Citizen.Await(p)
			end,
			UpdateAllGrade = function(self, jobId, workplaceId, gradeId, settingData)
				local onlineSIDs = {}
				if settingData.Name or settingData.Level then
					for _, player in pairs(Fetch:All()) do
						local char = player:GetData('Character')
						if char then
							table.insert(onlineSIDs, char:GetData('SID'))
							local jobs = char:GetData('Jobs') or {}
							local modified = false
							for i, job in ipairs(jobs) do
								if job.Id == jobId and (not workplaceId or (job.Workplace and job.Workplace.Id == workplaceId)) and job.Grade.Id == gradeId then
									if settingData.Name then
										jobs[i].Grade.Name = settingData.Name
									end
									if settingData.Level then
										jobs[i].Grade.Level = settingData.Level
									end
									modified = true
								end
							end
							if modified then
								char:SetData('Jobs', jobs)
								Phone:UpdateJobData(char:GetData('Source'))
							end
						end
					end

					local p = promise.new()
					local query
					local params
					if workplaceId then
						query = 'SELECT SID, Jobs FROM characters WHERE JSON_SEARCH(Jobs, "one", ?, NULL, "$[*].Id") IS NOT NULL AND JSON_SEARCH(Jobs, "one", ?, NULL, "$[*].Workplace.Id") IS NOT NULL AND JSON_SEARCH(Jobs, "one", ?, NULL, "$[*].Grade.Id") IS NOT NULL'
						params = { jobId, workplaceId, gradeId }
					else
						query = 'SELECT SID, Jobs FROM characters WHERE JSON_SEARCH(Jobs, "one", ?, NULL, "$[*].Id") IS NOT NULL AND JSON_SEARCH(Jobs, "one", ?, NULL, "$[*].Grade.Id") IS NOT NULL'
						params = { jobId, gradeId }
					end

					if #onlineSIDs > 0 then
						query = query .. ' AND SID NOT IN (?)'
						table.insert(params, {onlineSIDs})
					end

					MySQL.query(query, params, function(results)
						if results then
							local updatePromises = {}
							for _, c in ipairs(results) do
								local jobs = json.decode(c.Jobs or '[]')
								local modified = false
								for i, job in ipairs(jobs) do
									if job.Id == jobId and (not workplaceId or (job.Workplace and job.Workplace.Id == workplaceId)) and job.Grade.Id == gradeId then
										if settingData.Name then
											jobs[i].Grade.Name = settingData.Name
										end
										if settingData.Level then
											jobs[i].Grade.Level = settingData.Level
										end
										modified = true
									end
								end
								if modified then
									local innerP = promise.new()
									MySQL.update('UPDATE characters SET Jobs = ? WHERE SID = ?', { json.encode(jobs), c.SID }, function(affectedRows)
										innerP:resolve(affectedRows > 0)
									end)
									table.insert(updatePromises, innerP)
								end
							end
							if #updatePromises > 0 then
								Citizen.Await(promise.all(updatePromises))
							end
						end
						p:resolve(true)
					end)
					return Citizen.Await(p)
				end
				return false
			end,
		}
	},
	Data = {
		Set = function(self, jobId, key, val)
			if Jobs:DoesExist(jobId) and key then
				local p = promise.new()
				local job = Jobs:Get(jobId)
				if not job then
					p:resolve(false)
				else
					if not job.Data then
						job.Data = {}
					end
					job.Data[key] = val
					MySQL.update('UPDATE jobs SET Data = ? WHERE Id = ?', { json.encode(job.Data), jobId }, function(affectedRows)
						if affectedRows > 0 then
							RefreshAllJobData(jobId)
							p:resolve(true)
						else
							p:resolve(false)
						end
					end)
				end

				local res = Citizen.Await(p)
				return {
					success = res,
					code = 'ERROR',
				}
			else
				return {
					success = false,
					code = 'MISSING_JOB',
				}
			end
		end,
		Get = function(self, jobId, key)
			if key and JOB_CACHE[jobId] and JOB_CACHE[jobId].Data then
				return JOB_CACHE[jobId].Data[key]
			end
		end,
	},
}

AddEventHandler('Proxy:Shared:RegisterReady', function()
	exports['mythic-base']:RegisterComponent('Jobs', _JOBS)
end)