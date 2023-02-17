##
## @author: Christoph Haas
##
## @desc: Wraps a [NodePath] as an argument to a python instance or a SOFA (link)path
##
class ReferencePathArgument:
	extends PyArgument

	func get_class() -> String:
		return "ReferencePathArgument"
	func is_class(clazz: String) -> bool:
		return .is_class(clazz) or (clazz == get_class())

	const PyReferencePath = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_reference_path.gd").PyReferencePath

	var _default
	var _path: PyReferencePath
	var _enabled = true
	var _resolve_absolute = false

	func _init(name: String, path, source: Node, default_policy: int = DefaultValuePolicy.VALUE).(name):
		_path = PyReferencePath.new(path, source)
		_default = PyArgument.default_from_policy(default_policy, _path.get_path())

	# @override
	func as_value() -> PyArgument:
		push_warning("as_value is not supported")
		return self

	func resolve_as(reference_type: int) -> ReferencePathArgument:
		_path.set_reference_type(reference_type)
		return self

	# @override
	func as_identifier() -> PyArgument:
		_path.set_reference_type(PyReferencePath.ReferenceType.PYTHON_IDENTIFIER)
		return self

	func as_sofa_link() -> ReferencePathArgument:
		_path.set_reference_type(PyReferencePath.ReferenceType.SOFA_LINK_PATH)
		return self

	func as_sofa_access() -> ReferencePathArgument:
		_path.set_reference_type(PyReferencePath.ReferenceType.SOFA_ACCESS)
		return self

	func absolute() -> ReferencePathArgument:
		_resolve_absolute = true
		return self

	## access members of reference, e.g. ReferencePathArgument(@"my_node").access(".indices")
	func access(pattern: String) -> ReferencePathArgument:
		_path.set_access_pattern(pattern)
		return self

	func bind_access(instance: Object, funcname: String, arg_array: Array = []) -> ReferencePathArgument:
		_path.set_dynamic_access_pattern(instance, funcname, arg_array)
		return self

	func default(path) -> ReferencePathArgument:
		set_default(path)
		return self

	# @override
	func is_default() -> bool:
		if _path == null or _default == null:
			return false
		if typeof(_default) == TYPE_NODE_PATH:
			return _path.get_path() == _default
		else:
			return false

	func set_default(default):
		_default = default

	func get_default():
		return _default

	# @override
	func set_enabled(enable: bool):
		if _path._get_variant().get_variant_type() == PyReferencePath.NodePathVariant.VariantType.PROPERTY_WRAPPER:
			_path._get_variant().unwrap().set_enabled(enable)
			_enabled = enable
		else:
			_enabled = enable

	# @override
	func is_enabled() -> bool:
		if _path._get_variant().get_variant_type() == PyReferencePath.NodePathVariant.VariantType.PROPERTY_WRAPPER:
			return _path._get_variant().unwrap().is_enabled()
		else:
			return _enabled

	func get_reference_type() -> int:
		return _path.get_reference_type()

	# @override
	func generate_python_code(indent_depth: int, context: Dictionary = {}) -> String:
		var resolved: String = _path.resolve(_resolve_absolute)
		match get_reference_type():
			PyReferencePath.ReferenceType.PYTHON_IDENTIFIER:
				return PyArgument.value_to_string(resolved, false)
			PyReferencePath.ReferenceType.SOFA_LINK_PATH:
				return PyArgument.value_to_string(resolved, true)
			PyReferencePath.ReferenceType.SOFA_ACCESS:
				return PyArgument.value_to_string(resolved, false)
			_:
				assert(false, "Unknown reference type")
				return NONE

