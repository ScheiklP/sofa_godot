tool
extends Node
##
## @author: Christoph Haas
##
## @desc: Encapsulate sofa_env [code]add_plugins[/code]
## Adds a set of plugins to the scene graph.
## The list of plugins is filtered to remove duplicates.
## A Plugins node is added to the root_node.
##
#class_name SofaEnvPluginNode

func get_class() -> String:
	return "SofaEnvPluginNode"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) || (clazz == get_class())

func _get_property_list() -> Array:
	return _registry.gen_property_list()
func _set(property: String, value) -> bool:
	return _registry.handle_set(property, value)
func _get(property: String):
	return _registry.handle_get(property)

const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")
	
const sofa_env = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/sofa_env_modules.gd")
const PyProgram = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_program.gd")
const PyCallableStatement = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_callable_statement.gd")

var _statement: PyCallableStatement
var _registry = PropertyWrapperRegistry.new(self)

func _init():
	set_name(AddPlugins.FUNCTION_NAME)
	_statement = PyCallableStatement.new(AddPlugins.new(self, _registry))

func _enter_tree():
	assert(get_parent().is_class("SofaPythonRoot"), "plugin node may only be added as direct child of SofaEnvRoot")

func process_python(program: PyProgram, parent_identifier: String, indent_depth: int):
	assert(parent_identifier == program.get_sofa_root_identifier(), "Expected root node as parent of")
	_statement.get_argument("root_node").set_value(parent_identifier)
	_statement.write_to_program(program, indent_depth)


class AddPlugins:
	extends "res://addons/sofa_godot_plugin/sofa_python/python/py_callable.gd"

	const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")
	const sofa_env = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/sofa_env_modules.gd")
	const PyArgumentContainer = preload("res://addons/sofa_godot_plugin/sofa_python/python/arguments/py_argument_container.gd").PyArgumentContainer

	const MODULE = sofa_env.sofa_templates.scene_header
	const FUNCTION_NAME = "add_plugins"

	var _node: Node
	var _registry: PropertyWrapperRegistry

	func _init(node: Node, registry: PropertyWrapperRegistry, partial: bool = false).(FUNCTION_NAME, partial):
		_node     = node
		_registry = registry
		_setup_callable()

	func _setup_callable():
		add_import(MODULE, FUNCTION_NAME)
		var args = PyArgumentContainer.new(self).with_registry(_registry)
		## The scene's root node.
		args.add_plain("root_node").required(true).position(0).as_identifier()
		## Plugin names to load.
		# note that PLUGINS refers to the variable defined in [PyProgram]
		args.add_plain("plugin_list", "PLUGINS").required(true).position(1).as_identifier()

