extends State
class_name EnemyFollow

## the name of this state.
const stateName := "EnemyFollow" 

## Reference to the enemy that is being controlled.
@export var enemy: BasicEnemy
## Timer to check when the user leaves the detection radius how long will the enemy chase for. [br]
@export var interestTimer: Timer 

func _enter():
	super._enter()
	if !enemy._manager.is_server: return

	# connect functions for maintaing a chase and knowing who has entered detection range.
	if !interestTimer.timeout.is_connected(_on_interest_timeout): # if interest timer hasn't already been connected then connect it.
		interestTimer.timeout.connect(_on_interest_timeout)
	enemy.OnNearbyBodyExited.connect(_on_nearby_body_exited)
	enemy.OnNearbyBodyEntered.connect(_on_nearby_body_entered)

	# pick a random target to start if none is defined.
	if !enemy._target:
		enemy._target = enemy._nearbyBodies.pick_random()

func _exit():
	super._exit()
	if !enemy._manager.is_server: return

	# disconnect functions related to maintaing a chase and knowing who has entered detection range.
	enemy.OnNearbyBodyExited.disconnect(_on_nearby_body_exited)
	enemy.OnNearbyBodyEntered.disconnect(_on_nearby_body_entered)

func _update(delta: float):
	super._update(delta)
	if !enemy._manager.is_server: return
	# if the enemy is not on the floor then enter the falling state.
	if !enemy.is_on_floor():
		transitioned.emit(self, EnemyFalling.stateName)

func _physics_update(delta:float):
	super._physics_update(delta)
	if !enemy._manager.is_server: return

	# if there is a target to chase
	if enemy._target:
		# set the Navigation Agents target position to the targets position and move along the Navigation Agents path.
		enemy.Move(enemy._target.global_position)
	elif !enemy._nearbyBodies.is_empty(): # if there is no target and there are still nearby targets then pick one
		enemy._target = enemy._nearbyBodies.pick_random()
	else: # if there is no target or nearby targets then transition to the idle state.
		transitioned.emit(self, EnemyIdle.stateName)

## when a body exits the detection area.
func _on_nearby_body_exited(body: Node3D):
	if enemy._target == body and interestTimer.is_inside_tree():
		interestTimer.start()

## when a body enters the detection area
func _on_nearby_body_entered(body: Node3D):
	if enemy._target == body and !interestTimer.is_stopped():
		interestTimer.stop()

## when the interest timer completes.
func _on_interest_timeout():
	# check if there is an available nearby target
	if enemy._nearbyBodies.is_empty(): # if not then transition to idle
		enemy._target = null 
		transitioned.emit(self, EnemyIdle.stateName)
		return
	# if there is then pick one from list.
	enemy._target = enemy._nearbyBodies.pick_random()
