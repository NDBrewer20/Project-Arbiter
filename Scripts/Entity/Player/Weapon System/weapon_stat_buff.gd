class_name WeaponStatBuff extends Resource

enum BUFF_TYPE {
	MULTIPLY,
	ADD,
}

@export var stat: WeaponStats.BUFFABLE_WEAPON_STATS
@export var buff_amount: float
@export var buff_type: BUFF_TYPE

func _init(_stat: WeaponStats.BUFFABLE_WEAPON_STATS = WeaponStats.BUFFABLE_WEAPON_STATS.ATTACK, _buff_amount: float = 1.0, _buff_type: BUFF_TYPE = BUFF_TYPE.MULTIPLY) -> void:
	stat = _stat
	buff_type = _buff_type
	buff_amount = _buff_amount