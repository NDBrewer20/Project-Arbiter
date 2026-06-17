class_name Packet_EntityState extends PacketInfo

# [packet_type, id, id, state_byte_array]
# [0, 1, 2, string_byte_array] => 3+byte_array

## id of the player this packet belongs to.
var id: int
## stateName of the player
var stateName: String

## Factory method for creating a [Packet_EntityState] packet with the given parameters.
static func create(id: int, stateName: String) -> Packet_EntityState:
	var info: Packet_EntityState = Packet_EntityState.new()
	info.packet_type = PACKET_TYPE.ENTITY_STATE
	info.flag = ENetPacketPeer.FLAG_RELIABLE
	info.id = id
	info.stateName = stateName
	return info

## Factory method for creating a [Packet_EntityState] packet from a PackedByteArray of data. [br]
## This is used when receiving a packet to decode it into a [Packet_EntityState] instance.
static func create_from_data(data: PackedByteArray) -> Packet_EntityState:
	var info: Packet_EntityState = Packet_EntityState.new()
	info.decode(data)
	return info


## Encodes the [Packet_EntityState] data into a [PackedByteArray] for sending over the network. [br]
## The data is encoded in the following order: packet_type, id, stateName, position.x, position.y, position.z, rotation.y
func encode() -> PackedByteArray:
	var data: PackedByteArray = super.encode()
	
	var ascii_bytes: PackedByteArray = stateName.to_ascii_buffer()

	# Size of the packet data.
	data.resize(3 + ascii_bytes.size())

	# encode peer_id
	data.encode_u8(1, id)
	data.append_array(ascii_bytes)

	return data

## Decodes the [PlayerState] data from a [PackedByteArray] received over the network. [br]
## The data is decoded in the following order: packet_type, id, stateName, position.x, position.y, position.z, rotation.y
func decode(data: PackedByteArray) -> void:
	super.decode(data)
	id = data.decode_u8(1)
	stateName = data.slice(3).get_string_from_ascii()