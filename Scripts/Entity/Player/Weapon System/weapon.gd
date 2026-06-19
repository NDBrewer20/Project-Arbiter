class_name Weapon extends Resource

## What type of weapons are usable
enum WEAPON_TYPE{
	MELEE,
	RANGED,
}
@export_category("Weapon Information")
## name of the weapon
@export var name : StringName
## what type of weapon is in use.
@export var type : WEAPON_TYPE
## what stats the weapon uses.
@export var stats : WeaponStats
@export_category("VFX")
## how the weapon looks
@export var mesh : Mesh
## where the weapon will be positioned relative to the weapon holder.
@export var offsetPosition : Vector3
## how the weapon will be rotated relative to the weapon holder [br]
## [b]uses rotation_degrees[/b]
@export var offsetRotation : Vector3

## calculate the damage of the weapon based on its stats and current charge value..
func calculate_weapon_damage() -> float:
	return stats.current_attack * (1.0+(stats.chargePercent/2))