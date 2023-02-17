extends Reference
##
## @author: Christoph Haas
##
## @desc: Abstract class to bridge godot [Node]s and their respective properties with a [PyStatement].
##
#class_name PyStatementNode

const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")

const PyProgram   = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_program.gd")
const PyStatement = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_statement.gd")

var _node: Node
var _registry: PropertyWrapperRegistry
var _statement: PyStatement

func _init(node: Node, registry: PropertyWrapperRegistry, statement: PyStatement):
	_node      = node
	_registry  = registry
	_statement = statement 

func _setup():
	_setup_properties()
	_setup_statement()

# @override
func _setup_properties():
	pass

# @override
func _setup_statement():
	pass

# override
func _update_statement(program: PyProgram, parent_identifier: String):
	pass

func process(program: PyProgram, parent_identifier: String, indent_depth: int, recurse: bool = false):
	_update_statement(program, parent_identifier)
	get_statement().write_to_program(program, indent_depth)
	if recurse:
		process_children(program, indent_depth)

func process_children(program: PyProgram, indent_depth: int):
	for child in get_node().get_children():
		if child.has_method("process_python"):
			_process_child(child, program, indent_depth)

func _process_child(child: Node, program: PyProgram, indent_depth: int):
	var identifier = get_statement().get_identifier(get_node(), program)
	child.process_python(program, identifier, indent_depth)


func get_node():
	return _node

func get_registry() -> PropertyWrapperRegistry:
	return _registry

func get_statement():
	return _statement
