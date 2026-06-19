extends State
class_name EnemyFalling

## the name of this state.
const stateName := "EnemyFalling" 

## Reference to the enemy that is being controlled.
@export var enemy: BasicEnemy

func _enter():
	super._enter()
	if !enemy._manager.is_server: return 


func _exit():
	super._exit()
	if !enemy._manager.is_server: return

func _update(delta: float):
	super._update(delta)
	if !enemy._manager.is_server: return
	# if the enemy has touched the floor then transition to another grounded state.
	if enemy.is_on_floor():
		if enemy._target:
			transitioned.emit(self, EnemyFollow.stateName)
		else:
			transitioned.emit(self, EnemyIdle.stateName)

func _physics_update(delta:float):
	super._physics_update(delta)
	if !enemy._manager.is_server: return
	
	# force the enemy velocity component to fall down.
	enemy.velocityComponent.AddForce(Vector3.DOWN * 9.84 * delta)
	enemy.velocityComponent.Move(enemy)
