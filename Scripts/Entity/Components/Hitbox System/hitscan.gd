class_name HitscanComponent extends ShapeCast3D

## Who is creating the hitbox.
var attacker_stats: Stats
## what has been hit by the hitscan(s)
var hit_log: Hitlog
## starting point of the hitscan.
var origin: Vector3
## global position of the target position of hitscan.
var tarPos: Vector3
##
var damage_payload: float = 0.0

## Constructor for hitbox taking the creator's stats, lifetime of hitbox, desiredShape of hitbox, list of recent hits, and the hitbox owner weapon.
func _init(startPos: Vector3, _tarPos: Vector3, _damage:float, _attacker_stats: Stats, _hitbox_lifetime: float, _desiredShape: Shape3D, _hit_log: Hitlog = null) -> void:
	origin = startPos
	tarPos = _tarPos
	damage_payload = _damage
	attacker_stats = _attacker_stats
	shape = _desiredShape
	hit_log = _hit_log

func _ready() -> void:
	global_position = origin
	target_position = to_local(tarPos+origin)

	collide_with_areas = true
	collide_with_bodies = false
	# intialize the physics layers according to the faction the owner stats has.
	set_collision_mask_value(PhysicsLayers.NAMED_LAYER.DEFAULT, false)
	match attacker_stats.faction:
		Stats.FACTION.PLAYER:
			set_collision_mask_value(PhysicsLayers.NAMED_LAYER.ENEMY_HURTBOX, true)
		Stats.FACTION.ENEMY:
			set_collision_mask_value(PhysicsLayers.NAMED_LAYER.PLAYER_HURTBOX, true)
		_:
			PA_Debug.log_warning("hitscan:\nentity_id (%s): Faction not found" % (attacker_stats.owner as Entity)._manager.assigned_id)
	
func _physics_process(_delta: float) -> void:
	force_shapecast_update()
	if is_colliding():
		hitscan_colliding()

	queue_free.call_deferred()

func hitscan_colliding():
	# get how many collisions happened
	var hit_count = get_collision_count()
	for i in range(hit_count):
		# get the collision object and check if it has a hurtbox method.
		var hit_object = get_collider(i)
		if hit_object is not HurtboxComponent:
			return

		# get the owner of the hurtbox to check if you've already hit it.
		var hurtbox_owner = hit_object.get_owner()
		if hit_log:
			if hit_log.has_hit(hurtbox_owner):
				continue
			else:
				hit_log.log_hit(hurtbox_owner)

		# if it has hurtbox then hit the hurtbox using ranged weapon stats.
		(hit_object as HurtboxComponent).receive_hit(damage_payload,attacker_stats)
