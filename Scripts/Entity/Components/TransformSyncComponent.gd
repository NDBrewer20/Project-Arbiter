## This script is responsible for synchronizing the position and rotation of an entity across the network.
## It listens for [EntityTransform] packets from the server and updates the entity's transform accordingly.
class_name EntityTransformSync extends Node

## A reference to the [Entity] node that represents the entity's physical body in the scene.
@export var _body: Entity

## smooths out the position updates of the transform at the cost of introducing slight positional and rotational latency
@export var smooth: bool = true
## How agressive smoothing will be. [br]
## how many steps will be remembered from entity position.
@export var smoothStep: int = 3
@export var smoothValue: float = 75
var _cachedPosition: Array[Vector3]
var _cachedRotation: Array[Vector3]

func _enter_tree() -> void:
	# Connect to the signal that is emitted when an EntityTransform packet is received from the server.
	EntityNetworkGlobals.handle_entity_position.connect(client_handle_entity_position)

func _exit_tree() -> void:
	# Disconnect from the signal when this node is removed from the scene tree to prevent errors.
	EntityNetworkGlobals.handle_entity_position.disconnect(client_handle_entity_position)

func _physics_process(_delta: float) -> void:
	# After every physics process has run broadcast entity position/rotation.
	server_broadcast_entity_position.call_deferred()

func server_broadcast_entity_position() -> void:
	if !_body._manager.is_server: return
	# send out the enemy position data to clients.
	EntityTransform.create(_body._manager.assigned_id, _body.global_position, _body.global_rotation).broadcast(LowLevelNetworkHandler.connection)

func client_handle_entity_position(entity_transform: EntityTransform) -> void:
	if _body._manager.assigned_id != entity_transform.id: return # Not for this entity.

	if smooth:
		# smooth out the position of the entity based on last cached position and Packet position.
		var finalPosition :Vector3 = entity_transform.position 
		var finalRotation :Vector3  = entity_transform.rotation 
		for pos in _cachedPosition:
			finalPosition = pos.lerp(finalPosition,1-exp(get_physics_process_delta_time()*-smoothValue))
		for rot in _cachedRotation:
			finalRotation = rot.lerp(finalRotation,1-exp(get_physics_process_delta_time()*-smoothValue))

		# Update the entity's position and rotation based on the data received from the server.
		_body.global_position = finalPosition
		_body.global_rotation.y = finalRotation.y # packet only syncs y rotation.

		# Cache entity position and rotation for next iteration to use for smoothing.
		_cachedPosition.push_front(_body.global_position)
		_cachedRotation.push_front(entity_transform.rotation)
		# if cached values become too big.
		if _cachedPosition.size() > smoothStep:
			_cachedPosition.pop_back()
		if _cachedRotation.size() > smoothStep:
			_cachedRotation.pop_back()
	else:
		_body.global_position = entity_transform.position
		_body.global_rotation.y = entity_transform.rotation.y
