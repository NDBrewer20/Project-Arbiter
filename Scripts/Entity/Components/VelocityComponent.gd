class_name VelocityComponent extends Node

## the max possible speed for the character body using this component.
@export var maxSpeed: float = 100
## how quickly the max speed can be reached.
@export var accelerationCoefficient: float = 10

## the velocity used by this component.
var velocity: Vector3
## when velocity needs to be forcefully set without neglecting the natural velocity of the component.
var velocityOverride: Vector3 = Vector3.ZERO
## the base multiplier of the bodies speed
var speedMultiplier: float = 1
## based on the active speed modifiers retrieve the sum of all modifiers.
var speedPercentModifier: float:
	get:
		return speedPercentModifiers.values().reduce(func(accum,number): return accum + number,0)
## base multiplier of the acceleration.
var accelerationCoefficientMultiplier: float = 1

## returns the movement speed based on the possible max speed as a percent. 
var speedPercent: float:
	get:
		var temp : float = 1.0
		if calculatedMaxSpeed > 0: temp = calculatedMaxSpeed
		return min(velocity.length() / temp, 1.0)
## the possible max speed of the component based on baseline speed and modifiers and multipliers.
var calculatedMaxSpeed: float:
	get:
		return maxSpeed * (1.0 + speedPercentModifier ) * speedMultiplier

## list of active speed modifiers
var speedPercentModifiers: Dictionary[String,float] = {}

## will apply speed modifiers to given value and return the result.
func _apply_speed_modifiers(value: Vector3) -> Vector3:
	if value == Vector3.ZERO:
		return Vector3.ZERO
	var max_speed: float = calculatedMaxSpeed
	if max_speed <= 0.0:
		return value
	var length: float = value.length()
	return value if length <= max_speed else value.normalized() * max_speed

## accelerates the velocity to move toward the target velocity.
func AccelerateToVelocity(target_velocity: Vector3) -> void:
	var delta: float = get_physics_process_delta_time()
	# gets the blend between the current velocity and target velocity
	var blend: float = 1.0 - exp(-accelerationCoefficient * accelerationCoefficientMultiplier * delta)
	# prevent blend from reaching outside weight bounds (0-1)
	blend = clamp(blend, 0.0, 1.0)
	# set the velocity to the interpolated velocity with speed modifiers applied.
	velocity = _apply_speed_modifiers(velocity.lerp(target_velocity, blend))

## applies an impulse to the velocity.
func AddForce(force: Vector3) -> void:
	velocity += force

## accelerates the components velocity to move in given direction
func AccelerateInDirection(direction: Vector3) -> void:
	AccelerateToVelocity(GetMaxVelocity(direction))

## gets the max possible velocity in a given direction
func GetMaxVelocity(direction: Vector3) -> Vector3:
	return direction*calculatedMaxSpeed

## sets the velocity to the max possible velocity in a given direction.
func MaximizeVelocity(direction: Vector3) -> void:
	velocity = GetMaxVelocity(direction)

## moves the component velocity to [Vector3.ZERO]
func Decelerate() -> void:
	AccelerateToVelocity(Vector3.ZERO)

## sets a bodies velocity directly and moves it.
func Move(body: CharacterBody3D) -> void:
	body.velocity = velocityOverride if velocityOverride else velocity
	body.move_and_slide()

## adds a speed modifier to to be applied to velocity.
func AddSpeedPercentModifier(_name: String, change: float) -> void:
	var currentValue: float = GetSpeedPercentModifier(_name)
	currentValue += change
	SetSpeedPercentModifier(_name, currentValue)

## sets a new value to a speed modifier.
func SetSpeedPercentModifier(_name: String, val: float) -> void:
	speedPercentModifiers[_name] = val

## removes a tracked speed modifier.
func RemoveSpeedPercentModifier(_name: String):
	speedPercentModifiers.erase(_name)

## gets current value of a speed modifier.
func GetSpeedPercentModifier(_name: String) -> float:
	return speedPercentModifiers.get(_name, 0.0)
