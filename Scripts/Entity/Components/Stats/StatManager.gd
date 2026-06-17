class_name StatManager extends Node

## stats that define the characteristics of this entity.
@export var stats: Stats

func _ready() -> void:
	# set the owner of the stats equal to the owner of the stat manager.
	stats.owner = owner
	# enable the communication of the entity stat values for when a new player enters the server.
	LowLevelNetworkHandler.on_peer_connected.connect(stats._fetch_current_stat_values)
	EntityNetworkGlobals.client_recieve_entity_stat_values.connect(stats._set_current_stat_values)

## Communicate to the client the stat block values that need to be updated.
func _fetch_current_stat_values(peer_id: int):
	if !LowLevelNetworkHandler.is_server: return
	await owner.get_tree().physics_frame
	PA_Debug.log("server: telling client_id (%s) to update stat values of entity_id (%s)" % [peer_id,owner._manager.assigned_id])
	Packet_EntityStats.create(owner._manager.assigned_id, stats).send(LowLevelNetworkHandler.client_peers[peer_id])

## after recieving the stat value from the server update the local stat block.
func _set_current_stat_values(packet_stats: Packet_EntityStats):
	if owner._manager.assigned_id != packet_stats.id: return
	await owner.get_tree().physics_frame
	PA_Debug.log("client_id (%s): Updating entity_id (%s) stat values" % [ClientNetworkGlobals.id,packet_stats.id])
	stats.health = packet_stats.health
	stats.power = packet_stats.resource
	stats.recalculate_stats()