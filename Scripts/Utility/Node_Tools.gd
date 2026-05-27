## This script contains utility functions for working with nodes in Godot.
class_name NodeTools

## Manages the processing and signal blocking of a node. [br]
## If enabled is [false], the node will stop processing and block signals. [br]
## If enabled is [true], the node will start processing and unblock signals. [br]
static func manageNode(node: Node, enabled: bool) -> void:
	node.set_process(enabled)
	node.set_physics_process(enabled)
	node.set_process_input(enabled)
	node.set_process_unhandled_input(enabled)
	node.set_process_unhandled_key_input(enabled)
	node.set_block_signals(!enabled)
