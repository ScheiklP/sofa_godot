##
## @author: Christoph Haas
##
## @desc: A [PyStatement] encapsulating a [PyCallable] to generate the following code pattern:
## [code]assignee = caller.callable(arguments)[/code]
## [code]scene_description[key] = assignee[/code]
##
extends "res://addons/sofa_godot_plugin/sofa_python/python/py_statement.gd"

func get_class() -> String:
	return "PyCallableStatement"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) or (clazz == get_class())

const PyArgumentContainer = preload("res://addons/sofa_godot_plugin/sofa_python/python/arguments/py_argument_container.gd").PyArgumentContainer
const PyArgumentSet = preload("res://addons/sofa_godot_plugin/sofa_python/python/arguments/py_argument_set.gd")
const PyCallable = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_callable.gd")

var _callable: PyCallable

func _init(callable: PyCallable):
	_callable = callable

#	func _init(name: String, partial: bool = false, arguments: Array = []):
#		_callable = PyCallable.new(name, partial, arguments)

func get_callable() -> PyCallable:
	return _callable

func arguments() -> PyArgumentContainer:
	return PyArgumentContainer.new(_callable)

# @override
func generate_python_code(indent_depth: int, context: Dictionary = {}):
	return _callable.generate_python_code(indent_depth, context)

# @override
func _add_import(import: String):
	_callable._add_import(import)

# @override
func clear_imports():
	_callable.clear_imports()

# @override
func get_imports() -> Array:
	return _callable.get_imports()

# expose methods of Callable/ArgumentContainer
func get_argument(arg_name: String) -> PyArgument:
	return _callable.get_argument(arg_name)

func has_argument(arg_name: String) -> bool:
	return _callable.has_argument(arg_name)

func set_partial(partial: bool):
	_callable.set_partial(partial)

func is_partial() -> bool:
	return _callable.is_partial()

func get_caller() -> String:
	return _callable.get_caller()

func set_caller(caller: String):
	_callable.set_caller(caller)

func has_caller() -> bool:
	return _callable.has_caller()

func clear_caller():
	_callable.clear_caller()
