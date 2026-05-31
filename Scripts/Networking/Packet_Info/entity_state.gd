class_name Packet_EntityState extends PacketInfo

# [packet_type, id, state_byte_array]
# [0, 1, variant_byte_array] => 3+byte_array

## id of the player this packet belongs to.
var id: int
## state of the player
var state: State

## Factory method for creating a [Packet_EntityState] packet with the given parameters.
static func create(id: int, state: State) -> Packet_EntityState:
	var info: Packet_EntityState = Packet_EntityState.new()
	info.packet_type = PACKET_TYPE.ENTITY_STATE
	info.flag = ENetPacketPeer.FLAG_UNSEQUENCED
	info.id = id
	info.state = state
	return info

## Factory method for creating a [Packet_EntityState] packet from a PackedByteArray of data. [br]
## This is used when receiving a packet to decode it into a [Packet_EntityState] instance.
static func create_from_data(data: PackedByteArray) -> Packet_EntityState:
	var info: Packet_EntityState = Packet_EntityState.new()
	info.decode(data)
	return info


## Encodes the [Packet_EntityState] data into a [PackedByteArray] for sending over the network. [br]
## The data is encoded in the following order: packet_type, id, state, position.x, position.y, position.z, rotation.y
func encode() -> PackedByteArray:
	var data: PackedByteArray = super.encode()
	
	var state_byte_array := var_to_bytes(state)

	# Size of the packet data.
	data.resize(2 + state_byte_array.size())

	# encode peer_id
	data.encode_u8(1, id)
	data.append_array(state_byte_array)

	return data

## Decodes the [PlayerState] data from a [PackedByteArray] received over the network. [br]
## The data is decoded in the following order: packet_type, id, state, position.x, position.y, position.z, rotation.y
func decode(data: PackedByteArray) -> void:
	super.decode(data)
	id = data.decode_u8(1)
	state = data.decode_var(2)