class_name ThirdPersonPlayer extends Entity

# Player State Machine
## The state of the player, which determines how the player's movement is handled.
enum PlayerState {
	FLOOR = 0,
	JUMP = 1,
	FALL = 2,
}
## The current state of the player, which is used to determine how to handle movement and jumping.
var _state: PlayerState = PlayerState.FLOOR


# Player Events
signal playerJumped
signal playerLanded

# Player movement parameters
@export_category("Movement")
## The max speed the player can move at.
@export var runSpeed: float = 7.5
## the minimum speed the player can move at.
@export var walkSpeed: float = 5.0
## The rate at which the player accelerates to their max speed.
@export var acceleration: float = 10.0
## The rate at which the player decelerates to their min speed.
@export var deceleration: float = 20.0
var _speedActual: float = 0.0
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
var _airtime: float = 0.0


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
@export var coyoteTime: float = 0.15
var _coyoteUsable: bool # can the user press jump and have it work after starting to fall?
var _coyoteWindow: bool: # if the timer hasn't timed out (time since jump + coyote time > current time), the user can still jump
	get:
		return _timeSinceFirstFrame < _lastTimeOnGround + coyoteTime
var _canCoyote: bool: # is the user within the window to use coyote time?
	get:
		return _coyoteUsable and !is_on_floor() and _coyoteWindow

# Player Jump Buffer parameters
@export_subgroup("Jump Buffer")
@export var jumpBuffer: float = 0.2
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

func _enter_tree() -> void:
	# Connect the player position packet handling functions to the appropriate signals for both the server and client. 
	# This allows the player to receive updates about their position from the server and send their position to the server when it changes.
	#ServerNetworkGlobals.handle_player_position.connect(server_handle_player_position)
	#ClientNetworkGlobals.handle_player_position.connect(client_handle_player_position)
	pass

func _exit_tree() -> void:
	# Disconnect the player position packet handling functions from the signals when the player instance is removed from the scene tree 
	# to prevent errors from trying to access a deleted instance.
	#ServerNetworkGlobals.handle_player_position.disconnect(server_handle_player_position)
	#ClientNetworkGlobals.handle_player_position.disconnect(client_handle_player_position)
	pass

func _process(delta: float) -> void:
	if !_manager.is_authority: return # only the authority (owner) of this player instance should handle processing for it.
	_timeSinceFirstFrame += delta

func _input(event: InputEvent) -> void:
	if !_manager.is_authority: return # only the authority (owner) of this player instance should handle input for it.

	# Handle mouse input for camera rotation, but only if the cursor is in the default state. 
	# 	This is to prevent the player from rotating the camera while trying to interact with the UI.
	if event is InputEventMouseMotion and _cursorStateMachine._cursorState == PlayerCursor.CursorState.DEFAULT:
		rotate_y(deg_to_rad(-event.relative.x * mouse_Sensitivity)) # Rotate Player
		_camPivot.rotate_x(deg_to_rad(-event.relative.y * mouse_Sensitivity)) # Rotate Camera Pivot (Camera Pitch)
		_camPivot.rotation.x = clamp(_camPivot.rotation.x, deg_to_rad(camClamp.x), deg_to_rad(camClamp.y)) # Clamp Camera Pitch
	
	# Handle movement input
	var playerInput = Input.get_vector("Player_Left", "Player_Right", "Player_Forward", "Player_Back")
	_inputDirection.x = playerInput.x
	_inputDirection.y = 0
	_inputDirection.z = playerInput.y
	_inputDirection = global_transform.basis * _inputDirection # convert input to use the player's forward and right directions

	# Handle jump input. (Prevent player form jumping in PAUSE_ALL cursor state) 
	if Input.is_action_just_pressed("Player_Jump") and _cursorStateMachine._cursorState != PlayerCursor.CursorState.PAUSE_ALL:
		_isjumping = true
		_lastJumpPressed = _timeSinceFirstFrame

## Handles player movement when on the ground and in the air, including acceleration, deceleration, and air control.
func HandleMove(delta: float) -> void:
	# if the cursor is in the pause state, don't allow the player to move. This is to prevent the player from moving while trying to interact with the UI.
	if _cursorStateMachine._cursorState == PlayerCursor.CursorState.PAUSE_ALL:
		if is_on_floor(): # if the player is on the floor then we can cancel all velocity
			velocity.x = 0
			velocity.z = 0
		else: # otherwise we need to continue falling in the same direction.
			_inputDirection = Vector3.ZERO
		return
	
	if is_on_floor(): # Ground Movement
		var vel = velocity
		vel.y = 0
		if _inputDirection != Vector3.ZERO and vel.length() > 0.1: # if the player is trying to move and is currently moving
			_speedActual = lerp(_speedActual, runSpeed, acceleration * delta) # accelerate to run speed
		else: # if the player is not trying to move or is moving very slowly, decelerate to walk speed
			_speedActual = lerp(_speedActual, walkSpeed, deceleration * delta) # decelerate to walk speed

		# Set the velocity in the x and z direction based on the input direction and the actual speed.
		velocity.x = _inputDirection.normalized().x * _speedActual
		velocity.z = _inputDirection.normalized().z * _speedActual
	else: # Air Control
		# The air control factor is a value between airControlStart and airControlEnd that decreases over time based on how long the player has been in the air. 
		# This creates a feeling of losing control the longer the player is in the air.
		var t = clampf(_airtime / airControlFadeTime, 0, 1)
		var air_control_factor = lerp(airControlStart, airControlEnd, t)

		# Add to the velocity in the x and z direction based on the input direction, walk speed, and air control factor. 
		# This allows the player to have some control over their movement in the air, but not as much as on the ground.
		velocity.x += _inputDirection.normalized().x * walkSpeed * air_control_factor * delta
		velocity.z += _inputDirection.normalized().z * walkSpeed * air_control_factor * delta

