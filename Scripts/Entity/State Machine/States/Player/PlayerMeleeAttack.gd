extends State
class_name PlayerMeleeAttack

const stateName := "PlayerMeleeAttack"

@export var player: ThirdPersonPlayer
@export var hitbox_shape: Shape3D
@export var recovery_window: Timer
@export var send_attack_delay: Timer
var last_attack_time: float = 0.0
@export var comboBuffer: float = 0.25 # ideally this is set to be halfway between send_attack_delay and recovery_window, but for debug purposes manual timing.
var attemptCombo: bool = false
var comboWindow: bool:
	get:
		return player._timeSinceFirstFrame < last_attack_time + comboBuffer
var canCombo: bool:
	get:
		return comboWindow and attemptCombo

func _enter() -> void:
	super._enter()
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.
	recovery_window.timeout.connect(_after_recovery_window)
	send_attack_delay.timeout.connect(_send_attack_delayed)
	player.comboTimer.wait_time = recovery_window.wait_time * 1.1

	player.velocityComponent.AddForce(player.transform.basis.z * -3.5)

	# later specify a specific amount of time these are going to use based on corresponding animation that is playing.
	# this should timeout halfway through animation
	send_attack_delay.start()
	# this should timeout immediately after animation finishes.
	# setup recovery window to play after attack sequence
	recovery_window.start()

func _after_recovery_window():
	if !canCombo:
		transitioned.emit(self, PlayerFloor.stateName)
		return
	else:
		player.force_rotate_player()
		transitioned.emit(self, PlayerMeleeAttack.stateName)
		player.comboPosition += 1

func _send_attack_delayed():
	var hitbox = HitboxComponent.new(player.statManager.stats, 0.5, hitbox_shape)
	player.attackOrigin.add_child(hitbox)

func _exit() -> void:
	super._exit()
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.
	recovery_window.timeout.disconnect(_after_recovery_window)
	send_attack_delay.timeout.disconnect(_send_attack_delayed)
	attemptCombo = false
	last_attack_time = 0.0

func _update(delta: float):
	super._update(delta)
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.
	if Input.is_action_just_pressed("Player_Primary_Fire") and player._cursorStateMachine.Movement_Allowed():
		attemptCombo = true
		last_attack_time = player._timeSinceFirstFrame
	if !player.is_on_floor():
		transitioned.emit(self, PlayerFalling.stateName)

func _physics_update(delta: float):
	super._physics_update(delta)
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.
	player.velocityComponent.Decelerate()
	player.velocityComponent.Move(player)
