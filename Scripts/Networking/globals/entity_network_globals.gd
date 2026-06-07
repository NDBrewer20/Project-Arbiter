extends Node

## signal called when Packet_EntityTransform packet is recieved.
signal client_handle_entity_position(entity_transform: Packet_EntityTransform)
signal server_handle_entity_position(entity_id:int, entity_transform: Packet_EntityTransform)
signal handle_entity_id_assignment(entity_id_assignment: Packet_EntityIDAssignment)
signal handle_entity_id_unassignment(entity_id: Packet_EntityIDUnassignment)
signal recieve_Entity_stat_values(entity_stats: Packet_EntityStats)

var available_entity_ids: Array = range((2 ** 16)-1,-1,-1) 
var entity_ids: Dictionary[int, Entity] = {}

## This function is used to provision an entity id and fill in the specific entity in the list of entity ids. [br]
## This function is used in cases where you need to know the entity id at the time of instantiating the entity.
func provision_entity_id(entity: Entity) -> int:
	var id = available_entity_ids.pop_back()
	if id is not int:
		return -1
	entity_ids[id] = entity
	return id
## This function is used to provision an entity id but will not fill in the specific entity in the list of entity ids. [br]
## this function ASSUMES THAT YOU WILL FILL THIS ENTITY ID IN LATER. Failure to do so will cause problems with the entity id management system. [br]
## This function is used in cases where you need to know the entity id before you have the entity ready to be assigned to that id. 
func preprovision_entity_id() -> int:
	var id = available_entity_ids.pop_back()
	if id is not int:
		return -1
	entity_ids[id] = null
	return id
## This function is used to assign an entity id to an entity that has already been provisioned. [br]
## This function is used in cases where you have preprovisioned an entity id and now need to assign it to a specific entity.
func assign_entity_id(id: int, entity: Entity) -> bool:
	if !entity_ids.has(id) or entity_ids[id] != null:
		return false
	entity_ids[id] = entity
	return true
## Forcefully assign a entity id to an entity. if the entity id is already taken then this will fail and return false. [br]
## This function is used in cases where you need to assign a specific entity id to an entity such as when a client receives a packet to spawn an entity with a specific entity id.
func claim_entity_id(id: int, entity: Entity) -> bool:
	if available_entity_ids.has(id):
		available_entity_ids.erase(id)
		entity_ids[id] = entity
		return true
	return false
## Forcefully assign a entity id to an entity. if the entity id is already taken then this will fail and return false. [br]
## This function is used in cases where you need to assign a specific entity id to an entity such as when a client receives a packet to spawn an entity with a specific entity id but you don't
## have the entity ready at the time of claiming the entity id so you just want to reserve the entity id and fill in the entity later.
## Failure to fill in the entity later will cause problems with the entity id management system.
func preclaim_entity_id(id: int) -> bool:
	if available_entity_ids.has(id):
		available_entity_ids.erase(id)
		entity_ids[id] = null
		return true
	return false
## When done with an entity id, you can reclaim it so that it can be used for future entities. [br]
## This function is used in cases where an entity is removed from the game and its entity id can be reused for future entities.
func reclaim_entity_id(id: int) -> void:
	entity_ids.erase(id)
	available_entity_ids.push_back(id)

func _ready() -> void:
	LowLevelNetworkHandler.on_client_packet.connect(on_client_packet)
	LowLevelNetworkHandler.on_server_packet.connect(on_server_packet)

## Handler for server information packets
func on_server_packet(peer_id: int, data: PackedByteArray) -> void:
	# What packet type is being handled
	var packet_type: int = data.decode_u8(0)

	match packet_type:
		# when the a packet is sent for state management
		PacketInfo.PACKET_TYPE.ENTITY_STATE:
			# TODO: manage the state of client authority entities.
			pass
		
		PacketInfo.PACKET_TYPE.ENTITY_DAMAGED:
			server_handle_entity_damaged(Packet_EntityDamaged.create_from_data(data))

		# Enity related packets.
		PacketInfo.PACKET_TYPE.ENTITY_TRANSFORM:
			server_handle_entity_position.emit(peer_id, Packet_EntityTransform.create_from_data(data))

		# unknown packet was sent to server.
		_:
			push_error("Packet type with index ", data[0], " Unhandled!")

