class_name IDUnassignment extends PacketInfo

var id: int

static func create(id: int) -> IDUnassignment:
	var info: IDUnassignment = IDUnassignment.new()
	info.packet_type = PACKET_TYPE.ID_UNASSIGNMENT
	info.flag = ENetPacketPeer.FLAG_RELIABLE
	info.id = id
	return info

static func create_from_data(data: PackedByteArray) -> IDUnassignment:
	var info: IDUnassignment = IDUnassignment.new()
	info.decode(data)
	return info

# [packet_type, id]
# [0, 1] => 2 bytes
func encode() -> PackedByteArray:
	var data: PackedByteArray = super.encode()
	data.resize(2)
	data.encode_u8(1, id)

	return data

func decode(data: PackedByteArray) -> void:
	super.decode(data)
	id = data.decode_u8(1)