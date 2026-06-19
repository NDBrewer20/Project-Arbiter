extends Node3D
class_name CameraBehavior

## how quickly the camera will attempt to follow the target
@export var followCoefficient: float = 10
## what the camera is trying to follow
@export var target: Node3D = owner

func _physics_process(delta: float) -> void:
	## set the position to the interpolated position between the current position and the target position by blend using follow coefficient.
	global_position = global_position.lerp(target.global_position,1-exp(-followCoefficient*delta))
