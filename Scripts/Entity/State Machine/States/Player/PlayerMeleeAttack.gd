extends State
class_name PlayerMeleeAttack

const stateName := "PlayerMeleeAttack"

## reference to the player.
@export var player: ThirdPersonPlayer
## the shape of the hitbox for the melee attack.
@export var hitbox_shape: Shape3D
## the amount of time it takes to recover from the melee attack.
@export var recovery_window: Timer
## the amount of time into the animation the attack hitbox should be spawned.
@export var send_attack_delay: Timer
## the last attempt to attack.
var last_attack_time: float = 0.0
## how much time does the player have to queue a combo attack.
var comboBuffer: float:
	get:
		return 60.0 / player.weaponHolder.weapon.stats.current_fire_rate

## is a combo being attempted.
var attemptCombo: bool = false
# player within the window to perform a combo attack
var comboWindow: bool:
	get:
		return player._timeSinceFirstFrame < last_attack_time + comboBuffer
# player can initiate a combo attack.
var canCombo: bool:
	get:
		return comboWindow and attemptCombo


func _enter() -> void:
	super._enter()
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.

	# connect timers for attack recovery and attack delays.
	recovery_window.timeout.connect(_after_recovery_window)
	send_attack_delay.timeout.connect(_send_attack)

	# DEBUG force an impulse movement so that player can see that they're in attack state.
	player.velocityComponent.AddForce(player.transform.basis.z * -3.5)

	# this should timeout immediately after animation finishes.
	# setup recovery window to play after attack sequence
	recovery_window.start()
	# later specify a specific amount of time these are going to use based on corresponding animation that is playing.
	# this should timeout halfway through animation
	send_attack_delay.start(recovery_window.wait_time/2.0)
	player.comboTimer.wait_time = recovery_window.wait_time + 0.1

## once the recovery window is over.
func _after_recovery_window():
	# if the player cant initiate a combo
	if !canCombo:
		# transition to the floor state and reset the combo.
		transitioned.emit(self, PlayerFloor.stateName)
		player.comboPosition = 0
		player.comboTimer.stop()
		return
	else: # otherwise, if a combo is possible.
		player.force_rotate_player() # force the player to face camera direction
		# transitino to melee attack state
		transitioned.emit(self, PlayerMeleeAttack.stateName)
		# increment combo position.
		player.comboPosition += 1

## sends the melee attack paylod.
func _send_attack():
	# create a hitlog for hitbox to log hit enemies.
	var hitlog: Hitlog = Hitlog.new()
	# create hitbox to hit enemies and add it to the attack origin.
	var hitbox = HitboxComponent.new(player.statManager.stats, 0.5, hitbox_shape, hitlog,player.weaponHolder.weapon)
	player.attackOrigin.add_child(hitbox)


func _exit() -> void:
	super._exit()
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.
	# disconnect timers for attack delays and recovery windows.
	recovery_window.timeout.disconnect(_after_recovery_window)
	send_attack_delay.timeout.disconnect(_send_attack)
	# no longer attempting a combo.
	attemptCombo = false
	last_attack_time = 0.0

func _update(delta: float):
	super._update(delta)
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.
	# if the player is trying to attack (combo attacks)
	if Input.is_action_just_pressed("Player_Primary_Fire") and player._cursorStateMachine.Movement_Allowed():
		attemptCombo = true
		last_attack_time = player._timeSinceFirstFrame
	if !player.is_on_floor(): # if the player is not on the floor move to falling state.
		transitioned.emit(self, PlayerFalling.stateName)

func _physics_update(delta: float):
	super._physics_update(delta)
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.

	# deaccelerate the player in this state so they stop moving and move the body.
	player.velocityComponent.Decelerate()
	player.Move()
