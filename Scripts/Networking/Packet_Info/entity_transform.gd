class_name Packet_EntityTransform extends PacketInfo

# [type, id, id,
# pos.x, pos.x, pos.x, pos.x, 
# pos.y, pos.y, pos.y, pos.y, 
# pos.z, pos.z, pos.z, pos.z,
# Rot.y, Rot.y, Rot.y, Rot.y,
# vel.x, vel.x, vel.x, vel.x, 
# vel.y, vel.y, vel.y, vel.y, 
# vel.z, vel.z, vel.z, vel.z]
# [0, 1, 2, 
# 3, 4, 5, 6, 
# 7, 8, 9, 10 
# 11, 12, 13, 14,
# 15, 16, 17, 18,
# 19, 20, 21, 22,
# 23, 24, 25, 26,
# 27, 28, 29, 30] => 31 bytes

## id of the entity that this packet belongs to.
var id: int
## position of the entity.
var position: Vector3
var velocity: Vector3
## rotation of the entity.
var rotation: Vector3

## Factory method for creating a [Packet_EntityTransform] packet with the given parameters.
static func create(id: int, position: Vector3, velocity: Vector3, rotation: Vector3) -> Packet_EntityTransform:
	var info: Packet_EntityTransform = Packet_EntityTransform.new()
	info.packet_type = PACKET_TYPE.ENTITY_TRANSFORM
	info.flag = ENetPacketPeer.FLAG_UNSEQUENCED
	info.id = id
	info.position = position
	info.velocity = velocity
	info.rotation = rotation
	return info

## Factory method for creating a [Packet_EntityTransform] packet from a PackedByteArray of data. [br]
## This is used when receiving a packet to decode it into a [Packet_EntityTransform] instance.
static func create_from_data(data: PackedByteArray) -> Packet_EntityTransform:
	var info: Packet_EntityTransform = Packet_EntityTransform.new()
	info.decode(data)
	return info

## The data is encoded in the following order: packet_type, id, position.x, position.y, position.z, rotation.y
func encode() -> PackedByteArray:
	var data: PackedByteArray = super.encode()

	data.resize(31)
	data.encode_u16(1, id)
	data.encode_float(3, position.x)
	data.encode_float(7, position.y)
	data.encode_float(11, position.z)
	data.encode_float(15, rotation.y)
	data.encode_float(19, velocity.x)
	data.encode_float(23, velocity.y)
	data.encode_float(27, velocity.z)
	
	return data

## The data is decoded in the following order: packet_type, id, position.x, position.y, position.z, rotation.y
func decode(data: PackedByteArray) -> void:
	super.decode(data)
	id = data.decode_u16(1)
	position = Vector3(data.decode_float(3), data.decode_float(7), data.decode_float(11))
	rotation = Vector3(0,data.decode_float(15),0)
	velocity = Vector3(data.decode_float(19),data.decode_float(23),data.decode_float(27))