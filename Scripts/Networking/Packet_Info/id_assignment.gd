class_name Packet_IDAssignment extends PacketInfo

## id of the player that has connected.
var id: int
## id of the players connected to the server.
var remoted_ids: Array[int]

## Factory method for creating a [Packet_IDAssignment] packet with the given parameters.
static func create(id: int, remote_ids: Array[int]) -> Packet_IDAssignment:
	var info: Packet_IDAssignment = Packet_IDAssignment.new()
	info.packet_type = PACKET_TYPE.ID_ASSIGNMENT
	info.flag = ENetPacketPeer.FLAG_RELIABLE
	info.id = id
	info.remoted_ids = remote_ids
	return info

## Factory method for creating a [Packet_IDAssignment] packet from a PackedByteArray of data. [br]
## This is used when receiving a packet to decode it into a [Packet_IDAssignment] instance.
static func create_from_data(data: PackedByteArray) -> Packet_IDAssignment:
	var info: Packet_IDAssignment = Packet_IDAssignment.new()
	info.decode(data)
	return info

## Encodes the Packet data into a [PackedByteArray] for sending over the network. [br]
## The data is encoded in the following order: packet_type, id
func encode() -> PackedByteArray:
	var data: PackedByteArray = super.encode()

	data.resize(3 + remoted_ids.size())
	data.encode_u16(1, id)
	var offset := 0
	for i in remoted_ids.size():
		var remote_id: int = remoted_ids[i]
		data.encode_u16(3+offset, remote_id)
		offset += 2

	return data

## Decodes the Packet data from a [PackedByteArray] received over the network. [br]
## The data is decoded in the following order: packet_type, id
func decode(data: PackedByteArray) -> void:
	super.decode(data)
	id = data.decode_u16(1)
	for i in range(3, data.size(),2):
		remoted_ids.append(data.decode_u16(i))