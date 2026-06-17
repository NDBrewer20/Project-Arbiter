extends State
class_name PlayerFloor

const stateName := "PlayerFloor"

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
	
	# Temporary solution to test hitbox/hurtbox components.
	# if primary fire was pressed
	if Input.is_action_just_pressed("Player_Primary_Fire") and player._cursorStateMachine.Movement_Allowed():
		# if the player is using a melee weapon.
		if player.weaponHolder.weapon.type == Weapon.WEAPON_TYPE.MELEE:
			# transition to the melee state
			transitioned.emit(self, PlayerMeleeAttack.stateName)
		else: # otherwise the player is using a ranged weapon.
			# transition to the ranged attack state.
			transitioned.emit(self, PlayerRangedAttack.stateName)
	# if alt fire was pressed
	elif Input.is_action_just_pressed("Player_Alternative_Fire") and player._cursorStateMachine.Movement_Allowed():
		# if the player is using a melee weapon.
		if player.weaponHolder.weapon.type == Weapon.WEAPON_TYPE.MELEE:
			PA_Debug.log("TODO: Implement Alternative Firing State (MELEE)")
		else: # otherwise the player is using a ranged weapon.
			PA_Debug.log("TODO: Implement Alternative Firing State (RANGED)")

	# if the player wants to jump.
	if Input.is_action_just_pressed("Player_Jump") and player._cursorStateMachine.Movement_Allowed():
		# transition to the jump state.
		transitioned.emit(self, PlayerJump.stateName)
	elif !player.is_on_floor(): # else if the player is falling
		# transition to the falling state.
		transitioned.emit(self, PlayerFalling.stateName)
	
	# accelerate the player in the direction of player input and move the body.
	player.velocityComponent.AccelerateInDirection(player._inputDirection)
	player.Move()
