extends "res://addons/sofa_godot_plugin/property_wrappers/property_wrapper.gd"
##
## @author: Christoph Haas
##
## @desc:
##	Wrapper for [String] property
##

#class_name StringPropertyWrapper
func get_class() -> String:
	return "StringPropertyWrapper"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) || (clazz == get_class())

const _VALID_HINTS = [
	PROPERTY_HINT_NONE,
	PROPERTY_HINT_FILE,
	PROPERTY_HINT_DIR,
	PROPERTY_HINT_GLOBAL_FILE,
	PROPERTY_HINT_GLOBAL_DIR,
	PROPERTY_HINT_MULTILINE_TEXT,
	PROPERTY_HINT_PLACEHOLDER_TEXT,
]

var _str_val: String
var _property_hint: int
var _property_hint_string: String


func _init(inspector_path: String, value: String, property_hint: int = PROPERTY_HINT_NONE, property_hint_string = "").(inspector_path):
	_str_val = value

	assert(property_hint in _VALID_HINTS, "invalid string property hint")
	_property_hint = property_hint

	_property_hint_string = property_hint_string


func hint(property_hint: int):
	assert(property_hint in _VALID_HINTS, "invalid string property hint")
	_property_hint = property_hint
	return self

func hint_string(hint_string: String):
	_property_hint_string = hint_string
	return self

func _set_value(value: String) -> bool:
	_str_val = value
	return true


func get_value() -> String:
	return _str_val


func set_inspector_property(path: String, value: String) -> bool:
	return set_value(value) if path == get_inspector_path() else false


func get_inspector_entry() -> Dictionary:
	return {
		"name":  get_inspector_path(),
		"usage": _get_default_usage(),
		"type":  TYPE_STRING,
		"hint":  _property_hint,
		"hint_string" : _property_hint_string,
	}
