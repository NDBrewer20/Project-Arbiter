class_name EntityTransform extends PacketInfo

var id: int
var position: Vector3
var rotation: Vector3

static func create(id: int, position: Vector3, rotation: Vector3) -> EntityTransform:
	var info: EntityTransform = EntityTransform.new()
	info.packet_type = PACKET_TYPE.ENTITY_TRANSFORM
	info.flag = ENetPacketPeer.FLAG_UNSEQUENCED
	info.id = id
	info.position = position
	info.rotation = rotation
	return info

static func create_from_data(data: PackedByteArray) -> EntityTransform:
	var info: EntityTransform = EntityTransform.new()
	info.decode(data)
	return info

# [type, id, 
# Pos.x, Pos.x, Pos.x, Pos.x, 
# Pos.y, Pos.y, Pos.y, Pos.y, 
# Pos.z, Pos.z, Pos.z, Pos.z,
# Rot.y, Rot.y, Rot.y, Rot.y]
# [0, 1, 
# 2, 3, 4, 5, 
# 6, 7, 8, 9, 
# 10, 11, 12, 13,
# 14, 15, 16, 17] => 18 bytes
func encode() -> PackedByteArray:
	var data: PackedByteArray = super.encode()

	data.resize(18)
	data.encode_u8(1, id)
	data.encode_float(2, position.x)
	data.encode_float(6, position.y)
	data.encode_float(10, position.z)
	data.encode_float(14, rotation.y)

	return data

func decode(data: PackedByteArray) -> void:
	super.decode(data)
	id = data.decode_u8(1)
	position = Vector3(data.decode_float(2), data.decode_float(6), data.decode_float(10))
	rotation = Vector3(0,data.decode_float(14),0)