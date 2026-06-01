class_name Packet_EntityTransform extends PacketInfo

# [type, id, id,
# vel.x, vel.x, vel.x, vel.x, 
# vel.y, vel.y, vel.y, vel.y, 
# vel.z, vel.z, vel.z, vel.z,
# Rot.y, Rot.y, Rot.y, Rot.y]
# [0, 1, 2, 
# 3, 4, 5, 6, 
# 7, 8, 9, 10 
# 11, 12, 13, 14,
# 15, 16, 17, 18] => 19 bytes

## id of the entity that this packet belongs to.
var id: int
## velocity of the entity (client -> server).[br]
## position of the entity (server -> client).
var movement: Vector3
## rotation of the entity.
var rotation: Vector3

## Factory method for creating a [Packet_EntityTransform] packet with the given parameters.
static func create(id: int, movement: Vector3, rotation: Vector3) -> Packet_EntityTransform:
	var info: Packet_EntityTransform = Packet_EntityTransform.new()
	info.packet_type = PACKET_TYPE.ENTITY_TRANSFORM
	info.flag = ENetPacketPeer.FLAG_UNSEQUENCED
	info.id = id
	info.movement = movement
	info.rotation = rotation
	return info

## Factory method for creating a [Packet_EntityTransform] packet from a PackedByteArray of data. [br]
## This is used when receiving a packet to decode it into a [Packet_EntityTransform] instance.
static func create_from_data(data: PackedByteArray) -> Packet_EntityTransform:
	var info: Packet_EntityTransform = Packet_EntityTransform.new()
	info.decode(data)
	return info

## The data is encoded in the following order: packet_type, id, movement.x, movement.y, movement.z, rotation.y
func encode() -> PackedByteArray:
	var data: PackedByteArray = super.encode()

	data.resize(19)
	data.encode_u16(1, id)
	data.encode_float(3, movement.x)
	data.encode_float(7, movement.y)
	data.encode_float(11, movement.z)
	data.encode_float(15, rotation.y)

	return data

## The data is decoded in the following order: packet_type, id, movement.x, movement.y, movement.z, rotation.y
func decode(data: PackedByteArray) -> void:
	super.decode(data)
	id = data.decode_u16(1)
	movement = Vector3(data.decode_float(3), data.decode_float(7), data.decode_float(11))
	rotation = Vector3(0,data.decode_float(15),0)