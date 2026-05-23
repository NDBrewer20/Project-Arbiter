## This script is responsible for synchronizing the position and rotation of an entity across the network.
## It listens for EntityTransform packets from the server and updates the entity's transform accordingly.
class_name EntityTransformSync extends Node

## A reference to the CharacterBody3D node that represents the entity's physical body in the scene.
@export var _body: CharacterBody3D
## A reference to the NetworkManager that manages this entity instance.
@export var _manager: NetworkManager

## smooths out the position updates of the transform at the cost of introducing slight positional and rotational latency
@export var smooth: bool = true
@export var smoothValue: float = 10
var _cachedPosition: Vector3
var _cachedRotation: Vector3

func _enter_tree() -> void:
	# Connect to the signal that is emitted when an EntityTransform packet is received from the server.
	ClientNetworkGlobals.handle_entity_position.connect(client_handle_entity_position)

func _exit_tree() -> void:
	# Disconnect from the signal when this node is removed from the scene tree to prevent errors.
	ClientNetworkGlobals.handle_entity_position.disconnect(client_handle_entity_position)

func client_handle_entity_position(entity_transform: EntityTransform) -> void:
	if _manager.assigned_id != entity_transform.id: return # Not for this entity.

	var finalPosition :Vector3 = _cachedPosition.lerp(entity_transform.position,get_physics_process_delta_time()*smoothValue)
	var finalRotation :Vector3 = _cachedRotation.lerp(entity_transform.rotation,get_physics_process_delta_time()*smoothValue)

	# Update the entity's position and rotation based on the data received from the server.
	_body.global_position = finalPosition
	_body.global_rotation.y = finalRotation.y # packet only syncs y rotation.
	_cachedPosition = _body.global_position
	_cachedRotation = entity_transform.rotation
