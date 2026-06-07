class_name Packet_EntityStats extends PacketInfo

# [packet_type, (id, id), (health,health,health,health), (resource, resource, resource, resource, resource, resource, resource, resource)]
# [0, (1, 2), (3,4,5,6), (7,8,9,10,11,12,13,14)] => 15

## id of the player this packet belongs to.
var id: int
## stats of the player
var health : float
var resource: int

## Factory method for creating a [Packet_EntityStats] packet with the given parameters.
static func create(id: int, stats: Stats) -> Packet_EntityStats:
	var info: Packet_EntityStats = Packet_EntityStats.new()
	info.packet_type = PACKET_TYPE.ENTITY_STATS
	info.flag = ENetPacketPeer.FLAG_UNSEQUENCED
	info.id = id
	info.health = stats.health
	info.resource = stats.resource
	return info

## Factory method for creating a [Packet_EntityStats] packet from a PackedByteArray of data. [br]
## This is used when receiving a packet to decode it into a [Packet_EntityStats] instance.
static func create_from_data(data: PackedByteArray) -> Packet_EntityStats:
	var info: Packet_EntityStats = Packet_EntityStats.new()
	info.decode(data)
	return info


func encode() -> PackedByteArray:
	var data: PackedByteArray = super.encode()

	# Size of the packet data.
	data.resize(15)

	# encode peer_id
	data.encode_u16(1, id)
	data.encode_float(3, health)
	data.encode_s64(7,resource)

	return data

func decode(data: PackedByteArray) -> void:
	super.decode(data)
	id = data.decode_u16(1)
	health = data.decode_float(3)
	resource = data.decode_s64(7)
