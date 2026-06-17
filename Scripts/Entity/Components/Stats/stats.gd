@tool
extends Resource
class_name Stats

## define the max level achieveable by the instances of stats.
const MAX_LEVEL = 7
## list of buffable stats for a stat block.
enum BUFFABLE_STATS {
	MAX_HEALTH,
	POWER,
	DEFENSE,
	ATTACK,
	UNARMED_DAMAGE,
}
## the curves that define what multiplier is applied to a stat based on level. [br] 
## (Ex. level 2 could have 2x the stat of level 1)
@export var STAT_CURVES: Dictionary[BUFFABLE_STATS, Curve]

## emitted when stats health gets set to 0 (or less)
signal health_depleted
## emitted whenever the stats health value changes
signal health_changed(cur_health: float, max_health: float)
## emitted when stats power gets set to 0 (or less)
signal power_depleted
## emitted whenever the stats power value changes.
signal power_changed(cur_resource:int, max_resource:int)

## list of possible factions a stat block can belong to.
enum FACTION {
	ENEMY,
	PLAYER,
}
## which faction does this stat block belong to.
@export var faction: FACTION

## baseline max health of a given stat block.
@export var base_max_health: float = 100
## baseline max power of a given stat block.
@export var base_max_power: int = 100
## baseline defense of a given stat block.
@export var base_defense: float = 10
## baseline attack power of a given stat block.
@export var base_attack: float = 10
## baseline amount of unarmed damage for a given stat block.
@export var base_unarmed_damage: float = 10

## the current level of this specific stat block.
@export_range(1,MAX_LEVEL) var level: int = 1: set = _on_level_set

# important to note that current_stat_name means that it's the final value after all stat value modifiations (buffs + level multipliers)
## the current max health of a stat block
var current_max_health: float = 100
## current max power of a stat block.
var current_max_power: int = 100
## current defense power of a stat block.
var current_defense: float = 10
## current attack power of a stat block.
var current_attack: float = 10
## current unarmed damage for a stat block.
var current_unarmed_damage: float = 10

## current health value of a stat block.
var health : float = 0 : set = _on_health_set
## current power amount of a stat block.
var power: int = 0 : set = _on_power_set

## list of stat buffs applied to the stat block.
var stat_buffs: Array[StatBuff]

## owner of the stat block.
var owner: Node

## constructor for a stat block.
func _init() -> void:
	setup_stats.call_deferred()

## initial call to setup the stat block before owner is ready.
func setup_stats() -> void:
	recalculate_stats()
	health = current_max_health

## Setter for level variable
func _on_level_set(new_value: int) -> void:
	level = clampi(new_value, 1, MAX_LEVEL)
	recalculate_stats()

## adds a buff to the list of active buffs on this stat block.
func add_buff(buff: StatBuff) -> void:
	# add stat to buff list.
	stat_buffs.append(buff)

	# call for a recalculation at end of frame to apply all buffs that were applied this frame to stat block.
	delayed_recalculate_stats()

## removes a buff from list of active buffs on this stat block.
func remove_buff(buff: StatBuff) -> StatBuff:
	# retrieve the buff from list of stat buffs and remove it from list of active buffs
	var _buff = stat_buffs[buff]
	stat_buffs.erase(buff)

	# call for a recalculation at end of frame to apply all buffs that were applied this frame to stat block.
	delayed_recalculate_stats()
	
	# return the removed buff.
	return _buff

## determines if a recalculate stats is going to be called at end of frame.
var is_recalculate_delayed: bool = false
## delays the recalculate stats call to end of frame if it hasn't already been called.
func delayed_recalculate_stats()->void:
	# don't queue another recalculation if one is already scheduled.
	if !is_recalculate_delayed:
		is_recalculate_delayed = true # prevent another from executing recalculation
		recalculate_stats.call_deferred() # defer recalculation to end of frame

## Setter for stat block health variable.
func _on_health_set(new_value: float) -> void:
	# don't let the health go negative or past current_max_health
	health = clampf(new_value, 0, current_max_health)
	health_changed.emit(health, current_max_health) # health changed so emit signal.

	# if stat block health goes to 0 or below then emit signal to let connected functions know health has been depleted.
	if health <= 0: 
		health_depleted.emit()

