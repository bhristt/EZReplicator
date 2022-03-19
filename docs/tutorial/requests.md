EZReplicator also comes with support for requesting data from the server and client. Requesting data is more time consuming than sending signals, but it is useful for when the server needs a value from a client, or when the client needs a value from the server. 

In general, it is recommended to use EZReplicator to request data from the server **ONLY**. Anything in the client can be changed by external sources, so data from the client is not generally trusted.

---

## Requesting Data from the Server

Requesting for data from the server in a LocalScript is done by using `EZReplicator:RequestDataFromServer()`. This function sends a signal to the server, checks to see if the server has a handler for the given request, then returns the data requested.

A handler for the request can be made in the server. In order for data to be requested, there must be a handler made for the request on the appropriate Script/LocalScript. For requesting data from the server, a handler must be made on the server. This can be done by using `EZReplicator:SetServerRequestHandler()`.

To create a handler, in a Script,

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EZReplicator = require(ReplicatedStorage:WaitForChild("EZReplicator"))

--// creates a handler for the "MAIN_REQUEST" request
EZReplicator:SetServerRequestHandler("MAIN_REQUEST", function(player)
    return "This is what " .. tostring(player.DisplayName) .. "'s client requested!"
end)
```

The above handler will return a string to the client that requested the data from the "MAIN_REQUEST" request. For example, if a player named "bhristt" was requesting data from the "MAIN_REQUEST" request server handler, then the data returned would be the string "This is what bhristt's client requested!"

Now the question is, "how do we request data from the server?" Let's make some example code. In the client,

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EZReplicator = require(ReplicatedStorage:WaitForChild("EZReplicator"))

--// requests data from the server defined by the "MAIN_REQUEST" request handler
local playerString = EZReplicator:RequestDataFromServer("MAIN_REQUEST")

--// print the request result
print(playerString)
```

The code above will request data from the client defined by the "MAIN_REQUEST" server handler. Then, the received data will be printed to the console. The output should look something like:

```
This is what bhristt's client requested!
```

---

## Requesting Data from the Client

Requesting data from the client is a very similar process to requesting data from the server. The only difference when it comes to requesting data from the client is that the handler for the request must be made on the client side. We can do this by using `EZReplicator:SetClientRequestHandler()`.

To create a handler for requesting data from the client, in a LocalScript,

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EZReplicator = require(ReplicatedStorage:WaitForChild("EZReplicator"))

--// create a handler named "GIVE_ME_A_NUMBER"
EZReplicator:SetClientRequestHandler("GIVE_ME_A_NUMBER", function()
    return math.random(1, 10)
end)
```

The above code creates a request handler in the client named "GIVE_ME_A_NUMBER". When the server requests this data from the client, a random number between 1 and 10 should be returned.

Similarly to how we requested data from the server, we can request data from the client using `EZReplicator:RequestDataFromClient()`. In a Script,

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local EZReplicator = require(ReplicatedStorage:WaitForChild("EZReplicator"))
```