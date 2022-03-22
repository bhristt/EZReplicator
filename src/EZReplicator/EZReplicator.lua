--// written by bhristt (march 13 2022)
--// updated: march 19 2022
--// the replicator class for use in both the client and the server


--// services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")


--// modules
local Func = require(script:WaitForChild("Func"))
local Subscription = require(script:WaitForChild("Subscription"))
local SETTINGS = require(script:WaitForChild("Settings"))


--// declarations
local signal, request do
	local remoteFolder = script:WaitForChild("REMOTES")
	signal = remoteFolder:WaitForChild("SIGNAL")
	request = remoteFolder:WaitForChild("REQUEST")
end

--// private properties of objects
--// are stored in this table
local private = {}

--// connections for subscriptions and subscription store
--// this table is necessary because subscription store
--// connections are made in a different scope than the
--// replicator object
local subscriptionConnections = {}


--// constants
local IS_SERVER = RunService:IsServer()

local REPLICATOR_BINDABLE_NAMES = {
	SUBSCRIPTION_ADDED = "SUBSCRIPTION_ADDED",
	SUBSCRIPTION_REMOVED = "SUBSCRIPTION_REMOVED",
}

local SERVER_SIGNALS = {
	RECEIVE_CUSTOM_SIGNAL_FROM_CLIENT = "CUSTOM_CLIENT_SIGNAL_RECEIVED",
}

local SERVER_REQUESTS = {
	GET_SUBSCRIPTION_CACHE = "GET_SUBSCRIPTION_CACHE",
	RECEIVE_CUSTOM_REQUEST_FROM_CLIENT = "CUSTOM_CLIENT_REQUEST_RECEIVED",
}

local CLIENT_SIGNALS = {
	CREATE_SUBSCRIPTION = "CREATE_SUBSCRIPTION",
	UPDATE_SUBSCRIPTION = "UPDATE_SUBSCRIPTION",
	UPDATE_SUBSCRIPTION_PACKAGE = "UPDATE_SUBSCRIPTION_PACKAGE",
	REMOVE_SUBSCRIPTION = "REMOVE_SUBSCRIPTION",
	RECEIVE_CUSTOM_SIGNAL_FROM_SERVER = "CUSTOM_SERVER_SIGNAL_RECEIVED",
}

local CLIENT_REQUESTS = {
	RECEIVE_CUSTOM_REQUEST_FROM_SERVER = "CUSTOM_SERVER_REQUEST_RECEIVED",
}

local SERVER_CONNECTIONS = {
	CLIENT_SIGNAL_RECEIVED = "CLIENT_SIGNAL_RECEIVED",
	CLIENT_REQUEST_RECEIVED = "CLIENT_REQUEST_RECEIVED",
}

local CLIENT_CONNECTIONS = {
	SERVER_SIGNAL_RECEIVED = "SERVER_SIGNAL_RECEIVED",
	SERVER_REQUEST_RECEIVED = "SERVER_REQUEST_RECEIVED",
}

local WARNINGS = {
	MAX_SUBSCRIPTION_YIELD_REACHED = "[MAX SUBSCRIPTION YIELD REACHED] Max yield time is %is, passed %.3fs",
	SERVER_REQUEST_HANDLER_UNDEFINED = "[SERVER REQUEST HANDLER UNDEFINED] %s",
	CLIENT_REQUEST_HANDLER_UNDEFINED = "[CLIENT REQUEST HANDLER UNDEFINED] %s",
}

local ERRORS = {
	SERVER_FUNCTION_ONLY = "[SERVER FUNCTION ONLY] %s can only be used in the server!",
	CLIENT_FUNCTION_ONLY = "[CLIENT FUNCTION ONLY] %s can only be used in the client!",
	INVALID_SUBSCRIPTION_NAME = "[INVALID SUBSCRIPTION NAME] %s",
	INVALID_SUBSCRIPTION = "[INVALID SUBSCRIPTION] %s",
	INITIAL_REPLICATION_FAILED = "[INITIAL REPLICATION FAILED] %s",
	SERVER_DATA_REQUEST_FAILED = "[SERVER DATA REQUEST FAILED] %s",
	CLIENT_DATA_REQUEST_FAILED = "[CLIENT DATA REQUEST FAILED] %s",
}


--// type declarations
export type Subscription = typeof(Subscription.new())


--// Replicator class
local Replicator = {}
local ReplicatorFunctions = {}
local SubscriptionStoreFunctions = {}


