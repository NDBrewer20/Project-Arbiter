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
	
	# Temporary solution to test hitbox/hurtbox components. 
	# later to be replaced with a call to a specific weapon resource 
	# that will determine which state to transition to (melee, ranged) 
	if Input.is_action_just_pressed("Player_Primary_Fire") and player._cursorStateMachine.Movement_Allowed():
		if player.weaponHolder.weapon.type == Weapon.WEAPON_TYPE.MELEE:
			transitioned.emit(self, PlayerMeleeAttack.stateName)
		else:
			transitioned.emit(self, PlayerRangedAttack.stateName)
	elif Input.is_action_just_pressed("Player_Alternative_Fire") and player._cursorStateMachine.Movement_Allowed():
		if player.weaponHolder.weapon.type == Weapon.WEAPON_TYPE.MELEE:
			PA_Debug.log("TODO: Implement Alternative Firing State (MELEE)")
		else:
			PA_Debug.log("TODO: Implement Alternative Firing State (RANGED)")

	if Input.is_action_just_pressed("Player_Jump") and player._cursorStateMachine.Movement_Allowed():
		transitioned.emit(self, PlayerJump.stateName)
	elif !player.is_on_floor():
		transitioned.emit(self, PlayerFalling.stateName)
	
	player.velocityComponent.AccelerateInDirection(player._inputDirection)
	player.Move()
