class_name Packet_EntityDamaged extends PacketInfo

# [packet_type, 
#  attack_id, attack_id, 
#  defender_id, defender_id,
#  damage, damage, damage, damage]
# [0, 
#  1, 2, 
#  3, 4,
#  5, 6, 7 ,8] => 9 bytes

## attack_id of the entity that has spawned
var attack_id: int
var defender_id: int
var damage: float

## Factory method for creating a [Packet_EntityDamaged] packet with the given parameters.
static func create(damage: float, attack_id: int, defender_id: int) -> Packet_EntityDamaged:
	var info: Packet_EntityDamaged = Packet_EntityDamaged.new()
	info.packet_type = PACKET_TYPE.ENTITY_DAMAGED
	info.flag = ENetPacketPeer.FLAG_UNSEQUENCED
	info.attack_id = attack_id
	info.defender_id = defender_id
	info.damage = damage
	return info

## Factory method for creating a [Packet_EntityDamaged] packet from a PackedByteArray of data. [br]
## This is used when receiving a packet to decode it into a [Packet_EntityDamaged] instance.
static func create_from_data(data: PackedByteArray) -> Packet_EntityDamaged:
	var info: Packet_EntityDamaged = Packet_EntityDamaged.new()
	info.decode(data)
	return info

func encode() -> PackedByteArray:
	var data: PackedByteArray = super.encode()
	data.resize(9)
	data.encode_u16(1, attack_id)
	data.encode_u16(3, defender_id)
	data.encode_float(5, damage)
	return data

func decode(data: PackedByteArray) -> void:
	super.decode(data)
	attack_id = data.decode_u16(1)
	defender_id = data.decode_u16(3)
	damage = data.decode_float(5)