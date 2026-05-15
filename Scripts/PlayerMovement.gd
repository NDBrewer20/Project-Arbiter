extends CharacterBody3D

@export var debug: bool = false

# Player movement parameters
@export var speed: float = 5.0
var _inputDirection: Vector3 = Vector3.ZERO


# Player jumping parameters
@export var jumpVelocity: float = 4.5
var _isjumping: bool # is the user currently trying to jump?
var _lastJumpPressed: float # how long since the user last tried to jump?
var _lastTimeOnGround: float # how long since the user was last on the ground?

# Player Coyote Time parameters
@export var coyoteTime: float = 0.15
var _coyoteUsable: bool # can the user press jump and have it work after starting to fall?
var _coyoteWindow: bool: # if the timer hasn't timed out (time since jump + coyote time > current time), the user can still jump
	get:
		return _timeSinceFirstFrame < _lastTimeOnGround + coyoteTime
var _canCoyote: bool: # is the user within the window to use coyote time?
	get:
		return _coyoteUsable and !is_on_floor() and _coyoteWindow

# Player Jump Buffer parameters
@export var jumpBuffer: float = 0.2
var _bufferJumpUsable: bool # can the user press jump and have it work before landing?
var _bufferWindow: bool: # if the timer hasn't timed out (time since jump + jump buffer time > current time), the user can still jump
	get:
		return _timeSinceFirstFrame < _lastJumpPressed + jumpBuffer
var _canBufferJump: bool: # is the user within the window to use buffered jump?
	get:
		return _bufferJumpUsable and _bufferWindow


# Air control parameters
@export var airControlStart: float = 1.0
@export var airControlEnd: float = 0.45
@export var airControlFadeTime: float = 1.5
var _airtime: float = 0.0


# Camera control parametera
@onready var camPivot: Node3D = $CamOrigin
@export var camClamp: Vector2 = Vector2(-90, 45)
@export var mouse_Sensitivity: float = 0.1

# Internal Variables
var _timeSinceFirstFrame: float = 0.0

func _ready() -> void:
	$"CamOrigin/SpringArm3D".add_excluded_object(self)

func _process(delta: float) -> void:
	_timeSinceFirstFrame += delta

func _input(event: InputEvent) -> void:
	_inputDirection = Vector3.ZERO

	if event is InputEventMouseMotion and Input.is_action_pressed("Player_Rotate"):
		rotate_y(deg_to_rad(-event.relative.x * mouse_Sensitivity))
		camPivot.rotate_x(deg_to_rad(-event.relative.y * mouse_Sensitivity))
		camPivot.rotation.x = clamp(camPivot.rotation.x, deg_to_rad(camClamp.x), deg_to_rad(camClamp.y))
	
	# Handle movement input
	if Input.is_action_pressed("Player_Forward"):
		_inputDirection -= transform.basis.z
	if Input.is_action_pressed("Player_Back"):
		_inputDirection += transform.basis.z
	if Input.is_action_pressed("Player_Left"):
		_inputDirection -= transform.basis.x
	if Input.is_action_pressed("Player_Right"):
		_inputDirection += transform.basis.x

	if debug and Input.is_action_pressed("DEBUG_Quit"):
			get_tree().quit()

func _physics_process(delta: float) -> void:
	var direction = _inputDirection
	direction.y = 0
	direction = direction.normalized()

	if not is_on_floor():
		# How Long in Air
		_airtime += delta

		# Gravity
		velocity.y += -ProjectSettings.get_setting("physics/3d/default_gravity") * delta

		# Air Control
		var t = clamp(_airtime / airControlFadeTime, 0, 1)
		var air_control_factor = lerp(airControlStart, airControlEnd, t)

		velocity.x += direction.x * speed * air_control_factor * delta
		velocity.z += direction.z * speed * air_control_factor * delta
	else:
		velocity.y = 0

	if is_on_floor():
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed

		if Input.is_action_just_pressed("Player_Jump"):
			velocity.y = jumpVelocity

	move_and_slide()