extends Node

# handles logic to toggle remove mode
class_name ObjectRemoverSystem

signal remove_mode_toggled
signal remove_mode_disabled
signal remove_mode_enabled

var delete_selected = false

onready var controller_system := get_node(global_vars.CONTROLLER_SYSTEM_PATH)


func toggle_remove_mode():
	emit_signal("remove_mode_toggled")


func disable_remove_mode():
	emit_signal("remove_mode_disabled")
	delete_selected = false


func enable_remove_mode():
	emit_signal("remove_mode_enabled")
	delete_selected = true
