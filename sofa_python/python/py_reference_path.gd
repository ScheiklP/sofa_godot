##
## @author: Christoph Haas
##
## @desc: Wraps a [NodePath] as python instance or a SOFA (link)path
##
class PyReferencePath:
	extends Reference

	func get_class() -> String:
		return "PyReferencePath"
	func is_class(clazz: String) -> bool:
		return .is_class(clazz) or (clazz == get_class())

	const PyContext = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_python_context.gd")

	enum ReferenceType {
		PYTHON_IDENTIFIER,
		SOFA_LINK_PATH,
		SOFA_ACCESS,
	}

	var _path: NodePathVariant
	var _ref_type: int = ReferenceType.SOFA_ACCESS
	var _source: Node

	var _access_pattern = ""
	var _dynamic_access_pattern: FuncRef
	var _dynamic_access_pattern_args: Array = []

	func _init(path, source: Node):
		_path = NodePathVariant.new(path)
		_source = source

	func _get_variant() -> NodePathVariant:
		return _path

	func get_path() -> NodePath:
		return _path.get_node_path()

	func get_node() -> Node:
		return get_source().get_node_or_null(get_path())

	func exists() -> bool:
		return get_node() != null
	
	func get_scene_path() -> NodePath:
		return PyContext.get_scene_root().get_path_to(get_node())


	func set_reference_type(reference_type: int):
		assert(reference_type in ReferenceType.values(), "Invalid ReferenceType")
		_ref_type = reference_type

	func get_reference_type() -> int:
		return _ref_type


	func get_source() -> Node:
		return _source

	## access members of reference,
	## e.g. PyReferencePath.new(@"my_node").access(".indices")
	## yields "<my_node_identifier>.indices"
	func set_access_pattern(access_pattern: String):
		_access_pattern = access_pattern
		_dynamic_access_pattern = null
		_dynamic_access_pattern_args.clear()

	## access members of reference,
	## e.g. PyReferencePath.new(@"my_node").access(<dynamic_access(args)>)
	## yields "<my_node_identifier>.<dynamic_access(args)>"
	func set_dynamic_access_pattern(instance: Object, funcname: String, arg_array: Array = []):
		_dynamic_access_pattern = funcref(instance, funcname)
		_dynamic_access_pattern_args = arg_array
		_access_pattern = ""

	func get_access_pattern() -> String:
		if _dynamic_access_pattern != null:
			return _dynamic_access_pattern.call_funcv(_dynamic_access_pattern_args)
		else:
			return _access_pattern

	func has_access_pattern() -> bool:
		return (_dynamic_access_pattern != null) or (not _access_pattern.empty())

	func clear_access_pattern():
		_access_pattern = ""
		_dynamic_access_pattern = null
		_dynamic_access_pattern_args.clear()


	func resolve(absolute: bool = false) -> String:
		assert(exists(), "Reference does not exist at {path}".format({path=_path.get_node_path()}))
		var node = get_node()
		var code = ""
		match get_reference_type():
			ReferenceType.PYTHON_IDENTIFIER:
				code += _get_python_identifier(node)
			ReferenceType.SOFA_LINK_PATH:
				code += _get_sofa_link_path(node, absolute)
			ReferenceType.SOFA_ACCESS:
				code += _get_sofa_access(node, absolute)
			_:
				assert(false, "Unknown ReferenceType")
		if has_access_pattern():
			code += get_access_pattern()
		return code

	func _get_python_identifier(node: Node) -> String:
		assert(node.has_method("get_python_identifier"),
			"Node '{name}' does not provide a python identifier".format({name=node.get_name()}))
		var identifier = node.get_python_identifier()
		assert(not identifier.empty(),
			"The identifier for node '{name}' is not set".format({name=node.get_name()}))
		return identifier

	func _get_sofa_link_path(node: Node, absolute: bool) -> String:
		if absolute:
			return PyContext.get_sofa_link_path(node)
		else:
			return PyContext.get_relative_sofa_link_path(get_source(), node)

	func _get_sofa_access(node: Node, absolute: bool) -> String:
		if absolute:
			return PyContext.get_sofa_root_access(node)
		else:
			return PyContext.get_sofa_relative_access(node)

	## Encapsulate String, NodePath and NodePathPropertyWrapper
	class NodePathVariant:
		extends Reference

		func get_class() -> String:
			return "NodePathVariant"
		func is_class(clazz: String) -> bool:
			return .is_class(clazz) or (clazz == get_class())

		const NodePathPropertyWrapper = preload("res://addons/sofa_godot_plugin/property_wrappers/node_path_property_wrapper.gd")

		enum VariantType {
			NODE_PATH,
			PROPERTY_WRAPPER,
		}

		var _variant: int
		var _source: Node
		var _path

		func _init(path):
			set_node_path(path)

		func get_variant_type() -> int:
			return _variant

		func unwrap():
			return _path

		func set_node_path(path):
			match typeof(path):
				TYPE_STRING:
					_variant = VariantType.NODE_PATH
					_path = NodePath(path)
				TYPE_NODE_PATH:
					_variant = VariantType.NODE_PATH
					_path = path
				TYPE_OBJECT:
					if path.is_class("NodePathPropertyWrapper"):
						_variant = VariantType.PROPERTY_WRAPPER
						_path = path
					else:
						assert(false, "Invalid path variant")	
				_:
					assert(false, "Invalid path variant")

		func get_node_path() -> NodePath:
			match(_variant):
				VariantType.NODE_PATH:
					return _path
				VariantType.PROPERTY_WRAPPER:
					return (_path as NodePathPropertyWrapper).get_value()
				_:
					assert(false, "Unknown variant type")
					return @""
