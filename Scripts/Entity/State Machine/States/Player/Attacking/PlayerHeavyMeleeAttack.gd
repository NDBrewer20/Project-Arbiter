extends State
class_name PlayerHeavyMeleeAttack

const stateName := "PlayerHeavyMeleeAttack"

## reference to the player.
@export var player: ThirdPersonPlayer
## the shape of the hitbox for the melee attack.
@export var hitbox_shape: Shape3D

@export var movementSpeedPenalty: float = 0.5

func _enter() -> void:
	super._enter()
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.

	# add speed modifier to the player to reduce moving while in attacking state.
	player.velocityComponent.SetSpeedPercentModifier(stateName,-movementSpeedPenalty)

	# once a weapons charge has been filled send the attack immediately.
	player.weaponHolder.weapon.stats.charge_filled.connect(_send_attack)

## sends the melee attack paylod.
func _send_attack():
	# forcefully move the player to look at the direction they're facing so they attack is directed properly and doesn't miss.
	player.force_rotate_player()

	_hitscan_send_attack()
	
	# move to the idle state since the charged attack was just sent.
	transitioned.emit(self, PlayerAttackIdle.stateName)
	

func _hitbox_send_attack():
	# create a hitlog for hitbox to log hit enemies.
	var hitlog: Hitlog = Hitlog.new()
	# create hitbox to hit enemies and add it to the attack origin.
	var hitbox = HitboxComponent.new(player.weaponHolder.weapon.stats.current_attack, player.statManager.stats, 0.5, hitbox_shape, hitlog)
	player.attackOrigin.add_child(hitbox)


## function for sending a hitscan attack.
func _hitscan_send_attack():
	# get the position of the shape_cast and set it to the weapon position.
	var startPos := player._cam.global_position
	# set the target to the center of the screen * weapon range
	var ray_dir := player._cam.project_ray_normal(player._cam.get_viewport().get_visible_rect().size / 2)

	# Calculate current spread in degrees
	var weaponSpread := player.weaponHolder.weapon.stats.max_spread * (1.0 - player.weaponHolder.weapon.stats.current_accuracy) 
	var rand_x = randf_range(-weaponSpread, weaponSpread)
	var rand_y = randf_range(-weaponSpread, weaponSpread)

	# Rotate the direction vector using the camera's local axis
	var camera_basis := player._cam.global_transform.basis
	ray_dir = ray_dir.rotated(camera_basis.x, deg_to_rad(rand_x)) # Pitch (Up/Down spread)
	ray_dir = ray_dir.rotated(camera_basis.y, deg_to_rad(rand_y)) # Yaw (Left/Right spread)

	# Multiply by range to get the final target destination
	var tarPos := ray_dir * player.weaponHolder.weapon.stats.weapon_Range

	# create a hitlog for hitbox to log hit enemies.
	var hitlog: Hitlog = Hitlog.new()
	# create hitscan to hit enemies and add it to the attack origin.
	var hitscan = HitscanComponent.new(startPos, tarPos * player.weaponHolder.weapon.stats.weapon_Range, player.weaponHolder.weapon.stats.current_attack, player.statManager.stats, 0.5, hitbox_shape, hitlog)
	player.attackOrigin.add_child(hitscan)


func _exit() -> void:
	super._exit()
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.

	# let the player move freely now that charge state is over.
	player.velocityComponent.RemoveSpeedPercentModifier(stateName)
	player.weaponHolder.weapon.stats.charge_filled.disconnect(_send_attack)

	# reset the charge value at the end of the frame so that any possible damage calculations can go through before charge gets reset
	player.weaponHolder.weapon.stats.reset_charge.call_deferred()

func _update(delta: float):
	super._update(delta)
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.
	if !player.is_on_floor(): # if the player is not on the floor move to idle state
		transitioned.emit(self, PlayerAttackIdle.stateName)


func _physics_update(delta: float):
	super._physics_update(delta)
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.

	# while attack is still being held charge the Heavy attack.
	player.weaponHolder.weapon.stats.charge += float(player.weaponHolder.weapon.stats.current_charge_rate) * delta
	
	# if the player lets go of the heavy attack early then send the attack immediately so they can move on.
	if Input.is_action_just_released("Player_Primary_Fire"):
		_send_attack()
