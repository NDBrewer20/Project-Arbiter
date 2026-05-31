class_name PathfindComponent extends Node3D

@export_category("References")
@export var velocityComponent: VelocityComponent
@onready var _intervalTimer: Timer = $"Interval Timer"
@onready var navAgent: NavigationAgent3D = $"NavigationAgent3D"
@onready var parent: Node3D = get_parent() as Node3D
## a short delay before teleporting the characterbody to the navlink exit
@onready var _linkTimer: Timer = $"NavLink Timer"
var nav_link_end_position: Vector3
var nav_link_rid: RID


func _ready() -> void:
	navAgent.velocity_computed.connect(_on_velocity_computed)
	navAgent.link_reached.connect(_on_navigation_link_reached)
	_linkTimer.timeout.connect(_on_link_timeout)

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

func find_nearest_navmesh_target(desired_position: Vector3) -> Vector3:
	var _currentTargetPosition = navAgent.target_position
	navAgent.target_position = desired_position
	await get_tree().physics_frame
	var desiredPos: Vector3 = navAgent.get_final_position()
	navAgent.target_position = _currentTargetPosition
	return desiredPos

func _on_navigation_link_reached(details: Dictionary) -> void:
	if nav_link_rid.get_id() != RID().get_id(): return # prevent the nav agent from bouncing between two points on the same nav link.
	nav_link_rid = details.rid
	nav_link_end_position = details.link_exit_position
	_linkTimer.start()

func _on_link_timeout()-> void:
	parent.global_position = nav_link_end_position
	nav_link_end_position = Vector3.ZERO
	nav_link_rid = RID()


func _on_velocity_computed(velocity: Vector3) -> void:
	#var newDirection := velocity.normalized()
	velocityComponent.velocity = velocity #newDirection * velocityComponent.velocity.length()
