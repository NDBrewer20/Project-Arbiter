extends State
class_name PlayerFloor

const stateName := "PlayerFloor"

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
	
	if Input.is_action_just_pressed("Player_Jump"):
		transitioned.emit(self, PlayerJump.stateName)
	elif !player.is_on_floor():
		transitioned.emit(self, PlayerFalling.stateName)
	
	player.velocityComponent.AccelerateInDirection(player._inputDirection)
	player._lastOnFloor = player.is_on_floor()
	player.velocityComponent.Move(player)