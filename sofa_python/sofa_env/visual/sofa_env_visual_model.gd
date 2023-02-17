tool
extends Spatial
##
## @author: Christoph Haas
##
## @desc: Encapsulate sofa_env [code]add_visual_model[/code].
## Adds a visual model to a node.
## Do not use with SofaCarving plugin.
##
#class_name SofaEnvVisualModel

func get_class() -> String:
	return "SofaEnvVisualModel"
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

const AddVisualModel = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/visual/add_visual_model.gd")

var _statement: PyCallableStatement
var _registry = PropertyWrapperRegistry.new(self)
var _py_props = PyStatementProperties.new(self, _registry)

func _init():
	set_name(AddVisualModel.FUNCTION_NAME)
	_statement = PyCallableStatement.new(AddVisualModel.new(self, _registry))
	_statement.add_plugin_list(AddVisualModel.MODULE, AddVisualModel.MODULE.plugin_list)
	_py_props.register()

func get_python_identifier() -> String:
	return _py_props.get_identifier()

func process_python(program: PyProgram, parent_identifier: String, indent_depth: int):
	# update assignee and scene description key
	_py_props.update_statement(_statement)
	# update (unbound) plain arguments
	_statement.get_argument("attached_to").set_value(parent_identifier)
	_statement.write_to_program(program, indent_depth)
