class_name EnemyMovement extends CharacterBody3D

@onready var is_server: bool:
	get:
		return (get_parent() as EnemyManager).is_server

func _enter_tree() -> void:
	ClientNetworkGlobals.handle_entity_position.connect(client_handle_entity_position)

func _exit_tree() -> void:
	ClientNetworkGlobals.handle_entity_position.disconnect(client_handle_entity_position)

func _physics_process(delta: float) -> void:
	if !is_server: return # Don't let a client control enemy movement.
	if global_position.z < -2:
		velocity.z += transform.basis.z.normalized().z * delta
	elif global_position.z > 2:
		velocity.z += -transform.basis.z.normalized().z * delta
	move_and_slide()

	EntityTransform.create(0,global_position, global_rotation).broadcast(LowLevelNetworkHandler.connection)

func client_handle_entity_position(entity_transform: EntityTransform) -> void:
	global_position = entity_transform.position
	global_rotation.y = entity_transform.rotation.y # packet only syncs y rotation.
