##
## @author: Christoph Haas
##
## @desc: 
##
class DictionaryArgument:
	extends PyArgument

	func get_class() -> String:
		return "DictionaryArgument"
	func is_class(clazz: String) -> bool:
		return .is_class(clazz) or (clazz == get_class())

	const PyArgumentSet = preload("res://addons/sofa_godot_plugin/sofa_python/python/arguments/py_argument_set.gd")

	var _enabled: bool = true
	var _args = PyArgumentSet.new()

	func _init(arg_name: String, arguments: Array = []).(arg_name):
		_args.add_arguments(arguments)

	func arguments() -> PyArgumentSet:
		return _args

	# @override
	func get_imports() -> Array:
		var imports = _imports.duplicate(true)
		for arg in _args.get_arguments():
			if not arg.is_enabled():
				continue
			if arg.is_required() or not arg.is_default():
				for import in arg.get_imports():
					if not import in imports:
						imports.add_argument(import)
		return imports

	# @override
	func is_default() -> bool:
		for arg in _args.get_arguments():
			if arg.is_enabled() and not arg.is_default():
				return false
		return true

	# @override
	func is_required() -> bool:
		if .is_required():
			return true
		else:
			for arg in arguments().get_arguments():
				if arg.is_enabled() and arg.is_required():
					return true
		return false

	# @override
	func set_enabled(enable: bool):
		_enabled = enable

	# @override
	func is_enabled() -> bool:
		return _enabled

	# @override
	## generates a python dictionary of the following form:
	## [code]{"argument.get_name()": argument.generate_python_code()}[/code]
	func generate_python_code(indent_depth: int, context: Dictionary = {}) -> String:
		var args_to_assign = []
		for arg in arguments().get_arguments():
			if not arg.is_enabled():
				continue
			if arg.is_required() or not arg.is_default():
			 args_to_assign.append(arg)
		# sort args in order of ascending position
		args_to_assign.sort_custom(PyArgument, "compare_position_ascending")
		if args_to_assign.empty():
			return "{}"
		var code = "{\n"
		var idx = 0
		for arg in args_to_assign:
			code += "\t".repeat(indent_depth+1)
			#assert(not arg.is_name_omitted())
			code += "\"" + arg.get_name() + "\": " + arg.generate_python_code(indent_depth+1, context)
			if idx < args_to_assign.size() - 1:
				code += ","
			code += "\n"
			idx += 1
		code += "\t".repeat(indent_depth) + "}"
		return code
