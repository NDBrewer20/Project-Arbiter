class_name Entity extends CharacterBody3D

## Reference to [NetworkManager] for this Enemy instance.
@export var _manager: NetworkManager
## reference to the statManager
@export var statManager: StatManager

## signal for when an entity gets removed from scene tree.
signal handle_entity_removed(entity_id: int)

func _exit_tree() -> void:
	# emit signal with assigned id on removal.
	handle_entity_removed.emit(_manager.assigned_id)