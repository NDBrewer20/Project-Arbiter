extends Area3D
class_name HurtboxComponent

@export var owner_statManager: StatManager

func _ready() -> void:
	monitoring = false

	set_collision_layer_value(PhysicsLayers.NAMED_LAYER.DEFAULT, false)
	set_collision_mask_value(PhysicsLayers.NAMED_LAYER.DEFAULT, false)
	match owner_statManager.stats.faction:
		Stats.FACTION.PLAYER:
			set_collision_layer_value(PhysicsLayers.NAMED_LAYER.PLAYER_HURTBOX, true)
		Stats.FACTION.ENEMY:
			set_collision_layer_value(PhysicsLayers.NAMED_LAYER.ENEMY_HURTBOX, true)

func receive_hit(damage: int, attacker_stats: Stats) -> void:
	owner_statManager.stats.apply_incoming_damage(damage, attacker_stats)
	Packet_EntityDamaged.create(damage, attacker_stats.owner._manager.assigned_id, owner._manager.assigned_id).send(LowLevelNetworkHandler.server_peer)
