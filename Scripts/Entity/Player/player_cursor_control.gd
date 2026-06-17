class_name PlayerCursor extends Node

enum CursorState {
	DEFAULT = 0, # Normal gameplay, mouse is captured and player can look around and move freely.
	INTERACTING = 1, # Allows player input to a certain extent but disables mouse look.
	PAUSE_ALL = 2, # Stops all player input, used for "pause menu" and other specific limiting UI interactions.
}
## Current state of the player cursor.
var _cursorState: CursorState = CursorState.DEFAULT

func _ready() -> void:
	# when the player disconnects from the server setup disconnection functions.
	LowLevelNetworkHandler.on_disconnected_from_server.connect(_on_disconnected_from_server)

func _exit_tree() -> void:
	# cleanup any lingering signals.
	LowLevelNetworkHandler.on_disconnected_from_server.disconnect(_on_disconnected_from_server)

## When client disconnects from the server and its for this instance then free the cursor.
func _on_disconnected_from_server(peer_id: int):
	if peer_id == owner._manager.assigned_id: # this players cursor
		switchState(CursorState.PAUSE_ALL)

## if the cursor state is not currently on [enum CursorState.PAUSE_ALL].
func Movement_Allowed() -> bool:
	return _cursorState != CursorState.PAUSE_ALL

## if the cursor is currently captured and locked to the screen.
func Cursor_Locked() -> bool:
	return _cursorState == CursorState.DEFAULT

func _process(_delta: float) -> void:
	match _cursorState:
		# Default state the cursor is contained to the game window.
		CursorState.DEFAULT:
			if Input.is_action_just_pressed("ui_cancel"):
				switchState(CursorState.PAUSE_ALL)
		# Interacting state where player can move the mouse and move the character.
		CursorState.INTERACTING:
			if Input.is_action_just_pressed("ui_cancel"):
				switchState(CursorState.DEFAULT)
		# Pause State where player can move mouse but cannot move the character.
		CursorState.PAUSE_ALL:
			if Input.is_action_just_pressed("ui_cancel"):
				switchState(CursorState.DEFAULT)

## Switches the Cursor's state and handles any neccessary logic for a given state.
func switchState(state: CursorState) -> void:
	_cursorState = state
	match _cursorState:
		# Default state the cursor is contained to the game window.
		CursorState.DEFAULT:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		# Interacting state where player can move the mouse and move the character.
		CursorState.INTERACTING:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		# Pause State where player can move mouse but cannot move the character.
		CursorState.PAUSE_ALL:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
