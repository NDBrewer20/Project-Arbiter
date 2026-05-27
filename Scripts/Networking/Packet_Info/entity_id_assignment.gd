extends PacketInfo
class_name EntityIDAssignment

# [packet_type, id,
# pos.x, pos.x, pos.x, pos.x,
# pos.y, pos.y, pos.y, pos.y,
# pos.z, pos.z, pos.z, pos.z]
# [0, 1,
# 2, 3, 4, 5,
# 6, 7, 8, 9,
# 10, 11, 12, 13] => 14 bytes

## id of the entity that has spawned
var id: int
## position where entity was spawned.
var position: Vector3 

## Factory method for creating a [EntityIDAssignment] packet with the given parameters.
static func create(id: int, position: Vector3) -> EntityIDAssignment:
	var info: EntityIDAssignment = EntityIDAssignment.new()
	info.packet_type = PACKET_TYPE.ENTITY_ID_ASSIGNMENT
	info.flag = ENetPacketPeer.FLAG_RELIABLE
	info.id = id
	info.position = position
	return info

## Factory method for creating a [EntityIDAssignment] packet from a PackedByteArray of data. [br]
## This is used when receiving a packet to decode it into a [EntityIDAssignment] instance.
static func create_from_data(data: PackedByteArray) -> EntityIDAssignment:
	var info: EntityIDAssignment = EntityIDAssignment.new()
	info.decode(data)
	return info

func encode() -> PackedByteArray:
	var data: PackedByteArray = super.encode()
	data.resize(14)
	data.encode_u8(1, id)
	data.encode_float(2, position.x)
	data.encode_float(6,position.y)
	data.encode_float(10,position.z)
	return data

func decode(data: PackedByteArray) -> void:
	super.decode(data)
	id = data.decode_u8(1)
	position.x = data.decode_float(2)
	position.y = data.decode_float(6)
	position.z = data.decode_float(10)