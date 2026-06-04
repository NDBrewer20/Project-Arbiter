class_name BasicEnemy extends Entity

@export_category("Enemy Stats")
@export var stats: Stats

@export_category("Enemy Components")
@export var velocityComponent: VelocityComponent
@export var pathfindComponent: PathfindComponent
@export var detectionComponent: Area3D
@export var stateMachine: StateMachine

var _nearbyBodies: Array[Node3D]
signal OnNearbyBodyExited(body: Node3D)
signal OnNearbyBodyEntered(body: Node3D)

func _ready() -> void:
	LowLevelNetworkHandler.on_connected_to_server.connect(_on_connected_to_server)
	LowLevelNetworkHandler.on_disconnected_from_server.connect(_on_disconnect_from_server)
	detectionComponent.body_entered.connect(_on_body_entered)
	detectionComponent.body_exited.connect(_on_body_exit)
	stats.owner = self

func _on_connected_to_server() -> void:
	if !_manager.is_server:
		NodeTools.manageNode(velocityComponent, false)
		NodeTools.manageNode(pathfindComponent, false)
		NodeTools.manageNode(detectionComponent, false)

func _on_disconnect_from_server(_peerID: int) -> void:
	NodeTools.manageNode(velocityComponent, true)
	NodeTools.manageNode(pathfindComponent, true)
	NodeTools.manageNode(detectionComponent, true)

func _physics_process(_delta: float) -> void:	
	if !_manager.is_server: return # Don't let a client control enemy movement.
	
	var lookdir :Vector3 = velocity.normalized()
	lookdir.y = 0
	if global_position + lookdir != global_position:
		look_at(global_position + lookdir)


func _on_body_entered(body: Node3D) -> void:
	_nearbyBodies.append(body)
	OnNearbyBodyEntered.emit(body)

func _on_body_exit(body: Node3D) -> void:
	_nearbyBodies.erase(body)
	OnNearbyBodyExited.emit(body)
