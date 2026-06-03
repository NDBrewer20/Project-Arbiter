class_name VelocityComponent extends Node

@export var maxSpeed: float = 100
@export var accelerationCoefficient: float = 10

var velocity: Vector3
var velocityOverride: Vector3 = Vector3.ZERO
var speedMultiplier: float = 1
var speedPercentModifier: float:
	get:
		return speedPercentModifiers.values().reduce(func(accum,number): return accum + number,0)
var accelerationCoefficientMultiplier: float = 1

var AccelerationCoefficient: float:
	get: return accelerationCoefficient
var speedPercent: float:
	get:
		var temp : float = 1.0
		if calculatedMaxSpeed > 0: temp = calculatedMaxSpeed
		return min(velocity.length() / temp, 1.0)
var calculatedMaxSpeed: float:
	get:
		return maxSpeed * (1.0 + speedPercentModifier ) * speedMultiplier

var speedPercentModifiers: Dictionary[String,float] = {}

func _apply_speed_modifiers(value: Vector3) -> Vector3:
	if value == Vector3.ZERO:
		return Vector3.ZERO
	var max_speed: float = calculatedMaxSpeed
	if max_speed <= 0.0:
		return value
	var length: float = value.length()
	return value if length <= max_speed else value.normalized() * max_speed

func AccelerateToVelocity(target_velocity: Vector3) -> void:
	var delta: float = get_physics_process_delta_time()
	var blend: float = 1.0 - exp(-accelerationCoefficient * accelerationCoefficientMultiplier * delta)
	blend = clamp(blend, 0.0, 1.0)
	velocity = velocity.lerp(_apply_speed_modifiers(target_velocity), blend)

func AddForce(force: Vector3) -> void:
	velocity += force

func AccelerateInDirection(direction: Vector3) -> void:
	AccelerateToVelocity(GetMaxVelocity(direction))

func GetMaxVelocity(direction: Vector3) -> Vector3:
	return direction*calculatedMaxSpeed

func MaximizeVelocity(direction: Vector3) -> void:
	velocity = GetMaxVelocity(direction)

func Decelerate() -> void:
	AccelerateToVelocity(Vector3.ZERO)

func Move(body: CharacterBody3D) -> void:
	body.velocity = velocityOverride if velocityOverride else velocity
	body.move_and_slide()

func AddSpeedPercentModifier(_name: String, change: float) -> void:
	var currentValue: float = GetSpeedPercentModifier(_name)
	currentValue += change
	SetSpeedPercentModifier(_name, currentValue)

func SetSpeedPercentModifier(_name: String, val: float) -> void:
	speedPercentModifiers[_name] = val

func GetSpeedPercentModifier(_name: String) -> float:
	return speedPercentModifiers.get(_name, 0.0)
