class_name LowLevelEntitySpawner extends Node

enum SPAWNABLE {
	ENEMY_DEBUG,
}
const SPAWNABLE_NETWORK_ENTITIES: Dictionary[SPAWNABLE,PackedScene] = {
	SPAWNABLE.ENEMY_DEBUG : preload("uid://scl6pakak5ca"),
}

## Stores the reference to the node (id)(0) and it's spawn type (id)(1) by it's [assigned_id]
var _activeEntities: Dictionary[int,Array]

static var instance: LowLevelEntitySpawner

@export var spawnParent: Node3D

func _ready() -> void:
	if instance:
		queue_free()
		return
	instance = self
	# cleanup entities when disconnecting from server or when the server disconnects.
	LowLevelNetworkHandler.on_disconnected_from_server.connect(remove_entities)
	LowLevelNetworkHandler.on_server_disconnect.connect(remove_entities)
	EntityNetworkGlobals.handle_entity_id_unassignment.connect(remove_entity)
	# when a new peer connects to the server send them all the active entities so they can spawn them on their end.
	LowLevelNetworkHandler.on_peer_connected.connect(_on_peer_connected)
	# when the server assigns an entity id to spawn an entity on the client.
	EntityNetworkGlobals.handle_entity_id_assignment.connect(client_spawn_entity)

## removes a entity from the game.
func remove_entity(entity_id_unassignment: Packet_EntityIDUnassignment) -> void:
	# fetch entity from connected entity
	var id := entity_id_unassignment.id
	var entityDetails = _activeEntities.get(id)
	if entityDetails:
		var entity : Entity = entityDetails[0]
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

		Packet_EntityIDUnassignment.create(id).broadcast(LowLevelNetworkHandler.connection)

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
	var spawn_thread := Thread.new()
	var error := spawn_thread.start(_communicate_entity_spawns.bind(peer_id,convert_dictionary_to_threadsafe(_activeEntities)))
	if error != OK:
		PA_Debug.log_error("Failed to communicate entity spawns to new peer")

func _communicate_entity_spawns(peer_id: int, activeEntitiesSnapshot: Dictionary[int,Array]):
	for entity_id in activeEntitiesSnapshot:
		var entityposition :Vector3 = activeEntitiesSnapshot[entity_id][0]
		var spawn :SPAWNABLE= activeEntitiesSnapshot[entity_id][1]
		Packet_EntityIDAssignment.create(entity_id, spawn, entityposition).send(LowLevelNetworkHandler.client_peers[peer_id])

func convert_dictionary_to_threadsafe(old_dict: Dictionary[int, Array]) -> Dictionary[int, Array]:
	var new_dict: Dictionary[int, Array] = {}
	for key: int in old_dict.keys():
		var body: Entity = old_dict[key][0]
		var spawnable_data: SPAWNABLE = old_dict[key][1]
		new_dict[key] = [body.global_position, spawnable_data]
	return new_dict

## spawn a client entity and add to list of connected entities.
func client_spawn_entity(entity_id_assignment: Packet_EntityIDAssignment) -> void:
	if LowLevelNetworkHandler.is_server: return # server should not spawn another entity since it handles the original copy.
	var id  = entity_id_assignment.id

	var entity: Entity = SPAWNABLE_NETWORK_ENTITIES[entity_id_assignment.spawn].instantiate()
	var claimed := EntityNetworkGlobals.claim_entity_id(id,entity)
	if !claimed:
		entity.queue_free()
		EntityNetworkGlobals.reclaim_entity_id(id)
		PA_Debug.log("client_id (%s): failed to claim entity id (%s) for entity (%s)" % [ClientNetworkGlobals.id, id, entity])
		return
	
	entity._manager.assigned_id = id
	entity.name = "Entity " + str(id) # Optional
	spawnParent.add_child(entity)
	entity.global_position = entity_id_assignment.position

	_activeEntities[id] = [entity, entity_id_assignment.spawn]
	PA_Debug.log("client_id (%s): spawned entity (%s)-(%s) at (%s)" % [ClientNetworkGlobals.id, id, entity_id_assignment.spawn, entity.global_position])

static func server_spawn_entity(spawn: SPAWNABLE = SPAWNABLE.ENEMY_DEBUG, position: Vector3 = Vector3.ZERO) -> void:
	if !LowLevelNetworkHandler.is_server: return # if not the server then exit.

	var entity: Entity = SPAWNABLE_NETWORK_ENTITIES[spawn].instantiate()
	var id = EntityNetworkGlobals.provision_entity_id(entity)

	entity._manager.assigned_id = id
	entity.name = "Entity " + str(id) # Optional
	instance.spawnParent.add_child(entity)
	entity.global_position = position

	instance._activeEntities[id] = [entity, spawn]
	PA_Debug.log("server: adding entity (%s)-(%s):(%s)" % [id,spawn,entity])

	# send entity spawned packet
	Packet_EntityIDAssignment.create(id, spawn, entity.global_position).broadcast(LowLevelNetworkHandler.connection)
