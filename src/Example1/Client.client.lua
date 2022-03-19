--// services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// modules
local EZReplicator = require(ReplicatedStorage:WaitForChild("EZReplicator"))

--// wait for main subscription
local MAIN_SUBSCRIPTION = EZReplicator:WaitForSubscription("MAIN")

--// detect when a property has been changed in the MAIN subscription
--// this basically logs any changes made to the subscription
MAIN_SUBSCRIPTION.PropertyChanged:Connect(function(propIndex, propValue)
    print(tostring(propIndex) .. ": " .. tostring(propValue))
end)