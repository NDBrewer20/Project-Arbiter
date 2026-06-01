extends State
class_name PlayerFalling

const stateName := "PlayerFalling"

@export var player: ThirdPersonPlayer

func _enter() -> void:
	super._enter()

func _exit() -> void:
	super._exit()

func _update(delta: float):
	super._update(delta)

func _physics_update(delta: float):
	super._physics_update(delta)