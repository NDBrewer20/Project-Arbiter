class_name StatManager extends Node

@export var stats: Stats

func _ready() -> void:
	stats.owner = owner
	LowLevelNetworkHandler.on_peer_connected.connect(stats._fetch_current_stat_values)
	EntityNetworkGlobals.recieve_Entity_stat_values.connect(stats._set_current_stat_values)
