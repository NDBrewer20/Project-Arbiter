extends State
class_name PlayerRangedAttack

const stateName := "PlayerRangedAttack"

## reference to the player.
@export var player: ThirdPersonPlayer
## the shape_cast shape of the weapon (hitscan)
@export var hitscanShape: Shape3D
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

func _enter() -> void:
	super._enter()
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.
	# add speed modifier to the player while firing.
	player.velocityComponent.SetSpeedPercentModifier(stateName,-speedReduction)
	fire_timer.timeout.connect(_hitscan_send_attack) # force an attack when fire_timer times out.
	if fire_timer.is_stopped(): # if the fire_timer is stopped then fire an attack and start it.
		#_hitscan_send_attack()
		fire_timer.start()

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
	var hitscan = HitscanComponent.new(startPos, tarPos, player.weaponHolder.weapon.stats.current_attack, player.statManager.stats, 0.5, hitscanShape, hitlog)
	player.attackOrigin.add_child(hitscan)


func _exit() -> void:
	super._exit()
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.
	player.velocityComponent.RemoveSpeedPercentModifier(stateName) # remove the speed modifier since player will no longer be firing weapon.
	fire_timer.timeout.disconnect(_hitscan_send_attack) # disconnect the hitscan attack payload.
	

func _update(delta: float):
	super._update(delta)
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.
	# as soon as the player releases the primary attack button
	if Input.is_action_just_released("Player_Primary_Fire") or !player._cursorStateMachine.Cursor_Locked():
		# transition to the idle state.
		transitioned.emit(self, PlayerAttackIdle.stateName)

func _physics_update(delta: float):
	super._physics_update(delta)
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.

	if fire_timer.is_stopped(): # if the timer stops start it again.
		fire_timer.start()
