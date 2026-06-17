class_name WeaponStats extends Resource

## signal is emitted when charge reaches max_charge
signal charge_filled
## signal is emitted everytime charge changes.
signal charge_changed(cur_charge:int, max_charge:int)

## baseline the maximum amount that a weapon has to reach to be fully charged.
@export var base_max_charge: int = 100
## baseline how much charge is generated in one second
@export var base_charge_rate: int = 50
## baseline amount of damage a weapon deals.
@export var base_attack: float = 10
## baseline how many shots per minute (RPM)
@export var base_fire_rate: int = 150


# important to note that current_stat_name means that it's the final value after all stat value modifiations (buffs + level multipliers)
## the current max charge of a stat block
var current_max_charge: int = 100
## the current charge rate of stat block.
var current_charge_rate: int = 50
## the current attack power of a stat block.
var current_attack: float = 10
## the current fire rate of a stat block.
var current_fire_rate: int = 150

## the current charge amount.
var charge: int = 0 : set = _on_charge_set
## what percent the charge has reached.
var chargePercent: float:
	get:
		return float(charge) / current_max_charge

## list of stat buffs being applied to the weapon.
var stat_buffs: Array[WeaponStatBuff]
enum BUFFABLE_WEAPON_STATS {
	CHARGE,
	CHARGE_RATE,
	ATTACK,
}

## constructor for a stat block.
func _init() -> void:
	setup_stats.call_deferred()

## initial call to setup the stat block before owner is ready.
func setup_stats() -> void:
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

## setter for charge variable
func _on_charge_set(new_value: int) -> void:
	charge = clampi(new_value, 0, current_max_charge) # clamp the charge (cannot go negative or above max charge)
	charge_changed.emit(charge, current_max_charge) # charge was changed so emit signal.
	if charge >= current_max_charge: # if charge has been filled to maximum then emit signal.
		charge_filled.emit()

## recalculate the stats of the stat block.
func recalculate_stats() -> void:
	# fetch all stats multipliers and addends based on active buffs.
	var stat_multipliers: Dictionary = {}
	var stat_addends: Dictionary = {}
	for buff in stat_buffs:
		# name of stat being buffed.
		var stat_name : String = BUFFABLE_WEAPON_STATS.keys()[buff.stat].to_lower()
		# based on buff type (additive, multiplicative)
		match buff.BUFF_TYPE:
			# if additive then add the buff amount to the current stat being buffed.
			WeaponStatBuff.BUFF_TYPE.ADD:
				if not stat_addends.has(stat_name): # if [stat_addends] dictionary doesn't have instance of current stat then create it.
					stat_addends[stat_name] = 0.0
				# add the buff amount to the [stat_addends] dictionary.
				stat_addends[stat_name] += buff.buff_amount

			# if multiplicative then add the multiplier to the corresponding multiplier.
			WeaponStatBuff.BUFF_TYPE.MULTIPLY:
				if !stat_multipliers.has(stat_name): # if [stat_multipliers] dictionary doesn't have instance of current stat then create it.
					stat_multipliers[stat_name] = 1.0 # don't want base case to multiply value by 0
				# add buff amount to the [stat_multiplier] dictionary
				stat_multipliers[stat_name] += buff.buff_amount

				# if adding the multiplier would result in a value less than 0 then set to 0
				if stat_multipliers[stat_name] < 0:
					stat_multipliers[stat_name] = 0

	# intialize the stats based on their baseline values.
	current_max_charge = base_max_charge
	current_attack = base_attack
	current_charge_rate = base_charge_rate
	current_fire_rate = base_fire_rate

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
