--// services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// modules
local EZReplicator = require(ReplicatedStorage:WaitForChild("EZReplicator"))

--// create subscription
local MAIN_SUBSCRIPTION = EZReplicator:CreateSubscription("MAIN", {
    Foo = "Bar",
    Hotel = "Trivago",
})

--// wait for a bit so that the client gets the subscription
task.wait(5)

--// add some new properties and change some property values
--// this should replicate the properties in the client
--// it also fires a signal in the client
MAIN_SUBSCRIPTION:AddProperty("New Property", "Something in here")
MAIN_SUBSCRIPTION:AddProperty("New Property 2", "Something else in here")
MAIN_SUBSCRIPTION:SetProperty("Foo", "Wassup homie")