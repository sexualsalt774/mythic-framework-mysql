_MDT.Metrics = {
	Today = function(self)
		return MDT.Metrics:Get(GlobalState["MDT:Metric:CurrentDay"])
	end,
	Get = function(self, key)
		local p = promise.new()
		MySQL.single("SELECT * FROM mdt_metrics WHERE date = ?", {key}, function(result)
			if not result then
				p:resolve(false)
				return
			end

			p:resolve(result)
		end)
		return Citizen.Await(p)
	end,
}

function MetricsStartup()
	local date = os.date("*t")
	GlobalState["MDT:Metric:CurrentDay"] = string.format("%s/%s/%s", date.month, date.day, date.year)

	local r = MDT.Metrics:Today() or {}
	GlobalState["MDT:Metric:Arrests"] = r.Arrests or 0
	GlobalState["MDT:Metric:Reports"] = r.Reports or 0
	GlobalState["MDT:Metric:Warrants"] = r.Warrants or 0
	GlobalState["MDT:Metric:BOLOs"] = r.BOLOs or 0
	GlobalState["MDT:Metric:Search"] = r.Search or 0
end

AddEventHandler("MDT:Server:RegisterCallbacks", function()
	Callbacks:RegisterServerCallback("MDT:GetMetrics", function(source, data, cb)
        cb(MDT.Metrics:Get(data))
	end)
end)
