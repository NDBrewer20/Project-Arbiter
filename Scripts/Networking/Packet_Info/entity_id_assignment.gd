extends PacketInfo
class_name Packet_EntityIDAssignment

# [packet_type, id, id,
# pos.x, pos.x, pos.x, pos.x,
# pos.y, pos.y, pos.y, pos.y,
# pos.z, pos.z, pos.z, pos.z,
# spawn, spawn]
# [0, 1 , 2,
# 3, 4, 5 ,6
# 7, 8, 9, 10,
# 11, 12, 13 ,14,
# 15, 16] => 17 bytes

## id of the entity that has spawned
var id: int
## position where entity was spawned.
var position: Vector3 
## what entity was spawned
var spawn: LowLevelEntitySpawner.SPAWNABLE

## Factory method for creating a [Packet_EntityIDAssignment] packet with the given parameters.
static func create(id: int, spawn: LowLevelEntitySpawner.SPAWNABLE, position: Vector3) -> Packet_EntityIDAssignment:
	var info: Packet_EntityIDAssignment = Packet_EntityIDAssignment.new()
	info.packet_type = PACKET_TYPE.ENTITY_ID_ASSIGNMENT
	info.flag = ENetPacketPeer.FLAG_RELIABLE
	info.id = id
	info.spawn = spawn
	info.position = position
	return info

## Factory method for creating a [Packet_EntityIDAssignment] packet from a PackedByteArray of data. [br]
## This is used when receiving a packet to decode it into a [Packet_EntityIDAssignment] instance.
static func create_from_data(data: PackedByteArray) -> Packet_EntityIDAssignment:
	var info: Packet_EntityIDAssignment = Packet_EntityIDAssignment.new()
	info.decode(data)
	return info

func encode() -> PackedByteArray:
	var data: PackedByteArray = super.encode()
	data.resize(17)
	data.encode_u16(1, id)
	data.encode_float(3, position.x)
	data.encode_float(7,position.y)
	data.encode_float(11,position.z)
	data.encode_u16(15, spawn)
	return data

func decode(data: PackedByteArray) -> void:
	super.decode(data)
	id = data.decode_u16(1)
	position.x = data.decode_float(2)
	position.y = data.decode_float(6)
	position.z = data.decode_float(10)
	spawn = data.decode_u16(15) as LowLevelEntitySpawner.SPAWNABLE