extends Node

## signal for when server needs to update player position.
signal handle_player_position(peer_id: int, player_transform: Packet_EntityState)

## peers connected to the server.
var peer_ids: Array[int]

func _ready() -> void:
	LowLevelNetworkHandler.on_peer_connected.connect(on_peer_connected)
	LowLevelNetworkHandler.on_peer_disconnected.connect(on_peer_disconnected)
	LowLevelNetworkHandler.on_server_packet.connect(on_server_packet)

## when a peer connects add it to the list of peers and let clients know of a new peer.
func on_peer_connected(peer_id: int) -> void:
	peer_ids.append(peer_id)

	# create Packet_IDAssignment packet to broadcast to clients to inform of a new client.
	Packet_IDAssignment.create(peer_id, peer_ids).broadcast(LowLevelNetworkHandler.connection)

## when a peer disconnects remove it from the list of peers and let clients know a peer has disconnected.
func on_peer_disconnected(peer_id: int) -> void:
	peer_ids.erase(peer_id)
	
	# create Packet_IDUnassignment packet to broadcast to clients to inform of a disconnected client.
	Packet_IDUnassignment.create(peer_id).broadcast(LowLevelNetworkHandler.connection)

## Handler for server information packets
func on_server_packet(peer_id: int, data: PackedByteArray) -> void:
	# What packet type is being handled
	var packet_type: int = data.decode_u8(0)

	match packet_type:
		# Enity related packets.
		PacketInfo.PACKET_TYPE.ENTITY_TRANSFORM, PacketInfo.PACKET_TYPE.ENTITY_STATE:
			pass

		# unknown packet was sent to server.
		_:
			push_error("Packet type with index ", data[0], " Unhandled!")