--// written by bhristt (march 13 2022)
--// updated: march 19 2022
--// the subscription class for the replicator


--// services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")


--// modules
local Func = require(script.Parent:WaitForChild("Func"))
local SETTINGS = require(script.Parent:WaitForChild("Settings"))


--// declarations
local private = {}

--// store connections to client table
local clientTableConnections = {}


--// constants
local IS_SERVER = RunService:IsServer()

local CLIENT_TABLE_FILTER_TYPES = {
	WHITELIST = "WHITELIST",
	BLACKLIST = "BLACKLIST",
}

local BINDABLE_EVENT_NAMES = {
	PROPERTY_ADDED = "PROPERTY_ADDED",
	PROPERTY_CHANGED = "PROPERTY_CHANGED",
	PROPERTY_REMOVED = "PROPERTY_REMOVED",
	PLAYER_ADDED_TO_CLIENT_TBL = "PLAYER_ADDED_TO_CLIENT_TBL",
	PLAYER_REMOVED_FROM_CLIENT_TBL = "PLAYER_REMOVED_FROM_CLIENT_TBL",
}

local ERRORS = {
	SERVER_FUNCTION_ONLY = "[SERVER FUNCTION ONLY] %s",
	CLIENT_FUNCTION_ONLY = "[CLIENT FUNCTION ONLY] %s",
	INVALID_PROPERTY_NAME = "[INVALID PROPERTY NAME] %s",
	INVALID_PROPERTY = "[INVALID PROPERTY] %s",
	INVALID_USE_OF_CLIENT_TABLE = "[INVALID CLIENT TABLE USE] %s",
}


--// subscription class
local Subscription = {}
local SubscriptionFunc = {}


--// subscription class properties
--// ClientTableFilterTypes
Subscription.CLIENT_TABLE_FILTER_TYPES = setmetatable({}, {
	__index = CLIENT_TABLE_FILTER_TYPES,
	__newindex = function(tbl, index, val)
		error("Cannot add new indices to this table!")
	end,
})


--// no index metatable
local NoIndexMetaFunc = {}
local NO_INDEX_META = {
	__index = NoIndexMetaFunc,
	__newindex = function(tbl, index, val)
		error("Cannot add indices to this table!")
	end,
	__call = function(tbl, index)
		return rawget(tbl, index)
	end,
}
--// no index metatable functions
--// gets all indices in the table
--// does not return table functions
function NoIndexMetaFunc:GetProperties(): {[string]: any}
	local properties = {}
	for i, _ in pairs(self) do
		properties[i] = rawget(self, i)
	end
	return properties
end


