extends Node

## player instance to spawn.
@export var LOW_LEVEL_NETWORK_PLAYER: PackedScene
## players connected to the same server.
var _connectedPlayers: Dictionary[int, ThirdPersonPlayer] = {}

func _ready() -> void:
	# creating players
	LowLevelNetworkHandler.on_peer_connected.connect(spawn_player)
	ClientNetworkGlobals.handle_local_id_assignment.connect(spawn_player)
	ClientNetworkGlobals.handle_remote_id_assignment.connect(spawn_player)

	# removing players
	LowLevelNetworkHandler.on_disconnected_from_server.connect(remove_player)
	LowLevelNetworkHandler.on_peer_disconnected.connect(remove_player)
	ClientNetworkGlobals.handle_local_id_unassignment.connect(remove_player)
	ClientNetworkGlobals.handle_remote_id_unassignment.connect(remove_player)

## removes a client player from game and if removing user also clears all connected players and resets client id
func remove_player(id: int) -> void:
	# fetch player from _connected players
	var player := _connectedPlayers[id]
	PA_Debug.log("client_id (%s): removing player (%s):(%s)" % [ClientNetworkGlobals.id,id,player])
	# remove from _Connected players and free player.
	_connectedPlayers.erase(id)
	player.queue_free()

	# if we are removing the auth client 
	if id == ClientNetworkGlobals.id:
		# remove all connected players from current server and reset client id.
		for connID in _connectedPlayers:
			PA_Debug.log("client_id (%s): removing player (%s):(%s)" % [ClientNetworkGlobals.id,connID, _connectedPlayers[connID]])
			_connectedPlayers[connID].queue_free()
		_connectedPlayers.clear()
		ClientNetworkGlobals.id = -1

## spawn a client player and add to list of connected players.
func spawn_player(id: int) -> void:
	var player = LOW_LEVEL_NETWORK_PLAYER.instantiate()
	call_deferred("setupPlayer", player, id)
	call_deferred("add_child", player)
	_connectedPlayers[id] = player
	PA_Debug.log("client_id (%s): adding player (%s):(%s)" % [ClientNetworkGlobals.id,id,_connectedPlayers[id]])

## sets up player data on spawn.
func setupPlayer(player: ThirdPersonPlayer, id: int) -> void:
	player._manager.assigned_id = id
	player.name = str(id) # Optional
