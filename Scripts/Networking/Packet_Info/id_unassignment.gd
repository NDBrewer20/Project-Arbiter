class_name Packet_IDUnassignment extends PacketInfo

# [packet_type, id]
# [0, 1] => 2 bytes

## id of the player that has disconnected
var id: int

## Factory method for creating a [Packet_IDUnassignment] packet with the given parameters.
static func create(id: int) -> Packet_IDUnassignment:
	var info: Packet_IDUnassignment = Packet_IDUnassignment.new()
	info.packet_type = PACKET_TYPE.ID_UNASSIGNMENT
	info.flag = ENetPacketPeer.FLAG_RELIABLE
	info.id = id
	return info

## Factory method for creating a [Packet_IDUnassignment] packet from a PackedByteArray of data. [br]
## This is used when receiving a packet to decode it into a [Packet_IDUnassignment] instance.
static func create_from_data(data: PackedByteArray) -> Packet_IDUnassignment:
	var info: Packet_IDUnassignment = Packet_IDUnassignment.new()
	info.decode(data)
	return info

## Encodes the Packet data into a [PackedByteArray] for sending over the network. [br]
## The data is encoded in the following order: packet_type, id
func encode() -> PackedByteArray:
	var data: PackedByteArray = super.encode()
	data.resize(2)
	data.encode_u8(1, id)

	return data

## Decodes the Packet data from a [PackedByteArray] received over the network. [br]
## The data is decoded in the following order: packet_type, id
func decode(data: PackedByteArray) -> void:
	super.decode(data)
	id = data.decode_u8(1)