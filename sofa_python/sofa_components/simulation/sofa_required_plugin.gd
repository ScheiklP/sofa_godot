tool
extends Node
## @author: Christoph Haas
## @desc: SOFA RequiredPlugin
##
## https://github.com/sofa-framework/sofa/blob/master/Sofa/framework/Simulation/Core/src/sofa/simulation/RequiredPlugin.h
##

func get_class() -> String:
	return "SofaRequiredPlugin"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) or (clazz == get_class())

func _get_property_list() -> Array:
	return _registry.gen_property_list()
func _set(property: String, value) -> bool:
	return _registry.handle_set(property, value)
func _get(property: String):
	return _registry.handle_get(property)

const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")
const PyProgram = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_program.gd")

var _registry = PropertyWrapperRegistry.new(self)
var _plugin: RequiredPlugin

func _init():
	_plugin = RequiredPlugin.new(self, _registry)

func process_python(program: PyProgram, parent_identifier: String, indent_depth: int):
	_plugin.process(program, parent_identifier, indent_depth)



## <assignee> = <node>.addObject("RequiredPlugin", name=<name>, plugin_name=<plugin_name>)
class RequiredPlugin:
	extends "res://addons/sofa_godot_plugin/sofa_python/sofa_components/sofa_object_base.gd"

	const MODULE = "Sofa.Simulation"
	const TYPE = "RequiredPlugin"
	const cat_plugin = "SOFA RequiredPlugin"

	func _init(node: Node, registry: PropertyWrapperRegistry).(TYPE, node, registry):
		pass

	# @override
	func _setup_properties():
		_registry.make_string("", "pluginName").category(cat_plugin)

	# @override
	func _setup_statement():
		var args = arguments().with_registry(_registry)
		args.add_property("name", "pluginName").required(true)
		args.add_property("pluginName").required(true)

	# @override
	func _update(program: PyProgram, parent_identifier: String):
		assert(not get_argument("name").get_value().empty(), "name may not be empty")
		assert(not get_argument("pluginName").get_value().empty(), "plugin name may not be empty")

