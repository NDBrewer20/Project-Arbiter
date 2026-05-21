class_name EnemyMovement extends CharacterBody3D

## Reference to [NetworkManager] for this Enemy instance.
@export var _manager: NetworkManager

func _physics_process(delta: float) -> void:
	if !_manager.is_server: return # Don't let a client control enemy movement.

	# temp movement to show enemy sync across network.
	if global_position.z < -2:
		velocity.z += transform.basis.z.normalized().z * delta
	elif global_position.z > 2:
		velocity.z += -transform.basis.z.normalized().z * delta

	move_and_slide()

	# send out the enemy position data to clients.
	EntityTransform.create(0,global_position, global_rotation).broadcast(LowLevelNetworkHandler.connection)
