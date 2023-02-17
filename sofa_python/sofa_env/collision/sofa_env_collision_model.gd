tool
extends Spatial
##
## @author: Christoph Haas
##
## @desc: Encapsulate sofa_env [code]add_collision_model[/code].
## Adds a collision model to a node.
## Without collision models, objects do not interact on touch.
## For more details see https://www.sofa-framework.org/community/doc/components/collisions/collisionmodels/.
##
#class_name SofaEnvCollisionModel

func get_class() -> String:
	return "SofaEnvCollisionModel"
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
const PyStatementProperties = preload("res://addons/sofa_godot_plugin/sofa_python/properties/py_statement_properties.gd")
const PyCallableStatement = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_callable_statement.gd")

const AddCollisionModel = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/collision/add_collision_model.gd")

var _statement: PyCallableStatement
var _registry = PropertyWrapperRegistry.new(self)
var _py_props = PyStatementProperties.new(self, _registry)

func _init():
	set_name(AddCollisionModel.FUNCTION_NAME)
	_statement = PyCallableStatement.new(AddCollisionModel.new(self, _registry))
	_statement.add_plugin_list(AddCollisionModel.MODULE, AddCollisionModel.MODULE.plugin_list)
	_py_props.register()

func get_python_identifier() -> String:
	return _py_props.get_identifier()

func process_python(program: PyProgram, parent_identifier: String, indent_depth: int):
	# update assignee and scene description key
	_py_props.update_statement(_statement)
	# update (unbound) plain arguments
	_statement.get_argument("attached_to").set_value(parent_identifier)
	_statement.write_to_program(program, indent_depth)
