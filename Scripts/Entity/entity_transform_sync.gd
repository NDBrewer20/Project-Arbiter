## This script is responsible for synchronizing the position and rotation of an entity across the network.
## It listens for EntityTransform packets from the server and updates the entity's transform accordingly.
class_name EntityTransformSync extends Node

## A reference to the CharacterBody3D node that represents the entity's physical body in the scene.
@export var _body: CharacterBody3D
## A reference to the NetworkManager that manages this entity instance.
@export var _manager: NetworkManager

func _enter_tree() -> void:
	# Connect to the signal that is emitted when an EntityTransform packet is received from the server.
	ClientNetworkGlobals.handle_entity_position.connect(client_handle_entity_position)

func _exit_tree() -> void:
	# Disconnect from the signal when this node is removed from the scene tree to prevent errors.
	ClientNetworkGlobals.handle_entity_position.disconnect(client_handle_entity_position)

func client_handle_entity_position(entity_transform: EntityTransform) -> void:
	if _manager.assigned_id != entity_transform.id: return # Not for this entity.

	# Update the entity's position and rotation based on the data received from the server.
	_body.global_position = entity_transform.position
	_body.global_rotation.y = entity_transform.rotation.y # packet only syncs y rotation.
