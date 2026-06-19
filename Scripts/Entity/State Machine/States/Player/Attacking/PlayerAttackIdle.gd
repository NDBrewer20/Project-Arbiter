extends State
class_name PlayerAttackIdle

const stateName := "PlayerAttackIdle"

## reference to the player.
@export var player: ThirdPersonPlayer

var last_attack_pressed: float = 0.0
var heavyAttack: bool:
	get:
		return player._timeSinceFirstFrame > last_attack_pressed + 0.2
var meleeIntent: bool = false

func _enter() -> void:
	super._enter()
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.

func _exit() -> void:
	super._exit()
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.
	last_attack_pressed = 0.0
	meleeIntent = false

func _update(delta: float):
	super._update(delta)
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.
	match player.weaponHolder.weapon.type:
		Weapon.WEAPON_TYPE.MELEE:
			if player.is_on_floor() and player._cursorStateMachine.Cursor_Locked(): # don't let melee attacks be queued if the player isn't on the floor.
				if Input.is_action_just_pressed("Player_Primary_Fire"): # if the player just pressed attack note the time.
					last_attack_pressed = player._timeSinceFirstFrame
					meleeIntent = true
				# if the player lets go of attack before the heavy attack window comes up then go to the light attack combo.
				if Input.is_action_just_released("Player_Primary_Fire") and !heavyAttack and meleeIntent:
					transitioned.emit(self, PlayerMeleeAttack.stateName)
					return
				# if the player is still holding the attack button and the heavy attack window comes up then go to the heavy attack combo.
				elif Input.is_action_pressed("Player_Primary_Fire") and heavyAttack and meleeIntent:
					transitioned.emit(self,PlayerHeavyMeleeAttack.stateName)
					return
		Weapon.WEAPON_TYPE.RANGED:
			if player._cursorStateMachine.Cursor_Locked():
				if Input.is_action_pressed("Player_Primary_Fire"):
					transitioned.emit(self, PlayerRangedAttack.stateName)
					return
				if Input.is_action_just_pressed("Player_Alternative_Fire"):
					transitioned.emit(self,PlayerShove.stateName)
					return
	

func _physics_update(delta: float):
	super._physics_update(delta)
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.
