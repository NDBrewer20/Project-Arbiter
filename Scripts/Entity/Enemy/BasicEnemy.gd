class_name BasicEnemy extends Entity

@export_category("Enemy Components")
## refernce to the velocity component
@export var velocityComponent: VelocityComponent
## reference to the pathfinding component.
@export var pathfindComponent: PathfindComponent
## reference to the Detection radius
@export var detectionArea: Area3D
## reference to the state machine that controls the enemies movement.
@export var stateMachine: StateMachine

## list of nearby bodies that have entered the Enemies Detection Area.
var _nearbyBodies: Array[Node3D]
## signal for others to listen to when a body has just exited the detection area.
signal OnNearbyBodyExited(body: Node3D)
## signal for others to listen to when a body has just entered the detection area.
signal OnNearbyBodyEntered(body: Node3D)
## the current focused target for this enemy.
var _target: Node3D

func _ready() -> void:
	if !_manager.is_server: return
	# connect entity detection functions
	detectionArea.body_entered.connect(_on_body_entered)
	detectionArea.body_exited.connect(_on_body_exit)

	# when the entity no longer has any health then run death function.
	statManager.stats.health_depleted.connect(death)

func _exit_tree() -> void:
	if !_manager.is_server: return

	# if the entity is being removed then disconnect all signals to prevent errors.
	detectionArea.body_entered.disconnect(_on_body_entered)
	detectionArea.body_exited.disconnect(_on_body_exit)
	statManager.stats.health_depleted.disconnect(death)

## called when the entity's health gets depleted.
func death():
	if !_manager.is_server: return # if not the server
	
	# remove the entity from the game.
	LowLevelEntitySpawner.instance.server_remove_entity(_manager.assigned_id)

func _physics_process(_delta: float) -> void:	
	if !_manager.is_server: return # Don't let a client control enemy movement.
	
	# get the looking direction based on bodies velocity.
	var lookdir :Vector3 = velocity.normalized()
	lookdir.y = 0
	# if the look direction isn't looking at the bodies position then look that way.
	if !(global_position + lookdir).is_equal_approx(global_position):
		look_at(global_position + lookdir)

func Move(tarPos: Vector3 = global_position):
	# set Navigation Agents target position to the wander point and move to it. 
	pathfindComponent.SetTargetPosition(tarPos)
	pathfindComponent.FollowPath()
	velocityComponent.Move(self)

## called when a body enters the detection area.
func _on_body_entered(body: Node3D) -> void:
	# add body to nearby bodies list and emit signal.
	_nearbyBodies.append(body)
	OnNearbyBodyEntered.emit(body)

## called when a body exits the detection area.
func _on_body_exit(body: Node3D) -> void:
	# remove body from nearby bodies list and emit signal.
	_nearbyBodies.erase(body)
	OnNearbyBodyExited.emit(body)
	# as a fallback when the enemy loses the target and isn't in the enemy follow state then remove the current target.
	if body == _target and stateMachine.currentState.name != EnemyFollow.stateName:
		_target = null
