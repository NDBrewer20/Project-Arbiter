extends State
class_name EnemyFollow

const stateName := "EnemyFollow" 

## Reference to the enemy that is being controlled.
@export var enemy: BasicEnemy
var _target: Node3D
## Timer to check when the user leaves the detection radius how long will the enemy chase for. [br]
@export var interestTimer: Timer 

func _enter():
	super._enter()
	if !enemy._manager.is_server: return

	interestTimer.timeout.connect(_on_interest_timeout)
	enemy.OnNearbyBodyExited.connect(_on_nearby_body_exited)
	enemy.OnNearbyBodyEntered.connect(_on_nearby_body_entered)

	_target = enemy._nearbyBodies.pick_random()

func _exit():
	super._exit()
	if !enemy._manager.is_server: return

	interestTimer.timeout.disconnect(_on_interest_timeout)
	enemy.OnNearbyBodyExited.disconnect(_on_nearby_body_exited)
	enemy.OnNearbyBodyEntered.disconnect(_on_nearby_body_entered)

func _update(delta: float):
	super._update(delta)
	if !enemy._manager.is_server: return

func _physics_update(delta:float):
	super._physics_update(delta)
	if !enemy._manager.is_server: return
	
	if _target:
		enemy.pathfindComponent.SetTargetPosition(_target.global_position)
		enemy.pathfindComponent.FollowPath()
		enemy.velocityComponent.Move(enemy)
	elif !enemy._nearbyBodies.is_empty():
		_target = enemy._nearbyBodies.pick_random()
	else:
		_on_interest_timeout()

func _on_nearby_body_exited(body: Node3D):
	if _target == body and interestTimer.is_inside_tree():
		interestTimer.start()

func _on_nearby_body_entered(body: Node3D):
	if _target == body and !interestTimer.is_stopped():
		interestTimer.stop()

func _on_interest_timeout():
	if enemy._nearbyBodies.is_empty():
		_target = null
		transitioned.emit(self, EnemyIdle.stateName)
		return
	_target = enemy._nearbyBodies.pick_random()
