tool
extends Spatial

func get_class() -> String:
	return "AddVisualModelFunc"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) || (clazz == get_class())

func _set(property: String, value) -> bool:
	return _registry.handle_set(property, value)
func _get(property: String):
	return _registry.handle_get(property)
func _get_property_list() -> Array:
	return _registry.gen_property_list()

const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")
const PyCallable = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_callable.gd")
const AddVisualModel = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/visual/add_visual_model.gd")

const ARGUMENT_NAME = "add_visual_model_func"

var _callable: AddVisualModel
var _registry = PropertyWrapperRegistry.new(self)

func _init():
	set_name(ARGUMENT_NAME)
	_callable = AddVisualModel.new(self, _registry, true)
	#TODO: supply list specifying which arguments to disable
	_callable.get_argument("attached_to").disable()
	_callable.get_argument("name").disable()
	_callable.get_argument("surface_mesh_file_path").disable()

func get_callable() -> PyCallable:
	return _callable

func get_mesh_file_path() -> String:
	#return _registry.get_value("surface_mesh_file_path")
	return _callable.get_argument("surface_mesh_file_path").get_value()

func set_mesh_file_path(path: String):
	#_registry._get_property_wrapper("surface_mesh_file_path").set_value(path)
	_callable.get_argument("surface_mesh_file_path").set_value(path)
