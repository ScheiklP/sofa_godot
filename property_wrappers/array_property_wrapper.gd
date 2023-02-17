extends "res://addons/sofa_godot_plugin/property_wrappers/property_wrapper.gd"
##
## @author: Christoph Haas
##
## @desc:
##	Encapsulate [Array]s
##

#class_name ArrayPropertyWrapper
func get_class() -> String:
	return "ArrayPropertyWrapper"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) || (clazz == get_class())

var _array: Array

func _init(inspector_path: String, array: Array).(inspector_path):
	#assert(array != null, "array is null")
	_array = array


func _set_value(array: Array) -> bool:
	_array = array
	return true


func get_value() -> Array:
	return _array


func set_inspector_property(path: String, value: Array) -> bool:
	return set_value(value) if path == get_inspector_path() else false


func get_inspector_entry() -> Dictionary:
	return {
		"name":  get_inspector_path(),
		"usage": _get_default_usage(),
		"type":  TYPE_ARRAY,
	}
