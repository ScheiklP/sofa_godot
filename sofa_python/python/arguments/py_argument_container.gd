class PyArgumentContainer:
	extends Reference

	func get_class() -> String:
		return "PyArgumentContainer"
	func is_class(clazz: String) -> bool:
		return .is_class(clazz) or (clazz == get_class())

	const PropertyWrapper = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper.gd")
	const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")
	
	const PyArgumentSet      = preload("res://addons/sofa_godot_plugin/sofa_python/python/arguments/py_argument_set.gd")
	const PlainArgument      = preload("res://addons/sofa_godot_plugin/sofa_python/python/arguments/plain_argument.gd").PlainArgument
	const PropertyArgument   = preload("res://addons/sofa_godot_plugin/sofa_python/python/arguments/property_argument.gd").PropertyArgument
	const DictionaryArgument = preload("res://addons/sofa_godot_plugin/sofa_python/python/arguments/dictionary_argument.gd").DictionaryArgument
	const CallableArgument   = preload("res://addons/sofa_godot_plugin/sofa_python/python/arguments/callable_argument.gd").CallableArgument
	const ReferencePathArgument = preload("res://addons/sofa_godot_plugin/sofa_python/python/arguments/reference_path_argument.gd").ReferencePathArgument

	## see [set_argument]
	const IDENTIFIER_HINT = "!<identifier>"

	var _owner: Reference
	var _args: PyArgumentSet
	var _registry: PropertyWrapperRegistry = null

	func _init(owner: Reference):
		assert(owner.has_method("arguments"), "Argument owner is missing 'arguments()' method")
		_owner = owner
		_args  = owner.arguments() as PyArgumentSet

	func _wrap(owner: Reference) -> PyArgumentContainer:
		return get_script().new(owner).with_registry(get_registry())

	func unwrap():
		return _owner

	func add_dictionary(arg_name: String, arguments: Array = []) -> PyArgumentContainer:
		var argument = add_argument(DictionaryArgument.new(arg_name, arguments))
		return _wrap(argument)

	func add_callable(arg_name: String, callable_name: String, arguments: Array = []) -> PyArgumentContainer:
		var argument = add_argument(CallableArgument.new(arg_name, callable_name, false, arguments))
		return _wrap(argument)

	func add_partial_func(arg_name: String, func_name: String, func_args: Array = []) -> PyArgumentContainer:
		var argument = add_argument(CallableArgument.new(arg_name, func_name, true, func_args))
		return _wrap(argument)

	func add_plain(arg_name: String, value = PyArgument.NONE) -> PlainArgument:
		return add_argument(PlainArgument.new(arg_name, value)) as PlainArgument

	func add_property_raw(arg_name: String, property: PropertyWrapper) -> PropertyArgument:
		return add_argument(PropertyArgument.new(arg_name, property)) as PropertyArgument

	## add a (registered!) property
	func add_property(arg_name: String, property_path: String = "") -> PropertyArgument:
		var path = arg_name if property_path.empty() else property_path
		assert(has_registry(), "No PropertyWrapperRegistry specified")
		assert(get_registry().is_registered(path), "No property registered at path: " + path)
		return add_property_raw(arg_name, get_registry()._get_property_wrapper(path))

	func add_path_raw(arg_name: String, path: NodePath, source: Node) -> ReferencePathArgument:
		return add_argument(ReferencePathArgument.new(arg_name, path, source)) as ReferencePathArgument

	## add a NodePath from a (registered!) property
	func add_path(arg_name: String, source: Node, property_path: String = "") -> ReferencePathArgument:
		var path = arg_name if property_path.empty() else property_path
		assert(has_registry(), "No PropertyWrapperRegistry specified")
		assert(get_registry().is_registered(path), "No property registered at path: " + path)
		var path_property = get_registry()._get_property_wrapper(path)
		assert(path_property.is_class("NodePathPropertyWrapper"), "Wrapped property is not a NodePath")
		return add_argument(ReferencePathArgument.new(arg_name, path_property, source)) as ReferencePathArgument

	func set_argument(name: String, value, source: Node = null, default=null) -> PyArgument:
		var argument: PyArgument
		match typeof(value):
			#TODO: TYPE_ARRAY: new ListArgument.new(name) ...
			TYPE_DICTIONARY:
				var container = get_script().new(DictionaryArgument.new(name))
				for arg_key in value.keys():
					assert(typeof(arg_key) == TYPE_STRING and not arg_key.empty(), "invalid key name")
					container.set_argument(arg_key, value[arg_key], source)
				argument = container.unwrap()
			TYPE_OBJECT:
				if value.is_class("NodePathPropertyWrapper"):
					argument = ReferencePathArgument.new(name, value, source).default(default)
				elif value.is_class("PropertyWrapper"):
					argument = PropertyArgument.new(name, value).default(default)
				elif value.is_class("PyArgument")\
				  or value.is_class("PyArgumentSet")\
				  or value.is_class("PyArgumentContainer"):
						assert(false, "forbidden argument type")
				else:
					argument = PlainArgument.new(name, value).default(default)
			TYPE_NODE_PATH:
				argument = ReferencePathArgument.new(name, value, source).default(default)
			TYPE_STRING:
				# check if value should be treated as identifier
				if value.begins_with(IDENTIFIER_HINT):
					argument = PlainArgument.new(name, value.substr(IDENTIFIER_HINT.length())).default(default)
					argument.set_argument_type(PyArgument.ArgumentType.IDENTIFIER)
				else:
					argument = PlainArgument.new(name, value).default(default)
			_:
				argument = PlainArgument.new(name, value).default(default)
		if has_argument(name):
			replace_argument(name, argument)
		else:
			add_argument(argument)
		return argument

	func add_argument(argument: PyArgument) -> PyArgument:
		return _args.add_argument(argument)

	func get_argument_names() -> Array:
		return _args.get_argument_names()

	func get_argument(arg_name: String) -> PyArgument:
		return _args.get_argument(arg_name)

	func has_argument(arg_name: String) -> bool:
		return _args.has_argument(arg_name)

	func remove_argument(arg_name: String) -> bool:
		return _args.remove_argument(arg_name)

	func replace_argument(arg_name: String, argument: PyArgument) -> PyArgument:
		return _args.replace_argument(arg_name, argument)

	func find_argument(arg_name: String) -> int:
		return _args.find_argument(arg_name)
	
	func insert_argument(index: int, argument: PyArgument) -> PyArgument:
		return _args.insert_argument(index, argument)

	func replace_argument_at(index: int, argument: PyArgument) -> PyArgument:
		return _args.replace_argument_at(index, argument)

	func clear():
		_args.clear()


	func set_registry(registry: PropertyWrapperRegistry):
		_registry = registry

	func get_registry() -> PropertyWrapperRegistry:
		return _registry

	func has_registry() -> bool:
		return _registry != null

	func with_registry(registry: PropertyWrapperRegistry) -> PyArgumentContainer:
		set_registry(registry)
		return self

	func enabled(enable: bool) -> PyArgumentContainer:
		_owner.enabled(enable)
		return self

	func import(module, name: String = "") -> PyArgumentContainer:
		_owner.import(module, name)
		return self

	func omit_name(omit: bool) -> PyArgumentContainer:
		_owner.omit_name(omit)
		return self

	func as_value() -> PyArgumentContainer:
		_owner.as_value()
		return self

	func as_identifier() -> PyArgumentContainer:
		_owner.as_identifier()
		return self

	func required(required: bool) -> PyArgumentContainer:
		_owner.required(required)
		return self

	func position(pos: int) -> PyArgumentContainer:
		_owner.position(pos)
		return self
