tool
extends Node
#extends "res://addons/sofa_godot_plugin/sofa_python/sofa_python_node_base.gd"
##
## @author: Christoph Haas
##
## @desc: [code] obj: Sofa.Core.Object = sofa_node.addObject(type, **kwargs)[/code]
##
#class_name SofaCoreObject

func get_class() -> String:
	return "SofaCoreObject"
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

const PyProgram   = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_program.gd")
const PyStatement = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_statement.gd")

const AccessSofaInstance = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_core/access_sofa_instance.gd")

enum SofaObjectInstance {
	EXPOSE_EXISTING_OBJECT,
	ADD_OBJECT,
}

const cat_sofa_object = "Sofa Object"

var _add_object: AddObject
var _registry = PropertyWrapperRegistry.new(self)
var _py_props = PyStatementProperties.new(self, _registry)

func _init():
	_registry.set_category_order(funcref(SofaObjectCategoryOrder, "get_category_order"))
	_registry.make_enum({
			"Expose existing object":  SofaObjectInstance.EXPOSE_EXISTING_OBJECT,
			"Add object":              SofaObjectInstance.ADD_OBJECT
		},
		"sofa_object_instance")\
		.select_option_by_value(SofaObjectInstance.ADD_OBJECT)\
		.category(cat_sofa_object)\
		.callback(self, "_on_select_instance_option")
	_add_object = AddObject.new(self, _registry)
	_py_props.register()
	_select_instance_option()

func _on_select_instance_option(source_path: String, old_selection: int, selected_option: int):
	_select_instance_option()

func _select_instance_option():
	match _registry.get_value("sofa_object_instance"):
		SofaObjectInstance.EXPOSE_EXISTING_OBJECT:
			_add_object.disable()
		SofaObjectInstance.ADD_OBJECT:
			_add_object.enable()

func process_python(program: PyProgram, parent_identifier: String, indent_depth: int):
	var statement: PyStatement
	match _registry.get_value("sofa_object_instance"):
		SofaObjectInstance.EXPOSE_EXISTING_OBJECT:
			statement = AccessSofaInstance.new(self)
			statement.set_ancestor(parent_identifier)
		SofaObjectInstance.ADD_OBJECT:
			_add_object.update(parent_identifier)
			statement = _add_object
	_py_props.update_statement(statement)
	#program.append_code("\n" + "\t".repeat(indent_depth) + "# " + get_name())
	statement.write_to_program(program, indent_depth)



class AddObject:
	extends "res://addons/sofa_godot_plugin/sofa_python/python/py_callable_statement.gd"

	const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")

	const FUNCTION_NAME = "addObject"
	const cat_add_sofa_object = "addObject"

	var _node: Node
	var _registry: PropertyWrapperRegistry

	func _init(node: Node, registry: PropertyWrapperRegistry).(PyCallable.new(FUNCTION_NAME)):
		_node     = node
		_registry = registry
		_setup()

	func _setup():
		_setup_properties()
		_setup_statement()

	func _setup_properties():
		_registry.make_bool(false, "use_node_name_as_object_name").category(cat_add_sofa_object)
		_registry.make_string("", "type").category(cat_add_sofa_object)
		_registry.make_dict({}, "kwargs").category(cat_add_sofa_object)

	func enable():
		_registry.enable_category(cat_add_sofa_object)
	func disable():
		_registry.disable_category(cat_add_sofa_object)

	func _setup_statement():
		#statement.add_import("Sofa.Core.Object")
		var args = arguments().with_registry(_registry)
		args.add_property("type").required(true).omit_name(true).position(0)
		_update_kwargs()

	func update(caller: String):
		assert(not get_argument("type").get_value().empty(), "Required argument 'type' is not set")
		_update_kwargs()
		set_caller(caller)

	func _update_kwargs():
		var kwargs: Dictionary = _registry.get_value("kwargs")
		var arg_container: PyArgumentContainer = arguments()
		# remove discarded arguments
		var old_args = arg_container.get_argument_names()
		for arg_name in old_args:
			# skip required arguments, i.e. type
			if arg_container.get_argument(arg_name).is_required():
				continue
			if not arg_name in kwargs.keys():
				arg_container.remove_argument(arg_name)
		# handle name
		if _registry.get_value("use_node_name_as_object_name"):
			if kwargs.has("name"):
				push_warning("Option 'use_node_name_as_object_name' is overwritten by specified kwarg 'name'")
			else:
				kwargs["name"] = _node.get_name()
		# create/update remaining arguments
		for arg_name in kwargs.keys():
			assert(typeof(arg_name) == TYPE_STRING and not arg_name.empty() and not arg_name == "type", "Invalid kwarg key")
			# force is_default to be false
			arg_container.set_argument(arg_name, kwargs[arg_name], _node, null)



class SofaObjectCategoryOrder:
	extends Reference

	const UNCATEGORIZED = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd").UNCATEGORIZED
	const cat_code_gen  = preload("res://addons/sofa_godot_plugin/sofa_python/properties/py_statement_properties.gd").cat_code_gen

	# ensure that PyStatementProperties category comes last
	static func get_category_order(categories: Array) -> Array:
		var sorted = []
		if UNCATEGORIZED in categories:
			sorted.append(UNCATEGORIZED)
		if cat_sofa_object in categories:
			sorted.append(cat_sofa_object)
		if AddObject.cat_add_sofa_object in categories:
			sorted.append(AddObject.cat_add_sofa_object)
		if cat_code_gen in categories:
			sorted.append(cat_code_gen)
		assert(sorted.size() == categories.size())
		return sorted
