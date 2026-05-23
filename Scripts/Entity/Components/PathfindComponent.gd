class_name PathfindComponent extends Node3D

@export_category("References")
@export var velocityComponent: VelocityComponent
@onready var _intervalTimer: Timer = $"Interval Timer"
@onready var navAgent: NavigationAgent3D = $"NavigationAgent3D"
@onready var parent: Node3D = get_parent() as Node3D


func _ready() -> void:
	navAgent.velocity_computed.connect(_on_velocity_computed)
	navAgent.link_reached.connect(_on_navigation_link_reached)

func SetTargetPosition(tarPos: Vector3) -> void:
	if !_intervalTimer.is_stopped(): return

	_intervalTimer.start()
	navAgent.target_position = tarPos

func ForceSetTargetPosition(tarPos: Vector3) -> void:
	navAgent.target_position = tarPos
	_intervalTimer.start()

func FollowPath() -> void:
	if navAgent.is_navigation_finished():
		velocityComponent.Decelerate()
		return

	var direction = (navAgent.get_next_path_position()-global_position).normalized()
	velocityComponent.AccelerateInDirection(direction)
	if navAgent.avoidance_enabled:
		navAgent.velocity = velocityComponent.velocity
	else:
		_on_velocity_computed(velocityComponent.velocity)

func _on_navigation_link_reached(details: Dictionary) -> void:
	var nav_link_end_position: Vector3 = details.link_exit_position
	parent.global_position = nav_link_end_position

func _on_velocity_computed(velocity: Vector3) -> void:
	var newDirection := velocity.normalized()
	var currDirection := velocityComponent.velocity.normalized()
	var halfway = newDirection.lerp(currDirection, 1.0-exp(velocityComponent.AccelerationCoefficient * get_physics_process_delta_time()))
	velocityComponent.velocity = halfway * velocityComponent.velocity.length()
