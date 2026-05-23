class_name BasicEnemy extends Entity

@export var velocityComponent: VelocityComponent
@export var pathfindComponent: PathfindComponent
@export var detectionComponent: Area3D
@export var gravity: float = 9.84

var _target: Node3D

var _nearbyBodies: Array[Node3D]

func _ready() -> void:
	LowLevelNetworkHandler.on_connected_to_server.connect(_on_connected_to_server)
	LowLevelNetworkHandler.on_disconnected_from_server.connect(_on_disconnect_from_server)
	detectionComponent.body_entered.connect(_on_body_entered)
	detectionComponent.body_exited.connect(_on_body_exit)

func _on_connected_to_server() -> void:
	if !_manager.is_server:
		velocityComponent.set_process(false)
		pathfindComponent.set_process(false)
		detectionComponent.set_block_signals(true)

func _on_disconnect_from_server() -> void:
	velocityComponent.set_process(true)
	pathfindComponent.set_process(true)
	detectionComponent.set_block_signals(false)

func _physics_process(_delta: float) -> void:
	if !_manager.is_server: return # Don't let a client control enemy movement.

	if !_nearbyBodies.is_empty() and !_target:
		_target = _nearbyBodies.pick_random()

	var tarPos: Vector3 = global_position
	if _target: tarPos = _target.global_position
	
	var tarDir: Vector3 = global_position.direction_to(tarPos).normalized()
	tarDir.y = 0

	pathfindComponent.SetTargetPosition(tarPos)
	pathfindComponent.FollowPath()
	velocityComponent.Move(self)

	#PA_Debug.log("Entity (%s): is heading toward target (%s) with velocity (%s)" % [_manager.assigned_id, tarPos, velocity])

	var vel := velocity
	vel.y = 0
	if global_position + vel != global_position:
		look_at(global_position + vel.normalized())

	# send out the enemy position data to clients.
	EntityTransform.create(0,global_position, global_rotation).broadcast(LowLevelNetworkHandler.connection)

func _on_body_entered(body: Node3D) -> void:
	_nearbyBodies.append(body)

func _on_body_exit(body: Node3D) -> void:
	_nearbyBodies.erase(body)
	if _target == body:
		_target = null
