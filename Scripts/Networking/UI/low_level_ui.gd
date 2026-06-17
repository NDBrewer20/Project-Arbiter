extends Control

## the UI for connecting to a server.
@export var UI_connect: Container
@export var UI_ip_address: LineEdit
@export var UI_port: LineEdit
## The UI for disconnecting from a server.
@export var UI_connected: Container
@export var UI_server: Container
@export var spawnAmt: LineEdit
@export var removeAmt: LineEdit

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

## retrieves the connection details from the connection information text boxes.
func retrieve_connection_details() -> Array:
	# set baseline values to return if the textboxes are empty.
	var ip: String = "127.0.0.1"
	var port: int = 27015
	if !UI_ip_address.text.is_empty(): ip = IP.resolve_hostname(UI_ip_address.text,IP.TYPE_IPV4)
	if !UI_port.text.is_empty(): port = UI_port.text.to_int()
	return [ip,port]

## when server button is pressed start the server and disable corresponding UI
func _on_server_pressed() -> void:
	var details := retrieve_connection_details()
	LowLevelNetworkHandler.start_server(details[0],details[1])
	UI_connect.visible = false
	UI_connected.visible = true
	UI_server.visible = true

## when client button is pressed start the client and disable/enable corresponding UI
func _on_client_pressed() -> void:
	var details := retrieve_connection_details()
	LowLevelNetworkHandler.start_client(details[0],details[1])
	UI_connect.visible = false
	UI_connected.visible = true

## when host button is pressed start the host (client + server) and disable/enable corresponding UI
func _on_host_pressed() -> void:
	var details := retrieve_connection_details()
	LowLevelNetworkHandler.start_host(details[0],details[1])
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

## when DEBUG server spawn button is pressed it will spawn the specified amount of enemies on the server. 
func _on_spawn_enemy_pressed() -> void:
	var val := 1
	if !spawnAmt.text.is_empty():
		val = spawnAmt.text.to_int()
	for i in range(val):
		LowLevelEntitySpawner.server_spawn_entity(randi_range(0,LowLevelEntitySpawner.SPAWNABLE.size()-1), Vector3.UP)

## when DEBUG server remove button is pressed it will remove the specified amount of enemies on the server.
func _on_remove_enemy_pressed() -> void:
	var val := 1
	var spawner := LowLevelEntitySpawner.instance
	if !removeAmt.text.is_empty():
		val = clamp(removeAmt.text.to_int(), 1, spawner._activeEntities.size())
	for i in range(val):
		if !spawner._activeEntities.is_empty():
			spawner.server_remove_entity(spawner._activeEntities.keys().pick_random())