--// subscription store functions
--// adds a subscription to the subscription store
function SubscriptionStoreFunctions:AddSubscription(name: string, subscription: Subscription)
	rawset(self, name, subscription)
	if IS_SERVER then
		local connections = subscriptionConnections[self]
		local subConnections = {}
		--// when a property is changed, update the subscriptions on the respectul clients
		table.insert(subConnections, subscription.PropertyChanged:Connect(function(propIndex, propVal)
			local updateAllSubsOnPropChanged = subscription.UpdateAllSubsOnPropChanged
			if not updateAllSubsOnPropChanged then
				subscription:IterateThroughFilteredCTbl(function(player)
					signal:FireClient(player, CLIENT_SIGNALS.UPDATE_SUBSCRIPTION, name, propIndex, propVal)
				end)
			else
				signal:FireAllClients(CLIENT_SIGNALS.UPDATE_SUBSCRIPTION, name, propIndex, propVal)
			end
		end))
		--// when a player is added to the client table in the subscription, and the
		--// player is meant to receive the copy of the subscription, update the subscription
		--// for the player on their client
		table.insert(subConnections, subscription.PlayerAddedToClientTbl:Connect(function(player)
			local updateAllSubsOnPropChanged = subscription.UpdateAllSubsOnPropChanged
			local sendSignalToUpdateSub = false
			--// check if the player is meant to receive a replicated copy
			--// of the subscription in the server
			if not updateAllSubsOnPropChanged then
				local filteredClientTbl = subscription:GetFilteredClientTbl()
				if table.find(filteredClientTbl, player) then
					sendSignalToUpdateSub = true
				end
			else
				sendSignalToUpdateSub = true
			end
			--// if the player is meant to receive a replicated copy,
			--// send a replicated copy of the entire subscription
			if sendSignalToUpdateSub then
				local properties = subscription.Properties:GetProperties()
				signal:FireClient(player, CLIENT_SIGNALS.UPDATE_SUBSCRIPTION_PACKAGE, name, properties)
			end
		end))
		connections[subscription] = subConnections
	end
end
--// gets the subscription with the given name from the subscription store
function SubscriptionStoreFunctions:GetSubscription(name: string): Subscription?
	return rawget(self, name)
end
--// removes a subscription from the subscription store
function SubscriptionStoreFunctions:RemoveSubscription(name: string): Subscription?
	local subscription = rawget(self, name)
	rawset(self, name, nil)
	if IS_SERVER and subscription ~= nil then
		local connections = subscriptionConnections[self]
		local subConnections = connections[subscription]
		for _, connection in pairs(subConnections) do
			connection:Disconnect()
		end
		connections[subscription] = nil
		return subscription
	end
	return nil
end


--// constructor
--// creates a new replicator object
--// the replicator object only needs to be created once
function Replicator.new()
	local self = setmetatable({}, {
		__index = ReplicatorFunctions,
	})
	local pself = {}
	--// setup Replicator object
	self.CLIENT_TABLE_FILTER_TYPES = Subscription.CLIENT_TABLE_FILTER_TYPES
	--// setup private Replicator object
	pself.Initialized = false
	pself.Subscriptions = setmetatable({}:: {[string]: Subscription}, {
		__index = SubscriptionStoreFunctions,
	})
	pself.Bindables = {}:: {[string]: BindableEvent}
	pself.SignalListeners = {}:: {[string]: BindableEvent}
	pself.RequestHandlers = {}:: {[string]: ((...any) -> any)}
	pself.Connections = {}:: {RBXScriptConnection}
	--// setup Replicator events
	self.SubscriptionAdded = Func.StoreNewBindable(pself.Bindables, REPLICATOR_BINDABLE_NAMES.SUBSCRIPTION_ADDED)
	self.SubscriptionRemoved = Func.StoreNewBindable(pself.Bindables, REPLICATOR_BINDABLE_NAMES.SUBSCRIPTION_REMOVED)
	--// initialize
	private[self] = pself
	self:Init()
	return self
end


