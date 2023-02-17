extends "res://addons/sofa_godot_plugin/property_wrappers/property_wrapper.gd"
##
## @author: Christoph Haas
##
## @desc:
##	Wrapper for [code]bool[/code] property
##

#class_name BoolPropertyWrapper
func get_class() -> String:
	return "BoolPropertyWrapper"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) || (clazz == get_class())

var _bool_val: bool


func _init(inspector_path: String, value: bool).(inspector_path):
	_bool_val = value


func _set_value(value: bool) -> bool:
	_bool_val = value
	return true

func get_value():
	return _bool_val


func set_inspector_property(path: String, value: bool) -> bool:
	return set_value(value) if path == get_inspector_path() else false


func get_inspector_entry() -> Dictionary:
	return {
		"name":  get_inspector_path(),
		"usage": _get_default_usage(),
		"type":  TYPE_BOOL,
		"hint":  PROPERTY_HINT_NONE,
	}
