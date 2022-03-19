Basic usage of this module is very simple. A replication environment can be set up by using a Script parented to *ServerScriptService*, and a LocalScript that is a descendant of a *Player* object. 

Placing a LocalScript in *ReplicatedFirst* will also suffice.

---

## Server sided code
In the Script placed in *ServerScriptService*, the following code will create a `Subscription` called "MAIN".

```lua
--// assuming EZReplicator is placed in ReplicatedStorage,
--// services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// EZReplicator module
local EZReplicator = require(ReplicatedStorage:WaitForChild("EZReplicator"))

--// create a new subscription "MAIN" with initial properties
--// this subscription contains the properties Foo and Hotel
local MAIN_SUBSCRIPTION = EZReplicator:CreateSubscription("MAIN", {
    Foo = "Bar",
    Hotel = "Trivago",
})
```

---

## Client sided code
In the LocalScript, the following code will wait for the `Subscription` that was made in the server, and print out its properties.

```lua
--// assuming EZReplicator is placed in ReplicatedStorage,
--// services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// EZReplicator module
local EZReplicator = require(ReplicatedStorage:WaitForChild("EZReplicator"))

--// wait for the "MAIN" subscription
local MAIN_SUBSCRIPTION = EZReplicator:WaitForSubscription("MAIN")

--// read out the properties of the "MAIN" subscription
local mainSubscriptionProperties = MAIN_SUBSCRIPTION.Properties:GetProperties()
for i, v in pairs(mainSubscriptionProperties) do
    print(tostring(i) .. ": " .. tostring(v))
end
```

If we were to play test in game with the Script and LocalScript having this code, the output would look something like

```
Foo: Bar
Hotel: Trivago
```

---

## Adding and Removing Subscription properties
Let's consider a scenario where a `Subscription` has already been initialized. How do we add properties to the `Subscription`, and what are the limitations when it comes to adding properties?

Adding properties to a `Subscription` is easy. To add a property to the `Subscription`, we can use the function `Subscription:AddProperty()`. In the server script,

```lua
--// initialize the MAIN subscription
local MAIN_SUBSCRIPTION = EZReplicator:CreateSubscription("MAIN", {
    Foo = "Bar",
    Hotel = "Trivago",
})

--// add more properties to the MAIN subscription
--// adds the property named "Goofy" with the value "Ahhhh"
MAIN_SUBSCRIPTION:AddProperty("Goofy", "Ahhhh")
--// adds the property named "NinePlusTen" with the value 21
MAIN_SUBSCRIPTION:AddProperty("NinePlusTen", 21)
```

The code above adds two properties to the "MAIN" `Subscrpition`. When a new property is added to a `Subscription`, an event is fired on the Client, but the value is automatically replicated to all clients. Trying to get the values of the new added properties on the client would not throw any errors.

To remove properties, we can use the function `Subscription:RemoveProperty()`. In the server script,

```lua
--// add more properties to the MAIN subscription
--// adds the property named "Goofy" with the value "Ahhhh"
MAIN_SUBSCRIPTION:AddProperty("Goofy", "Ahhhh")
--// adds the property named "NinePlusTen" with the value 21
MAIN_SUBSCRIPTION:AddProperty("NinePlusTen", 21)

--// what if we want to remove the NinePlusTen property?
MAIN_SUBSCRIPTION:RemoveProperty("NinePlusTen")
```

The above code removes the "NinePlusTen" property from the `Subscription`. Once again, this sends a signal to the Client, but also automatically replicates to each client. It is important to note that `Subscription:AddProperty()` and `Subscription:RemoveProperty()` are **server only functions**! They cannot be used on the client.

---

## Changing Subscription properties
Changing `Subscription` properties is also very easy. The subscription comes with the function `Subscription:SetProperty()`. Using this function, we can change the values of each property.

For example, in the server script,

```lua
--// initialize the MAIN subscription
local MAIN_SUBSCRIPTION = EZReplicator:CreateSubscription("MAIN", {
    Foo = "Bar",
    Hotel = "Trivago",
})

--// change the value of Foo to Cat
MAIN_SUBSCRIPTION:SetProperty("Foo", "Cat")
```

The `Subscription:SetProperty()` function is a **server only function**! It cannot be used on the client.