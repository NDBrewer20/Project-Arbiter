extends State
class_name PlayerJump

const stateName := "PlayerJump"

## reference to the player.
@export var player: ThirdPersonPlayer

func _enter() -> void:
	super._enter()
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.
	player.velocityComponent.AddForce(Vector3.UP*player.jumpVelocity)
	#player.velocityComponent.Move(player) # apply the jump velocity immediately so that the player starts moving upwards right away instead of waiting for the next physics frame to apply the velocity, which would cause a small delay before the player starts moving upwards.
	player._coyoteUsable = false # reset coyote time when the player jumps to prevent double jumps.
	player._bufferJumpUsable = false # reset jump buffering when the player jumps to prevent buffered jumps from triggering after the player has already jumped.
	player._lastJumpPressed = 0 # reset the jump buffer timer when the player jumps to prevent buffered jumps from triggering after the player has already jumped.

func _exit() -> void:
	super._exit()
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.
	player._isjumping = false # reset the jump input so that holding the jump button doesn't cause the player to keep jumping when they land.

func _update(delta: float):
	super._update(delta)
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.

func _physics_update(delta: float):
	super._physics_update(delta)
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.
	# if the players at the apex of their jump or they just released the jump.
	if player.velocity.y <= 0 || Input.is_action_just_released("Player_Jump"):
		# transition to the falling state.
		transitioned.emit(self, PlayerFalling.stateName)

	# create the impulse for air control and gravity.
	var impulse: Vector3 = Vector3(0,-player.gravity,0)
	var t = clampf((player._timeSinceFirstFrame - player._lastTimeOnGround) / player.airControlFadeTime, 0, 1)
	var air_control_factor = lerp(player.airControlStart, player.airControlEnd, t)
	impulse += player._inputDirection * air_control_factor

	# apply the impulse to the player velocity and move.
	player.velocityComponent.AddForce(impulse * delta)
	player.Move()
