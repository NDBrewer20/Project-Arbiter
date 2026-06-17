extends State
class_name PlayerRangedAttack

const stateName := "PlayerRangedAttack"

## reference to the player.
@export var player: ThirdPersonPlayer
# how much the players speed is reduced while firing.
@export var speedReduction: float = 0.3
## reference to the timer that prevents firing weapon until timeout.
@export var fire_timer: Timer
## How many shots are fired per minute (RPM)
@onready var fireRate: float:
	get:
		return 60.0 / player.weaponHolder.weapon.stats.current_fire_rate
## how far can the weapon shoot.
var weaponRange: float = 200
## the shape_cast of the weapon (hitscan)
@onready var shape_cast: ShapeCast3D = $ShapeCast3D

func _enter() -> void:
	super._enter()
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.
	# add speed modifier to the player while firing.
	player.velocityComponent.SetSpeedPercentModifier(stateName,-speedReduction)
	fire_timer.timeout.connect(_hitscan_send_attack) # force an attack when fire_timer times out.
	if fire_timer.is_stopped(): # if the fire_timer is stopped then fire an attack and start it.
		_hitscan_send_attack()
		fire_timer.start()

## function for sending a hitscan attack.
func _hitscan_send_attack():
	# get the position of the shape_cast and set it to the weapon position.
	shape_cast.global_position = player.weaponHolder.global_position
	# set the target to the center of the screen * weapon range
	shape_cast.target_position = player._cam.project_ray_normal(player._cam.get_viewport().get_visible_rect().size/2) * weaponRange
	# force a physics calculation for the shape cast.
	shape_cast.force_shapecast_update()
	# if it collides with something.
	if shape_cast.is_colliding():
		# get how many collisions happened
		var hit_count = shape_cast.get_collision_count()
		for i in range(hit_count):
			# get the collision object and check if it has a hurtbox method.
			var hit_object = shape_cast.get_collider(i)
			if !hit_object.has_method("receive_hit"):
				return
			# if it has hurtbox then hit the hurtbox using ranged weapon stats.
			hit_object.receive_hit(player.weaponHolder.weapon.calculate_weapon_damage(), player.statManager.stats)

func _exit() -> void:
	super._exit()
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.
	player.velocityComponent.RemoveSpeedPercentModifier(stateName) # remove the speed modifier since player will no longer be firing weapon.
	fire_timer.timeout.disconnect(_hitscan_send_attack) # disconnect the hitscan attack payload.
	

func _update(delta: float):
	super._update(delta)
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.
	# as soon as the player releases the primary attack button
	if Input.is_action_just_released("Player_Primary_Fire") or !player._cursorStateMachine.Movement_Allowed():
		# transition to the floor state.
		transitioned.emit(self, PlayerFloor.stateName)

	# if the player leaves the floor then go the falling state.
	if !player.is_on_floor():
		transitioned.emit(self, PlayerFalling.stateName)
	elif Input.is_action_just_pressed("Player_Jump"): # else if the player jumps go to jumping state.
		transitioned.emit(self, PlayerJump.stateName)

func _physics_update(delta: float):
	super._physics_update(delta)
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.
	
	if fire_timer.is_stopped(): # if the timer stops start it again.
		fire_timer.start()

	# allow the player to move toward input direction and move body.
	player.velocityComponent.AccelerateInDirection(player._inputDirection)
	player.Move()
