extends Resource
class_name Stats

const MAX_LEVEL = 7
enum buffableStats {
	MAX_HEALTH,
	RESOURCE,
	DEFENSE,
	ATTACK,
}
@export var STAT_CURVES: Dictionary[buffableStats, Curve]

signal health_depleted
signal health_changed(cur_health: float, max_health: float)
signal resource_depleted
signal resource_changed(cur_resource:int, max_resource:int)

enum FACTION {
	ENEMY,
	PLAYER,
}
@export var faction: FACTION

@export var base_max_health: float = 100
@export var base_max_resource: int = 100
@export var base_defense: float = 10
@export var base_attack: float = 10

@export_range(1,MAX_LEVEL) var level: int = 1: set = _on_level_set

var current_max_health: float = 100
var current_max_resource: int = 100
var current_defense: float = 10
var current_attack: float = 10

var health : float = 0 : set = _on_health_set
var resource: int = 0 : set = _on_resource_set

var stat_buffs: Array[StatBuff]

var owner: Node

func _init() -> void:
	setup_stats.call_deferred()

## Communicate to the client the stat block values that need to be updated.
func _fetch_current_stat_values(peer_id: int):
	if !LowLevelNetworkHandler.is_server: return
	await owner.get_tree().physics_frame
	PA_Debug.log("server: telling client_id (%s) to update stat values of entity_id (%s)" % [peer_id,owner._manager.assigned_id])
	Packet_EntityStats.create(owner._manager.assigned_id, self).send(LowLevelNetworkHandler.client_peers[peer_id])

func _set_current_stat_values(packet_stats: Packet_EntityStats):
	if owner._manager.assigned_id != packet_stats.id: return
	await owner.get_tree().physics_frame
	PA_Debug.log("client_id (%s): Updating entity_id (%s) stat values" % [ClientNetworkGlobals.id,packet_stats.id])
	health = packet_stats.health
	resource = packet_stats.resource
	recalculate_stats()


func setup_stats() -> void:
	recalculate_stats()
	health = current_max_health

func _on_level_set(new_value: int) -> void:
	level = clampi(new_value, 1, MAX_LEVEL)
	recalculate_stats()

func add_buff(buff: StatBuff) -> void:
	stat_buffs.append(buff)
	if !is_recalculate_delayed:
		is_recalculate_delayed = true
		delayed_recalculate_stats.call_deferred()

func remove_buff(buff: StatBuff) -> StatBuff:
	var _buff = stat_buffs[buff]
	stat_buffs.erase(buff)
	if !is_recalculate_delayed: 
		is_recalculate_delayed = true
		delayed_recalculate_stats.call_deferred()
	return _buff

var is_recalculate_delayed: bool = false
func delayed_recalculate_stats()->void:
	is_recalculate_delayed = false
	recalculate_stats()
	
func _on_health_set(new_value: float) -> void:
	health = clampf(new_value, 0, current_max_health)
	health_changed.emit(health, current_max_health)
	if health <= 0:
		health_depleted.emit()

func calculate_incoming_damage(incoming_damage: float, attack_stats: Stats) -> float:
	var dam = incoming_damage * (attack_stats.current_attack / (attack_stats.current_attack + base_defense))
	return dam
func apply_incoming_damage(incoming_damage: float, attack_stats: Stats):
	var dam = calculate_incoming_damage(incoming_damage,attack_stats)
	health -= dam
	PA_Debug.log("entity_id (%s) took %s damage, current health is %s" % [owner._manager.assigned_id, dam, health])

static func calculate_damage(base_damage: float, attack_stats: Stats, defense_stats: Stats) -> float:
	var dam = base_damage * (attack_stats.current_attack / (attack_stats.current_attack + defense_stats.current_defense))
	return dam

func _on_resource_set(new_value: int) -> void:
	resource = clampi(new_value, 0, current_max_resource)
	resource_changed.emit(resource, current_max_resource)
	if resource <= 0:
		resource_depleted.emit()

func recalculate_stats() -> void:
	var stat_multipliers: Dictionary = {}
	var stat_addends: Dictionary = {}
	for buff in stat_buffs:
		var stat_name : String = buffableStats.keys()[buff.stat].to_lower()
		match buff.buff_type:
			StatBuff.BuffType.ADD:
				if not stat_addends.has(stat_name):
					stat_addends[stat_name] = 0.0
				stat_addends[stat_name] += buff.buff_amount

			StatBuff.BuffType.MULTIPLY:
				if !stat_multipliers.has(stat_name):
					stat_multipliers[stat_name] = 1.0
				stat_multipliers[stat_name] += buff.buff_amount

				if stat_multipliers[stat_name] < 0:
					stat_multipliers[stat_name] = 0

	var stat_sample_pos: float = (float(level)/MAX_LEVEL) - 0.01
	current_max_health = base_max_health * STAT_CURVES[buffableStats.MAX_HEALTH].sample(stat_sample_pos)
	current_max_resource = base_max_resource * round(STAT_CURVES[buffableStats.RESOURCE].sample(stat_sample_pos))
	current_defense = base_defense * STAT_CURVES[buffableStats.DEFENSE].sample(stat_sample_pos)
	current_attack = base_attack * STAT_CURVES[buffableStats.ATTACK].sample(stat_sample_pos)

	for stat_name in stat_multipliers:
		var cur_property_name: String = str("current_" + stat_name)
		set(cur_property_name, get(cur_property_name) * stat_multipliers[stat_name])
	for stat_name in stat_addends:
		var cur_property_name: String = str("current_" + stat_name)
		set(cur_property_name, get(cur_property_name) + stat_addends[stat_name])