## Handler for client information packets.
func on_client_packet(data: PackedByteArray) -> void:
	# What type of packet is being handled
	var packet_type: int = data.decode_u8(0)

	match packet_type:
		# packets unrelated to entities
		PacketInfo.PACKET_TYPE.ID_ASSIGNMENT,PacketInfo.PACKET_TYPE.ID_UNASSIGNMENT:
			pass

		# when the packet is related to an entity's transform
		PacketInfo.PACKET_TYPE.ENTITY_TRANSFORM:
			# emit a signal to have client handle the new packet for the specific entity.
			client_handle_entity_position.emit(Packet_EntityTransform.create_from_data(data))
		
		PacketInfo.PACKET_TYPE.ENTITY_ID_ASSIGNMENT:
			handle_entity_id_assignment.emit(Packet_EntityIDAssignment.create_from_data(data))

		PacketInfo.PACKET_TYPE.ENTITY_ID_UNASSIGNMENT:
			handle_entity_id_unassignment.emit(Packet_EntityIDUnassignment.create_from_data(data))

		PacketInfo.PACKET_TYPE.ENTITY_STATE:
			# TODO: give the client a signal to manage the state of the different server managed statemachines.
			pass

		PacketInfo.PACKET_TYPE.ENTITY_STATS:
			recieve_Entity_stat_values.emit(Packet_EntityStats.create_from_data(data))

		PacketInfo.PACKET_TYPE.ENTITY_DAMAGED:
			client_handle_entity_damaged(Packet_EntityDamaged.create_from_data(data))

		# unknown packet was sent to client.
		_:
			push_error("Packet type with index ", data[0], " unhandled!")

func client_handle_entity_damaged(entity_damaged: Packet_EntityDamaged) -> void:
	if LowLevelNetworkHandler.is_server: return
	# if the client is the attacker or defender, then they have already applied the damage locally and can ignore this packet.
	if entity_damaged.defender_id == ClientNetworkGlobals.id or entity_damaged.attack_id == ClientNetworkGlobals.id: return
	var defenderEntity = entity_ids.get(entity_damaged.defender_id)
	var attackEntity = entity_ids.get(entity_damaged.attack_id)
	PA_Debug.log("client_id (%s): entity_id (%s) attacked entity_id (%s) for %s damage" % [ClientNetworkGlobals.id, attackEntity._manager.assigned_id, defenderEntity._manager.assigned_id, Stats.calculate_damage(entity_damaged.damage, attackEntity.statManager.stats, defenderEntity.statManager.stats)])
	defenderEntity.statManager.stats.apply_incoming_damage(entity_damaged.damage, attackEntity.statManager.stats)

func server_handle_entity_damaged(entity_damaged: Packet_EntityDamaged) -> void:
	if !LowLevelNetworkHandler.is_server: return
	var defenderEntity : Entity = entity_ids.get(entity_damaged.defender_id)
	var attackEntity : Entity = entity_ids.get(entity_damaged.attack_id)
	PA_Debug.log("server: entity_id (%s) attacked entity_id (%s) for %s damage" % [attackEntity._manager.assigned_id, defenderEntity._manager.assigned_id, Stats.calculate_damage(entity_damaged.damage, attackEntity.statManager.stats, defenderEntity.statManager.stats)])
	defenderEntity.statManager.stats.apply_incoming_damage(entity_damaged.damage, attackEntity.statManager.stats)
	Packet_EntityDamaged.create(entity_damaged.damage, attackEntity._manager.assigned_id, defenderEntity._manager.assigned_id).broadcast(LowLevelNetworkHandler.connection)
