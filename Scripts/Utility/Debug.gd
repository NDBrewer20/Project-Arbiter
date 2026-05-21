class_name PA_Debug extends Node

static var debug: bool = true

## Utility function for logging debug messages. Only prints if debug mode is enabled.
static func log(message: String) -> void:
	if debug:
		print(message)

## Utility function for logging warning messages. Only prints if debug mode is enabled.
static func log_warning(message: String) -> void:
	if debug:
		push_warning(message)

## Utility function for logging error messages. Only prints if debug mode is enabled.
static func log_error(message: String) -> void:
	if debug:
		push_error(message)
