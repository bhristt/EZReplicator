EZReplicator comes with functions to send signals and request data from both the server and the client. Sending signals is simple, and requesting data is also very simple.

---

## Sending Signals from the Client

Let's consider a scenario where we want to send a signal to the server every time a player clicks a button. This can be done by using `EZReplicator:SendSignalToServer()` to send a signal every time the button is clicked. We can set this signal up in the client like so:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EZReplicator = require(ReplicatedStorage:WaitForChild("EZReplicator"))

local button = script.Parent:FindFirstChild("TextButton")

button.MouseButton1Down:Connect(function()
    --// send a signal to the server that the player clicked the button
    EZReplicator:SendSignalToServer("PlayerClickedButton")
end)
```

---

## Listening for Client Signals in the Server

Now that the client sends a signal every time the button is clicked, how do we listen for that signal in the server? This can be done by using `EZReplicator:GetClientSignal()` to create a connection to the signal.

For example, in the server,

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EZReplicator = require(ReplicatedStorage:WaitForChild("EZReplicator"))

--// create a connection to the signal
EZReplicator:GetClientSignal("PlayerClickedButton"):Connect(function(player)
    print(tostring(player.DisplayName) .. " clicked a button!")
end)
```

The code above will create a connection to the Client Signal named "PlayerClickedButton". Then, when it's fired, will print the player's name followed by the text " clicked a button!". If a player named "Player1" clicks the button three times, then the output will look like

```
Player1 clicked a button!
Player1 clicked a button!
Player1 clicked a button!
```

---

## Sending Signals from the Server

For sending signals from the server to the client, there are three functions for doing so. 

1. The first function is `EZReplicator:SendSignalToClient()`. This function sends a signal to the provided client **ONLY**. It is useful when it comes to sending signals to specific players. This being said, let's consider a scenario where a signal must be sent to 1 random player to tell them a secret message. In the server,
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local EZReplicator = require(ReplicatedStorage:WaitForChild("EZReplicator"))

local plrs = Players:GetPlayers()
local randPlr = plrs[math.random(1, #plrs)]

--// sends a signal to a random player with the signal name "SECRET_MESSAGE"
--// the first argument of the signal is the message "This is a secret message!"
EZReplicator:SendSignalToClient(randPlr, "SECRET_MESSAGE", "This is a secret message!")
```

2. Let's consider another scenario where a signal must be sent to all players at the same time. In this case, we can use the function `EZReplicator:SendSignalToAllClients()`. This function sends a signal to all the clients connected to the server. In the server,
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EZReplicator = require(ReplicatedStorage:WaitForChild("EZReplicator"))

--// sends a signal to all players with the signal name "EXPOSED_MESSAGE"
--// the first argument of the signal is the message "This is an exposed message!"
EZReplicator:SendSignalToAllClients("EXPOSED_MESSAGE", "This is an exposed message!")
```

3. For the final scenario, let's consider a case where we want to send a signal to all players except some players. In this case, we can use the function `EZReplicator:SendSignalToAllClientsExcept()`. This function sends a signal to all players connected to the server except for the provided player(s). In the server,
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local EZReplicator = require(ReplicatedStorage:WaitForChild("EZReplicator"))

--// create an ignore list of players
--// for this example, let's say this game always has
--// more than 4 people playing
local plrs = Players:GetPlayers()
local plrsIgnore = {}
for i = 1, 4 do
    table.insert(plrsIgnore, table.remove(plrs, math.random(1, #plrs)))
end

--// sends a signal to all players except the ones
--// that were placed in the ignore list
EZReplicator:SendSignalToAllClientsExcept(plrsIgnore, "HIDDEN_MESSAGE", "This is a message that is hidden to some players!")
```

---

## Listening for Server Signals in the Client
Similar to how we listen for Signals in the Server from the Client, we can listen to Signals in the Client from the Server. This is done using the function `EZReplicator:GetServerSignal()` to create a connection to the signal.

For this example, let's say we were continuing case 2 of sending signals to the client from the server. In the client,

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EZReplicator = require(ReplicatedStorage:WaitForChild("EZReplicator"))

--// create a connection to the signal
EZReplicator:GetServerSignal("EXPOSED_MESSAGE"):Connect(function(exposedMessage)
    print(exposedMessage)
end)
```

The code above will create a connection to the Server Signal named "EXPOSED_MESSAGE". It also has a parameter called "exposedMessage", which contains the exposed message that was sent to the client from the server. The exposed message is then output to the console. The output would look something like

```
This is an exposed message!
```

---