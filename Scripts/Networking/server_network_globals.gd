extends Node

signal handle_player_position(peer_id: int, player_transform: PlayerTransform)
signal handle_entity_position(e_id: int, entity_transform: EntityTransform)

var peer_ids: Array[int]

func _ready() -> void:
	LowLevelNetworkHandler.on_peer_connected.connect(on_peer_connected)
	LowLevelNetworkHandler.on_peer_disconnected.connect(on_peer_disconnected)
	LowLevelNetworkHandler.on_server_packet.connect(on_server_packet)

func on_peer_connected(peer_id: int) -> void:
	peer_ids.append(peer_id)

	IDAssignment.create(peer_id, peer_ids).broadcast(LowLevelNetworkHandler.connection)

func on_peer_disconnected(peer_id: int) -> void:
	peer_ids.erase(peer_id)

	# Make another packet IDUnassignment to broadcast disconnection of peers

func on_server_packet(peer_id: int, data: PackedByteArray) -> void:
	var packet_type: int = data.decode_u8(0)

	match packet_type:
		PacketInfo.PACKET_TYPE.PLAYER_TRANSFORM:
			handle_player_position.emit(peer_id, PlayerTransform.create_from_data(data))
			
		_:
			push_error("Packet type with index ", data[0], " Unhandled!")