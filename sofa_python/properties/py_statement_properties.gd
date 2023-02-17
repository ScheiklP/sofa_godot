##
## @author: Christoph Haas
##
## @desc: Adds [EditorInspector] properties controlling the assignment of python statements.
## The result of a python statement may be assigned to an identifier.
## In addition the assignment statement might be added to the "scene description dictionary".
## 
extends Reference

const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")
const StringPropertyWrapper = preload("res://addons/sofa_godot_plugin/property_wrappers/string_property_wrapper.gd")
const EnumPropertyWrapper = preload("res://addons/sofa_godot_plugin/property_wrappers/enum_property_wrapper.gd")

const PyContext   = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_python_context.gd")
const PyStatement = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_statement.gd")

const cat_code_gen = "Code Generation"

enum AssignmentOption {
	DISABLED,
	NODE,
	CUSTOM,
}

var _node: Node
var _registry: PropertyWrapperRegistry
var _enabled: bool = true

## whether to assign the result of the python statement to an identifier
var _assignee_options: EnumPropertyWrapper
## the identifer of the resulting instance
var _assignee_identifier: StringPropertyWrapper
## whether to add the result of the python statement to the program's scene description dict
var _key_options: EnumPropertyWrapper
## the key to assign the resulting instance to
var _scene_description_key: StringPropertyWrapper

func _init(node: Node, registry: PropertyWrapperRegistry):
	_node = node
	_registry = registry

func register(default_assignment_option: int = AssignmentOption.DISABLED):
	_setup_properties(default_assignment_option)
	return self

func _setup_properties(default_assignment_option: int):
	assert(default_assignment_option in AssignmentOption.values(), "Unknown option")
	# assign resulting instance to identifier
	_assignee_options = _registry.make_enum({
			"Disabled":                    AssignmentOption.DISABLED,
			"Use node name as identifier": AssignmentOption.NODE,
			"Custom identifier":           AssignmentOption.CUSTOM,
		},
		"assignment/identifier")\
		.select_option_by_value(default_assignment_option)\
		.category(cat_code_gen)\
		.callback(self, "_on_toogle_assignment_properties")
	_assignee_identifier = _registry.make_string(_node.get_name(), "assignment/custom_identifier")\
		.category(cat_code_gen)
	# add resulting instance to scene description dictionary
	_key_options = _registry.make_enum({
			"Disabled":             AssignmentOption.DISABLED,
			"Use node name as key": AssignmentOption.NODE,
			"Custom key":           AssignmentOption.CUSTOM,
		},
		"scene_description/key")\
		.select_option_by_value(default_assignment_option)\
		.category(cat_code_gen)\
		.callback(self, "_on_toogle_assignment_properties")
	_scene_description_key = _registry.make_string(_node.get_name(), "scene_description/custom_key")\
		.category(cat_code_gen)
	_toggle_assignment_properties()

func _on_toogle_assignment_properties(source_path: String, old_value, new_value):
	_toggle_assignment_properties()

func _toggle_assignment_properties():
	match _assignee_options.get_value():
		AssignmentOption.DISABLED, AssignmentOption.NODE:
			_registry.disable_path("assignment/custom_identifier")
		AssignmentOption.CUSTOM:
			_registry.enable_path("assignment/custom_identifier")
			if _assignee_identifier.get_value().empty():
				_assignee_identifier.set_value(_node.get_name())
	match _key_options.get_value():
		AssignmentOption.DISABLED, AssignmentOption.NODE:
			_registry.disable_path("scene_description/custom_key")
		AssignmentOption.CUSTOM:
			_registry.enable_path("scene_description/custom_key")
			if _scene_description_key.get_value().empty():
				_scene_description_key.set_value(_node.get_name())

func select_assignee_option(option: int):
	assert(option in AssignmentOption.values(), "Unknown option")
	_assignee_options.select_option_by_value(option, true)

func select_scene_description_key_option(option: int):
	assert(option in AssignmentOption.values(), "Unknown option")
	_key_options.select_option_by_value(option, true)


func disable():
	_enabled = false
	_registry.disable_category(cat_code_gen)

func enable():
	_enabled = true
	_registry.enable_category(cat_code_gen)

func is_enabled() -> bool:
	return _enabled


func has_assignee() -> bool:
	return _assignee_options.get_value() in [AssignmentOption.NODE, AssignmentOption.CUSTOM]

func get_assignee() -> String:
	match _assignee_options.get_value():
		AssignmentOption.DISABLED:
			return ""
		AssignmentOption.NODE:
			return _node.get_name()
		AssignmentOption.CUSTOM:
			return _assignee_identifier.get_value()
		_:
			assert(false, "Unknown assignment option")
			return ""

func has_scene_description_key() -> bool:
	return _key_options.get_value() in [AssignmentOption.NODE, AssignmentOption.CUSTOM]

func get_scene_description_key() -> String:
	match _key_options.get_value():
		AssignmentOption.DISABLED:
			return ""
		AssignmentOption.NODE:
			return _node.get_name()
		AssignmentOption.CUSTOM:
			return _scene_description_key.get_value()
		_:
			assert(false, "Unknown assignment option")
			return ""

func has_identifier() -> bool:
	return has_assignee() or has_scene_description_key()

func get_identifier() -> String:
	if has_assignee():
		return get_assignee()
	elif has_scene_description_key():
		return "{dict}[\"{key}\"]"\
			.format({dict=PyContext.get_sofa_scene_description_identifier(), key=get_scene_description_key()})
	else:
		return ""


func update_statement(statement: PyStatement):
	update_assignee(statement)
	update_scene_description_key(statement)

## assign the resulting instance to the specified identifier
func update_assignee(statement: PyStatement):
	if has_assignee():
		statement.set_assignee(get_assignee())
	else:
		statement.clear_assignee()

## add the resulting instance to the scene description dict
func update_scene_description_key(statement: PyStatement):
	if has_scene_description_key():
		statement.set_scene_description_key(get_scene_description_key())
	else:
		statement.clear_scene_description_key()

