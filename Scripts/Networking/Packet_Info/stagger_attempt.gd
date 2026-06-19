class_name Packet_StaggerAttempt extends PacketInfo

# [packet_type, 
#  attack_id, attack_id, 
#  defender_id, defender_id,]
# [0, 
#  1, 2, 
#  3, 4,] => 5 bytes

## attack_id of the entity that has spawned
var attack_id: int
var defender_id: int

## Factory method for creating a [Packet_StaggerAttempt] packet with the given parameters.
static func create(attack_id: int, defender_id: int) -> Packet_StaggerAttempt:
	var info: Packet_StaggerAttempt = Packet_StaggerAttempt.new()
	info.packet_type = PACKET_TYPE.STAGGER_ATTEMPT
	info.flag = ENetPacketPeer.FLAG_RELIABLE
	info.attack_id = attack_id
	info.defender_id = defender_id
	return info

## Factory method for creating a [Packet_StaggerAttempt] packet from a PackedByteArray of data. [br]
## This is used when receiving a packet to decode it into a [Packet_StaggerAttempt] instance.
static func create_from_data(data: PackedByteArray) -> Packet_StaggerAttempt:
	var info: Packet_StaggerAttempt = Packet_StaggerAttempt.new()
	info.decode(data)
	return info

func encode() -> PackedByteArray:
	var data: PackedByteArray = super.encode()
	data.resize(5)
	data.encode_u16(1, attack_id)
	data.encode_u16(3, defender_id)
	return data

func decode(data: PackedByteArray) -> void:
	super.decode(data)
	attack_id = data.decode_u16(1)
	defender_id = data.decode_u16(3)