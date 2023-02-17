tool
extends Node

func get_class() -> String:
	return "AddSolverFunc"
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
const AddSolver = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/solver/add_solver.gd")

const ARGUMENT_NAME = "add_solver_func"

var _callable: AddSolver
var _registry = PropertyWrapperRegistry.new(self)

func _init():
	set_name(ARGUMENT_NAME)
	_callable = AddSolver.new(self, _registry, true)
	_callable.get_argument("attached_to").disable()

func get_callable() -> PyCallable:
	return _callable
