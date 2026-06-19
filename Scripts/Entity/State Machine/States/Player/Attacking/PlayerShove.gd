extends State
class_name PlayerShove

const stateName := "PlayerShove"

## reference to the player.
@export var player: ThirdPersonPlayer
## the shape of the hitbox for the melee attack.
@export var hitbox_shape: Shape3D
## the amount of time it takes to recover from the melee attack.
@export var recovery_window: Timer
## the amount of time into the animation the attack hitbox should be spawned.
@export var send_attack_delay: Timer
@export var shoveForce: float = 3.5

func _enter() -> void:
	super._enter()
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.

	# add speed modifier to the player to prevent moving while in attacking state.
	player.velocityComponent.SetSpeedPercentModifier(stateName,-0.2)

	# connect timers for attack recovery and attack delays.
	recovery_window.timeout.connect(_after_recovery_window)
	send_attack_delay.timeout.connect(_send_attack)

	# this should timeout immediately after animation finishes.
	# setup recovery window to play after attack sequence
	recovery_window.start()
	# later specify a specific amount of time these are going to use based on corresponding animation that is playing.
	# this should timeout halfway through animation
	send_attack_delay.start(recovery_window.wait_time/2.0)

## once the recovery window is over.
func _after_recovery_window():
	transitioned.emit(self, PlayerAttackIdle.stateName)

## sends the melee attack paylod.
func _send_attack():
	# create a hitlog for hitbox to log hit enemies.
	var hitlog: Hitlog = Hitlog.new()
	# create hitbox to hit enemies and add it to the attack origin.
	var hitbox = HitboxComponent.new(0.0, player.statManager.stats, 0.5, hitbox_shape, hitlog)
	# Shove should be centered on the player so that the player can push enemies that are behind them.
	player.add_child(hitbox)

	for hit_node in hitlog.hit_log:
		if hit_node is Entity:
			var hit_entity:Entity = hit_node as Entity
			Packet_StaggerAttempt.create(player._manager.assigned_id, hit_entity._manager.assigned_id).send(LowLevelNetworkHandler.server_peer)



func _exit() -> void:
	super._exit()
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.

	player.velocityComponent.RemoveSpeedPercentModifier(stateName)
	# disconnect timers for attack delays and recovery windows.
	recovery_window.timeout.disconnect(_after_recovery_window)
	send_attack_delay.timeout.disconnect(_send_attack)

func _update(delta: float):
	super._update(delta)
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.
	if !player.is_on_floor(): # if the player is not on the floor move to idle state
		transitioned.emit(self, PlayerAttackIdle.stateName)

func _physics_update(delta: float):
	super._physics_update(delta)
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.
