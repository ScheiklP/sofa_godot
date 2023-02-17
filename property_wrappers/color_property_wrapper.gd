extends "res://addons/sofa_godot_plugin/property_wrappers/property_wrapper.gd"
##
## @author: Christoph Haas
##
## @desc:
##	Encapsulate [Color]s
##

#class_name ColorPropertyWrapper
func get_class() -> String:
	return "ColorPropertyWrapper"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) || (clazz == get_class())

var _color: Color
var _no_alpha: bool

func _init(inspector_path: String, color: Color, no_alpha: bool = false).(inspector_path):
	_color = color
	_no_alpha = no_alpha

## [code]PROPERTY_HINT_COLOR_NO_ALPHA[/code]
func no_alpha(no_alpha: bool = true):
	_no_alpha = no_alpha
	return self

func _set_value(color: Color) -> bool:
	_color = color
	return true


func get_value() -> Color:
	return _color


func set_inspector_property(path: String, value: Color) -> bool:
	return set_value(value) if path == get_inspector_path() else false


func get_inspector_entry() -> Dictionary:
	return {
		"name":  get_inspector_path(),
		"usage": _get_default_usage(),
		"type":  TYPE_COLOR,
		"hint":  PROPERTY_HINT_COLOR_NO_ALPHA if _no_alpha else PROPERTY_HINT_NONE,
	}
