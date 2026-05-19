class_name PlayerManager extends Node3D

var is_authority: bool:
	get:
		return owner_id == ClientNetworkGlobals.id
var owner_id: int