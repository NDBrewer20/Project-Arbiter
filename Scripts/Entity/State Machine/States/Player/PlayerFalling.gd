extends State
class_name PlayerFalling

const stateName := "PlayerFalling"

@export var player: ThirdPersonPlayer

func _enter() -> void:
	super._enter()
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.

func _exit() -> void:
	super._exit()
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.
	player.velocityComponent.velocity.y = 0 # reset the vertical velocity when landing to prevent the player from bouncing if they hit the ground with a lot of downward velocity.

func _update(delta: float):
	super._update(delta)
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.

func _physics_update(delta: float):
	super._physics_update(delta)
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.

	if (player._canBufferJump and player.is_on_floor()) or (player._isjumping and player._canCoyote):
		transitioned.emit(self, PlayerJump.stateName)
	elif player.is_on_floor():
		transitioned.emit(self, PlayerFloor.stateName)

	var impulse: Vector3 = Vector3(0,-player.gravity,0)
	var t = clampf((player._timeSinceFirstFrame - player._lastTimeOnGround) / player.airControlFadeTime, 0, 1)
	var air_control_factor = lerp(player.airControlStart, player.airControlEnd, t)
	impulse += player._inputDirection * air_control_factor
	
	player.velocityComponent.AddForce(impulse * delta)
	player._lastOnFloor = player.is_on_floor()
	player.velocityComponent.Move(player)
