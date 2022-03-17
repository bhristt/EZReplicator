--// written by bhristt (march 13 2022)
--// updated: march 17 2022
--// the subscription class for the replicator


--// services
local RunService = game:GetService("RunService")


--// modules
local Func = require(script.Parent:WaitForChild("Func"))
local SETTINGS = require(script.Parent:WaitForChild("Settings"))


--// declarations
local private = {}


--// constants
local IS_SERVER = RunService:IsServer()

local BINDABLE_EVENT_NAMES = {
	PROPERTY_ADDED = "PROPERTY_ADDED",
	PROPERTY_CHANGED = "PROPERTY_CHANGED",
	PROPERTY_REMOVED = "PROPERTY_REMOVED",
}

local ERRORS = {
	SERVER_FUNCTION_ONLY = "[SERVER FUNCTION ONLY] %s",
	CLIENT_FUNCTION_ONLY = "[CLIENT FUNCTION ONLY] %s",
	INVALID_PROPERTY_NAME = "[INVALID PROPERTY NAME] %s",
	INVALID_PROPERTY = "[INVALID PROPERTY] %s",
}


--// subscription class
local Subscription = {}
local SubscriptionFunc = {}
local NoIndexMetaFunc = {}


--// no index metatable
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


--// constructor
function Subscription.new(propTable: {[string]: any}?)
	local self = setmetatable({}, {
		__index = SubscriptionFunc,
	})
	local pself = {}
	--// setup new subscription object
	self.Properties = setmetatable({}:: {[string]: any}, NO_INDEX_META)
	--// setup new private subscription object
	pself.Initialized = false
	pself.Bindables = {}:: {[string]: BindableEvent}
	pself.Listeners = {}:: {[string]: BindableEvent}
	pself.Connections = {}:: {RBXScriptConnection}
	--// setup bindables for subscription object
	self.PropertyAdded = Func.StoreNewBindable(pself.Bindables, BINDABLE_EVENT_NAMES.PROPERTY_ADDED)
	self.PropertyChanged = Func.StoreNewBindable(pself.Bindables, BINDABLE_EVENT_NAMES.PROPERTY_CHANGED)
	self.PropertyRemoved = Func.StoreNewBindable(pself.Bindables, BINDABLE_EVENT_NAMES.PROPERTY_REMOVED)
	--// initialize
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
		--// fire added and changed bindables
		local addedBindable = bindables[BINDABLE_EVENT_NAMES.PROPERTY_ADDED]
		local changedBindable = bindables[BINDABLE_EVENT_NAMES.PROPERTY_CHANGED]
		--// check if a listener was made for the property
		local listener = listeners[propIndex]
		local property = properties(propIndex)
		--// check if the property exists in the subscription
		if property == nil then
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
		--// fire changed bindable
		local changedBindable = bindables[BINDABLE_EVENT_NAMES.PROPERTY_CHANGED]
		--// check if a listener was made for the property
		local listener = listeners[propIndex]
		local property = properties(propIndex)
		--// check that the property exists
		if property ~= nil then
			rawset(properties, propIndex, nil)
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
function SubscriptionFunc:GetPropertyChangedSignal(propIndex: string): BindableEvent
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
		Func.StoreNewBindable(listeners, propIndex)
		listener = listeners[propIndex]
	end
	--// return the listener for the given property
	return listener
end


--// return
return Subscription
