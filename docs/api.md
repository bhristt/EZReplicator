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
Creates a new `Subscription` object with the given name and initial property table. If the initial property table is `nil`, defaults to `{}`. This also fired the `EZReplicator.SubscriptionAdded` RBXScriptSignal.

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
) --> [boolean]
```