--// replicator server functions
--// creates a subscription with the given name
function ReplicatorFunctions:CreateSubscription(subscriptionName: string, propTable: {[string]: any}?): Subscription
	if IS_SERVER then
		local pself = private[self]
		local bindables = pself.Bindables
		local subscriptionStore = pself.Subscriptions
		--// get the bindable for a subscription added
		local subscriptionAddedBindable = bindables[REPLICATOR_BINDABLE_NAMES.SUBSCRIPTION_ADDED]
		--// check that a subscription with the given name was not already made
		--// if a subscription with the same name was made, error
		if subscriptionStore:GetSubscription(subscriptionName) == nil then
			--// create new subscription and add to subscription store
			--// send a signal to all clients to replicate the subscription
			local newSubscription = Subscription.new(propTable)
			subscriptionStore:AddSubscription(subscriptionName, newSubscription)
			signal:FireAllClients(CLIENT_SIGNALS.CREATE_SUBSCRIPTION, subscriptionName, propTable)
			subscriptionAddedBindable:Fire(newSubscription)
			--// return the subscription
			return newSubscription
		else
			error(string.format(ERRORS.INVALID_SUBSCRIPTION_NAME, "Subscription '" .. tostring(subscriptionName) .. "' has already been created!"))
		end
	else
		error(string.format(ERRORS.SERVER_FUNCTION_ONLY, "Replicator:CreateSubscription()"))
	end
end
--// removes the subscription with the given name
function ReplicatorFunctions:RemoveSubscription(subscriptionName: string)
	if IS_SERVER then
		local pself = private[self]
		local bindables = pself.bindables
		local subscriptionStore = pself.Subscriptions
		--// get the bindable for a subscription removed
		local subscriptionRemovedBindable = bindables[REPLICATOR_BINDABLE_NAMES.SUBSCRIPTION_REMOVED]
		--// check that a subscription with the given name was made
		--// if a subscription with the given name wasn't found, errors
		local subscription = subscriptionStore:GetSubscription(subscriptionName)
		if subscription ~= nil then
			local subscriptionRemoved = subscriptionStore:RemoveSubscription(subscriptionName)
			if subscriptionRemoved then
				signal:FireAllClients(CLIENT_SIGNALS.REMOVE_SUBSCRIPTION, subscriptionName)
				subscriptionRemovedBindable:Fire(subscriptionRemoved)
			end
		else
			error(string.format(ERRORS.INVALID_SUBSCRIPTION, "'" .. tostring(subscriptionName) .. "' is not a valid subscription"))
		end
	else
		error(string.format(ERRORS.SERVER_FUNCTION_ONLY, "Replicator:RemoveSubscription()"))
	end
end
--// sends a signal with the given name to the given client
--// the client can handle the signal via Replicator:GetServerSignal()
--// returns whether the signal was successfully sent to the player
function ReplicatorFunctions:SendSignalToClient(player: Player, signalName: string, ...: any): boolean
	if IS_SERVER then
		local args = {...}
		local success, err = pcall(function()
			signal:FireClient(player, CLIENT_SIGNALS.RECEIVE_CUSTOM_SIGNAL_FROM_SERVER, signalName, unpack(args))
		end)
		return success
	else
		error(string.format(ERRORS.SERVER_FUNCTION_ONLY, "Replicator:SendSignalToClient()"))
	end
end
--// sends a signal with the given name to all clients except the provided client(s)
--// the client can handle the signal via Replicator:GetServerSignal()
function ReplicatorFunctions:SendSignalToAllClientsExcept(plrs: Player | {Player}, signalName: string, ...: any): {[Player]: boolean}
	if IS_SERVER then
		local args = {...}
		--// convert plrs into a table
		if type(plrs) ~= "table" then
			plrs = {plrs}
		end
		--// create success table for players
		local successTbl = {}
		--// iterate through players and send a signal to all players
		--// except the ones provided in the arguments
		for _, player in pairs(Players:GetPlayers()) do
			if not table.find(plrs, player) then
				local success, err = pcall(function()
					signal:FireClient(player, CLIENT_SIGNALS.RECEIVE_CUSTOM_SIGNAL_FROM_SERVER, signalName, unpack(args))
				end)
				successTbl[player] = success
			end
		end
		--// return the success table
		return successTbl
	else
		error(string.format(ERRORS.SERVER_FUNCTION_ONLY, "Replicator:SendSignalToAllClientsExcept()"))
	end
end
--// sends a signal with the given name to all clients
--// the client can handle the signal via Replicator:GetServerSignal()
function ReplicatorFunctions:SendSignalToAllClients(signalName: string, ...: any)
	if IS_SERVER then
		local args = {...}
		signal:FireAllClients(CLIENT_SIGNALS.RECEIVE_CUSTOM_SIGNAL_FROM_SERVER, signalName, unpack(args))
	else
		error(string.format(ERRORS.SERVER_FUNCTION_ONLY, "Replicator:SendSignalToAllClients()"))
	end
