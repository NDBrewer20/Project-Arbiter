extends Node

# Server side Signals
## when a peer is connected to the server.
signal on_peer_connected(peer_id: int)
## when a peer is disconnected from the server.
signal on_peer_disconnected(peer_id: int)
## when the server is closing.
signal on_server_disconnect()
## when the server recieves a packet.
signal on_server_packet(peer_id: int, data: PackedByteArray)

# Client side Signals
## when the client connects to the server.
signal on_connected_to_server()
## when the client disconnects from a server.
signal on_disconnected_from_server(peer_id: int)
## when a client recieves a packet.
signal on_client_packet(data: PackedByteArray)

# Server Variables
## possible peer IDs that can be used on the server.
#var available_peer_ids: Array = range(255, -1, -1) # List of available peer IDs (255 down to 0)
## client peers connected to the server.
var client_peers: Dictionary[int, ENetPacketPeer]

# Client Variables
## server connection
var server_peer: ENetPacketPeer

# General Variables
## Core ENet host managing connected peers and packet routing.
var connection: ENetConnection
## if this instance is the server.
var is_server: bool = false
## if this instance is the host.
var is_host: bool = false
## the host's peer id
var host_peer_id: int = -1

func _process(_delta: float) -> void:
	if connection == null:
		return

	handleEvents()

func _notification(what: int) -> void:
	# if the user force closes the application
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_server:
			disconnect_server()
		elif is_host:
			disconnect_host()
		else:
			disconnect_client()

## handle all the packet events.
func handleEvents() -> void:
	# fetch packet.
	var packet_event: Array = connection.service()
	# check packet event type.
	var event_type: ENetConnection.EventType = packet_event[0]

	# while there are packets to process.
	while event_type != ENetConnection.EVENT_NONE:
		# fetch the peer.
		var peer: ENetPacketPeer = packet_event[1]
		match event_type:
			# Packet Event Error
			ENetConnection.EVENT_ERROR:
				push_warning("ENet Connection Event Error occurred: Package resulted in an unknown error!")
				return
			# A peer has connected
			ENetConnection.EVENT_CONNECT:
				if is_server:
					peer_connected(peer)
				else:
					connected_to_server()
			# A peer has disconnected.
			ENetConnection.EVENT_DISCONNECT:
				if is_server:
					peer_disconnected(peer)
				else:
					disconnected_from_server()
					return # connection was set to null
			# A peer sent out a packet.
			ENetConnection.EVENT_RECEIVE:
				if is_server:
					on_server_packet.emit(peer.get_meta("peer_id"), peer.get_packet())
				else:
					on_client_packet.emit(peer.get_packet())
		
		# Call Service again to handle remaining packets in current while loop.
		packet_event = connection.service()
		event_type = packet_event[0]

## starts the server for listening.
func start_server(ip_address: String="127.0.0.1", port: int = 27015) -> void:
	connection = ENetConnection.new()
	# bind connection to start a listener.
	var error: Error = connection.create_host_bound(ip_address, port)
	# if connection fails
	if error:
		print("Failed to start server: ", error_string(error))
		connection = null
		return
	print("Server started on ", ip_address, ":", port)
	is_server = true

## disconnects the server.
func disconnect_server() -> void:
	if !is_server:
		push_warning("cannot disconnect server when not running as server.")

	on_server_disconnect.emit()

	# Disconnect all connected remote peers cleanly.
	if client_peers:
		for peer_id in client_peers.keys():
			var peer = client_peers[peer_id]
			if peer:
				peer.peer_disconnect()
				on_peer_disconnected.emit(peer_id)
			EntityNetworkGlobals.reclaim_entity_id(peer_id)
		client_peers.clear()

	# Try to destroy the ENet host, then null the connection.
	if connection != null:
		connection.destroy()
	connection = null

	is_server = false


