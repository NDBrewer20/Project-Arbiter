class_name WeaponStatBuff extends Resource

## depicts whether a buff is [br] 
## multipicative (base_stat * multiplier) [br]
## additive (base_stat + addend)
enum BUFF_TYPE {
	MULTIPLY,
	ADD,
}

## which stat is being buffed.
@export var stat: WeaponStats.BUFFABLE_WEAPON_STATS
## how much does the stat get buffed by.
@export var buff_amount: float
## what type of buff (multiplicative, additive).
@export var buff_type: BUFF_TYPE

## Constructor for a stat buff/debuff taking which stat to buff, the buff amount, and what type of buff.
func _init(_stat: WeaponStats.BUFFABLE_WEAPON_STATS = WeaponStats.BUFFABLE_WEAPON_STATS.ATTACK, _buff_amount: float = 1.0, _buff_type: BUFF_TYPE = BUFF_TYPE.MULTIPLY) -> void:
	stat = _stat
	buff_type = _buff_type
	buff_amount = _buff_amount