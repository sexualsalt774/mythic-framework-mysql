AddMythicEventHandler("Shared:DependencyUpdate", RetrieveComponents)
function RetrieveComponents()
    Banking = exports["mythic-base"]:FetchComponent("Banking")
end

AddEventHandler("Core:Shared:Ready", function()
    exports["mythic-base"]:RequestDependencies(KEY, { 
        "Banking",
    }, function(error)
        if #error > 0 then return; end
        RetrieveComponents()
        local f = Banking.Accounts:GetOrganization("dgang")
        print(f.Account)
        print(json.encode(f, {indent = true}))
    end)
end)