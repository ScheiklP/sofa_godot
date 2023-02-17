extends "res://addons/sofa_godot_plugin/sofa_python/python/py_callable_statement.gd"
## <assignee> = <node>.addObject(<type>, name=<name>, ...)

func get_class() -> String:
	return "SofaObjectBase"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) or (clazz == get_class())

const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")
const PyStatementProperties = preload("res://addons/sofa_godot_plugin/sofa_python/properties/py_statement_properties.gd")

const FUNCTION_NAME = "addObject"

var _node: Node
var _registry: PropertyWrapperRegistry
var _py_props: PyStatementProperties
var _type: String

func _init(type: String, node: Node, registry: PropertyWrapperRegistry).(PyCallable.new(FUNCTION_NAME)):
	_type = type
	_node = node
	_registry = registry
	_py_props = PyStatementProperties.new(_node, _registry)
	setup()

func setup():
	setup_properties()
	setup_statement()

func setup_properties():
	_setup_properties()
	_py_props.register()

func setup_statement():
	arguments().add_plain("type").position(0).omit_name(true).required(true).bind(self, "get_sofa_object_type")
	#arguments().add_plain("name").position(1).bind(_node, "get_name")
	_setup_statement()

func update(program: PyProgram, parent_identifier: String):
	_py_props.update_statement(self)
	set_caller(parent_identifier)
	_update(program, parent_identifier)

func process(program: PyProgram, parent_identifier: String, indent_depth: int, recurse: bool = false):
	update(program, parent_identifier)
	write_to_program(program, indent_depth)
	if recurse:
		process_children(program, indent_depth)

func process_children(program: PyProgram, indent_depth: int):
	for child in get_node().get_children():
		if child.has_method("process_python"):
			_process_child(child, program, indent_depth)

func _process_child(child: Node, program: PyProgram, indent_depth: int):
	var identifier = get_identifier(_node, program)
	child.process_python(program, identifier, indent_depth)

func set_sofa_object_type(type: String):
	_type = type

func get_sofa_object_type() -> String:
	return _type

func get_node():
	return _node

#func get_python_identifier() -> String:
#	return _py_props.get_identifier()

# @override
func _setup_properties():
	pass

# @override
func _setup_statement():
	pass

# @override
func _update(program: PyProgram, parent_identifier: String):
	pass