end
--// gets a bindable event for listening for client signals
--// when a client signal with the given name is fired, the bindable event
--// returned by this function is also fired
function ReplicatorFunctions:GetClientSignal(signalName: string): RBXScriptSignal
	if IS_SERVER then
		local pself = private[self]
		local signalListeners = pself.SignalListeners
		local listener = signalListeners[signalName]
		if listener == nil then
			listener = Func.StoreNewBindable(signalListeners, signalName)
        else
            listener = listener.Event
		end
		return listener
	else
		error(string.format(ERRORS.SERVER_FUNCTION_ONLY, "Replicator:GetClientSignal()"))
	end
end
--// requests the given client for data
--// will send a signal to the client to request data,
--// then the client will send a signal with the data
--// back to the server
function ReplicatorFunctions:RequestDataFromClient(player: Player, dataKey: string, ...: any): (boolean, any)
	if IS_SERVER then
		local args = {...}
		local success, result = pcall(function()
			return request:InvokeClient(player, CLIENT_REQUESTS.RECEIVE_CUSTOM_REQUEST_FROM_SERVER, dataKey, unpack(args))
		end)
		return success, result
	else
		error(string.format(ERRORS.SERVER_FUNCTION_ONLY, "Replicator:RequestDataFromClient()"))
	end
end
--// handles the data request from the client with the given dataKey
--// this handler will remain idle for the lifespan of the replicator
function ReplicatorFunctions:SetServerRequestHandler(dataKey: string, func: (player: Player, ...any) -> any)
	if IS_SERVER then
		local pself = private[self]
		local requestHandlers = pself.RequestHandlers
		requestHandlers[dataKey] = func
	else
		error(string.format(ERRORS.SERVER_FUNCTION_ONLY, "Replicator:SetServerRequestHandler()"))
	end
end


--// replicator client functions
--// sends a signal with the given name to the server
--// the server can handle the signal via Replicator:GetClientSignal()
function ReplicatorFunctions:SendSignalToServer(signalName: string, ...: any)
	if not IS_SERVER then
		local args = {...}
		signal:FireServer(SERVER_SIGNALS.RECEIVE_CUSTOM_SIGNAL_FROM_CLIENT, signalName, unpack(args))
	else
		error(string.format(ERRORS.CLIENT_FUNCTION_ONLY, "Replicator:SendSignalToServer()"))
	end
end
--// gets a bindable event for listening to server signals
--// when a server signal with the given name is fired, then the bindable event
--// returned by this function is also fired
function ReplicatorFunctions:GetServerSignal(signalName: string): RBXScriptSignal
	if not IS_SERVER then
		local pself = private[self]
		local signalListeners = pself.SignalListeners
		local listener = signalListeners[signalName]
		if listener == nil then
			listener = Func.StoreNewBindable(signalListeners, signalName)
        else
            listener = listener.Event
		end
		return listener
	else
		error(string.format(ERRORS.CLIENT_FUNCTION_ONLY, "Replicator:GetServerSignal()"))
	end
end
--// requests the server for data
--// will send a signal to the server to request data,
--// then the server will send a signal with the data
--// back to the client
function ReplicatorFunctions:RequestDataFromServer(dataKey: string, ...: any): (boolean, any)
	if not IS_SERVER then
		local args = {...}
		local success, result = pcall(function()
			return request:InvokeServer(SERVER_REQUESTS.RECEIVE_CUSTOM_REQUEST_FROM_CLIENT, dataKey, unpack(args))
		end)
		return success, result
	else
		error(string.format(ERRORS.CLIENT_FUNCTION_ONLY, "Replicator:RequestDataFromServer()"))
	end
end
--// handles the data request from the server with the given dataKey
--// this handler will remain idle for the lifespan of the replicator
function ReplicatorFunctions:SetClientRequestHandler(dataKey: string, func: (...any) -> any)
	if not IS_SERVER then
		local pself = private[self]
		local requestHandlers = pself.RequestHandlers
		requestHandlers[dataKey] = func
	else
		error(string.format(ERRORS.CLIENT_FUNCTION_ONLY, "Replicator:SetClientRequestHandler()"))
	end
end


