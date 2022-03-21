## EZReplicator
### EZReplicator.SubscriptionAdded
```lua
EZReplicator.SubscriptionAdded    [RBXScriptSignal]
```
This RBXScriptSignal is fired when a new `Subscription` is added to the EZReplicator Subscription store. Connecting to it requires a function with the following format:
```lua
EZReplicator.SubscriptionAdded:Connect(function(newSubscription: Subscription)
    --// code
end)
```
### EZReplicator.SubscriptionRemoved
```lua
EZReplicator.SubscriptionRemoved    [RBXScriptSignal]
```
This RBXScriptSignal is fired when a `Subscription` has been removed from the EZReplicator Subscription store. Connecting to it requires a function with the following format:
```lua
EZReplicator:SubscriptionRemoved:Connect(function()
    --// code
end)
```