extends Node

## signal called when Packet_EntityTransform packet is recieved.
signal client_handle_entity_position(entity_transform: Packet_EntityTransform)
signal server_handle_entity_position(entity_id:int, entity_transform: Packet_EntityTransform)
signal handle_entity_id_assignment(entity_id_assignment: Packet_EntityIDAssignment)
signal handle_entity_id_unassignment(entity_id: Packet_EntityIDUnassignment)

var available_entity_ids: Array = range((2 ** 16)-1,-1,-1) 
var entity_ids: Array[int]

func _ready() -> void:
	LowLevelNetworkHandler.on_client_packet.connect(on_client_packet)
	LowLevelNetworkHandler.on_server_packet.connect(on_server_packet)

## Handler for server information packets
func on_server_packet(peer_id: int, data: PackedByteArray) -> void:
	# What packet type is being handled
	var packet_type: int = data.decode_u8(0)

	match packet_type:
		# when the a packet is sent for state management
		PacketInfo.PACKET_TYPE.ENTITY_STATE:
			# TODO: manage the state of client authority entities.
			pass
		
		# Enity related packets.
		PacketInfo.PACKET_TYPE.ENTITY_TRANSFORM:
			server_handle_entity_position.emit(peer_id, Packet_EntityTransform.create_from_data(data))

		# unknown packet was sent to server.
		_:
			push_error("Packet type with index ", data[0], " Unhandled!")

## Handler for client information packets.
func on_client_packet(data: PackedByteArray) -> void:
	# What type of packet is being handled
	var packet_type: int = data.decode_u8(0)

	match packet_type:
		# packets unrelated to entities
		PacketInfo.PACKET_TYPE.ID_ASSIGNMENT,PacketInfo.PACKET_TYPE.ID_UNASSIGNMENT:
			pass

		# when the packet is related to an entity's transform
		PacketInfo.PACKET_TYPE.ENTITY_TRANSFORM:
			# emit a signal to have client handle the new packet for the specific entity.
			client_handle_entity_position.emit(Packet_EntityTransform.create_from_data(data))
		
		PacketInfo.PACKET_TYPE.ENTITY_ID_ASSIGNMENT:
			handle_entity_id_assignment.emit(Packet_EntityIDAssignment.create_from_data(data))

		PacketInfo.PACKET_TYPE.ENTITY_ID_UNASSIGNMENT:
			handle_entity_id_unassignment.emit(Packet_EntityIDUnassignment.create_from_data(data))

		PacketInfo.PACKET_TYPE.ENTITY_STATE:
			# TODO: give the client a signal to manage the state of the different server managed statemachines.
			pass

		# unknown packet was sent to client.
		_:
			push_error("Packet type with index ", data[0], " unhandled!")

func provision_entity_id() -> int:
	var id = available_entity_ids.pop_back()
	if id is not int:
		return -1
	entity_ids.append(id)
	return id

func claim_entity_id(id: int) -> bool:
	if available_entity_ids.has(id):
		available_entity_ids.erase(id)
		entity_ids.append(id)
		return true
	return false

func reclaim_entity_id(id: int) -> void:
	entity_ids.erase(id)
	available_entity_ids.push_back(id)
