extends Node

@export var LOW_LEVEL_NETWORK_ENTITY: PackedScene

var _connectedEntities: Dictionary[int,Entity]

func _ready() -> void:
	# cleanup all entities that were spawned by the server on this client.
	LowLevelNetworkHandler.on_disconnected_from_server.connect(remove_entities)
	LowLevelNetworkHandler.on_server_disconnect.connect(remove_entities)
	LowLevelNetworkHandler.on_peer_connected.connect(_on_peer_connected)
	EntityNetworkGlobals.handle_entity_id_assignment.connect(client_spawn_entity)
	EntityNetworkGlobals.handle_entity_id_unassignment.connect(remove_entity)

## removes a entity from the game.
func remove_entity(id: int) -> void:
	# fetch entity from connected entity
	var entity: Entity = _connectedEntities.get(id)
	if entity:
		PA_Debug.log("client_id (%s): removing entity (%s):(%s)" % [ClientNetworkGlobals.id,id,entity])
		# remove from connected entities and free entity.
		_connectedEntities.erase(id)
		EntityNetworkGlobals.reclaim_entity_id(id)
		entity.queue_free()

## removes all entities spawned by this spawner.
func remove_entities(_peer_id: int = -1) -> void:
	for entity_id in _connectedEntities:
		EntityNetworkGlobals.reclaim_entity_id(entity_id)
		var entity := _connectedEntities[entity_id]
		PA_Debug.log("client_id (%s): removing entity (%s):(%s)" % [ClientNetworkGlobals.id,entity_id,entity])
		entity.queue_free()
	_connectedEntities.clear()

## when a client joins send them all the active entities
func _on_peer_connected(peer_id: int) -> void:
	if !LowLevelNetworkHandler.is_server: return
	PA_Debug.log("server: telling client_id (%s) to spawn entities" % [peer_id])
	for entity_id in _connectedEntities:
		var entity := _connectedEntities[entity_id]
		EntityIDAssignment.create(entity_id,entity.global_position).send(LowLevelNetworkHandler.client_peers[peer_id])

## spawn a client entity and add to list of connected entities.
func client_spawn_entity(entity_id_assignment: EntityIDAssignment) -> void:
	if LowLevelNetworkHandler.is_server: return # server should not spawn another entity since it handles the original copy.
	var id  = entity_id_assignment.id
	var claimed := EntityNetworkGlobals.claim_entity_id(id)
	if !claimed: return # if you can't claim this entity id then don't spawn it.

	var entity: Entity = LOW_LEVEL_NETWORK_ENTITY.instantiate()

	entity._manager.assigned_id = id
	entity.name = "Entity " + str(id) # Optional
	add_child(entity)
	entity.global_position = entity_id_assignment.position

	_connectedEntities[id] = entity
	PA_Debug.log("client_id (%s): spawned entity (%s) at (%s)" % [ClientNetworkGlobals.id,id,entity.global_position])

func server_spawn_entity(position: Vector3 = Vector3.ZERO) -> void:
	if !LowLevelNetworkHandler.is_server: return # if not the server then exit.

	var entity: Entity = LOW_LEVEL_NETWORK_ENTITY.instantiate()
	var id = EntityNetworkGlobals.provision_entity_id()

	entity._manager.assigned_id = id
	entity.name = "Entity " + str(id) # Optional
	get_tree().get_first_node_in_group("entity spawner").add_child(entity)
	entity.global_position = position

	_connectedEntities[id] = entity
	PA_Debug.log("server: adding entity (%s):(%s)" % [id,entity])

	# send entity spawned packet
	EntityIDAssignment.create(id, entity.global_position).broadcast(LowLevelNetworkHandler.connection)
