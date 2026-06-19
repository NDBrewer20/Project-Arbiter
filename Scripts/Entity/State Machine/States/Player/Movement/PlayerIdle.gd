extends State
class_name PlayerIdle

const stateName := "PlayerIdle"

## refernce to the player.
@export var player: ThirdPersonPlayer

func _enter() -> void:
	super._enter()
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.

func _exit() -> void:
	super._exit()
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.

func _update(delta: float):
	super._update(delta)
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.

func _physics_update(delta: float):
	super._physics_update(delta)
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.

	# if the player wants to move around.
	if !player._inputDirection.is_equal_approx(Vector3.ZERO):
		transitioned.emit(self, PlayerFloor.stateName)
	
	# if the player wants to jump.
	if Input.is_action_just_pressed("Player_Jump") and player._cursorStateMachine.Movement_Allowed():
		# transition to the jump state.
		transitioned.emit(self, PlayerJump.stateName)
	elif !player.is_on_floor(): # else if the player is falling
		# transition to the falling state.
		transitioned.emit(self, PlayerFalling.stateName)
	
