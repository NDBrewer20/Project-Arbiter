extends Control

func _on_server_pressed() -> void:
	LowLevelNetworkHandler.start_server()
	queue_free()

func _on_client_pressed() -> void:
	LowLevelNetworkHandler.start_client()
	queue_free()