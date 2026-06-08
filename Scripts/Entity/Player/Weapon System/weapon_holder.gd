@tool
class_name WeaponHolder extends Node3D

@export var weapon : Weapon:
	set(value):
		weapon = value
		if Engine.is_editor_hint():
			load_weapon()
@export var weapon_mesh: MeshInstance3D

func _ready() -> void:
	load_weapon()

func load_weapon():
	weapon_mesh.mesh = weapon.mesh
	position = weapon.offsetPosition
	rotation_degrees = weapon.offsetRotation