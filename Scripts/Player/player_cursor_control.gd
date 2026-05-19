class_name PlayerCursor extends Node

@export var debug: bool = false

enum CursorState {
	DEFAULT = 0, # Normal gameplay, mouse is captured and player can look around and move freely.
	INTERACTING = 1, # Allows player input to a certain extent but disables mouse look.
	PAUSE_ALL = 2, # Stops all player input, used for "pause menu" and other specific limiting UI interactions.
}
var _cursorState: CursorState = CursorState.DEFAULT

func _enter_tree() -> void:
	switchState(CursorState.DEFAULT)

func _exit_tree() -> void:
	switchState(CursorState.INTERACTING)

func _process(delta: float) -> void:
	match _cursorState:
		CursorState.DEFAULT:
			if Input.is_action_just_pressed("ui_cancel"):
				switchState(CursorState.PAUSE_ALL)
		CursorState.INTERACTING:
			if Input.is_action_just_pressed("ui_cancel"):
				switchState(CursorState.DEFAULT)
		CursorState.PAUSE_ALL:
			if Input.is_action_just_pressed("ui_cancel"):
				switchState(CursorState.DEFAULT)

func switchState(state: CursorState) -> void:
	_cursorState = state
	match _cursorState:
		CursorState.DEFAULT:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		CursorState.INTERACTING:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		CursorState.PAUSE_ALL:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
