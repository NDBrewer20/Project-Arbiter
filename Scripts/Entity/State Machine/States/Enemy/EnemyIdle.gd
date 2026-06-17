extends State
class_name EnemyIdle

const stateName := "EnemyIdle"

## Reference to the enemy that is being controlled.
@export var enemy: BasicEnemy
## Clamps the Randomized time that the Enemy will wander a path for. [br]
## Clamps from X -> Y (1, 3)
@export var wanderTimeClamp: Vector2 = Vector2(1,3)

## the point that the enemy will wander to.
var _wanderPoint: Vector3
## the position that the idle state was entered at.
var _cachedStartPosition: Vector3
## how long to wander on this path for.
var _wanderTime: float

## randomly picks a new position to wander on and the duration of wandering.
func randomize_wander():
	# pick a direction to move in
	var moveDirection := Vector3(randf_range(-1,1),randf_range(-0.5,1),randf_range(-1,1)).normalized()
	# set the point to wander to.
	_wanderPoint = _cachedStartPosition + (moveDirection * enemy.detectionArea.scale.length())
	# set how long to wander for.
	_wanderTime = randf_range(wanderTimeClamp.x,wanderTimeClamp.y)

func _enter():
	super._enter()
	if !enemy._manager.is_server: return

	# if there are nearby bodies to pursue then go to the follow state.
	if !enemy._nearbyBodies.is_empty() or enemy._target:
		transitioned.emit(self, EnemyFollow.stateName)

	# connect detection area to see when a body comes near. 
	enemy.OnNearbyBodyEntered.connect(_on_nearby_body_entered)

	# if starting position hasn't been cached yet then set it.
	if !_cachedStartPosition:
		_cachedStartPosition = enemy.global_position
	
	# randomize the wander direction.
	randomize_wander()

func _exit():
	if !enemy._manager.is_server: return
	# disconnect the detection area so the state machine stays clean.
	enemy.OnNearbyBodyEntered.disconnect(_on_nearby_body_entered)

func _update(delta: float):
	super._update(delta)
	if !enemy._manager.is_server: return
	
	# if the enemy is no longer on the floor then move to the falling state.
	if !enemy.is_on_floor():
		transitioned.emit(self, EnemyFalling.stateName)

	# if there is still time to wander then decrease the _wanderTime
	if _wanderTime > 0:
		_wanderTime -= delta
	# if the wander timer is up then randomize wander direction.
	else:
		randomize_wander()

func _physics_update(delta: float):
	super._physics_update(delta)
	if !enemy._manager.is_server: return
	# set Navigation Agents target position to the wander point and move to it. 
	enemy.pathfindComponent.SetTargetPosition(_wanderPoint)
	enemy.pathfindComponent.FollowPath()
	enemy.velocityComponent.Move(enemy)

## when a body enters the detection area
func _on_nearby_body_entered(_body: Node3D):
	# transition to the enemyFollow state
	transitioned.emit(self, EnemyFollow.stateName)