## starts the server and a manually managed client instance
func start_host(ip_address: String="127.0.0.1", port: int = 27015) -> void:
	start_server(ip_address, port)
	if connection == null:
		return

	is_host = true
	# reserve host peer id and force a local id assignment.
	host_peer_id = EntityNetworkGlobals.provision_entity_id()
	ClientNetworkGlobals.id = host_peer_id
	ClientNetworkGlobals.handle_local_id_assignment.emit(host_peer_id)

	# Keep host in the server peer list so new clients learn about the host player.
	ServerNetworkGlobals.peer_ids.append(host_peer_id)

	print("Host started with local player id: ", host_peer_id)

## disconnects the host
func disconnect_host() -> void:
	if not is_host:
		push_warning("Cannot disconnect host when not running as host!")
		return

	# push peer id back into available pool
	EntityNetworkGlobals.reclaim_entity_id(host_peer_id)
	# Inform server globals and clients that the host id is being unassigned.
	on_peer_disconnected.emit(host_peer_id)

	# Disconnect the server.
	disconnect_server()

	# Reset host/server flags and id.
	is_host = false
	host_peer_id = -1

	print("Host disconnected and server closed")

## when a peer is connected to the server.
func peer_connected(peer: ENetPacketPeer) -> void:
	# reserve a peer id
	var peer_id: int = EntityNetworkGlobals.provision_entity_id()
	if peer_id == -1:
		var entityToRemove: int = EntityNetworkGlobals.entity_ids.pick_random()
		PA_Debug.log("server: attempting to assign peer id (%s)" % [entityToRemove])
		while client_peers.has(entityToRemove) || host_peer_id == entityToRemove:
			entityToRemove = EntityNetworkGlobals.entity_ids.pick_random()
			PA_Debug.log("server: attempting to assign peer id (%s)" % [entityToRemove])
		LowLevelEntitySpawner.instance.server_remove_entity(entityToRemove)
		peer_id = EntityNetworkGlobals.provision_entity_id()
	# add metadata to peer using reserved peer id
	peer.set_meta("peer_id", peer_id)
	# add peer it list of managed clients
	client_peers[peer_id] = peer

	# emit signal for a peer connection.
	print("Peer connected with ID: ", peer_id)
	on_peer_connected.emit(peer_id)

## when a peer is disconnected from the server.
func peer_disconnected(peer: ENetPacketPeer) -> void:
	# fetch peer id
	var peer_id: int = peer.get_meta("peer_id")
	# push peer id back into available pool
	EntityNetworkGlobals.reclaim_entity_id(peer_id)
	# remove peer from list of managed clients.
	client_peers.erase(peer_id)

	# emit signal for peer disconnection.
	print("Peer disconnected with ID: ", peer_id)
	on_peer_disconnected.emit(peer_id)

## start the client
func start_client(ip_address: String = "127.0.0.1", port: int = 27015) -> void:
	connection = ENetConnection.new()
	# create host for connection to server.
	var error: Error = connection.create_host(1)
	# if creation fails
	if error:
		print("Failed to start client: ", error_string(error))
		connection = null
		return
	
	# bind connection to server.
	print("Client started")
	server_peer = connection.connect_to_host(ip_address, port)

## manually to force a clean disconnect.
func disconnect_client() -> void:
	if is_server and not is_host: # Don't let the server or host run this command.
		push_warning("Cannot disconnect client from server when running as a server!")
		return
	
	# This happens automatically when the client disconnects from the server
	# disconnect from the server cleanly.
	server_peer.peer_disconnect()

## when the client is connected to the server.
func connected_to_server() -> void:
	PA_Debug.log("client_id (%s): connected to server" % [ClientNetworkGlobals.id])
	on_connected_to_server.emit()

## when the client is disconnected from the server.
func disconnected_from_server() -> void:
	PA_Debug.log("client_id (%s): Disconnected from server" % [ClientNetworkGlobals.id])
	on_disconnected_from_server.emit(ClientNetworkGlobals.id)
	# null connection when disconnected.
	connection = null
