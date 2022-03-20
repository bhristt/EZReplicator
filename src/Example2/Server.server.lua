local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local EZReplicator = require(ReplicatedStorage:WaitForChild("EZReplicator"))

local MAIN_SUBSCRIPTION = EZReplicator:CreateSubscription("MAIN", {
    TestValue = 1,
})
MAIN_SUBSCRIPTION.UpdateAllSubsOnPropChanged = false
MAIN_SUBSCRIPTION.ClientTableFilterType = EZReplicator.CLIENT_TABLE_FILTER_TYPES.WHITELIST



function playerAdded(player)
    MAIN_SUBSCRIPTION:AddPlayerToClientTbl(player)
end



Players.PlayerAdded:Connect(playerAdded)