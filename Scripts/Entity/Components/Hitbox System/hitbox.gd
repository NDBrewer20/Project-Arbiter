class_name HitboxComponent extends Area3D

## Who is creating the hitbox.
var attacker_stats: Stats
## how long the hitbox will live for.
var hitbox_lifetime: float
## shape of the hitbox.
var shape: Shape3D
## what has been hit by the hitbox(s)
var hit_log: Hitlog
## how much damage is supposed to be dealt by this hitbox.
var damage_payload: float = 0.0

## Constructor for hitbox taking the creator's stats, lifetime of hitbox, shape of hitbox, list of recent hits, and the hitbox owner weapon.
func _init(_damage:float, _attacker_stats: Stats, _hitbox_lifetime: float, _shape: Shape3D, _hit_log: Hitlog = null) -> void:
	damage_payload = _damage
	attacker_stats = _attacker_stats
	hitbox_lifetime = _hitbox_lifetime
	shape = _shape
	hit_log = _hit_log

func _ready() -> void:
	monitorable = false
	area_entered.connect(_on_area_entered)

	# if the hitbox has a defined lifetime set a timer to delete it once timer reaches timeout.
	if hitbox_lifetime > 0.0:
		var new_timer = Timer.new()
		add_child(new_timer)
		new_timer.timeout.connect(queue_free)
		new_timer.call_deferred("start", hitbox_lifetime)

	# if the hitbox has a defined shape create the shape and add it to the hitbox.
	if shape:
		var collision_shape = CollisionShape3D.new()
		collision_shape.shape = shape
		add_child(collision_shape)

	# intialize the physics layers according to the faction the owner stats has.
	set_collision_layer_value(PhysicsLayers.NAMED_LAYER.DEFAULT, false)
	set_collision_mask_value(PhysicsLayers.NAMED_LAYER.DEFAULT, false)
	match attacker_stats.faction:
		Stats.FACTION.PLAYER:
			set_collision_mask_value(PhysicsLayers.NAMED_LAYER.ENEMY_HURTBOX, true)
		Stats.FACTION.ENEMY:
			set_collision_mask_value(PhysicsLayers.NAMED_LAYER.PLAYER_HURTBOX, true)
		_:
			PA_Debug.log_warning("hitbox:\nentity_id (%s): Faction not found" % (attacker_stats.owner as Entity)._manager.assigned_id)

func _on_area_entered(area: Area3D) -> void:
	# if you didn't hit a hurtbox don't continue
	if !area.has_method("receive_hit"):
		return

	# get the owner of the hurtbox to check if you've already hit it.
	var hurtbox_owner = area.get_owner()
	if hit_log:
		if hit_log.has_hit(hurtbox_owner):
			return
		else:
			hit_log.log_hit(hurtbox_owner)

	(area as HurtboxComponent).receive_hit(damage_payload, attacker_stats)
