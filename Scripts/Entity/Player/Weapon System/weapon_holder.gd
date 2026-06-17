@tool
class_name WeaponHolder extends Node3D

## the current weapon being used by this holder.
@export var weapon : Weapon:
	set(value):
		weapon = value
		if weapon:
			load_weapon()
## the reference to the mesh of the weapon holder instance.
@export var weapon_mesh: MeshInstance3D

func _ready() -> void:
	# load the weapon when ready.
	load_weapon()

## loads the weapon details to the corresponding parts (mesh, position, rotation)
func load_weapon():
	weapon_mesh.mesh = weapon.mesh
	position = weapon.offsetPosition
	rotation_degrees = weapon.offsetRotation