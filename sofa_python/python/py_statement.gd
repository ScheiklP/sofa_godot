##
## @author: Christoph Haas
##
## @desc: models a python statement of the following structure:
## [code]assignee = <code>[/code]
## [code]scene_description[key] = assignee[/code]
##
extends Reference

func get_class() -> String:
	return "PyStatement"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) or (clazz == get_class())

const PyContext = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_python_context.gd")
const PyProgram = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_program.gd")

var _assignee: String = ""
var _scene_description_key: String = ""

#var _imports: Array = []
var _plugins: Dictionary = {}


func set_assignee(assignee: String):
	_assignee = assignee

func get_assignee() -> String:
	return _assignee

func has_assignee() -> bool:
	return not get_assignee().empty()

func clear_assignee():
	set_assignee("")


func set_scene_description_key(key: String):
	_scene_description_key = key

func get_scene_description_key() -> String:
	return _scene_description_key

func has_scene_description_key() -> bool:
	return not get_scene_description_key().empty()

func clear_scene_description_key():
	set_scene_description_key("")


## [code]from <module> import <name>[/code]
func add_import(module, name: String = ""):
	_add_import(PyContext.make_module_import(module, name))

# @override
func _add_import(import: String):
	pass

# @override
func clear_imports():
	pass

# @override
func get_imports() -> Array:
	return []

## add required sofa plugin
func add_sofa_plugin(plugin_name: String):
	# add plugin list with empty import
	_add_plugin_list("", "[\"{plugin}\"]".format({plugin=plugin_name}))

func add_plugin_list(module, plugin_list: String):
	var import = PyContext.make_plugin_import(module, plugin_list)
	_add_plugin_list(import, plugin_list)

func _add_plugin_list(import: String, plugin_list: String):
	assert(not plugin_list.empty(), "empty plugin list")
	#assert(not import.empty(), "empty plugin list import")
	if not _plugins.has(plugin_list):
		_plugins[plugin_list] = import

func get_plugin_lists() -> Dictionary:
	return _plugins.duplicate(true)

func clear_plugin_lists():
	_plugins.clear()


func get_identifier(node: Node, program: PyProgram) -> String:
	if has_assignee():
		return get_assignee()
	elif has_scene_description_key():
		return program.scene_description_access(get_scene_description_key())
	else:
		#return program.sofa_root_access(node)
		return PyContext.get_sofa_relative_access(node)

# @override
func generate_python_code(indent_depth: int, context: Dictionary = {}) -> String:
	return ""

## append a python statement of the following form:
## [code]assignee = <statement code>[/code]
## [code]scene_description[key] = assignee[/code]
func write_to_program(program: PyProgram, indent_depth: int, context: Dictionary = {}) -> String:
	# register imports and plugins
	program.add_imports(get_imports())
	program.add_plugin_lists(get_plugin_lists())
	# scene_description[key] = ...
	var scene_description_access = program.scene_description_access(get_scene_description_key())
	# assignment
	var code = "\t".repeat(indent_depth)
	if has_assignee():
		program.add_instance(get_assignee())
		code += get_assignee() + " = "
	elif has_scene_description_key():
		program.add_scene_description_key(get_scene_description_key())
		code += scene_description_access + " = "
	# instruction call
	code += generate_python_code(indent_depth, context)
	# assign instance to scene description on separate line
	if has_assignee() and has_scene_description_key():
		code += "\n"
		code += "\t".repeat(indent_depth)
		code += scene_description_access + " = " + get_assignee()
	# append code
	program.append_code(code)
	return code