## calculate the amount of damage that would happen based on incoming damage and attacker stats to [b]self[/b] stat block [br]
## see [apply_incoming_damage] to effect the health of the stat block based on parameters.
func calculate_incoming_damage(incoming_damage: float, attack_stats: Stats) -> float:
	var dam = incoming_damage * (attack_stats.current_attack / max(current_defense,1.0))
	return dam
## calculate and apply the incoming damage [br]
## see [calculate_incoming_damage] for amount of damage without application.
func apply_incoming_damage(incoming_damage: float, attack_stats: Stats):
	# calculate the incoming damage and apply it.
	var dam = calculate_incoming_damage(incoming_damage,attack_stats)
	health -= dam
	PA_Debug.log("entity_id (%s) took %s damage, current health is %s" % [owner._manager.assigned_id, dam, health])

## calculate the damage that would take place between two stat blocks (attacker/defender)
static func calculate_damage(base_damage: float, attack_stats: Stats, defense_stats: Stats) -> float:
	var dam = defense_stats.calculate_incoming_damage(base_damage,attack_stats)
	return dam

## setter function for power variable.
func _on_power_set(new_value: int) -> void:
	# clamp the power value between 0 and max power.
	power = clampi(new_value, 0, current_max_power)
	power_changed.emit(power, current_max_power) # power changed so emit signal.
	# if the power gets depleted signal connected functions to run.
	if power <= 0:
		power_depleted.emit()

## recalculate the stats of the stat block.
func recalculate_stats() -> void:
	# fetch all stats multipliers and addends based on active buffs.
	var stat_multipliers: Dictionary = {}
	var stat_addends: Dictionary = {}
	for buff in stat_buffs:
		# name of stat being buffed.
		var stat_name : String = BUFFABLE_STATS.keys()[buff.stat].to_lower()
		# based on buff type (additive, multiplicative)
		match buff.buff_type:
			# if additive then add the buff amount to the current stat being buffed.
			StatBuff.BuffType.ADD:
				if !stat_addends.has(stat_name): # if [stat_addends] dictionary doesn't have instance of current stat then create it.
					stat_addends[stat_name] = 0.0
				# add the buff amount to the [stat_addends] dictionary.
				stat_addends[stat_name] += buff.buff_amount

			# if multiplicative then add the multiplier to the corresponding multiplier.
			StatBuff.BuffType.MULTIPLY:
				if !stat_multipliers.has(stat_name): # if [stat_multipliers] dictionary doesn't have instance of current stat then create it.
					stat_multipliers[stat_name] = 1.0 # don't want base case to multiply value by 0
				# add buff amount to the [stat_multiplier] dictionary
				stat_multipliers[stat_name] += buff.buff_amount

				# if adding the multiplier would result in a value less than 0 then set to 0
				if stat_multipliers[stat_name] < 0:
					stat_multipliers[stat_name] = 0

	# find a position to sample on the curve.
	var stat_sample_pos: float = (float(level)/MAX_LEVEL)
	# set the current stat values to the base value * level multiplier.
	current_max_health = base_max_health * STAT_CURVES[BUFFABLE_STATS.MAX_HEALTH].sample(stat_sample_pos)
	current_max_power = base_max_power * round(STAT_CURVES[BUFFABLE_STATS.POWER].sample(stat_sample_pos))
	current_defense = base_defense * STAT_CURVES[BUFFABLE_STATS.DEFENSE].sample(stat_sample_pos)
	current_attack = base_attack * STAT_CURVES[BUFFABLE_STATS.ATTACK].sample(stat_sample_pos)
	current_unarmed_damage = base_unarmed_damage * STAT_CURVES[BUFFABLE_STATS.UNARMED_DAMAGE].sample(stat_sample_pos)

	# for each buffable stat apply the modifiers to the corresponding stat.
	for stat_name in stat_multipliers:
		var cur_property_name: String = str("current_" + stat_name)
		set(cur_property_name, get(cur_property_name) * stat_multipliers[stat_name])
	for stat_name in stat_addends:
		var cur_property_name: String = str("current_" + stat_name)
		set(cur_property_name, get(cur_property_name) + stat_addends[stat_name])
	
	# if this was called during a delayed recalculation then allow another recalcuation to be queued.
	if is_recalculate_delayed:
		is_recalculate_delayed = false
