##
## @author: Christoph Haas
##
## @desc: A [PyCallable] may be used to model a python
## - function/constructor call: "<caller>.<callable>(<arguments>)"
## - function object:           "<caller>.<callable>"
## - partial function:          "partial(<caller>.<callable>, <arguments>)"
## 
## This is loosely comparable to python's Callable type (https://docs.python.org/3/library/typing.html#callable).
## However, return values of a python Callable are not modelled by [PyCallable].
## Instead, assignments are handeled via [PyStatement].
##
extends "res://addons/sofa_godot_plugin/sofa_python/python/arguments/py_argument_set.gd"

func get_class() -> String:
	return "PyCallable"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) or (clazz == get_class())

const PyContext = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_python_context.gd")
const PyArgumentSet = preload("res://addons/sofa_godot_plugin/sofa_python/python/arguments/py_argument_set.gd")

var _partial = false
var _imports: Array = []
var _callable: String
var _caller: String = ""

func _init(name: String, partial: bool = false, arguments: Array = []):
	_callable = name
	set_partial(partial)
	#_args.add_arguments(arguments)
	add_arguments(arguments)

func arguments() -> PyArgumentSet:
	return self

func set_partial(partial: bool):
	if _partial == partial:
		return
	else:
		_partial = partial
	if _partial:
		add_import("functools", "partial")
	else:
		_imports.erase(PyContext.make_module_import("functools", "partial"))

func is_partial() -> bool:
	return _partial


func set_callable(name: String):
	_callable = name

func get_callable() -> String:
	return _callable


func set_caller(caller: String):
	_caller = caller

func get_caller() -> String:
	return _caller

func has_caller() -> bool:
	return not get_caller().empty()

func clear_caller():
	set_caller("")



func _get_arguments_to_assign(sort_arguments: bool = true) -> Array:
	var args_to_assign = []
	for arg in get_arguments():
		if not arg.is_enabled():
			continue
		# if callable is wrapped in partial then ignore required arguments that are unchanged, i.e. default-valued
		if is_partial():
			if not arg.is_default():
				args_to_assign.append(arg)
		else:
			if arg.is_required() or not arg.is_default():
				args_to_assign.append(arg)
	if sort_arguments:
		# sort args in order of ascending position
		args_to_assign.sort_custom(PyArgument, "compare_position_ascending")
	return args_to_assign


## [code]from <module> import <name>[/code]
func add_import(module, name: String = ""):
	_add_import(PyContext.make_module_import(module, name))

func _add_import(import: String):
	if not import in _imports:
		_imports.append(import)

func clear_imports():
	_imports.clear()
	if is_partial():
		add_import("functools", "partial")

func get_imports() -> Array:
	var imports = _imports.duplicate(true)
	# append imports of arguments if not already present in own imports
	for arg in _get_arguments_to_assign():
		for import in arg.get_imports():
			if not import in imports:
				imports.append(import)
	return imports


func generate_python_code(indent_depth: int, context: Dictionary = {}) -> String:
	var args_to_assign = _get_arguments_to_assign(true)
	# caller.callable(args) vs. callable(args)
	var call: String
	if has_caller():
		call = get_caller() + "." + get_callable()
	else:
		call = get_callable()
	# return if there are no arguments to assign
	if args_to_assign.empty():
		return call if is_partial() else call + "()"
	# partial(caller.callable, args) vs. caller.callable(args)
	var code: String
	if is_partial():
		code = "partial(" + call + ",\n"
	else:
		code = call + "(\n"
	# add arguments to call
	var idx = 0
	for arg in args_to_assign:
		code += "\t".repeat(indent_depth+1)
		if not arg.is_name_omitted():
			code += arg.get_name() + "="
		code += arg.generate_python_code(indent_depth+1, context)
		if idx < args_to_assign.size() - 1:
			code += ","
		code += "\n"
		idx += 1
	code += "\t".repeat(indent_depth) + ")"
	return code
