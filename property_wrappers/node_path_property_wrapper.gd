extends "res://addons/sofa_godot_plugin/property_wrappers/property_wrapper.gd"
##
## @author: Christoph Haas
##
## @desc:
##	Wrapper for [NodePath] property
##

#class_name NodePathPropertyWrapper
func get_class() -> String:
	return "NodePathPropertyWrapper"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) || (clazz == get_class())

var _node_path: NodePath


func _init(inspector_path: String, value: NodePath).(inspector_path):
	_node_path = value


func _set_value(value: NodePath) -> bool:
	_node_path = value
	return true

func get_value() -> NodePath:
	return _node_path


func set_inspector_property(path: String, value: NodePath) -> bool:
  return set_value(value) if path == get_inspector_path() else false


func get_inspector_entry() -> Dictionary:
	return {
		"name":  get_inspector_path(),
		"usage": _get_default_usage(),
		"type":  TYPE_NODE_PATH,
		"hint":  PROPERTY_HINT_NONE,
	}
