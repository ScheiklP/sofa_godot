tool
extends Node
##
## @author: Christoph Haas
##
## @desc: Encapsulate sofa_env [code]add_solver[/code].
## Adds a time integration scheme and a linear solver to a node.
##
#class_name SofaEnvSolver

func get_class() -> String:
	return "SofaEnvSolver"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) || (clazz == get_class())

func _set(property: String, value) -> bool:
	return _registry.handle_set(property, value)
func _get(property: String):
	return _registry.handle_get(property)
func _get_property_list() -> Array:
	return _registry.gen_property_list()

const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")

const PyProgram = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_program.gd")
const PyCallableStatement = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_callable_statement.gd")
const PyStatementProperties = preload("res://addons/sofa_godot_plugin/sofa_python/properties/py_statement_properties.gd")

const AddSolver = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/solver/add_solver.gd")

var _statement: PyCallableStatement
var _registry = PropertyWrapperRegistry.new(self)
var _py_props = PyStatementProperties.new(self, _registry)

func _init():
	set_name(AddSolver.FUNCTION_NAME)
	_statement = PyCallableStatement.new(AddSolver.new(self, _registry))
	_statement.add_plugin_list(AddSolver.MODULE, AddSolver.MODULE.plugin_list)
	_py_props.register()

func get_python_identifier() -> String:
	return _py_props.get_identifier()

func process_python(program: PyProgram, parent_identifier: String, indent_depth: int):
	_py_props.update_statement(_statement)
	_statement.get_argument("attached_to").set_value(parent_identifier)
	_statement.write_to_program(program, indent_depth)
