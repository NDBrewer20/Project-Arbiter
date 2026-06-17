extends RefCounted
class_name Hitlog

# the list of nodes hit by a hitbox.
var hit_log: Array = []

## check if the hitlog has a specific node in the list.
func has_hit(node: Node) -> bool:
	return hit_log.has(node)

## log a node as being hit by a hitbox.
func log_hit(node: Node) -> void:
	hit_log.append(node)