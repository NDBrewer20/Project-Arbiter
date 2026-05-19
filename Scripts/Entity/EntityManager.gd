class_name EntityManager extends Node3D

var is_server: bool:
	get:
		return LowLevelNetworkHandler.is_server
var entity_id: int
