extends "res://addons/sofa_godot_plugin/property_wrappers/property_wrapper.gd"
##
## @author: Christoph Haas
##
## @desc:
##	Encapsulate [Dictionary]s
##

#class_name DictionaryPropertyWrapper
func get_class() -> String:
	return "DictionaryPropertyWrapper"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) || (clazz == get_class())

var _dict: Dictionary

func _init(inspector_path: String, dict: Dictionary).(inspector_path):
	#assert(dict != null, "dict is null")
	_dict = dict


func _set_value(dict: Dictionary) -> bool:
	_dict = dict
	return true


func get_value() -> Dictionary:
	return _dict


func set_inspector_property(path: String, value: Dictionary) -> bool:
	return set_value(value) if path == get_inspector_path() else false


func get_inspector_entry() -> Dictionary:
	return {
		"name":  get_inspector_path(),
		"usage": _get_default_usage(),
		"type":  TYPE_DICTIONARY,
	}
