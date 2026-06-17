extends State
class_name PlayerFalling

const stateName := "PlayerFalling"

## reference to the player
@export var player: ThirdPersonPlayer

func _enter() -> void:
	super._enter()
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.

func _exit() -> void:
	super._exit()
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.
	player.velocityComponent.velocity.y = 0 # reset the vertical velocity when landing.

func _update(delta: float):
	super._update(delta)
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.

func _physics_update(delta: float):
	super._physics_update(delta)
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.

	# check if the player can buffer a jump and is on the floor OR is trying to jump and can initiate a coyote jump
	if (player._canBufferJump and player.is_on_floor()) or (player._isjumping and player._canCoyote):
		# then transition to the jump state
		transitioned.emit(self, PlayerJump.stateName)
	elif player.is_on_floor(): # otherwise if the player is on the floor then go to the floor state.
		transitioned.emit(self, PlayerFloor.stateName)

	# create the impulse for the player gravity and air strafing.
	var impulse: Vector3 = Vector3(0,-player.gravity,0)
	var t = clampf((player._timeSinceFirstFrame - player._lastTimeOnGround) / player.airControlFadeTime, 0, 1)
	var air_control_factor = lerp(player.airControlStart, player.airControlEnd, t)
	impulse += player._inputDirection * air_control_factor
	
	# apply the impulse to the player velocity and move.
	player.velocityComponent.AddForce(impulse * delta)
	player.Move()
