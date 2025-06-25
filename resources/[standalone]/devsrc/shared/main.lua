KEY = 'Devsrc'

function AddMythicEventHandler(str, cb)
    AddEventHandler(("%s:%s"):format(KEY, str), cb)
end