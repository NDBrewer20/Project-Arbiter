extends Control

## the UI for connecting to a server.
@export var UI_connect: Container
## The UI for disconnecting from a server.
@export var UI_connected: Container
@export var UI_server: Container
@export var spawnAmt: LineEdit

func _ready() -> void:
	UI_connect.visible = true
	UI_connected.visible = false
	UI_server.visible = false
	LowLevelNetworkHandler.on_disconnected_from_server.connect(_on_disconnected_from_server)

## when this client disconnects from server then go back to connection UI
func _on_disconnected_from_server(peer_id: int):
	if peer_id == ClientNetworkGlobals.id:
		UI_connect.visible = true
		UI_connected.visible = false		
		UI_server.visible = false

## when server button is pressed start the server and disable corresponding UI
func _on_server_pressed() -> void:
	LowLevelNetworkHandler.start_server()
	UI_connect.visible = false
	UI_connected.visible = true
	UI_server.visible = true

## when client button is pressed start the client and disable/enable corresponding UI
func _on_client_pressed() -> void:
	LowLevelNetworkHandler.start_client()
	UI_connect.visible = false
	UI_connected.visible = true

## when host button is pressed start the host (client + server) and disable/enable corresponding UI
func _on_host_pressed() -> void:
	LowLevelNetworkHandler.start_host()
	UI_connect.visible = false
	UI_connected.visible = true
	UI_server.visible = true

## when Disconnect button is pressed if you're a host disconnect the host gracefully otherwise, disconnect the client and disable/enable corresponding UI
func _on_disconnect_pressed() -> void:
	if LowLevelNetworkHandler.is_host:
		LowLevelNetworkHandler.disconnect_host()
		UI_server.visible = false
	elif LowLevelNetworkHandler.is_server:
		LowLevelNetworkHandler.disconnect_server()
		UI_server.visible = false
	else:
		LowLevelNetworkHandler.disconnect_client()
	UI_connect.visible = true
	UI_connected.visible = false

func _on_spawn_enemy_pressed() -> void:
	var val := 1
	if !spawnAmt.text.is_empty():
		val = spawnAmt.text.to_int()
	for i in range(val):
		get_tree().get_first_node_in_group("entity spawner").server_spawn_entity(Vector3.UP)
