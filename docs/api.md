!!! notice
    Requiring the EZReplicator module from the **Client** will request the Server to send a table of all the `Subscription` objects made. If this request fails, it will retry the given amount of times specified in the **Settings** module inside the EZReplicator module.

---

## EZReplicator Properties
### EZReplicator.CLIENT_TABLE_FILTER_TYPES
```lua
EZReplicator.CLIENT_TABLE_FILTER_TYPES    [Dictionary]
```
`EZReplicator.CLIENT_TABLE_FILTER_TYPES` is a dictionary containing the valid filter types of the `Subscription` client table. The client table filter type of a `Subscription` can be changed by changing `Subscription.ClientTableFilterType`. `EZReplicator.CLIENT_TABLE_FILTER_TYPES` is the dictionary:
```lua
EZReplicator.CLIENT_TABLE_FILTER_TYPES = {
    WHITELIST = "WHITELIST",
    BLACKLIST = "BLACKLIST",
}
```
### EZReplicator.SubscriptionAdded
```lua
EZReplicator.SubscriptionAdded    [RBXScriptSignal] (newSubscription [Subscription])
```
This RBXScriptSignal is fired when a new `Subscription` is added to the EZReplicator Subscription store.
### EZReplicator.SubscriptionRemoved
```lua
EZReplicator.SubscriptionRemoved    [RBXScriptSignal] (subscriptionRemoved [Subscription])
```
This RBXScriptSignal is fired when a `Subscription` has been removed from the EZReplicator Subscription store.

---

## EZReplicator Server Functions
!!! warning
    EZReplicator server functions must be used in a server Script **only**! Attempting to use EZReplicator server functions in the client will result in an error!

### EZReplicator:CreateSubscription()
```lua
EZReplicator:CreateSubscription(
    subscriptionName,
    propTable
) --> [Subscription]
-- subscriptionName    [string] -- Subscription name
-- propTable    [table]: -- Allows initialization of Subscription with custom properties
--  {
--    -- property names must be strings, property values can be anything
--    [string]: [any]
--  }
-- OR
-- propTable    [nil]
```
Creates a new `Subscription` object with the given name and initial property table. If the initial property table is `nil`, defaults to `{}`. This also fires the `EZReplicator.SubscriptionAdded` RBXScriptSignal.

!!! warning
    If there is a `Subscription` in the EZReplicator Subscription store with the same name as the given Subscription name, then this function will throw an error. It is important that, when creating `Subscriptions`, to name each different `Subscription` a different name.

### EZReplicator:RemoveSubscription()
```lua
EZReplicator:RemoveSubscription(
    subscriptionName
) --> nil
-- subscriptionName    [string] -- The name of the Subscription to remove
```
Removes the `Subscription` with the given name. This also fires the `EZReplicator.SubscriptionRemoved` RBXScriptSignal.

!!! warning
    If a `Subscription` with the given name is **NOT** found, then the this function will throw an error. Make sure that your code keeps track of `Subscription` objects that are made and deleted. You can check if a `Subscription` with the given name exists by using `EZReplicator:GetSubscription()`

### EZReplicator:SendSignalToClient()
```lua
EZReplicator:SendSignalToClient(
    player,
    signalName,
    ...
) --> [boolean]
-- player    [Player] -- The player that the server is sending the signal to
-- signalName    [string] -- The name of the signal being sent to the client
-- ...    [any] -- The arguments being passed to the signal (supports multiple arguments)
```
Sends a signal with the given name to the given client. Optional arguments may be passed to the signal. If the signal was successfully sent, the function returns `true`. If the signal sending process was not successul, the function returns `false`.
### EZReplicator:SendSignalToAllClientsExcept()
```lua
EZReplicator:SendSignalToAllClientsExcept(
    plrs,
    signalName,
    ...
) --> [table]:
--  {
--    -- A table which shows which signals were successful for which players
--    [Player]: [boolean]
--  }
--
--
-- plrs    [table]:
--  {
--    -- A regular numbered list of players
--    [number]: [Player]
--  }
-- OR
-- plrs    [Player] -- A single player if a list of players is not required
-- signalName    [string] -- The name of the signal being sent to the client(s)
-- ...    [any] -- The arguments being passed to the signal (supports multiple arguments)
```
Sends a signal with the given name to all clients except for the given players. Optional arguments may be passed to the signal. Returns a table with `Player` indices whos respective values describe whether the signal was successfully sent to the respective client or not.

