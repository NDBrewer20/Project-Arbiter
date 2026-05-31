class_name StateMachine extends Node

@export var initial_state: State

var currentState: State
var _states: Dictionary = {}

func _ready() -> void:
	for child in get_children():
		if child is State:
			_states[child.name.to_lower()] = child
			child.transitioned.connect(_on_child_transition)

	if initial_state:
		initial_state._enter()
		currentState = initial_state

func _process(delta: float) -> void:
	if currentState:
		currentState._update(delta)

func _physics_process(delta: float) -> void:
	if currentState:
		currentState._physics_update(delta)

func _on_child_transition(state: State, new_state_name: String) -> void:
	if state != currentState: return

	var new_state: State = _states.get(new_state_name.to_lower())
	if !new_state:
		return
	
	if currentState:
		currentState._exit()

	new_state._enter()

	currentState = new_state

