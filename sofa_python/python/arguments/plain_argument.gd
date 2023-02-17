##
## @author: Christoph Haas
##
## @desc: Wraps a scalar or object as python argument
##
class PlainArgument:
	extends PyArgument

	func get_class() -> String:
		return "PlainArgument"
	func is_class(clazz: String) -> bool:
		return .is_class(clazz) or (clazz == get_class())

	var _value
	var _default_value
	var _enabled = true
	var _binding: FuncRef = null
	var _binding_arguments: Array = []
	var _transform: FuncRef = null

	func _init(arg_name: String, value, default_policy: int = DefaultValuePolicy.VALUE).(arg_name):
		_value = value
		_default_value = PyArgument.default_from_policy(default_policy, value)

	# @override
	func is_default() -> bool:
		if get_value() == null or get_default() == null:
			return false
		else:
			return String(get_value()) == String(get_default())

	# @override
	func set_enabled(enable: bool):
		_enabled = enable

	# @override
	func is_enabled() -> bool:
		return _enabled

	# @override
	func generate_python_code(indent_depth: int, context: Dictionary = {}) -> String:
		match get_argument_type():
			ArgumentType.IDENTIFIER:
				return PyArgument.value_to_string(get_value(), false)
			ArgumentType.VALUE:
				return PyArgument.value_to_string(get_value(), true)
			_:
				assert(false, "Unknown argument type")
				return NONE

	func bind(instance: Object, funcname: String, arg_array: Array = []) -> PlainArgument:
		set_binding(instance, funcname, arg_array)
		return self

	func set_binding(instance: Object, funcname: String, arg_array: Array = []):
		_binding = funcref(instance, funcname)
		_binding_arguments = arg_array

	func has_binding() -> bool:
		return _binding != null

	func remove_binding():
		_binding = null
		_binding_arguments.clear()

	func transform(instance: Object, funcname: String) -> PlainArgument:
		set_transform(instance, funcname)
		return self

	func set_transform(instance: Object, funcname: String):
		_transform = funcref(instance, funcname)

	func has_transform() -> bool:
		return _transform != null

	func remove_transform():
		_transform = null

	func default(default_value) -> PlainArgument:
		set_default(default_value)
		return self

	func set_default(default_value):
		_default_value = default_value

	func get_default():
		return _default_value

	func get_value():
		var value = null
		if has_binding():
			value = _binding.call_funcv(_binding_arguments)
		else:
			value = _value
		if has_transform():
			return _transform.call_func(value)
		else:
			return value

	func set_value(value):
		if has_binding():
			push_warning("Cannot set value while argument is bound")
		else:
			_value = value
