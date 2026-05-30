extends Node

## signal called when EntityTransform packet is recieved.
signal handle_entity_position(entity_transform: EntityTransform)
signal handle_entity_id_assignment(entity_id_assignment: EntityIDAssignment)
signal handle_entity_id_unassignment(entity_id: EntityIDUnassignment)

var available_entity_ids: Array = range((2 ** 16)-1,-1,-1) 
var entity_ids: Array[int]

func _ready() -> void:
	LowLevelNetworkHandler.on_client_packet.connect(on_client_packet)

## Handler for client information packets.
func on_client_packet(data: PackedByteArray) -> void:
	# What type of packet is being handled
	var packet_type: int = data.decode_u8(0)

	match packet_type:
		# packets unrelated to entities
		PacketInfo.PACKET_TYPE.ID_ASSIGNMENT,PacketInfo.PACKET_TYPE.ID_UNASSIGNMENT,PacketInfo.PACKET_TYPE.PLAYER_TRANSFORM:
			pass

		# when the packet is related to an entity's transform
		PacketInfo.PACKET_TYPE.ENTITY_TRANSFORM:
			# emit a signal to have client handle the new packet for the specific entity.
			handle_entity_position.emit(EntityTransform.create_from_data(data))
		
		PacketInfo.PACKET_TYPE.ENTITY_ID_ASSIGNMENT:
			handle_entity_id_assignment.emit(EntityIDAssignment.create_from_data(data))

		PacketInfo.PACKET_TYPE.ENTITY_ID_UNASSIGNMENT:
			handle_entity_id_unassignment.emit(EntityIDUnassignment.create_from_data(data))

		# unknown packet was sent to client.
		_:
			push_error("Packet type with index ", data[0], " unhandled!")

func provision_entity_id() -> int:
	var id = available_entity_ids.pop_back()
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