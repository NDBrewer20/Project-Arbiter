extends Control

## the UI for connecting to a server.
@export var UI_connect: VBoxContainer
## The UI for disconnecting from a server.
@export var UI_disconnect: VBoxContainer

func _ready() -> void:
	UI_connect.visible = true
	UI_disconnect.visible = false

## when server button is pressed start the server and disable corresponding UI
func _on_server_pressed() -> void:
	LowLevelNetworkHandler.start_server()
	UI_connect.visible = false

## when client button is pressed start the client and disable/enable corresponding UI
func _on_client_pressed() -> void:
	LowLevelNetworkHandler.start_client()
	UI_connect.visible = false
	UI_disconnect.visible = true

## when host button is pressed start the host (client + server) and disable/enable corresponding UI
func _on_host_pressed() -> void:
	LowLevelNetworkHandler.start_host()
	UI_connect.visible = false
	UI_disconnect.visible = true

## when Disconnect button is pressed if you're a host disconnect the host gracefully otherwise, disconnect the client and disable/enable corresponding UI
func _on_disconnect_pressed() -> void:
	if LowLevelNetworkHandler.is_host:
		LowLevelNetworkHandler.disconnect_host()
	else:
		LowLevelNetworkHandler.disconnect_client()
	UI_connect.visible = true
	UI_disconnect.visible = false
