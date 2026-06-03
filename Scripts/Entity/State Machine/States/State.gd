class_name State extends Node

signal transitioned

func _ready() -> void:
	name = self.get("stateName")

func _enter():
	pass

func _exit():
	pass

func _update(_delta:float):
	pass

func _physics_update(_delta: float):
	pass
