class_name PlayerMovement extends CharacterBody3D

@export var debug: bool = false

# Networking parameters
var is_authority: bool:
	get:
		return !LowLevelNetworkHandler.is_server && owner_id == ClientNetworkGlobals.id
var owner_id: int

# Player Events
signal playerJumped
signal playerLanded

# Player movement parameters
@export var runSpeed: float = 7.5
@export var walkSpeed: float = 5.0
@export var acceleration: float = 10.0
@export var deceleration: float = 20.0
var _speedActual: float = 0.0
var _inputDirection: Vector3 = Vector3.ZERO


# Player jumping parameters
@export var jumpVelocity: float = 4.5
var _lastOnFloor: bool # was the user on the ground in the last frame?
var _isjumping: bool = false # is the user currently trying to jump?
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

func _enter_tree() -> void:
	ServerNetworkGlobals.handle_player_position.connect(server_handle_player_position)
	ClientNetworkGlobals.handle_player_position.connect(client_handle_player_position)

func _exit_tree() -> void:
	ServerNetworkGlobals.handle_player_position.disconnect(server_handle_player_position)
	ClientNetworkGlobals.handle_player_position.disconnect(client_handle_player_position)

func _process(delta: float) -> void:
	_timeSinceFirstFrame += delta

func _input(event: InputEvent) -> void:
	if !is_authority: return

	_inputDirection = Vector3.ZERO

	if event is InputEventMouseMotion and Input.is_action_pressed("Player_Rotate"):
		rotate_y(deg_to_rad(-event.relative.x * mouse_Sensitivity))
		camPivot.rotate_x(deg_to_rad(-event.relative.y * mouse_Sensitivity))
		camPivot.rotation.x = clamp(camPivot.rotation.x, deg_to_rad(camClamp.x), deg_to_rad(camClamp.y))
	
	# Handle movement input
	var playerInput = Input.get_vector("Player_Left", "Player_Right", "Player_Forward", "Player_Back")
	_inputDirection.x = playerInput.x
	_inputDirection.y = 0
	_inputDirection.z = playerInput.y
	_inputDirection = global_transform.basis * _inputDirection

	if Input.is_action_just_pressed("Player_Jump"):
		_isjumping = true
		_lastJumpPressed = _timeSinceFirstFrame

	if debug and Input.is_action_pressed("DEBUG_Quit"):
			get_tree().quit()


func HandleMove(delta: float) -> void:
	if is_on_floor():
		if _inputDirection == Vector3.ZERO:
			_speedActual = lerp(_speedActual, walkSpeed, deceleration * delta)
		else:
			_speedActual = lerp(_speedActual, runSpeed, acceleration * delta)
		velocity.x = _inputDirection.normalized().x * _speedActual
		velocity.z = _inputDirection.normalized().z * _speedActual
	else:
		# Air Control
		var t = clampf(_airtime / airControlFadeTime, 0, 1)
		var air_control_factor = lerp(airControlStart, airControlEnd, t)

		velocity.x += _inputDirection.normalized().x * walkSpeed * air_control_factor * delta
		velocity.z += _inputDirection.normalized().z * walkSpeed * air_control_factor * delta

func HandleJump() -> void:
	if !_isjumping and !_canBufferJump:
		return
	
	if is_on_floor() or _canCoyote:
		Jump()

	_isjumping = false

func HandleFalling(delta: float) -> void:
	if not is_on_floor():
		# How Long in Air
		_airtime += delta

		# Gravity
		velocity.y += -ProjectSettings.get_setting("physics/3d/default_gravity") * delta

func Jump() -> void:
	_coyoteUsable = false
	_bufferJumpUsable = false
	_lastJumpPressed = 0
	velocity.y = jumpVelocity
	playerJumped.emit()

func checkCollision() -> void:
	# If last frame was not on the ground but this frame is, then the player has just landed
	if !_lastOnFloor and is_on_floor():
		_coyoteUsable = true
		_bufferJumpUsable = true
		_airtime = 0
		playerLanded.emit()
	# if last frame was on the ground but this frame is not, then the player has just started falling
	elif _lastOnFloor and not is_on_floor():
		_lastTimeOnGround = _timeSinceFirstFrame
	

func _physics_process(delta: float) -> void:
	if !is_authority: return
	checkCollision()
	HandleJump()
	HandleFalling(delta)
	HandleMove(delta)

	_lastOnFloor = is_on_floor()
	move_and_slide()

	PlayerTransform.create(owner_id, global_position, global_rotation).send(LowLevelNetworkHandler.server_peer)


func server_handle_player_position(peer_id: int, player_transform: PlayerTransform) -> void:
	if owner_id != peer_id: return
	global_position = player_transform.position
	global_rotation = player_transform.rotation
	PlayerTransform.create(owner_id, global_position, global_rotation).broadcast(LowLevelNetworkHandler.connection)

func client_handle_player_position(player_transform: PlayerTransform) -> void:
	if is_authority || owner_id != player_transform.id: return

	global_position = player_transform.position 
	global_rotation.y = player_transform.rotation.y