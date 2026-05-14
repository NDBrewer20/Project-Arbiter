extends CharacterBody3D

@export var debug: bool = false

# Player movement parameters
@export var Speed: float = 5.0

var input_Direction: Vector3 = Vector3.ZERO

# Player jumping parameters
@export var JumpVelocity: float = 4.5
@export var JumpBuffer: float = 0.2
@export var CoyoteTime: float = 0.15


var coyoteUsable: bool # can the user press jump and have it work after starting to fall?
var coyoteWindow: bool # if the timer hasn't timed out (time since jump + coyote time > current time), the user can still jump
var canCoyote: bool: # is the user within the window to use coyote time?
	get:
		return coyoteUsable and coyoteWindow
var CoyoteTimer: Timer # timer to track coyote time

var is_jumping: bool # is the user currently trying to jump?
var bufferJumpUsable: bool # can the user press jump and have it work before landing?
var bufferWindow: bool # if the timer hasn't timed out (time since jump + jump buffer time > current time), the user can still jump
var canBufferJump: bool: # is the user within the window to use buffered jump?
	get:
		return bufferJumpUsable and bufferWindow
var BufferJumpTimer: Timer # timer to track jump buffering


# Air control parameters
@export var AirControlStart: float = 1.0
@export var AirControlEnd: float = 0.45
@export var AirControlFadeTime: float = 1.5

var air_time: float = 0.0

# Camera control parameters
@onready var camPivot: Node3D = $CamOrigin
@export var camClamp: Vector2 = Vector2(-90, 45)
@export var mouse_Sensitivity: float = 0.1

func _ready() -> void:
	$"CamOrigin/SpringArm3D".add_excluded_object(self)
	CoyoteTimer = Timer.new()
	CoyoteTimer.one_shot = true
	CoyoteTimer.wait_time = CoyoteTime
	CoyoteTimer.timeout.connect(func():
		coyoteWindow = false
	)
	add_child(CoyoteTimer)
	BufferJumpTimer = Timer.new()
	BufferJumpTimer.one_shot = true
	BufferJumpTimer.wait_time = JumpBuffer
	BufferJumpTimer.timeout.connect(func():
		bufferWindow = false
	)
	add_child(BufferJumpTimer)

func _input(event: InputEvent) -> void:
	input_Direction = Vector3.ZERO

	if event is InputEventMouseMotion and Input.is_action_pressed("Player_Rotate"):
		rotate_y(deg_to_rad(-event.relative.x * mouse_Sensitivity))
		camPivot.rotate_x(deg_to_rad(-event.relative.y * mouse_Sensitivity))
		camPivot.rotation.x = clamp(camPivot.rotation.x, deg_to_rad(camClamp.x), deg_to_rad(camClamp.y))
	
	# Handle movement input
	if Input.is_action_pressed("Player_Forward"):
		input_Direction -= transform.basis.z
	if Input.is_action_pressed("Player_Back"):
		input_Direction += transform.basis.z
	if Input.is_action_pressed("Player_Left"):
		input_Direction -= transform.basis.x
	if Input.is_action_pressed("Player_Right"):
		input_Direction += transform.basis.x

	if debug and Input.is_action_pressed("DEBUG_Quit"):
			get_tree().quit()

func _physics_process(delta: float) -> void:
	var direction = input_Direction
	direction.y = 0
	direction = direction.normalized()

	if not is_on_floor():
		# How Long in Air
		air_time += delta

		# Gravity
		velocity.y += -ProjectSettings.get_setting("physics/3d/default_gravity") * delta

		# Air Control
		var t = clamp(air_time / AirControlFadeTime, 0, 1)
		var air_control_factor = lerp(AirControlStart, AirControlEnd, t)

		velocity.x += direction.x * Speed * air_control_factor * delta
		velocity.z += direction.z * Speed * air_control_factor * delta
	else:
		velocity.y = 0

	if is_on_floor():
		velocity.x = direction.x * Speed
		velocity.z = direction.z * Speed

		if Input.is_action_just_pressed("Player_Jump"):
			velocity.y = JumpVelocity

	move_and_slide()