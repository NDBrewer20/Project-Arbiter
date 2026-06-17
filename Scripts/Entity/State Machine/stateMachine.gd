class_name StateMachine extends Node

## the intial state that the state machine should enter on.
@export var initial_state: State
## what states cause an animation lock [br]
## animation locks prevent specific inputs causing the controller to move on.
@export var anim_locked_states: Array[State]

## current state that the statemachine is in.
var currentState: State
## the list of available states in state machine.
var _states: Dictionary = {}

func _ready() -> void:
	# initialize statemachine list of available states.
	for child in get_children():
		if child is State:
			_states[child.name.to_lower()] = child
			child.transitioned.connect(_on_child_transition)
	# if there is an initial state then enter it.
	if initial_state:
		initial_state._enter()
		currentState = initial_state

func _process(delta: float) -> void:
	if currentState:
		# call update every process frame.
		currentState._update(delta)

func _physics_process(delta: float) -> void:
	if currentState:
		# call physics update very physics process frame.
		currentState._physics_update(delta)

## when a child wants to transition to new state taking in the old state and new state name.
func _on_child_transition(state: State, new_state_name: String) -> void:
	# if attempting to transition when not the current state then return.
	if state != currentState: return

	# get the new state from list of available states.
	var new_state: State = _states.get(new_state_name.to_lower())
	if !new_state: # if failed to retrieve then silently fail.
		return
	
	# if current state exists then exit.
	if currentState:
		currentState._exit()

	# enter the new state and update current state variable.
	new_state._enter()
	currentState = new_state

## check if current state belongs to [anim_locked_states]
func animLocked() -> bool:
	return anim_locked_states.has(currentState)