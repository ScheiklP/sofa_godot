extends "res://addons/sofa_godot_plugin/property_wrappers/property_wrapper.gd"
##
## @author: Christoph Haas
##
## @desc:
##	Encapsulate [Mesh]s via [code]PROPERTY_HINT_RESOURCE_TYPE[/code]
##

#class_name MeshPropertyWrapper
func get_class() -> String:
	return "MeshPropertyWrapper"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) || (clazz == get_class())

var _mesh: Mesh

func _init(inspector_path: String, mesh: Mesh).(inspector_path):
	#assert(mesh != null, "resource is null")
	_mesh = mesh


func _set_value(mesh: Mesh) -> bool:
	_mesh = mesh
	return true


func get_value() -> Mesh:
	return _mesh


func set_inspector_property(path: String, value: Mesh) -> bool:
	return set_value(value) if path == get_inspector_path() else false


func get_inspector_entry() -> Dictionary:
	return {
		"name":  get_inspector_path(),
		"usage": _get_default_usage(),
		"type":  TYPE_OBJECT,
		"hint":  PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "Mesh",
	}