## Checks if the player can jump.
func HandleJump() -> void:
	# if the player wants to jump and can queue a jump.
	if !_isjumping and !_canBufferJump:
		return
	
	# if they player is on the floor OR can initiate a "Wile. E. Coyote" jump
	if is_on_floor() or _canCoyote:
		Jump()

	# After jumping the player should no longer be able wanting to jump.
	_isjumping = false

func HandleFalling(delta: float) -> void:
	# How Long in Air
	_airtime += delta

	# Gravity
	velocity.y += -gravity * delta

func Jump() -> void:
	_coyoteUsable = false
	_bufferJumpUsable = false
	_lastJumpPressed = 0
	velocity.y = jumpVelocity
	playerJumped.emit()

## Checks if the player has just landed or just started falling.
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
	# State Machine for handling player vfx, sfx, and other events related to the player's movement state.
	handleStateEffects()
	
	# only the authority (owner) of this player instance should handle physics for it.
	if !_manager.is_authority: return 

	checkCollision()

	# State Machine for handling player movement.
	match _state:
		# if the player is on the ground, check if they are trying to jump or if they have walked off a ledge and should start falling.
		PlayerState.FLOOR: 
			HandleMove(delta)
			if Input.is_action_just_pressed("Player_Jump"):
				switchState(PlayerState.JUMP)
			elif !is_on_floor():
				switchState(PlayerState.FALL)
		# if the player is in the jump state, apply gravity
		# if the player's vertical velocity is less than or equal to 0, they have reached (or passed) the peak of their jump and should start falling.
		PlayerState.JUMP:
			HandleMove(delta)
			HandleFalling(delta)
			if velocity.y <= 0:
				switchState(PlayerState.FALL)
		# if the player is in the fall state, apply gravity and check if they have landed on the ground to switch back to the floor state.
		PlayerState.FALL:
			HandleMove(delta)
			# Coyote Time and Jump Buffer handling is done in the HandleJump function, 
			# 	which is called every frame while in the air to check if the player can jump.
			HandleJump() 
			HandleFalling(delta)
			if is_on_floor():
				switchState(PlayerState.FLOOR)

	# Cache the floor state for next frame.
	_lastOnFloor = is_on_floor()
	move_and_slide()

## Switches the player's state and handles any necessary logic for entering that state.
func switchState(state: PlayerState) -> void:
	_state = state
	match _state:
		PlayerState.FLOOR:
			pass
		# if the player has just entered the jump state, call the HandleJump function to make them jump.
		PlayerState.JUMP:
			HandleJump()
		PlayerState.FALL:
			pass

## Handles any effects related to the [enum PlayerState], such as playing landing or jumping vfx/sfx. 
## This is called every frame in the physics process to ensure that effects are triggered correctly based on the player's current state.
func handleStateEffects() -> void:
	match _state:
		PlayerState.FLOOR:
			pass
		PlayerState.JUMP:
			pass
		PlayerState.FALL:
			pass

## Server Position Packet Handling. sets the transform of the player on the server.[br]
## uses the [PlayerTransform] to sync the position of the player [br]
## [b]on the server from the client (Client -> Server)[/b], and then broadcasts the new position to all clients.
func server_handle_player_position(peer_id: int, EntityState: Packet_EntityState) -> void:
	if _manager.assigned_id != peer_id: return # if the owner of this player doesn't match the peer that sent the packet, ignore.

	# Set the player's state to match the state sent in the packet. 
	# This ensures that the server has the correct state for the player, 
	# 	which is important for handling vfx, sfx, and other events related to the player's movement state on the server and clients.
	#switchState(EntityState.state)

	# Broadcast the player's new server transform to all clients, (including owner).
	# 	(Optional) Could have server override client authority here to check if the player position is valid for a given player.
	#	and if the position is invalid then overwrite the position sent from client and broadcast the new position.
	#Packet_EntityState.create(_manager.assigned_id, _state,).broadcast(LowLevelNetworkHandler.connection)

## Client Position Packet Handling. sets the transform of the player on the client.[br]
## uses the [PlayerTransform] to sync the position of the player [br]
## [b]on the client from the server (Server -> Client)[/b].
func client_handle_player_position(player_transform: Packet_EntityState) -> void:
	if _manager.is_authority || _manager.assigned_id != player_transform.id: return # if this client is the owner, or if the packet is not for this player instance, ignore.

	# If this client is not the authority (owner) of this player instance, update the player's state to match the state sent in the packet.
	# This ensures that the client instance has the correct state for the player, 
	# 	which is important for handling vfx, sfx, and other events related to the player's movement state
	#if !_manager.is_authority:
		#switchState(player_transform.state)
