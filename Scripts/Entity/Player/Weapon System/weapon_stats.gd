class_name WeaponStats extends Resource

signal charge_filled
signal charge_changed(cur_charge:int, max_charge:int)

@export var base_max_charge: int = 100
## How much charge is generated in one second
@export var base_charge_rate: int = 50
@export var base_attack: float = 10
## how many shots per minute (RPM)
@export var base_fire_rate: int = 150

var current_max_charge: int = 100
var current_charge_rate: int = 50
var current_attack: float = 10
var current_fire_rate: int = 150

var charge: int = 0 : set = _on_charge_set

var stat_buffs: Array[WeaponStatBuff]
enum BUFFABLE_WEAPON_STATS {
	CHARGE,
	CHARGE_RATE,
	ATTACK,
}

func _init() -> void:
	setup_stats.call_deferred()


func setup_stats() -> void:
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

func _on_charge_set(new_value: int) -> void:
	charge = clampi(new_value, 0, current_max_charge)
	charge_changed.emit(charge, current_max_charge)
	if charge >= current_max_charge:
		charge_filled.emit()

func recalculate_stats() -> void:
	var stat_multipliers: Dictionary = {}
	var stat_addends: Dictionary = {}
	for buff in stat_buffs:
		var stat_name : String = BUFFABLE_WEAPON_STATS.keys()[buff.stat].to_lower()
		match buff.BUFF_TYPE:
			WeaponStatBuff.BUFF_TYPE.ADD:
				if not stat_addends.has(stat_name):
					stat_addends[stat_name] = 0.0
				stat_addends[stat_name] += buff.buff_amount

			WeaponStatBuff.BUFF_TYPE.MULTIPLY:
				if !stat_multipliers.has(stat_name):
					stat_multipliers[stat_name] = 1.0
				stat_multipliers[stat_name] += buff.buff_amount

				if stat_multipliers[stat_name] < 0:
					stat_multipliers[stat_name] = 0

	current_max_charge = base_max_charge
	current_attack = base_attack
	current_charge_rate = base_charge_rate
	current_fire_rate = base_fire_rate

	for stat_name in stat_multipliers:
		var cur_property_name: String = str("current_" + stat_name)
		set(cur_property_name, get(cur_property_name) * stat_multipliers[stat_name])
	for stat_name in stat_addends:
		var cur_property_name: String = str("current_" + stat_name)
		set(cur_property_name, get(cur_property_name) + stat_addends[stat_name])

