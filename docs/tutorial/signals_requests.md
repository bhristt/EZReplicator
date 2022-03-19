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

The code above will create a connection to the Client Signal named "PlayerClickedButton", then, when it's fired, will print the player's name followed by the text " clicked a button!". If a player named "Player1" clicks the button three times, then the output will look like

```
Player1 clicked a button!
Player1 clicked a button!
Player1 clicked a button!
```

---

## Sending Signals from the Server

For sending signals from the server to the client, there are three methods of doing so. 