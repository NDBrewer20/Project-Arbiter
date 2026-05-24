class_name BasicEnemy extends Entity

@export var velocityComponent: VelocityComponent
@export var pathfindComponent: PathfindComponent
@export var detectionComponent: Area3D


#var _target: Node3D

var _nearbyBodies: Array[Node3D]
signal OnNearbyBodyExited(body: Node3D)
signal OnNearbyBodyEntered(body: Node3D)

func _ready() -> void:
	LowLevelNetworkHandler.on_connected_to_server.connect(_on_connected_to_server)
	LowLevelNetworkHandler.on_disconnected_from_server.connect(_on_disconnect_from_server)
	detectionComponent.body_entered.connect(_on_body_entered)
	detectionComponent.body_exited.connect(_on_body_exit)
	#interestTimer.timeout.connect(_on_interest_timeout)

func _on_connected_to_server() -> void:
	if !_manager.is_server:
		velocityComponent.set_process(false)
		pathfindComponent.set_process(false)
		detectionComponent.set_block_signals(true)

func _on_disconnect_from_server(_peerID: int) -> void:
	velocityComponent.set_process(true)
	pathfindComponent.set_process(true)
	detectionComponent.set_block_signals(false)

func _physics_process(_delta: float) -> void:	
	if !_manager.is_server: return # Don't let a client control enemy movement.
#
#	if !_nearbyBodies.is_empty() and !_target:
#		_target = _nearbyBodies.pick_random()
#
#	var tarPos: Vector3
#	if _target: tarPos = _target.global_position
#	else: tarPos = await pathfindComponent.find_nearest_navmesh_target(global_position)
#	var tarDir: Vector3 = global_position.direction_to(tarPos).normalized()
#	tarDir.y = 0
#
#	pathfindComponent.SetTargetPosition(tarPos)
#	pathfindComponent.FollowPath()
#	velocityComponent.Move(self)
#
	var lookdir :Vector3 = velocity.normalized()
	lookdir.y = 0
	if global_position + lookdir != global_position:
		look_at(global_position + lookdir)


func _on_body_entered(body: Node3D) -> void:
	_nearbyBodies.append(body)
	OnNearbyBodyEntered.emit(body)

#func _on_interest_timeout() -> void:
#	_target = null

func _on_body_exit(body: Node3D) -> void:
	_nearbyBodies.erase(body)
	OnNearbyBodyExited.emit(body)
