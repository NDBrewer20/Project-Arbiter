extends PacketInfo
class_name EntityIDUnassignment

# [packet_type, id, id]
# [0, 1 , 2] => 3 bytes

## id of the entity that has spawned
var id: int

## Factory method for creating a [EntityIDUnassignment] packet with the given parameters.
static func create(id: int) -> EntityIDUnassignment:
	var info: EntityIDUnassignment = EntityIDUnassignment.new()
	info.packet_type = PACKET_TYPE.ENTITY_ID_UNASSIGNMENT
	info.flag = ENetPacketPeer.FLAG_RELIABLE
	info.id = id
	return info

## Factory method for creating a [EntityIDUnassignment] packet from a PackedByteArray of data. [br]
## This is used when receiving a packet to decode it into a [EntityIDUnassignment] instance.
static func create_from_data(data: PackedByteArray) -> EntityIDUnassignment:
	var info: EntityIDUnassignment = EntityIDUnassignment.new()
	info.decode(data)
	return info

func encode() -> PackedByteArray:
	var data: PackedByteArray = super.encode()
	data.resize(3)
	data.encode_u16(1, id)
	return data

func decode(data: PackedByteArray) -> void:
	super.decode(data)
	id = data.decode_u16(1)