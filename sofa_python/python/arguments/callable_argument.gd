##
## @author: Christoph Haas
##
## @desc: Wraps a [PyCallable] as an argument to a python function
##
class CallableArgument:
	extends PyArgument

	func get_class() -> String:
		return "CallableArgument"
	func is_class(clazz: String) -> bool:
		return .is_class(clazz) or (clazz == get_class())

	const PyCallable    = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_callable.gd")
	const PyArgumentSet = preload("res://addons/sofa_godot_plugin/sofa_python/python/arguments/py_argument_set.gd")

	var _enabled = true
	var _callable: PyCallable

	func _init(arg_name: String, callable_name: String, partial: bool = false, arguments: Array = []).(arg_name):
		_callable = PyCallable.new(callable_name, partial, arguments)

	func set_callable(callable: PyCallable) -> CallableArgument:
		_callable = callable
		return self

	func arguments() -> PyArgumentSet:
		return _callable.arguments()

	func is_partial() -> bool:
		return _callable.is_partial()

	# @override
	func _add_import(import: String) -> bool:
		return _callable._add_import(import)

	# @override
	func get_imports() -> Array:
		return _callable.get_imports()

	# override
	func clear_imports():
		_callable.clear_imports()

	# @override
	func is_default() -> bool:
		for arg in arguments().get_arguments():
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
	func generate_python_code(indent_depth: int, context: Dictionary = {}) -> String:
		return _callable.generate_python_code(indent_depth, context)
