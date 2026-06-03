extends Node3D
class_name CameraBehavior

@export var followCoefficient: float = 10

func _physics_process(delta: float) -> void:
	global_position = global_position.lerp(owner.global_position,1-exp(-followCoefficient*delta))