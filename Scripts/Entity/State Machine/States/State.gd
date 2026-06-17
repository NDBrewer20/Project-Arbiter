class_name State extends Node

## emitted whenever a state wants to transition to a new one.
signal transitioned(cur_state, new_state_name)

func _ready() -> void:
	# set the name of state equal to stateName
	# typicall stateName will be defined in classes that inherit from this class
	name = self.get("stateName")

## when the state is entered this is called.
func _enter():
	pass

## when the state is exited this is called.
func _exit():
	pass

## called every process frame.
func _update(_delta:float):
	pass

## called every physics_process frame
func _physics_update(_delta: float):
	pass
