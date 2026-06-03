extends Area3D
class_name HurtboxComponent

@onready var owner_stats: Stats = owner.stats

func _ready() -> void:
	monitoring = false

	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	match owner_stats.faction:
		Stats.FACTION.PLAYER:
			set_collision_layer_value(32, true)
		Stats.FACTION.ENEMY:
			set_collision_layer_value(31, true)

func receive_hit(damage: int, attacker_stats: Stats) -> void:
	owner_stats.apply_incoming_damage(damage, attacker_stats.current_attack)