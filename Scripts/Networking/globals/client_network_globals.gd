extends Node

## signal called when id is assigned.
signal handle_local_id_assignment(local_id: int)
signal handle_local_id_unassignment(local_id: int)
## signal called when remote id's are assigned.
signal handle_remote_id_assignment(remote_id: int)
signal handle_remote_id_unassignment(remote_id: int)

## assigned peer id from server.
var id: int = -1
## peer ids connected to the server.
var remote_ids: Array[int]

func _ready() -> void:
	# whenever the network handler gets a client packet we need to handle it.
	LowLevelNetworkHandler.on_client_packet.connect(on_client_packet)

## Handler for client information packets.
func on_client_packet(data: PackedByteArray) -> void:
	# What type of packet is being handled
	var packet_type: int = data.decode_u8(0)

	match packet_type:
		# when an id gets assigned to a new client.
		PacketInfo.PACKET_TYPE.ID_ASSIGNMENT:
			PA_Debug.log("client_id (%s): Recieved Packet_IDAssignment" % [id])
			# if were not already assigned an id then take the id from this packet, otherwise add it to the remote ids.
			manage_ids(Packet_IDAssignment.create_from_data(data))

		# when id needs to be removed from a disconnecting client.
		PacketInfo.PACKET_TYPE.ID_UNASSIGNMENT:
			PA_Debug.log("client_id (%s): Recieved Packet_IDUnassignment" % [id])
			remove_ids(Packet_IDUnassignment.create_from_data(data))

		# packets unrelated to Player/client manipulation
		PacketInfo.PACKET_TYPE.ENTITY_TRANSFORM, PacketInfo.PACKET_TYPE.ENTITY_ID_ASSIGNMENT, PacketInfo.PACKET_TYPE.ENTITY_ID_UNASSIGNMENT, PacketInfo.PACKET_TYPE.ENTITY_STATE:
			pass
		
		# unknown packet was sent to client.
		_:
			push_error("Packet type with index ", data[0], " unhandled!")

## manage client ids [br]
## if current clients [id] is unassigned then take the passed [id] otherwise, add id to [remote_ids] for tracking.
func manage_ids(id_assignment: Packet_IDAssignment) -> void:
	if id == -1: # we haven't been assigned an id already
		# take the id and emit id assignment signal
		id = id_assignment.id
		PA_Debug.log("client_id (%s): Set ID to %s" % [id, id])
		handle_local_id_assignment.emit(id_assignment.id)

		# update remoted ids to include what is already connected to the server.
		remote_ids = id_assignment.remoted_ids
		for remote_id in remote_ids:
			# ignore current id since we are already connected.
			if remote_id == id: continue
			PA_Debug.log("client_id (%s): remote id assigned (%s)" % [id, remote_id])
			# emit remote id assignment signal.
			handle_remote_id_assignment.emit(remote_id)
	else: # if we already have an id.
		# add the id to remote_ids and signal remote id assignment. 
		PA_Debug.log("client_id (%s): remote id packet assigned (%s)" % [id, id_assignment.id])
		remote_ids.append(id_assignment.id)
		handle_remote_id_assignment.emit(id_assignment.id)

## remove client ids [br]
## if the unassigned id belongs to this client then reset everything and clear [remote_ids] otherwise, remove id from [remote_ids]
func remove_ids(id_unassignment: Packet_IDUnassignment) -> void:
	if id == id_unassignment.id: # if we are disconnecting
		# emit a signal that we are unassigning every known client and clear our remote_ids 
		for remote_id in remote_ids:
			PA_Debug.log("client_id (%s): remote id unassigned (%s)" % [id, remote_id])
			handle_remote_id_unassignment.emit(remote_id)
		remote_ids.clear()

		# reinitialize values and emit signal that we are unassigned an id.
		PA_Debug.log("client_id (%s): id unassigned %s" % [id, id_unassignment.id])
		handle_local_id_unassignment.emit(id_unassignment.id)
		id = -1
		PA_Debug.log("client_id (%s): after unassignment %s" % [id_unassignment.id, id])
	else: # if another client disconnected
		# remove the client from peer list and emit signal of their disconnection.
		PA_Debug.log("client_id (%s): remote id packet unassigned (%s)" % [id, id_unassignment.id])
		remote_ids.erase(id_unassignment.id)
		handle_remote_id_unassignment.emit(id_unassignment.id)