--// replicator replicated functions
--// initializes the replicator
function ReplicatorFunctions:Init()
	local pself = private[self]
	--// check if object has already been initialized
	if not pself.Initialized then
		pself.Initialized = true
	else
		return
	end
	--// create connections for data transmission between
	--// server and client (setup remote events)
	local connections = pself.Connections
	if IS_SERVER then
		--// setup server connection to all clients
		--// sets up the remote event and remote function for the server
		connections[SERVER_CONNECTIONS.CLIENT_SIGNAL_RECEIVED] = signal.OnServerEvent:Connect(function(player: Player, signalName: string, ...: any)
			local func = {
				--// receives a custom signal from the client
				--// fires the bindable event attached to the signal (if there is one)
				--// if there isn't a bindable event attached to the signal, does nothing
				[SERVER_SIGNALS.RECEIVE_CUSTOM_SIGNAL_FROM_CLIENT] = function(customSignalName: string, ...: any)
					local signalListeners = pself.SignalListeners
					local listener = signalListeners[customSignalName]
					if listener ~= nil then
						listener:Fire(player, ...)
					end
				end,
			}
			if func[signalName] ~= nil then
				func[signalName](...)
			end
		end)
		request.OnServerInvoke = function(player: Player, requestName: string, ...: any)
			local func = {
				--// returns the subscription store of the server replicator
				[SERVER_REQUESTS.GET_SUBSCRIPTION_CACHE] = function()
					return pself.Subscriptions
				end,
				--// receives a custom request from the client
				--// returns whatever the handler for the given dataKey returns
				[SERVER_REQUESTS.RECEIVE_CUSTOM_REQUEST_FROM_CLIENT] = function(dataKey: string, ...: any)
					local requestHandlers = pself.RequestHandlers
					local handler = requestHandlers[dataKey]
					if handler ~= nil then
						return handler(player, ...)
					else
						warn(string.format(WARNINGS.SERVER_REQUEST_HANDLER_UNDEFINED, "Did not find server handler for dataKey '" .. tostring(dataKey) .. "'"))
					end
				end,
			}
			if func[requestName] ~= nil then
				return func[requestName](...)
			end
		end
		--// setup subscription store connection table
		local subscriptionStore = pself.Subscriptions
		subscriptionConnections[subscriptionStore] = {}
	else
		--// setup client connection to the server
		--// sets up the remote event and remote function for the client
		connections[CLIENT_CONNECTIONS.SERVER_SIGNAL_RECEIVED] = signal.OnClientEvent:Connect(function(signalName: string, ...: any)
			local func = {
				--// creates a subscription with the given name and property table
				--// stores the subscription in the client subscription store
				[CLIENT_SIGNALS.CREATE_SUBSCRIPTION] = function(subscriptionName: string, propTable: {[string]: any})
					local bindables = pself.Bindables
					local subscriptionAddedBindable = bindables[REPLICATOR_BINDABLE_NAMES.SUBSCRIPTION_ADDED]
					local subscriptions = pself.Subscriptions
					local newSubscription = Subscription.new(propTable)
					subscriptions:AddSubscription(subscriptionName, newSubscription)
					subscriptionAddedBindable:Fire(newSubscription)
				end,
				--// updates the subscription with the given name and changes the given property
				--// should be given a property index and a property value
				[CLIENT_SIGNALS.UPDATE_SUBSCRIPTION] = function(subscriptionName: string, propIndex: string, propVal: any)
					local subscriptions = pself.Subscriptions
					local subscription = subscriptions:GetSubscription(subscriptionName)
					if subscription ~= nil then
						local subscriptionProperties = subscription.Properties:GetProperties()
						subscriptionProperties[propIndex] = propVal
						subscription:UpdateSubscription(subscriptionProperties)
					end
				end,
				--// updates the subscription with the given name and updates all properties
				--// should be given a full property table
				[CLIENT_SIGNALS.UPDATE_SUBSCRIPTION_PACKAGE] = function(subscriptionName, propTable: {[string]: any})
					local subscriptions = pself.Subscriptions
					local subscription = subscriptions:GetSubscription(subscriptionName)
					if subscription ~= nil then
						subscription:UpdateSubscription(propTable)
					end
				end,
				--// removes the subscription with the given name
				--// if the subscription does not exist, does nothing
				[CLIENT_SIGNALS.REMOVE_SUBSCRIPTION] = function(subscriptionName: string)
					local subscriptions = pself.Subscriptions
					local subscription = subscriptions:GetSubscription(subscriptionName)
					if subscription ~= nil then
						local bindables = pself.Bindables
						local subscriptionRemovedBindable = bindables[REPLICATOR_BINDABLE_NAMES.SUBSCRIPTION_REMOVED]
						subscriptions:RemoveSubscription(subscriptionName)
						subscriptionRemovedBindable:Fire(subscription)
					end
				end,
				--// receives a custom signal from the server
				--// fires the bindable event attached to the signal (if there is one)
				--// if there isn't a bindable event attached to the signal, does nothing
				[CLIENT_SIGNALS.RECEIVE_CUSTOM_SIGNAL_FROM_SERVER] = function(customSignalName: string, ...: any)
					local signalListeners = pself.SignalListeners
					local listener = signalListeners[customSignalName]
					if listener ~= nil then
						listener:Fire(...)
					end
				end,
			}
			if func[signalName] ~= nil then
				func[signalName](...)
			end
		end)
		request.OnClientInvoke = function(requestName: string, ...: any)
			local func = {
				--// receives a custom request from the server
				--// returns whatever the handler for the given dataKey returns
				[CLIENT_REQUESTS.RECEIVE_CUSTOM_REQUEST_FROM_SERVER] = function(dataKey: string, ...: any)
					local requestHandlers = pself.RequestHandlers
					local handler = requestHandlers[dataKey]
					if handler ~= nil then
						return handler(...)
					else
						warn(string.format(WARNINGS.CLIENT_REQUEST_HANDLER_UNDEFINED, "Did not find client handler for dataKey '" .. tostring(dataKey) .. "'"))
					end
				end,
			}
			if func[requestName] ~= nil then
				return func[requestName](...)
			end
		end
		--// begin loop for requesting data from the server
		--// this loop repeats the amount of times specified in the settings module
		local r_cur, r_max = 0, SETTINGS.MAX_SERVER_DATA_REQUEST_RETRIES
		local success, subscriptions = nil, nil
		while r_cur < r_max + 1 do
			--// request the subscriptions already made from the server
			--// the subscriptions should still have the properties attached to them
			success, subscriptions = pcall(function()
				return request:InvokeServer(SERVER_REQUESTS.GET_SUBSCRIPTION_CACHE)
			end)
			--// if the subscriptions were successfully returned
			--// then break the loop and continue to storing in the client
			if success and subscriptions ~= nil then
				break
			end
			r_cur += 1
			--// wait for another retry
			task.wait(SETTINGS.DATA_RETRY_WAIT_TIME)
		end
		--// check if the subscriptions successfully returned
		--// store the subscriptions in the client to finalize the replication
		if success and subscriptions ~= nil then
			local subscriptionStore = pself.Subscriptions
			for name, sub in pairs(subscriptions) do
				subscriptionStore:AddSubscription(name, Subscription.new(sub.Properties))
			end
		else
			error(string.format(ERRORS.INITIAL_REPLICATION_FAILED, "Unable to get initial subscriptions from the server!"), 0)
		end
	end
