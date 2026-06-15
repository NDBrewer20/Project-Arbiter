extends State
class_name PlayerRangedAttack

const stateName := "PlayerRangedAttack"

@export var player: ThirdPersonPlayer
@export var speedReduction: float = 0.3
@export var fire_timer: Timer
## How many shots are fired per minute (RPM)
@onready var fireRate: float:
	get:
		return 60.0 / player.weaponHolder.weapon.stats.current_fire_rate
var weaponRange: float = 200
@onready var shape_cast: ShapeCast3D = $ShapeCast3D

func _enter() -> void:
	super._enter()
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.
	player.velocityComponent.SetSpeedPercentModifier(stateName,-speedReduction)
	fire_timer.timeout.connect(_hitscan_send_attack)
	if fire_timer.is_stopped():
		_hitscan_send_attack()
		fire_timer.start()


func _hitscan_send_attack():
	shape_cast.global_position = player.weaponHolder.global_position
	shape_cast.target_position = player._cam.project_ray_normal(player._cam.get_viewport().get_visible_rect().size/2) * weaponRange
	shape_cast.force_shapecast_update()
	if shape_cast.is_colliding():
		var hit_count = shape_cast.get_collision_count()
		for i in range(hit_count):
			var hit_object = shape_cast.get_collider(i)
			if !hit_object.has_method("receive_hit"):
				return
			hit_object.receive_hit(player.weaponHolder.weapon.calculate_weapon_damage(), player.statManager.stats)

func _exit() -> void:
	super._exit()
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.
	player.velocityComponent.RemoveSpeedPercentModifier(stateName)
	fire_timer.timeout.disconnect(_hitscan_send_attack)
	

func _update(delta: float):
	super._update(delta)
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.
	if Input.is_action_just_released("Player_Primary_Fire") or !player._cursorStateMachine.Movement_Allowed():
		transitioned.emit(self, PlayerFloor.stateName)

	if !player.is_on_floor():
		transitioned.emit(self, PlayerFalling.stateName)
	elif Input.is_action_just_pressed("Player_Jump"):
		transitioned.emit(self, PlayerJump.stateName)

func _physics_update(delta: float):
	super._physics_update(delta)
	if !player._manager.is_authority: return # Only run this code if this client has authority over the player.
	
	if fire_timer.is_stopped():
		fire_timer.start()

	player.velocityComponent.AccelerateInDirection(player._inputDirection)
	player.Move()
