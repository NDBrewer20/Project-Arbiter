class_name LowLevelEntitySpawner extends Node

enum SPAWNABLE {
	ENEMY_DEBUG,
}
const SPAWNABLE_NETWORK_ENTITIES: Dictionary[SPAWNABLE,PackedScene] = {
	SPAWNABLE.ENEMY_DEBUG : preload("uid://scl6pakak5ca"),
}

## Stores the reference to the node (id)(0) and it's spawn type (id)(1) by it's [assigned_id]
var _activeEntities: Dictionary[int,Array]

func _ready() -> void:
	# cleanup all entities that were spawned by the server on this client.
	LowLevelNetworkHandler.on_disconnected_from_server.connect(remove_entities)
	LowLevelNetworkHandler.on_server_disconnect.connect(remove_entities)
	LowLevelNetworkHandler.on_peer_connected.connect(_on_peer_connected)
	EntityNetworkGlobals.handle_entity_id_assignment.connect(client_spawn_entity)
	EntityNetworkGlobals.handle_entity_id_unassignment.connect(remove_entity)

## removes a entity from the game.
func remove_entity(entity_id_unassignment: EntityIDUnassignment) -> void:
	# fetch entity from connected entity
	var id := entity_id_unassignment.id
	var entity: Entity = _activeEntities.get(id)[0]
	if entity:
		PA_Debug.log("client_id (%s): removing entity (%s):(%s)" % [ClientNetworkGlobals.id,id,entity])
		# remove from connected entities and free entity.
		_activeEntities.erase(id)
		EntityNetworkGlobals.reclaim_entity_id(id)
		entity.queue_free()

## removes an entity on the server and broadcasts its removal to clients.
func server_remove_entity(id: int):
	if !LowLevelNetworkHandler.is_server: return

	var entity: Entity = _activeEntities.get(id)[0]
	if entity:
		PA_Debug.log("server: removing entity (%s):(%s)" % [id,entity])
		# remove from connected entities and free entity.
		_activeEntities.erase(id)
		EntityNetworkGlobals.reclaim_entity_id(id)
		entity.queue_free()

		EntityIDUnassignment.create(id).broadcast(LowLevelNetworkHandler.connection)

## removes all entities spawned by this spawner.
func remove_entities(_peer_id: int = -1) -> void:
	for entity_id in _activeEntities:
		EntityNetworkGlobals.reclaim_entity_id(entity_id)
		var entity: Entity = _activeEntities[entity_id][0]
		PA_Debug.log("client_id (%s): removing entity (%s):(%s)" % [ClientNetworkGlobals.id,entity_id,entity])
		entity.queue_free()
	_activeEntities.clear()

## when a client joins send them all the active entities
func _on_peer_connected(peer_id: int) -> void:
	if !LowLevelNetworkHandler.is_server: return
	PA_Debug.log("server: telling client_id (%s) to spawn entities" % [peer_id])
	for entity_id in _activeEntities:
		var entity :Entity = _activeEntities[entity_id][0]
		var spawn :SPAWNABLE= _activeEntities[entity_id][1]
		EntityIDAssignment.create(entity_id, spawn, entity.global_position).send(LowLevelNetworkHandler.client_peers[peer_id])

## spawn a client entity and add to list of connected entities.
func client_spawn_entity(entity_id_assignment: EntityIDAssignment) -> void:
	if LowLevelNetworkHandler.is_server: return # server should not spawn another entity since it handles the original copy.
	var id  = entity_id_assignment.id
	var claimed := EntityNetworkGlobals.claim_entity_id(id)
	if !claimed: return # if you can't claim this entity id then don't spawn it.

	var entity: Entity = SPAWNABLE_NETWORK_ENTITIES[entity_id_assignment.spawn].instantiate()

	entity._manager.assigned_id = id
	entity.name = "Entity " + str(id) # Optional
	add_child(entity)
	entity.global_position = entity_id_assignment.position

	_activeEntities[id] = [entity, entity_id_assignment.spawn]
	PA_Debug.log("client_id (%s): spawned entity (%s)-(%s) at (%s)" % [ClientNetworkGlobals.id, id, entity_id_assignment.spawn, entity.global_position])

func server_spawn_entity(spawn: SPAWNABLE = SPAWNABLE.ENEMY_DEBUG, position: Vector3 = Vector3.ZERO) -> void:
	if !LowLevelNetworkHandler.is_server: return # if not the server then exit.

	var entity: Entity = SPAWNABLE_NETWORK_ENTITIES[spawn].instantiate()
	var id = EntityNetworkGlobals.provision_entity_id()

	entity._manager.assigned_id = id
	entity.name = "Entity " + str(id) # Optional
	get_tree().get_first_node_in_group("entity spawner").add_child(entity)
	entity.global_position = position

	_activeEntities[id] = [entity, spawn]
	PA_Debug.log("server: adding entity (%s)-(%s):(%s)" % [id,spawn,entity])

	# send entity spawned packet
	EntityIDAssignment.create(id, spawn, entity.global_position).broadcast(LowLevelNetworkHandler.connection)
