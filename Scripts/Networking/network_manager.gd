## This Script is responsible for storing the network parameters for a player instance 
## and providing utility functions for checking network authority and ownership.
class_name NetworkManager extends Node

## if this instance is the server (host)
var is_server: bool:
	get:
		return LowLevelNetworkHandler.is_server
## Whether this client is the authority (owner) of this instance.
var is_authority: bool:
	get:
		return assigned_id == ClientNetworkGlobals.id
## The peer ID of the client that owns this instance.
var assigned_id: int