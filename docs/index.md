# Home

EZReplicator is a module that makes it easy to replicate objects, and send
signals between the server and client. The purpose of the module is to
provide reliable server-client replication without having to deal with the 
complexities of setting up an environment to replicate between server and client.

With EZReplicator, you can create `Subscriptions`. A `Subscription` is a set of data
that is created in the server, but automatically replicated to each client connected
to the server. Each time a property inside a `Subscription` is changed, the property is
automatically replicated to each client instantly after being changed.

The benefits of using EZReplicator for replication purposes in your experience are:

- **Easy to learn** - EZReplicator is a module that is very easy to learn. It is meant to be beginner friendly, using mostly Getter and Setter functions
- **Reliable, easy to fix errors** - EZReplicator is meant to be a reliable module. It outputs custom error messages, making it easy to spot and fix errors

> **Disclaimer**: Although EZReplicator has been thoroughly tested, EZReplicator has not been used in any large scale Roblox projects before. Any errors or issues found in the module should be reported.