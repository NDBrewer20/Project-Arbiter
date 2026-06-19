class_name ThirdPersonPlayer extends Entity

@export_category("State Machine")
## the movement state machine for the player.
@export var movementStateMachine: StateMachine
@export var attackingStateMachine: StateMachine


# Player Combat
@export_category("Combat")
## the players weapon holder reference.
@export var weaponHolder: WeaponHolder
## the origin of attacks for the player.
@export var attackOrigin: Node3D
## where the player is in their attack combo, this is used to determine which attack to use next in the combo sequence. 
## Resets after a certain amount of time or if the player uses a different attack.
var comboPosition: int = 0 : set = _on_combo_position_set
var comboTimer: Timer
## setter function for combo position.
func _on_combo_position_set(new_value: int) -> void:
	comboPosition = new_value
	# starts the timer that on timeout will wipe current combo position.
	comboTimer.start()


# Player movement parameters
@export_category("Movement")
## reference to the players velocity component.
@export var velocityComponent: VelocityComponent
## direction of movement input from player.
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
## the force of gravity on the player.
@export var gravity: float = 9.8
## the amount of force used by the player to jump.
@export var jumpVelocity: float = 4.5
## was the user on the ground in the last frame?
var _lastOnFloor: bool 
## is the user currently trying to jump?
var _isjumping: bool = false 
## how long since the user last tried to jump?
var _lastJumpPressed: float 
## how long since the user was last on the ground?
var _lastTimeOnGround: float 

# Player Coyote Time parameters
@export_subgroup("Coyote Time")
## how long the player has to queue a coyote jump after leaving the ground.
@export var coyoteTime: float = 0.16
## can the user press jump and have it work after starting to fall?
var _coyoteUsable: bool 
## if the timer hasn't timed out (time since jump + coyote time > current time), the user can still jump
var _coyoteWindow: bool: 
	get:
		return _timeSinceFirstFrame < _lastTimeOnGround + coyoteTime
## is the user within the window to use coyote time?
var _canCoyote: bool:
	get:
		return _coyoteUsable and !is_on_floor() and _coyoteWindow

# Player Jump Buffer parameters
@export_subgroup("Jump Buffer")
## how long the player has to queue a jump before they land.
@export var jumpBuffer: float = 0.21
## can the user press jump and have it work before landing?
var _bufferJumpUsable: bool 
## if the timer hasn't timed out (time since jump + jump buffer time > current time), the user can still jump
var _bufferWindow: bool: 
	get:
		return _timeSinceFirstFrame < _lastJumpPressed + jumpBuffer
## is the user within the window to use buffered jump?
var _canBufferJump: bool: 
	get:
		return _bufferJumpUsable and _bufferWindow


# Camera control parametera
@export_category("Camera")
## The pivot point for the camera, which is used to rotate the camera around the player. This should be a child node of the player that is positioned at the player's head or where you want the camera to rotate around.
@export var _camPivot: Node3D
## the transform component of the camera used to determine the position of the camera independently of the player.
@export var _camGimbal: Node3D
## reference to the players camera.
@export var _cam: Camera3D
## The minimum and maximum angles the camera can pitch up and down, in degrees. [br]
## Example setup: X is minimum (looking down [-90]), Y is maximum (looking up [45]).
@export var camClamp: Vector2 = Vector2(-90, 45)
## The sensitivity of the mouse input for rotating the camera. Higher values make the camera rotate faster in response to mouse movement.
@export var mouse_Sensitivity: float = 0.1
## how quickly the player will attempt to turn to face the desired direction.
@export var turnSpeedAcceleration: float = 10

# Player Cursor State Machine
@export_category("Cursor")
## the cursor state machine used by the player.
@export var _cursorStateMachine: PlayerCursor

# Internal Variables
## how long has it been since the first frame this player has seen.
var _timeSinceFirstFrame: float = 0.0


func _ready() -> void:
	if !_manager.is_authority: # if the instance isn't the auth player remove unneccessary nodes for other players on this client. 
		cleanClientChildren()
		return
	# create combo timer for player.
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

	# remove camera gimbal and cursor state machine.
	_camGimbal.queue_free()
	_cursorStateMachine.queue_free()

func _process(delta: float) -> void:
	if !_manager.is_authority: return # only the authority (owner) of this player instance should handle processing for it.
	_timeSinceFirstFrame += delta # increment time since first frame.

func _input(event: InputEvent) -> void:
	if !_manager.is_authority: return # only the authority (owner) of this player instance should handle input for it.

	# Handle mouse input for camera rotation, but only if the cursor is in the default state. 
	# 	This is to prevent the player from rotating the camera while trying to interact with the UI.
	if event is InputEventMouseMotion and _cursorStateMachine.Cursor_Locked():
		_camGimbal.rotate_y(deg_to_rad(-event.relative.x * mouse_Sensitivity)) # Rotate Player camera
		_camPivot.rotate_x(deg_to_rad(-event.relative.y * mouse_Sensitivity)) # Rotate Camera Pivot (Camera Pitch)
		_camPivot.rotation.x = clamp(_camPivot.rotation.x, deg_to_rad(camClamp.x), deg_to_rad(camClamp.y)) # Clamp Camera Pitch

	# Handle jump input. (Prevent player form jumping in PAUSE_ALL cursor state) 
	if event.is_action_pressed("Player_Jump") and _cursorStateMachine.Movement_Allowed():
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

	# fetch player input before doing anything with it.
	get_player_input()

	# check and update collision information.
	checkCollision()

	# if the cursor is locked then try to rotate the player to look at the camera direction.
	if _cursorStateMachine.Cursor_Locked():
		try_rotate_player()

## move the player body
func Move():
	# set the last known floor value.
	_lastOnFloor = is_on_floor()
	# move the player body using the velocity component.
	velocityComponent.Move(self)

## gets the players movement input based on left, right, forward, and back buttons being pressed.
func get_player_input():
	# Handle movement input
	if _cursorStateMachine.Movement_Allowed():
		var playerInput = Input.get_vector("Player_Left", "Player_Right", "Player_Forward", "Player_Back")
		_inputDirection.x = playerInput.x
		_inputDirection.y = 0
		_inputDirection.z = playerInput.y
		# convert input to use the player's forward and right directions
		_inputDirection = global_transform.basis * _inputDirection 
	else:
		_inputDirection = Vector3.ZERO

## try to rotate the player if restrictions aren't active.
func try_rotate_player():
	# there is currently anything pressed and it's not the ui_cancel input.
	var pressingValidButton: bool = Input.is_anything_pressed() and !Input.is_action_pressed("ui_cancel")
	# if valid button and not in an animation lock then allow player rotation.
	if pressingValidButton and !movementStateMachine.animLocked()and !attackingStateMachine.animLocked():
		# rotate the player to match the camera's y rotation when the player is providing input. This makes movement relative to the camera direction.
		global_rotation.y = lerp_angle(global_rotation.y, _camGimbal.global_rotation.y, 1.0-exp(-turnSpeedAcceleration*get_physics_process_delta_time()))

## forecfully rotate the player to face the camera direction.
func force_rotate_player():
	# force rotate the player to match the camera's y rotation regardless of input. 
	# This is used in certain attack states to ensure the player is facing the correct direction for the attack animation.
	global_rotation.y = _camGimbal.global_rotation.y 
