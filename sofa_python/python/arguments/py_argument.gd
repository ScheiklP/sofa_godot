extends Reference
##
## @author: Christoph Haas
##
## @desc: Models a python argument
##
class_name PyArgument

const PyContext = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_python_context.gd")

func get_class() -> String:
	return "PyArgument"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) or (clazz == get_class())

# policy for initializing the argument's default value
enum DefaultValuePolicy {
	VALUE,
	NONE,
	NULL,
}

# consider argument type for string conversion
enum ArgumentType {
	VALUE,
	IDENTIFIER,
}

const NONE = PyContext.PY_NONE
const POSITION_NONE: int = -1

## argument name
var _name: String
## whether the argument represents a value or an identifier
var _arg_type: int = ArgumentType.VALUE
## whether the argument is required
var _required = false
## whether to omit the argument name in code generation
var _omit_name = false
## argument position in signature
var _pos = POSITION_NONE
## imports needed by the argument
var _imports : Array = []

func _init(arg_name: String):
	assert(not arg_name.empty(), "argument name may not be empty")
	_name = arg_name

func omit_name(omit: bool) -> PyArgument:
	set_omit_name(omit)
	return self

func as_value() -> PyArgument:
	set_argument_type(ArgumentType.VALUE)
	return self

func as_identifier() -> PyArgument:
	set_argument_type(ArgumentType.IDENTIFIER)
	return self

func required(required: bool) -> PyArgument:
	set_required(required)
	return self

func position(pos: int) -> PyArgument:
	_pos = pos
	return self

func enabled(enabled: bool) -> PyArgument:
	set_enabled(enabled)
	return self

func import(module, name: String = "") -> PyArgument:
	add_import(module, name)
	return self

func get_name() -> String:
	return _name

func set_omit_name(omit: bool):
	_omit_name = omit

func is_name_omitted() -> bool:
	return _omit_name

func set_argument_type(argument_type: int):
	assert(argument_type in ArgumentType.values(), "Invalid argument type specfied")
	_arg_type = argument_type

func get_argument_type() -> int:
	return _arg_type

func get_position() -> int:
	return _pos

## [code]from <module> import <name>[/code]
func add_import(module, name: String = ""):
	_add_import(PyContext.make_module_import(module, name))

# @override
func _add_import(import: String):
	if not import in _imports:
		_imports.append(import)

# @override
func clear_imports():
	_imports.clear()

# @override
func get_imports() -> Array:
	return _imports.duplicate(true)

# @override
func is_default() -> bool:
	return false

# @override
func set_required(required: bool):
	_required = required

# @override
func is_required() -> bool:
	return _required

# @override
func set_enabled(enable: bool):
	pass

# @override
func is_enabled() -> bool:
	return false

func enable():
	set_enabled(true)

func disable():
	set_enabled(false)

# @override
func generate_python_code(indent_depth: int, context: Dictionary = {}) -> String:
	return ""

static func default_from_policy(default_policy: int, value):
	match default_policy:
		DefaultValuePolicy.VALUE:
			return value
		DefaultValuePolicy.NONE:
			return NONE
		DefaultValuePolicy.NULL:
			return null
		_:
			assert(false, "Unknown DefaultValuePolicy") 

## returns true if rhs should be placed after lhs
static func compare_position_ascending(lhs: PyArgument, rhs: PyArgument) -> bool:
	if lhs.get_position() == POSITION_NONE and \
	   rhs.get_position() == POSITION_NONE:
		return false
	elif rhs.get_position() == POSITION_NONE:
		return true
	elif lhs.get_position() == POSITION_NONE:
		return false
	else:
		return lhs.get_position() < rhs.get_position()


static func value_to_string(value, escape_string: bool = true) -> String:
	match typeof(value):
		TYPE_BOOL:
			return "True" if value else "False"
		TYPE_STRING:
			if escape_string:
				return "\"%s\"" % [value]
			else:
				return value
		TYPE_ARRAY:
				if value.empty():
					return "[]"
				var array_string = "["
				for i in range(value.size()):
					if i + 1 == value.size():
						array_string += value_to_string(value[i], escape_string) + "]"
					else:
						array_string += value_to_string(value[i], escape_string) + ", "
				return array_string
		TYPE_COLOR:
			return "(%s, %s, %s, %s)" % [value.r, value.g, value.b, value.a]
		TYPE_VECTOR2:
			return "(%s, %s)" % [value.x, value.y]
		TYPE_VECTOR3:
			return "(%s, %s, %s)" % [value.x, value.y, value.z]
		TYPE_QUAT:
			return "(%s, %s, %s, %s)" % [value.x, value.y, value.z, value.w]
		_:
			return JSON.print(value)
