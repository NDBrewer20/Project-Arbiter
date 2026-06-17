class_name PathfindComponent extends Node3D

@export_category("References")
## reference to the velocity component to move the characterbody.
@export var velocityComponent: VelocityComponent
## The interval on which the target position can be updated. [br] 
## Once the timer is stopped target position can be updated.
@onready var _intervalTimer: Timer = $"Interval Timer"
## the navigation agent that this pathfind component requires.
@onready var navAgent: NavigationAgent3D = $"NavigationAgent3D"
## a short delay before teleporting the characterbody to the navlink exit
@onready var _linkTimer: Timer = $"NavLink Timer"
## the position at the end of the nav link currently being traversed.
var nav_link_end_position: Vector3
## the RID of the nav link currently being traversed.
var nav_link_rid: RID


func _ready() -> void:
	# connect the obstacle avoidance velocity computation.
	navAgent.velocity_computed.connect(_on_velocity_computed)
	# when a nav link is reached connect nav link handling.
	navAgent.link_reached.connect(_on_navigation_link_reached)
	# connect nav link timer so that the owner can be moved to the end of nav link.
	_linkTimer.timeout.connect(_on_link_timeout)

## sets the NavigationAgents target position as long as the interval timer isn't active.
func SetTargetPosition(tarPos: Vector3) -> void:
	# check if interval timer is stopped
	if !_intervalTimer.is_stopped(): return

	# start interval timer and set target position.
	_intervalTimer.start()
	navAgent.target_position = tarPos

## forcefully set the target position regardless of interval timer.
func ForceSetTargetPosition(tarPos: Vector3) -> void:
	# set target position and restart timer.
	navAgent.target_position = tarPos
	_intervalTimer.start()

## have the velocity component inherit the velocity to move to the next point in the path based on NavigationAgent's computed path.
func FollowPath() -> void:
	# if the agent is done navigating then decelerate the agent.
	if navAgent.is_navigation_finished():
		velocityComponent.Decelerate()
		return

	# get the direction to the next position on the path.
	var direction = (navAgent.get_next_path_position()-global_position).normalized()
	# accelerate toward the direction of the next position on the path.
	velocityComponent.AccelerateInDirection(direction)
	if navAgent.avoidance_enabled: # if using avoidance then set the nav agents velocity.
		navAgent.velocity = velocityComponent.velocity

## forcefully checks the nearest positions to the desired position by overriding the nav agents target position and then setting the target position back.
func find_nearest_navmesh_target(desired_position: Vector3) -> Vector3:
	# retrieve current target position and set new target position to desired position
	var _currentTargetPosition = navAgent.target_position
	ForceSetTargetPosition(desired_position)

	# wait for a physics frame so that the path gets recalculated.
	await get_tree().physics_frame
	
	# get the position closest to the desired position on the navmesh for this agent. and set the target position back to original target.
	var actualPos: Vector3 = navAgent.get_final_position()
	ForceSetTargetPosition(_currentTargetPosition)

	# return actual position found on navmesh.
	return actualPos

## when a navigation link is reached check fetch it's information and start the countdown to teleportation.
func _on_navigation_link_reached(details: Dictionary) -> void:
	if nav_link_rid.get_id() != RID().get_id(): return # prevent the nav agent from bouncing between two points on the same nav link.
	nav_link_rid = details.rid
	nav_link_end_position = details.link_exit_position
	_linkTimer.start()

## when the navlink timer ends set the owners position to the nav link end position and reset the stored values.
func _on_link_timeout()-> void:
	owner.global_position = nav_link_end_position
	nav_link_end_position = Vector3.ZERO
	nav_link_rid = RID()

## when the NavigationAgent recalculates the velocity for obstacle avoidance apply it to the velocityComponent.
func _on_velocity_computed(velocity: Vector3) -> void:
	velocityComponent.velocity = velocity
