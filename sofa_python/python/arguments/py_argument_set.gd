extends Reference
##
## @author: Christoph Haas
##
## @desc: 
##

func get_class() -> String:
	return "PyArgumentSet"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) or (clazz == get_class())

var _args: Array = []

func get_arguments() -> Array:
	return _args

func get_argument_names() -> Array:
	var arg_names = []
	for arg in _args:
		arg_names.append(arg.get_name())
	return arg_names

func has_argument(arg_name: String) -> bool:
	return get_argument(arg_name) != null

func get_argument(arg_name: String) -> PyArgument:
	var idx = find_argument(arg_name)
	if idx == -1:
		return null
	else:
		return _args[idx]

func add_arguments(arguments: Array):
	for arg in arguments:
		add_argument(arg)

func add_argument(argument: PyArgument) -> PyArgument:
	return insert_argument(_args.size(), argument)

func remove_argument(arg_name: String) -> bool:
	var idx = find_argument(arg_name)
	if idx == -1:
		return false
	else:
		_args.remove(idx)
		return true

func find_argument(arg_name: String) -> int:
	for idx in range(_args.size()):
		if _args[idx].get_name() == arg_name:
			return idx
	return -1

func insert_argument(index: int, argument: PyArgument) -> PyArgument:
	assert(argument != null, "Argument is null")
	assert(not has_argument(argument.get_name()), "Argument name already in use")
	_args.insert(index, argument)
	return argument

func replace_argument(arg_name: String, argument: PyArgument) -> PyArgument:
	return replace_argument_at(find_argument(arg_name), argument)

func replace_argument_at(index: int, argument: PyArgument) -> PyArgument:
	assert(index in range(0, _args.size()), "invalid index")
	var replaced_argument = _args[index]
	if replaced_argument.get_name() != argument.get_name():
		assert(not has_argument(argument.get_name()), "Argument name already in use")
	_args[index] = argument
	return replaced_argument

func clear():
	_args.clear()