extends Node3D

@export var follow_target: Node3D
@export var follow_Offset: Vector3 = Vector3(0, 2, 4)
@export var follow_Smoothing: float = 5.0

var previous_Follow_Target_Position: Vector3

func _ready() -> void:
	previous_Follow_Target_Position = follow_target.global_position

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	var smoothed_follow_position = previous_Follow_Target_Position.lerp(follow_target.global_position, delta * follow_Smoothing)

	global_position = smoothed_follow_position + follow_Offset

	previous_Follow_Target_Position = follow_target.global_position
