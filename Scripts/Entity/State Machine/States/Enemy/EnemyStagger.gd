extends State
class_name EnemyStagger

const stateName := "EnemyStagger"

## reference to the player.
@export var enemy: BasicEnemy
## the amount of time it takes to recover from the melee attack.
@export var recovery_window: Timer


func _enter() -> void:
	super._enter()
	if !enemy._manager.is_server: return 
	# connect timers for attack recovery and attack delays.
	recovery_window.timeout.connect(_after_recovery_window)

	# this should timeout immediately after animation finishes.
	# setup recovery window to play after attack sequence
	recovery_window.start()

## once the recovery window is over.
func _after_recovery_window():
	transitioned.emit(self, EnemyIdle.stateName)


func _exit() -> void:
	super._exit()
	if !enemy._manager.is_server: return

func _update(delta: float):
	super._update(delta)
	if !enemy._manager.is_server: return 

func _physics_update(delta: float):
	super._physics_update(delta)
	if !enemy._manager.is_server: return 

	enemy.velocityComponent.Move(enemy)
