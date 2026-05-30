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
	var moveDirection := Vector3(randf_range(-1,1),randf_range(-0.5,1),randf_range(-1,1)).normalized()
	_wanderPoint = _cachedStartPosition + (moveDirection * enemy.detectionComponent.scale.length())
	_wanderTime = randf_range(wanderTimeClamp.x,wanderTimeClamp.y)

func _enter():
	super._enter()
	if !enemy._manager.is_server: return

	enemy.OnNearbyBodyEntered.connect(_on_nearby_body_entered)

	if !_cachedStartPosition:
		_cachedStartPosition = enemy.global_position
	
	randomize_wander()

func _exit():
	if !enemy._manager.is_server: return
	enemy.OnNearbyBodyEntered.disconnect(_on_nearby_body_entered)

func _update(delta: float):
	super._update(delta)
	if !enemy._manager.is_server: return
	if _wanderTime > 0:
		_wanderTime -= delta

	else:
		randomize_wander()

func _physics_update(delta: float):
	super._physics_update(delta)
	if !enemy._manager.is_server: return

	enemy.pathfindComponent.SetTargetPosition(_wanderPoint)
	enemy.pathfindComponent.FollowPath()
	enemy.velocityComponent.Move(enemy)

func _on_nearby_body_entered(_body: Node3D):
	Transitioned.emit(self, EnemyFollow.stateName)