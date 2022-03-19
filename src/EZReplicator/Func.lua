--// written by bhristt (march 13 2022)
--// updated: march 13 2022
--// a class containing general functions used in the subscription
--// and replicator classes


--// Func class
--// since Func is a general class, we don't need to
--// instantiate any objects of this class
local Func = {}


--// creates a bindable event and stores it in the given table
--// at the given index, returns the RBXScriptSignal of the BindableEvent
function Func.StoreNewBindable(tbl, index): RBXScriptSignal
	local newBindable = Instance.new("BindableEvent")
	tbl[index] = newBindable
	return newBindable.Event
end


--// clones a table and returns a clone of the given table
function Func.CloneTbl(tbl): {[any]: any}
    local ntbl = {}
    for i, v in pairs(tbl) do
        ntbl[i] = type(v) == "table" and Func.CloneTbl(v) or v
    end
    return ntbl
end


--// return
return Func