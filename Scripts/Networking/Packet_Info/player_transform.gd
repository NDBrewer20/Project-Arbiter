class_name PlayerTransform extends PacketInfo

# [packet_type, id, player_state
# Pos.x, Pos.x, Pos.x, Pos.x, 
# Pos.y, Pos.y, Pos.y, Pos.y, 
# Pos.z, Pos.z, Pos.z, Pos.z,
# Rot.y, Rot.y, Rot.y, Rot.y]
# [0, 1, 2
# 3, 4, 5, 6, 
# 7, 8, 9, 10, 
# 11, 12, 13, 14,
# 15, 16, 17, 18] => 19 bytes

## id of the player this packet belongs to.
var id: int
## state of the player
var player_state: ThirdPersonPlayer.PlayerState
## player position
var position: Vector3
## player rotation (only y-value is synced)
var rotation: Vector3

## Factory method for creating a [PlayerTransform] packet with the given parameters.
static func create(id: int, player_state: ThirdPersonPlayer.PlayerState, position: Vector3, rotation: Vector3) -> PlayerTransform:
	var info: PlayerTransform = PlayerTransform.new()
	info.packet_type = PACKET_TYPE.PLAYER_TRANSFORM
	info.flag = ENetPacketPeer.FLAG_UNSEQUENCED
	info.id = id
	info.player_state = player_state
	info.position = position
	info.rotation = rotation
	return info

## Factory method for creating a [PlayerTransform] packet from a PackedByteArray of data. [br]
## This is used when receiving a packet to decode it into a [PlayerTransform] instance.
static func create_from_data(data: PackedByteArray) -> PlayerTransform:
	var info: PlayerTransform = PlayerTransform.new()
	info.decode(data)
	return info


## Encodes the [PlayerTransform] data into a [PackedByteArray] for sending over the network. [br]
## The data is encoded in the following order: packet_type, id, player_state, position.x, position.y, position.z, rotation.y
func encode() -> PackedByteArray:
	var data: PackedByteArray = super.encode()
	
	# Size of the packet data.
	data.resize(19)

	# encode peer_id
	data.encode_u8(1, id)
	# encode player state
	data.encode_u8(2, player_state)
	# encode position
	data.encode_float(3, position.x)
	data.encode_float(7, position.y)
	data.encode_float(11, position.z)
	# encode rotation
	data.encode_float(15, rotation.y)

	return data

## Decodes the [PlayerTransform] data from a [PackedByteArray] received over the network. [br]
## The data is decoded in the following order: packet_type, id, player_state, position.x, position.y, position.z, rotation.y
func decode(data: PackedByteArray) -> void:
	super.decode(data)
	id = data.decode_u8(1)
	player_state = data.decode_u8(2) as ThirdPersonPlayer.PlayerState
	position = Vector3(data.decode_float(3), data.decode_float(7), data.decode_float(11))
	rotation = Vector3(0,data.decode_float(15),0)