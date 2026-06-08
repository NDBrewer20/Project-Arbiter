class_name ThirdPersonPlayer extends Entity

@export_category("State Machine")
@export var stateMachine: StateMachine


# Player Combat
@export_category("Combat")
@export var weaponHolder: WeaponHolder
@export var attackOrigin: Node3D
## where the player is in their attack combo, this is used to determine which attack to use next in the combo sequence. 
## Resets after a certain amount of time or if the player uses a different attack.
var comboPosition: int = 0 : set = _on_combo_position_set
var comboTimer: Timer
func _on_combo_position_set(new_value: int) -> void:
	comboPosition = new_value
	comboTimer.start()


# Player movement parameters
@export_category("Movement")
@export var velocityComponent: VelocityComponent
var _inputDirection: Vector3 = Vector3.ZERO

# Air control parameters
@export_subgroup("Air Control")
## How much control the player has over their movement in the air at the start of their jump.[br]
## (1.0 = full control, 0.0 = no control)
@export var airControlStart: float = 1.0
## How much control the player has over their movement in the air at the end of their jump.[br]
## (1.0 = full control, 0.0 = no control)
@export var airControlEnd: float = 0.45
## How long it takes for the player to go from full air control to no air control in seconds.
@export var airControlFadeTime: float = 1.5


# Player jumping parameters
@export_category("Jumping")
@export var gravity: float = 9.8
@export var jumpVelocity: float = 4.5
var _lastOnFloor: bool # was the user on the ground in the last frame?
var _isjumping: bool = false # is the user currently trying to jump?
var _lastJumpPressed: float # how long since the user last tried to jump?
var _lastTimeOnGround: float # how long since the user was last on the ground?

# Player Coyote Time parameters
@export_subgroup("Coyote Time")
@export var coyoteTime: float = 0.16
var _coyoteUsable: bool # can the user press jump and have it work after starting to fall?
var _coyoteWindow: bool: # if the timer hasn't timed out (time since jump + coyote time > current time), the user can still jump
	get:
		return _timeSinceFirstFrame < _lastTimeOnGround + coyoteTime
var _canCoyote: bool: # is the user within the window to use coyote time?
	get:
		return _coyoteUsable and !is_on_floor() and _coyoteWindow

# Player Jump Buffer parameters
@export_subgroup("Jump Buffer")
@export var jumpBuffer: float = 0.21
var _bufferJumpUsable: bool # can the user press jump and have it work before landing?
var _bufferWindow: bool: # if the timer hasn't timed out (time since jump + jump buffer time > current time), the user can still jump
	get:
		return _timeSinceFirstFrame < _lastJumpPressed + jumpBuffer
var _canBufferJump: bool: # is the user within the window to use buffered jump?
	get:
		return _bufferJumpUsable and _bufferWindow


# Camera control parametera
@export_category("Camera")
## The pivot point for the camera, which is used to rotate the camera around the player. This should be a child node of the player that is positioned at the player's head or where you want the camera to rotate around.
@export var _camPivot: Node3D
@export var _camGimbal: Node3D
@export var _cam: Camera3D
## The minimum and maximum angles the camera can pitch up and down, in degrees. [br]
## Example setup: X is minimum (looking down [-90]), Y is maximum (looking up [45]).
@export var camClamp: Vector2 = Vector2(-90, 45)
## The sensitivity of the mouse input for rotating the camera. Higher values make the camera rotate faster in response to mouse movement.
@export var mouse_Sensitivity: float = 0.1

# Player Cursor State Machine
@export_category("Cursor")
@export var _cursorStateMachine: PlayerCursor

# Internal Variables
var _timeSinceFirstFrame: float = 0.0


func _ready() -> void:
	if !_manager.is_authority: # if the instance isn't the auth player remove unneccessary nodes for other players on this client. 
		cleanClientChildren()
		return
	comboTimer = Timer.new()
	add_child(comboTimer)
	comboTimer.one_shot = true
	comboTimer.timeout.connect(func() -> void: comboPosition = 0)

	# Initialize the Player Cursor.
	_cursorStateMachine.switchState(PlayerCursor.CursorState.DEFAULT)

	# Exclude the player from the camera's spring arm to prevent the camera from colliding with the player and causing jittery movement.
	_camPivot.get_node("SpringArm3D").add_excluded_object(self)

