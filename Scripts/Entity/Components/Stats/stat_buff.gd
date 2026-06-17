extends Resource
class_name StatBuff

## depicts whether a buff is [br] 
## multipicative (base_stat * multiplier) [br]
## additive (base_stat + addend)
enum BuffType {
	MULTIPLY,
	ADD,
}

## Which stat is being buffed.
@export var stat: Stats.BUFFABLE_STATS
## how much does the stat get buffed by.
@export var buff_amount: float
## what type of buff (multiplicative, additive).
@export var buff_type: BuffType

## Constructor for a stat buff/debuff taking which stat to buff, the buff amount, and what type of buff.
func _init(_stat: Stats.BUFFABLE_STATS = Stats.BUFFABLE_STATS.MAX_HEALTH, _buff_amount: float = 1.0, _buff_type: BuffType = BuffType.MULTIPLY) -> void:
	stat = _stat
	buff_type = _buff_type
	buff_amount = _buff_amount