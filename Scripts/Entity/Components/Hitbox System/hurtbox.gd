extends Area3D
class_name HurtboxComponent

## the stats of the owner of the hurtbox
@export var owner_statManager: StatManager

func _ready() -> void:
	monitoring = false

	# intialize hurtbox physics layers.
	set_collision_layer_value(PhysicsLayers.NAMED_LAYER.DEFAULT, false)
	set_collision_mask_value(PhysicsLayers.NAMED_LAYER.DEFAULT, false)
	match owner_statManager.stats.faction:
		Stats.FACTION.PLAYER:
			set_collision_layer_value(PhysicsLayers.NAMED_LAYER.PLAYER_HURTBOX, true)
		Stats.FACTION.ENEMY:
			set_collision_layer_value(PhysicsLayers.NAMED_LAYER.ENEMY_HURTBOX, true)
		_:
			PA_Debug.log_warning("Hurtbox:\nentity_id (%s): Faction not set" % (owner as Entity)._manager.assigned_id)

## apply the damage from the attacker hitbox to the owner's health
func receive_hit(damage: float, attacker_stats: Stats) -> void:
	# apply the incoming damage to the owner's health.
	owner_statManager.stats.apply_incoming_damage(damage, attacker_stats)
	# inform the server that the owner was damaged.
	if !(owner as Entity)._manager.is_server:
		Packet_EntityDamaged.create(damage, attacker_stats.owner._manager.assigned_id, owner._manager.assigned_id).send(LowLevelNetworkHandler.server_peer)
	else: # if you are the server let everyone else know of the entity being damaged.
		Packet_EntityDamaged.create(damage, attacker_stats.owner._manager.assigned_id, owner._manager.assigned_id).broadcast(LowLevelNetworkHandler.connection)

