extends Node

@export var LOW_LEVEL_NETWORK_PLAYER: PackedScene

func _ready() -> void:
	LowLevelNetworkHandler.on_peer_connected.connect(spawn_player)
	ClientNetworkGlobals.handle_local_id_assignment.connect(spawn_player)
	ClientNetworkGlobals.handle_remote_id_assignment.connect(spawn_player)

func spawn_player(id: int) -> void:
	var player = LOW_LEVEL_NETWORK_PLAYER.instantiate()
	(player.get_node("Player Body") as PlayerMovement).owner_id = id
	player.name = str(id) # optional

	call_deferred("add_child", player)
