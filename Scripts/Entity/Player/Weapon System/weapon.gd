class_name Weapon extends Resource


enum WEAPON_TYPE{
	MELEE,
	RANGED,
}
@export_category("Weapon Information")
@export var name : StringName
@export var type : WEAPON_TYPE
@export var stats : WeaponStats
@export_category("VFX")
@export var mesh : Mesh
@export var offsetPosition : Vector3
@export var offsetRotation : Vector3

func calculate_weapon_damage() -> float:
	# attack * (1+(chargePercent/2))
	# 10 * (1 + (0.5/2))
	# 10 * (1 + 0.25)
	# 10 * 1.25
	# 12.5
	return stats.current_attack * (1.0+((float(stats.charge)/stats.current_max_charge))/2.0)