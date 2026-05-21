class_name PacketInfo

## What type of packets can be sent.
enum PACKET_TYPE {
	ID_ASSIGNMENT = 0,
	PLAYER_TRANSFORM = 1,
	ID_UNASSIGNMENT = 2,
	ENTITY_TRANSFORM = 3,
}

## Controls what type of packet is being sent.
var packet_type: PACKET_TYPE
## Controls whether the packet will be sent reliably or unreliably. [br]
## [enum ENetPacketPeer.FLAG_RELIABLE] [br]
## [enum ENetPacketPeer.FLAG_UNSEQUENCED] [br]
var flag: int

## Encodes the [PacketInfo] data into a [PackedByteArray] for sending over the network. [br]
func encode() -> PackedByteArray:
	var data: PackedByteArray
	data.resize(1)
	data.encode_u8(0,packet_type)
	return data

## Decodes the [PacketInfo] data from a [PackedByteArray] received over the network. [br]
func decode(data: PackedByteArray) -> void:
	packet_type = data.decode_u8(0) as PACKET_TYPE

func send(target: ENetPacketPeer) -> void:
	if target:
		target.send(0, encode(), flag)
	else:
		push_error("packet couldn't send to target: Target not found.")

func broadcast(server: ENetConnection) -> void:
	if server:
		server.broadcast(0,encode(),flag)
	else:
		push_error("packet couldn't broadcast from server: Server not found.")
