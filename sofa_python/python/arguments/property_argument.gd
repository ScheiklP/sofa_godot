class PropertyArgument:
	extends PyArgument
	##
	## @author: Christoph Haas
	##
	## @desc: Use (value of) [PropertyWrapper] as python argument.
	##
	#class_name PropertyArgument

	func get_class() -> String:
		return "PropertyArgument"
	func is_class(clazz: String) -> bool:
		return .is_class(clazz) or (clazz == get_class())

	const PropertyWrapper = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper.gd")


	var _property: PropertyWrapper
	var _default_value
	var _transform: FuncRef

	func _init(arg_name: String, property: PropertyWrapper, default_policy: int = DefaultValuePolicy.VALUE).(arg_name):
		_property = property
		_default_value = PyArgument.default_from_policy(default_policy, get_value())

	func transform(instance: Object, funcname: String) -> PropertyArgument:
		set_transform(instance, funcname)
		return self

	func set_transform(instance: Object, funcname: String):
		_transform = funcref(instance, funcname)

	func has_transform() -> bool:
		return _transform != null

	func remove_transform():
		_transform = null

	func get_property() -> PropertyWrapper:
		return _property

	func get_value():
		var value = _property.get_value()
		if has_transform():
			return _transform.call_func(value)
		else:
			return value

	func set_value(value):
		return _property.set_value(value)

	# @override
	func default(default) -> PropertyArgument:
		_default_value = default
		return self

	# @override
	func is_default() -> bool:
		if get_value() == null or _default_value == null:
			return false
		else:
			return String(get_value()) == String(_default_value)

	# @override
	func set_enabled(enable: bool):
		_property.set_enabled(enable)

	# @override
	func is_enabled() -> bool:
		return _property.is_enabled()

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