--// client table metatable
local ClientTableFunc = {}
local CLIENT_TABLE_META = {
	__index = ClientTableFunc,
	__newindex = function(tbl, index, val)
		error("Cannot add new indices to this table!")
	end,
}
--// client table functions
--// adds a new player to the client table
--// creates a connection to remove the player
--// from the table when the player leaves
function ClientTableFunc:AddPlayer(player: Player)
	--// check if player is already in the table
	if table.find(self, player) then
		return
	end
	--// add the player to the client table
	local connections = clientTableConnections[self]
	connections[player] = Players.PlayerRemoving:Connect(function(playerRemoving)
		if playerRemoving == player then
			self:RemovePlayer(player)
		end
	end)
	rawset(self, #self + 1, player)
end
--// iterates through all players in the game, accounting
--// for the filter type of the table
function ClientTableFunc:IterateAccountingFilter(filterType: string, func: (plr: Player) -> any)
	local iterationType = {
		[CLIENT_TABLE_FILTER_TYPES.WHITELIST] = function()
			for _, plr in ipairs(self) do
				func(plr)
			end
		end,
		[CLIENT_TABLE_FILTER_TYPES.BLACKLIST] = function()
			for _, plr in pairs(Players:GetPlayers()) do
				if not table.find(self, plr) then
					func(plr)
				end
			end
		end,
	}
	if iterationType[filterType] ~= nil then
		iterationType[filterType]()
	end
end
--// removes a player from the client table
--// if the player is not in the client table, does nothing
function ClientTableFunc:RemovePlayer(player: Player)
	local connections = clientTableConnections[self]
	--// check if the player is in the client table
	local playerInList = table.find(self, player)
	if playerInList then
		local playerConnection = connections[player]
		if playerConnection ~= nil then	
			playerConnection:Disconnect()
		end
		rawset(self, playerInList, nil)
		for i = playerInList + 1, #self do
			local p = self[i]
			rawset(self, i, nil)
			rawset(self, i - 1, p)
		end
	end
end


--// constructor
function Subscription.new(propTable: {[string]: any}?)
	local self = setmetatable({}, {
		__index = SubscriptionFunc,
	})
	local pself = {}
	--// setup new subscription object
	self.Properties = setmetatable(propTable or {}:: {[string]: any}, NO_INDEX_META)
	self.StoreTablePropertyAsPointer = false
	self.UpdateAllSubsOnPropChanged = true
	self.ClientTableFilterType = CLIENT_TABLE_FILTER_TYPES.WHITELIST
	--// setup new private subscription object
	pself.Initialized = false
	pself.Bindables = {}:: {[string]: BindableEvent}
	pself.ClientTable = setmetatable({}:: {Player}, CLIENT_TABLE_META)
	pself.Listeners = {}:: {[string]: BindableEvent}
	pself.Connections = {}:: {RBXScriptConnection}
	--// setup bindables for subscription object
	self.PropertyAdded = Func.StoreNewBindable(pself.Bindables, BINDABLE_EVENT_NAMES.PROPERTY_ADDED)
	self.PropertyChanged = Func.StoreNewBindable(pself.Bindables, BINDABLE_EVENT_NAMES.PROPERTY_CHANGED)
	self.PropertyRemoved = Func.StoreNewBindable(pself.Bindables, BINDABLE_EVENT_NAMES.PROPERTY_REMOVED)
	self.PlayerAddedToClientTbl = Func.StoreNewBindable(pself.Bindables, BINDABLE_EVENT_NAMES.PLAYER_ADDED_TO_CLIENT_TBL)
	self.PlayerRemovedFromClientTbl = Func.StoreNewBindable(pself.Bindables, BINDABLE_EVENT_NAMES.PLAYER_REMOVED_FROM_CLIENT_TBL)
	--// initialize
	clientTableConnections[pself.ClientTable] = {}
	private[self] = pself
	self:Init()
	return self
end


--// subscription server functions
--// creates a new property in the given subscription
--// if the given property name is already a property of the subscription, errors
function SubscriptionFunc:AddProperty(propIndex: string, propVal: any)
	if IS_SERVER then
		local pself = private[self]
		local bindables = pself.Bindables
		local listeners = pself.Listeners
		local properties = self.Properties
		local storeTablePropertyAsPointer = self.StoreTablePropertyAsPointer
		--// fire added and changed bindables
		local addedBindable = bindables[BINDABLE_EVENT_NAMES.PROPERTY_ADDED]
		local changedBindable = bindables[BINDABLE_EVENT_NAMES.PROPERTY_CHANGED]
		--// check if a listener was made for the property
		local listener = listeners[propIndex]
		local property = properties(propIndex)
		--// check if the property exists in the subscription
		if property == nil then
			if type(propVal) == "table" and not storeTablePropertyAsPointer then
				propVal = Func.CloneTbl(propVal)
			end
			rawset(properties, propIndex, propVal)
			if listener ~= nil then
				listener:Fire(propVal)
			end
			addedBindable:Fire(propIndex, propVal)
			changedBindable:Fire(propIndex, propVal)
		else
			error(string.format(ERRORS.INVALID_PROPERTY, "A property with the name '" .. tostring(propIndex) .. "' already exists in this subscription!"))
		end
	else
		error(string.format(ERRORS.SERVER_FUNCTION_ONLY, "Subscription:AddProperty() can only be used on the server!"))
	end
end
--// sets the value of a property to the given value
--// if the property does not exist in the subscription, errors
function SubscriptionFunc:SetProperty(propIndex: string, propVal: any)
	if IS_SERVER then
		local pself = private[self]
		local bindables = pself.Bindables
		local listeners = pself.Listeners
		local properties = self.Properties
		local storeTablePropertyAsPointer = self.StoreTablePropertyAsPointer
		--// fire changed bindable
		local changedBindable = bindables[BINDABLE_EVENT_NAMES.PROPERTY_CHANGED]
		--// check if a listener was made for the property
		local listener = listeners[propIndex]
		local property = properties(propIndex)
		--// check that the property exists
		if property ~= nil then
			if type(propVal) == "table" and not storeTablePropertyAsPointer then
				propVal = Func.CloneTbl(propVal)
			end
			rawset(properties, propIndex, propVal)
			if listener ~= nil then
				listener:Fire(propVal)
			end
			changedBindable:Fire(propIndex, propVal)
		else
			error(string.format(ERRORS.INVALID_PROPERTY, "'" .. tostring(propIndex) .. "' is not a valid property of this subscription!"))
		end
	else
		error(string.format(ERRORS.SERVER_FUNCTION_ONLY, "Subscription:SetProperty() can only be used on the server!"))
	end
end
--// removes a property in the given subscription
--// if the property does not exist in the subscription, errors
function SubscriptionFunc:RemoveProperty(propIndex: string)
	if IS_SERVER then
		local pself = private[self]
		local bindables = pself.Bindables
		local listeners = pself.Listeners
		local properties = self.Properties
		--// fire changed and removed bindables
		local changedBindable = bindables[BINDABLE_EVENT_NAMES.PROPERTY_CHANGED]
		local removedBindable = bindables[BINDABLE_EVENT_NAMES.PROPERTY_REMOVED]
		--// check if a listener was made for the property
		local listener = listeners[propIndex]
		local property = properties(propIndex)
		--// check that the property exists
		if property ~= nil then
			rawset(properties, propIndex, nil)
			if listener ~= nil then
				listener:Fire(nil)
			end
			changedBindable:Fire(propIndex, nil)
			removedBindable:Fire(propIndex)
		else
			error(string.format(ERRORS.INVALID_PROPERTY, "'" .. tostring(propIndex) .. "' is not a valid property of this subscription!"))
		end
	else
		error(string.format(ERRORS.SERVER_FUNCTION_ONLY, "Subscription:RemoveProperty() can only be used on the server!"))
	end
end
--// adds a player to the client table of the subscription
--// if the player is already in the client table, does nothing
function SubscriptionFunc:AddPlayerToClientTbl(player: Player)
	if IS_SERVER then
		local pself = private[self]
		local ctbl = pself.ClientTable
		ctbl:AddPlayer(player)
	else
		error(string.format(ERRORS.SERVER_FUNCTION_ONLY, "Subscription:AddPlayerToClientTbl() can only be used on the server!"))
	end
end
--// gets the list of players in the client table
--// the client table is a table that has functions attached to it
--// to protect the client table, a clone of the table can be made instead
function SubscriptionFunc:GetClientTbl(): {Player}
	if IS_SERVER then
		local pself = private[self]
		local ctbl = pself.ClientTable
		local ctbl_nm = {}
		for i, v in ipairs(ctbl) do
			ctbl_nm[i] = v
		end
		return ctbl_nm
	else
		error(string.format(ERRORS.SERVER_FUNCTION_ONLY, "Subscription:GetClientTbl() can only be used on the server!"))
	end
end
--// iterates through the client table according to the filter type
--// if the filter type is set to WHITELIST, only uses players in the table
--// if the filter type is set to BLACKLIST, only uses players outside of the table
function SubscriptionFunc:IterateThroughFilteredCTbl(func: (plr: Player) -> any)
	if IS_SERVER then
		local pself = private[self]
		local ctbl = pself.ClientTable
		local filterType = self.ClientTableFilterType
		ctbl:IterateAccountingFilter(filterType, func)
	else
		error(string.format(ERRORS.SERVER_FUNCTION_ONLY, "Subscription:IterateThroughFilteredCTbl() can only be used on the server!"))
	end
end
--// removes a player from the client table
--// if the player is not in the client table, does nothing
function SubscriptionFunc:RemovePlayerFromClientTbl(player: Player)
	if IS_SERVER then
		local pself = private[self]
		local ctbl = pself.ClientTable
		ctbl:RemovePlayer(player)
	else
		error(string.format(ERRORS.SERVER_FUNCTION_ONLY, "Subscription:RemovePlayerFromClientTbl() can only be used on the server!"))
	end
end

--// subscription client functions
--// updates the subscription with the given property table
function SubscriptionFunc:UpdateSubscription(propTable: {[string]: any})
	if not IS_SERVER then
		local pself = private[self]
		local bindables = pself.Bindables
		local listeners = pself.Listeners
		local properties = self.Properties
		--// fire property added, changed, and removed bindables
		local addedBindable = bindables[BINDABLE_EVENT_NAMES.PROPERTY_ADDED]
		local changedBindable = bindables[BINDABLE_EVENT_NAMES.PROPERTY_CHANGED]
		local removedBindable = bindables[BINDABLE_EVENT_NAMES.PROPERTY_REMOVED]
		--// begin to update properties
		--// fire changed events and added events if adding new property
		--// if a listener has been created for a property being changed, fire the listener
		for propIndex, propValue in pairs(propTable) do
			local prevPropValue = properties(propIndex)
			if prevPropValue ~= propValue then
				changedBindable:Fire(propIndex, propValue)
				local listener = listeners[propIndex]
				if listener ~= nil then
					listener:Fire(propValue)
				end
				if prevPropValue == nil then
					addedBindable:Fire(propIndex, propValue)
				elseif propValue == nil then
					removedBindable:Fire(propIndex)
				end
				rawset(properties, propIndex, propValue)
			end
		end
	else
		error(string.format(ERRORS.CLIENT_FUNCTION_ONLY, "Subscription:UpdateSubscription() can only be used on the client!"))
	end
end


--// subscription replicated functions
--// initializes the subscription object
function SubscriptionFunc:Init()
	local pself = private[self]
	--// check if the subscription object has been initialized
	if not pself.Initialized then
		pself.Initialized = true
	else
		return
	end
	--// initialize the subscription object
	
end
--// gets the property in the property table
--// if the property does not exist in the subscription, errors
function SubscriptionFunc:GetProperty(propIndex: string): any
	local pself = private[self]
	local properties = self.Properties
	--// check if the property with the given index exists
	local property = properties(propIndex)
	if property == nil then
		error(string.format(ERRORS.INVALID_PROPERTY, "'" .. tostring(propIndex) .. "' is not a valid property in the subscription!"))
	end
	--// return the property value
	return property
end
--// gets a listener for the given property
--// if a listener is not available for the property, creates a new one
--// if the property does not exist, errors
function SubscriptionFunc:GetPropertyChangedSignal(propIndex: string): RBXScriptSignal
	local pself = private[self]
	local listeners = pself.Listeners
	local properties = self.Properties
	--// check if the property with the given index exists
	local property = properties(propIndex)
	if property == nil then
		error(string.format(ERRORS.INVALID_PROPERTY, "'" .. tostring(propIndex) .. "' is not a valid property in the subscription!"))
	end
	--// gets or creates a listener for the given property
	local listener = listeners[propIndex]
	if listener == nil then
		listener = Func.StoreNewBindable(listeners, propIndex)
	else
		listener = listener.Event
	end
	--// return the listener for the given property
	return listener
end


--// return
return Subscription