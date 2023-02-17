tool
extends Node
##
## @author: Christoph Haas
##
## @desc: Either exposes an existing node instance via:
## [code]node = root_node["path.to.node"][/code]
## or calls [code]addChild[/code] on parent node yielding the following python code:
## [code]node: Sofa.Core.Node = sofa_node.addChild(name, **kwargs)[/code]
##
#class_name SofaCoreNode

func get_class() -> String:
	return "SofaCoreNode"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) or (clazz == get_class())

func _get_property_list() -> Array:
	return _registry.gen_property_list()
func _set(property: String, value) -> bool:
	return _registry.handle_set(property, value)
func _get(property: String):
	return _registry.handle_get(property)

const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")
const PyStatementProperties = preload("res://addons/sofa_godot_plugin/sofa_python/properties/py_statement_properties.gd")

const PyProgram = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_program.gd")
const PyStatement = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_statement.gd")
const PyCallableStatement = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_callable_statement.gd")

const AccessSofaInstance = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_core/access_sofa_instance.gd")

enum SofaNodeInstance {
	EXPOSE_EXISTING_NODE,
	ADD_CHILD,
}

const cat_sofa_node = "Sofa Node"
const default_name = "sofa_node"

var _registry = PropertyWrapperRegistry.new(self)
var _py_props = PyStatementProperties.new(self, _registry)

func _init():
	if get_parent() == null:
		set_name(default_name)
	else:
		set_name(get_parent().get_name() + "_" + default_name)
	_registry.make_enum({
			"Expose existing node": SofaNodeInstance.EXPOSE_EXISTING_NODE,
			"Add child node":       SofaNodeInstance.ADD_CHILD
		},
		"sofa_node_instance")\
		.select_option_by_value(SofaNodeInstance.ADD_CHILD)\
		.category(cat_sofa_node)
	_py_props.register(PyStatementProperties.AssignmentOption.NODE)


#func get_python_identifier() -> String:
#	return _py_props.get_identifier()

func process_python(program: PyProgram, parent_identifier: String, indent_depth: int):
	var statement: PyStatement
	match _registry.get_value("sofa_node_instance"):
		SofaNodeInstance.EXPOSE_EXISTING_NODE:
			statement = AccessSofaInstance.new(self)
			statement.set_ancestor(parent_identifier)
		SofaNodeInstance.ADD_CHILD:
			statement = PyCallableStatement.new(AddChild.new(self))
			statement.set_caller(parent_identifier)
		_:
			assert(false, "Unknown option")
	_py_props.update_statement(statement)
	# append python code
	#program.append_code("\n" + "\t".repeat(indent_depth) + "# " + get_name())
	statement.write_to_program(program, indent_depth)
	# traverse children
	_process_children(program, statement.get_identifier(self, program), indent_depth)

func _process_children(program: PyProgram, node_identifier: String, indent_depth: int):
	for child_node in get_children():
		if child_node.has_method("process_python"):
			child_node.process_python(program, node_identifier, indent_depth)



## <parent_node>.addChild(<name>)
class AddChild:
	extends "res://addons/sofa_godot_plugin/sofa_python/python/py_callable.gd"

	const PyArgumentContainer = preload("res://addons/sofa_godot_plugin/sofa_python/python/arguments/py_argument_container.gd").PyArgumentContainer
	
	const FUNCTION_NAME = "addChild"

	var _node: Node

	func _init(node: Node, partial: bool = false).(FUNCTION_NAME, partial):
		_node = node
		_setup_statement()

	func _setup_statement():
		#add_import("Sofa.Core.Node")
		PyArgumentContainer.new(self).add_plain("child").required(true).position(0).omit_name(true).bind(_node, "get_name")
