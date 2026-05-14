extends CharacterBody3D

@export var debug: bool = false

# Player movement parameters
@export var Speed: float = 5.0
@export var JumpVelocity: float = 4.5

# Air control parameters
@export var AirControlStart: float = 1.0
@export var AirControlEnd: float = 0.45
@export var AirControlFadeTime: float = 1.5

# Camera control parameters
@onready var camPivot: Node3D = $CamOrigin
@export var camClamp: Vector2 = Vector2(-90, 45)
@export var mouse_Sensitivity: float = 0.1

# Internal variables
var input_Direction: Vector3 = Vector3.ZERO
var air_time: float = 0.0


func _ready() -> void:
	$"CamOrigin/SpringArm3D".add_excluded_object(self)

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