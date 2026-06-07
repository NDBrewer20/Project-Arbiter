## This script is responsible for synchronizing the position and rotation of an entity across the network.
## It listens for [Packet_EntityTransform] packets from the server and updates the entity's transform accordingly.
class_name EntityTransformSync extends Node

## A reference to the [Entity] node that represents the entity's physical body in the scene.
@export var _body: Entity


func _enter_tree() -> void:
	# Connect to the signal that is emitted when an Packet_EntityTransform packet is received from the server.
	EntityNetworkGlobals.client_handle_entity_position.connect(client_handle_entity_position)
	EntityNetworkGlobals.server_handle_entity_position.connect(server_handle_entity_position)

func _exit_tree() -> void:
	# Disconnect from the signal when this node is removed from the scene tree to prevent errors.
	EntityNetworkGlobals.client_handle_entity_position.disconnect(client_handle_entity_position)
	EntityNetworkGlobals.server_handle_entity_position.disconnect(server_handle_entity_position)


func _physics_process(_delta: float) -> void:
	# After every physics process has run broadcast entity position/rotation.
	communicate_entity_position.call_deferred()

func communicate_entity_position() -> void:
	if !LowLevelNetworkHandler.connection: return # If there is no connection don't try to send entity transform data.
	if _body._manager.is_server:
		# send out the enemy position data to clients.
		if _body.get("velocity"):
			Packet_EntityTransform.create(_body._manager.assigned_id, _body.global_position, _body.velocity, _body.global_rotation).broadcast(LowLevelNetworkHandler.connection)
		else:
			Packet_EntityTransform.create(_body._manager.assigned_id, _body.global_position, Vector3.ZERO, _body.global_rotation).broadcast(LowLevelNetworkHandler.connection)
	elif _body._manager.is_authority:
		if _body.get("velocity"):
			Packet_EntityTransform.create(_body._manager.assigned_id, _body.global_position, _body.velocity, _body.global_rotation).send(LowLevelNetworkHandler.server_peer)
		else:
			Packet_EntityTransform.create(_body._manager.assigned_id, _body.global_position, Vector3.ZERO, _body.global_rotation).send(LowLevelNetworkHandler.server_peer)

## if a client has authority over the movement of a entity then move the servers copy of the entity.
func server_handle_entity_position(entity_id: int, entity_transform: Packet_EntityTransform) -> void:
	if entity_id != _body._manager.assigned_id: return # Not for this entity.
	
	_body.global_rotation.y = entity_transform.rotation.y
	if _body.get("velocity"):
		_body.velocity = entity_transform.velocity
		var velocityComponent: VelocityComponent = _body.get("velocityComponent")
		if velocityComponent:
			velocityComponent.velocityOverride = entity_transform.velocity
		if _body is ThirdPersonPlayer:
			_body._inputDirection = entity_transform.velocity.normalized()
	await get_tree().physics_frame
	_body.global_position = entity_transform.position
	# send out the entity position data to clients.
	if _body.get("velocity"):
		Packet_EntityTransform.create(_body._manager.assigned_id, _body.global_position, _body.velocity, _body.global_rotation).broadcast(LowLevelNetworkHandler.connection)
	else:
		Packet_EntityTransform.create(_body._manager.assigned_id, _body.global_position, Vector3.ZERO, _body.global_rotation).broadcast(LowLevelNetworkHandler.connection)
	
	
func client_handle_entity_position(entity_transform: Packet_EntityTransform) -> void:
	if _body._manager.is_authority or _body._manager.assigned_id != entity_transform.id: return # the entity is the owner of this entity or not for this entity.

	_body.global_rotation.y = entity_transform.rotation.y
	if _body.get("velocity"):
		_body.velocity = entity_transform.velocity
		var velocityComponent : VelocityComponent = _body.get("velocityComponent")
		if velocityComponent:
			velocityComponent.velocityOverride = entity_transform.velocity
	if _body is ThirdPersonPlayer:
		_body._inputDirection = entity_transform.velocity.normalized()
	await get_tree().physics_frame # wait for the current frame to finish to prevent jittery movement.
	_body.global_position = _body.global_position.lerp(entity_transform.position, 0.5) # lerp the position to prevent jittery movement.
	
