AddMythicEventHandler("Shared:DependencyUpdate", RetrieveComponents)
function RetrieveComponents()
    Logger = exports["mythic-base"]:FetchComponent("Logger")
end

AddEventHandler("Core:Shared:Ready", function()
    exports["mythic-base"]:RequestDependencies(KEY, { 
        "Logger",
    }, function(error)
        if #error > 0 then return; end
        RetrieveComponents()
    end)
end)