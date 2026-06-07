class_name Entity extends CharacterBody3D

## Reference to [NetworkManager] for this Enemy instance.
@export var _manager: NetworkManager
@export var statManager: StatManager

signal handle_entity_removed(entity_id: int)

func _exit_tree() -> void:
	handle_entity_removed.emit(_manager.assigned_id)