end
--// waits for the subscription with the given name
--// if the total time waited is greater than the max
--// subscription wait time, errors
function ReplicatorFunctions:WaitForSubscription(subscriptionName: string): Subscription?
	local pself = private[self]
	local subscriptions = pself.Subscriptions
	--// begin wait loop for waiting for the subscription
	local t_cur, t_fin = 0, SETTINGS.SUBSCRIPTION_MAX_WAIT_TIME
	while t_cur < t_fin do
		t_cur += task.wait(SETTINGS.SUBSCRIPTION_WAIT_INTERVAL)
		local subscription = subscriptions:GetSubscription(subscriptionName)
		if subscription ~= nil then
			return subscription
		end
	end
	--// if the subscription was not found, print a warning and return nil
	warn(string.format(WARNINGS.MAX_SUBSCRIPTION_YIELD_REACHED, t_fin, t_cur))
	return nil
end
--// gets the subscription with the given name
--// if the subscription for the given name does not exist, returns nil
--// optional yield argument to wait for the subscription
function ReplicatorFunctions:GetSubscription(subscriptionName: string, yield: boolean?): Subscription?
	local pself = private[self]
	local subscriptions = pself.Subscriptions
	--// if yield, the wait for the subscription, otherwise return the subscription
	return yield and self:WaitForSubscription(subscriptionName) or subscriptions:GetSubscription(subscriptionName)
end


--// return
return Replicator.new()