!!! notice
    This function sends a signal to all other players, so the success table that is returned should have indices with all players but the provided players. The success table can be used to send a signal to the unsuccessfully signaled clients.

### EZReplicator:SendSignalToAllClients()
```lua
EZReplicator:SendSignalToAllClients(
    signalName,
    ...
) --> nil
-- signalName    [string] -- The name of the signal being sent to the client
-- ...    [any] -- The arguments being passed to the signal (supports multiple arguments)
```
Sends a signal with the given name to all clients connected to the server. Optional arguments may be passed to the signal. Does not return anything.

!!! notice
    This function uses the default [RemoteEvent:FireAllClients()](https://developer.roblox.com/en-us/api-reference/function/RemoteEvent/FireAllClients#:~:text=The%20FireAllClients%20function%20fires%20the,connected%20to%20an%20OnClientEvent%20event.) function, not a custom fire all clients function. This function is prone to errors, so I may add a custom procedure in the future for success checking.

### EZReplicator:GetClientSignal()
```lua
EZReplicator:GetClientSignal(
    signalName
) --> [RBXScriptSignal] (player [Player], ... [any])
-- signalName    [string] -- The name of the signal requested
```
Gets an `RBXScriptSignal` for the client signal with the given name. When the client sends a signal to the server with the given name, the signal received by this function will fire.
### EZReplicator:RequestDataFromClient()
```lua
EZReplicator:RequestDataFromClient(
    player,
    dataKey,
    ...
) --> [boolean, any]
-- player    [Player] -- The client which the server is requesting data from
-- dataKey    [string] -- The dataKey of the data request
-- ...    [any] -- The arguments passed along with the request (supports multiple arguments)
```
Requests data from the given dataKey from the given client. Optional arguments may be passed to the request. Returns whether the request was successful as the first return argument, and the data as the second return argument.

!!! notice
    The success and data return arguments are received from the pcall function. This being said, it is important to note that if the success return argument of the function is false, then the data return argument of the function will be an error message string, **not** `nil`.

### EZReplicator:SetServerRequestHandler()
```lua
EZReplicator:SetServerRequestHandler(
    dataKey,
    func
) --> nil
-- dataKey    [string] -- The dataKey of the server request
-- func    [function] (player [Player], ... [any]) --> [any] -- A function in the server that returns the data requested from the client
```
Sets the server request handler for the given dataKey to the given handler function. The given handler function must return the value that is being requested by the client.

!!! notice
    This function does not check for overwriting dataKeys. If a dataKey has already been defined, and this function gets called again using the same dataKey, the previous dataKey handler gets overwritten with the new dataKey handler.

---

## EZReplicator Client Functions
!!! warning
    EZReplicator client functions can be used in a LocalScript **only**! Attempting to use EZReplicator client functions in the server will result in an error!

### EZReplicator:SendSignalToServer()
```lua
EZReplicator:SendSignalToServer(
    signalName,
    ...
) --> nil
-- signalName    [string] -- The name of the signal to send to the server
-- ...    [any] -- The arguments passed to the signal (supports multiple arguments)
```
Sends a signal with the given name to the server. Optional arguments may be passed to the signal. Does not return anything.
### EZReplicator:GetServerSignal()
```lua
EZReplicator:GetServerSignal(
    signalName
) --> [RBXScriptSignal] (... [any])
-- signalName    [string] -- The name of the signal requested
```
Gets an `RBXScriptSignal` for the server signal with the given name. When the server sends a signal to the client with the given name, the signal received by this function will fire.
### EZReplicator:RequestDataFromServer()
```lua
EZReplicator:RequestDataFromServer(
    dataKey,
    ...
) --> [boolean, any]
-- dataKey    [string]
-- ...    [any]
```
Requests data from the given dataKey from the server. Optional arguments may be passed to the request. Returns whether the request was successful as the first return argument, and the data as the second return argument.

!!! notice
    The success and data return arguments are received from the pcall function. This being said, it is important to note that if the success return argument of the function is false, then the data return argument of the function will be an error message string, **not** `nil`.

### EZReplicator:SetClientRequestHandler()
```lua
EZReplicator:SetClientRequestHandler(
    dataKey,
    func
) --> nil
-- dataKey    [string]
-- func    [function] (... [any])
```
Sets the client request handler for the given dataKey to the given handler function. The given handler function must return the value that is being requested by the server.

!!! notice
    This function does not check for overwriting dataKeys. If a dataKey has already been defined, and this function gets called again using the same dataKey, the previous dataKey handler gets overwritten with the new dataKey handler.

---

## EZReplicator Universal Functions
### EZReplicator:Init()
```lua
EZReplicator:Init() --> nil
```
Initializes the EZReplicator object. This is a function called once at the creation of the EZReplicator object. This function does nothing after it is called the first time.
### EZReplicator:WaitForSubscription()
```lua
EZReplicator:WaitForSubscription(
    subscriptionName
) --> [Subscription] OR nil
-- subscriptionName    [string]
```
Waits for the `Subscription` with the given name. If the function yields for more than the time given in the Settings module, then the function returns nil.

!!! warning
    If the function happens to yield for more than the yield time specified in the Settings module, the function will print a warning message to the console.

### EZReplicator:GetSubscription()
```lua
EZReplicator:GetSubscription(
    subscriptionName,
    yield
) --> [Subscription] or nil
-- subscriptionName    [string]
-- yield    [boolean]
-- OR
-- yield    [nil]
```
Gets the `Subscription` with the given name. Optional yield parameter for waiting for the `Subscription` instead (which does the same thing as `EZReplicator:WaitForSubscription()`). If yield is not specified, defaults to `false`.

---

## Subscription Properties
### Subscription.Properties
```lua
Subscription.Properties    [table]:
--  {
--    -- a table with string indices and any values
--    [string]: [any]
--  }
```
Contains the properties of the `Subscription`.
### Subscription.StoreTablePropertyAsPointer
```lua
Subscription.StoreTablePropertyAsPointer    [boolean]
```
An option to store table value properties in the property table as pointers referencing the same table, or clones of the provided tables. If this is set to true, will store table property values as pointers instead of making clones of the given tables.
### Subscription.UpdateAllSubscriptionsOnPropChanged
```lua
Subscription.UpdateAllSubscriptionsOnPropChanged    [boolean]
```
An option to update the `Subscription` for all clients connected to the server. If this is set to false, you must specify the clients that will be automatically updated when the `Subscription` is changed in the server.
### Subscription.ClientTableFilterType
```lua
Subscription.ClientTableFilterType    [string] "WHITELIST", or "BLACKLIST"
```
The filter type of the client table of the `Subscription`. You can set this by typing a string, or using the `EZReplicator.CLIENT_TABLE_FILTER_TYPES` dictionary. For example,
```lua
Subscription.ClientTableFilterType = "WHITELIST"
-- OR
Subscription.ClientTableFilterType = EZReplicator.CLIENT_TABLE_FILTER_TYPES.WHITELIST
```
### Subscription.PropertyAdded
```lua
Subscription.PropertyAdded    [RBXScriptSignal] (propIndex [string], propValue [any])
```
An RBXScriptSignal used for signaling that a new property has been added to the `Subscription`.
### Subscription.PropertyChanged
```lua
Subscription.PropertyChanged    [RBXScriptSignal] (propIndex [string], propValue [any])
```
An RBXScriptSignal used for signaling that a property in the `Subscription` has been changed.
### Subscription.PropertyRemoved
```lua
Subscription.PropertyRemoved    [RBXScriptSignal] (propIndex [string])
```
An RBXScriptSignal used for signaling that a property in the `Subscription` was removed.

---

## Subscription Server Functions
### Subscription:AddProperty()
```lua
Subscription:AddProperty(
    propIndex,
    propValue
) --> nil
-- propIndex    [string]
-- propValue    [any]
```
Adds a property to the `Subscription` with the given index and the given value.

!!! warning
    Attempting to add a property to the `Subscription` with an already existing index results in an error. It is important to keep track of property indices!

!!! failure
    Do not attempt to add properties by adding indices to the `Subscription.Properties` table directly! This will result in an error.

### Subscription:SetProperty()
```lua
Subscription:SetProperty(
    propIndex,
    propValue
) --> nil
-- propIndex    [string]
-- propValue    [any]
```
Sets the value of the property with the given index to the given value.

!!! failure
    Attempting to change the value of a property by changing the `Subscription.Properties` table directly will result in unintended behavior!

### Subscription:RemoveProperty()
```lua
Subscription:RemoveProperty(
    propIndex
) --> nil
-- propIndex    [string]
```
Removes the property with the given index from the `Subscription`.

!!! warning
    If there is not a property with the given index in the `Subscription`, then an error will be thrown. It is important to keep track of property indices.

!!! failure
    Attempting to remove a property from the `Subscription` by changing the `Subscription.Properties` table directly will result in unintended behavior!

### Subscription:AddPlayerToClientTbl()
```lua
Subscription:AddPlayerToClientTbl(
    player
) --> nil
-- player    [Player]
```
Adds a player to the `Subscription` client table. If the client table already contains the player, then this function does nothing.
### Subscription:GetClientTbl()
```lua
Subscription:GetClientTbl() --> [table]:
--  {
--    [number]: [Player]
--  }
```
Gets a copy of the client table.
### Subscription:GetFilteredClientTbl()
```lua
Subscription:GetFilteredClientTbl() --> [table]:
--  {
--    [number]: [Player]
--  }
```
Gets a copy of the filtered client table. Filtered refers to the `Subscription.ClientTableFilterType` property.
### Subscription:IterateThroughFilteredCTbl()
```lua
Subscription:IterateThroughFilteredCTbl(
    func
) --> nil
-- func    [function] (plr [Player]) --> nil
```
Iterates through the filtered client table and calls the given function, passing the player in the iteration as the argument.
### Subscription:RemovePlayerFromClientTbl()
```lua
Subscription:RemovePlayerFromClientTbl(
    player
) --> nil
-- player    [Player]
```
Removes the given player from the `Subscription` client table. If the given player is already not in the client table, does nothing.

---

## Subscription Client Functions
### Subscription:UpdateSubscription()
```lua
Subscription:UpdateSubscription(
    propTable
) --> nil
-- propTable    [table]:
--  {
--    [string]: [any]
--  }
```
Sets the property table of the `Subscription` to the give property table. As it does this, it fires the changed signals for each property that is changed.

!!! notice
    This function should not be used at all if the `Subscription` is being replicated on the client. It is intended to only be used by the EZReplicator module for updating `Subscription` properties!

---

## Subscription Universal Functions
### Subscription:Init()
```lua
Subscription:Init() --> nil
```
Initializes the `Subscription` object. This is a function called once at the creation of the `Subscription` object. This function does nothing after it is called the first time.
### Subscription:GetProperty()
```lua
Subscription:GetProperty(
    propIndex
) --> [any]
-- propIndex    [string]
```
Gets the property with the given index from the `Subscription`.

!!! warning
    If the given property index does not exist in the `Subscription`, then this function will throw an error.

### Subscription:GetPropertyChangedSignal()
```lua
Subscription:GetPropertyChangedSignal(
    propIndex
) --> [RBXScriptSignal]
-- propIndex    [string]
```
Gets an `RBXScriptSignal` for the property in the `Subscription` with the given index.

!!! notice
    This function will not throw an error if a signal for a non-existing property is requested.

---