## Cleans up any child nodes that shouldn't exist on non-authority instances of the player.
func cleanClientChildren() -> void:
	# If this client is not the authority (owner) of this player instance,
	# Disable processing input for this instance since only the authority should handle input for it.
	set_process_input(false)
	_camPivot.queue_free()
	_cursorStateMachine.queue_free()

func _process(delta: float) -> void:
	if !_manager.is_authority: return # only the authority (owner) of this player instance should handle processing for it.
	_timeSinceFirstFrame += delta

func _input(event: InputEvent) -> void:
	if !_manager.is_authority: return # only the authority (owner) of this player instance should handle input for it.

	# Handle mouse input for camera rotation, but only if the cursor is in the default state. 
	# 	This is to prevent the player from rotating the camera while trying to interact with the UI.
	if event is InputEventMouseMotion and _cursorStateMachine.Cursor_Locked():
		_camGimbal.rotate_y(deg_to_rad(-event.relative.x * mouse_Sensitivity)) # Rotate Player camera
		_camPivot.rotate_x(deg_to_rad(-event.relative.y * mouse_Sensitivity)) # Rotate Camera Pivot (Camera Pitch)
		_camPivot.rotation.x = clamp(_camPivot.rotation.x, deg_to_rad(camClamp.x), deg_to_rad(camClamp.y)) # Clamp Camera Pitch

	# Handle movement input
	if _cursorStateMachine.Movement_Allowed(): # if the cursor is not in the pause state, allow movement input. This is to prevent the player from moving while trying to interact with the UI.
		var playerInput = Input.get_vector("Player_Left", "Player_Right", "Player_Forward", "Player_Back")
		_inputDirection.x = playerInput.x
		_inputDirection.y = 0
		_inputDirection.z = playerInput.y
		_inputDirection = global_transform.basis * _inputDirection # convert input to use the player's forward and right directions
	else:
		_inputDirection = Vector3.ZERO # if the cursor isn't in the default state, ignore movement input to prevent the player from moving while trying to interact with the UI.

	# Handle jump input. (Prevent player form jumping in PAUSE_ALL cursor state) 
	if Input.is_action_just_pressed("Player_Jump") and _cursorStateMachine.Movement_Allowed():
		_isjumping = true
		_lastJumpPressed = _timeSinceFirstFrame


## Checks if the player has just landed or just started falling.
func checkCollision() -> void:
	# If last frame was not on the ground but this frame is, then the player has just landed
	if !_lastOnFloor and is_on_floor():
		_coyoteUsable = true
		_bufferJumpUsable = true
	# if last frame was on the ground but this frame is not, then the player has just started falling
	elif _lastOnFloor and not is_on_floor():
		_lastTimeOnGround = _timeSinceFirstFrame
	

func _physics_process(_delta: float) -> void:
	# only the authority (owner) of this player instance should handle physics for it.
	if !_manager.is_authority: return 
	if _cursorStateMachine.Cursor_Locked():
		try_rotate_player()
	checkCollision()

func Move():
	_lastOnFloor = is_on_floor()
	velocityComponent.Move(self)

func try_rotate_player():
	var pressingValidButton: bool = Input.is_anything_pressed() and !Input.is_action_pressed("ui_cancel")
	var animLocked: bool = stateMachine.currentState.name == PlayerMeleeAttack.stateName
	if pressingValidButton and !animLocked:
		global_rotation.y = _camGimbal.global_rotation.y # rotate the player to match the camera's y rotation when the player is providing input. This makes movement relative to the camera direction.

func force_rotate_player():
	global_rotation.y = _camGimbal.global_rotation.y # force rotate the player to match the camera's y rotation regardless of input. This is used in certain attack states to ensure the player is facing the correct direction for the attack animation.
