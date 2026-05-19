extends Node

# Server side Signals
signal on_peer_connected(peer_id: int)
signal on_peer_disconnected(peer_id: int)
signal on_server_packet(peer_id: int, data: PackedByteArray)

# Client side Signals
signal on_connected_to_server()
signal on_disconnected_from_server()
signal on_client_packet(data: PackedByteArray)

# Server Variables
var available_peer_ids: Array = range(255, -1, -1) # List of available peer IDs (255 down to 0)
var client_peers: Dictionary[int, ENetPacketPeer]

# Client Variables
var server_peer: ENetPacketPeer

# General Variables
var connection: ENetConnection
var is_server: bool = false
var is_host: bool = false
var host_peer_id: int = -1

func _process(delta: float) -> void:
	if connection == null:
		return

	handleEvents()

func handleEvents() -> void:
	var packet_event: Array = connection.service()
	var event_type: ENetConnection.EventType = packet_event[0]

	while event_type != ENetConnection.EVENT_NONE:
		var peer: ENetPacketPeer = packet_event[1]
		match event_type:
			ENetConnection.EVENT_ERROR:
				push_warning("ENet Connection Event Error occurred: Package resulted in an unkown error!")
				return
			ENetConnection.EVENT_CONNECT:
				if is_server:
					peer_connected(peer)
				else:
					connected_to_server()
			ENetConnection.EVENT_DISCONNECT:
				if is_server:
					peer_disconnected(peer)
				else:
					disconnected_from_server()
					return # connection was set to null
			ENetConnection.EVENT_RECEIVE:
				if is_server:
					on_server_packet.emit(peer.get_meta("peer_id"), peer.get_packet())
				else:
					on_client_packet.emit(peer.get_packet())
		
		# Call Service again to handle remaining packets in current while loop.
		packet_event = connection.service()
		event_type = packet_event[0]


func start_server(ip_address: String="127.0.0.1", port: int = 27015) -> void:
	connection = ENetConnection.new()
	var error: Error = connection.create_host_bound(ip_address, port)
	if error:
		print("Failed to start server: ", error_string(error))
		connection = null
		return
	print("Server started on ", ip_address, ":", port)
	is_server = true

func start_host(ip_address: String="127.0.0.1", port: int = 27015) -> void:
	start_server(ip_address, port)
	if connection == null:
		return

	is_host = true
	host_peer_id = available_peer_ids.pop_back()
	ClientNetworkGlobals.id = host_peer_id
	ClientNetworkGlobals.handle_local_id_assignment.emit(host_peer_id)

	# Keep host in the server peer list so new clients learn about the host player.
	ServerNetworkGlobals.peer_ids.append(host_peer_id)

	print("Host started with local player id: ", host_peer_id)

func peer_connected(peer: ENetPacketPeer) -> void:
	var peer_id: int = available_peer_ids.pop_back()
	peer.set_meta("peer_id", peer_id)
	client_peers[peer_id] = peer

	print("Peer connected with ID: ", peer_id)
	on_peer_connected.emit(peer_id)

func peer_disconnected(peer: ENetPacketPeer) -> void:
	var peer_id: int = peer.get_meta("peer_id")
	available_peer_ids.push_back(peer_id)
	client_peers.erase(peer_id)

	print("Peer disconnected with ID: ", peer_id)
	on_peer_disconnected.emit(peer_id)

func start_client(ip_address: String = "127.0.0.1", port: int = 27015) -> void:
	connection = ENetConnection.new()
	var error: Error = connection.create_host(1)
	if error:
		print("Failed to start client: ", error_string(error))
		connection = null
		return
	print("Client started")
	server_peer = connection.connect_to_host(ip_address, port)

# This happens automatically when the client disconnects from the server, but can be called manually to force a clean disconnect.
func disconnect_client() -> void:
	if is_server:
		push_warning("Cannot disconnect client from server when running as a server!")
		return
	
	server_peer.peer_disconnect()

func connected_to_server() -> void:
	print("Connected to server")
	on_connected_to_server.emit()

func disconnected_from_server() -> void:
	print("Disconnected from server")
	on_disconnected_from_server.emit()
	connection = null