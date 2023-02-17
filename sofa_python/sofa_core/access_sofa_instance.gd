extends "res://addons/sofa_godot_plugin/sofa_python/python/py_statement.gd"

var _node: Node
# identifier of a Sofa.Core.Node instance
# that may index the (relative) path to the [member _node] (and its associated SofaPython instance)
var _ancestor_identifier: String = ""

func _init(node: Node):
	_node = node

func set_ancestor(identifier: String):
	_ancestor_identifier = identifier

func has_ancestor() -> bool:
	return not get_ancestor().empty()

func get_ancestor() -> String:
	return _ancestor_identifier

func clear_ancestor():
	_ancestor_identifier = ""

## <assignee> = <ancestor_node>["<path.from.ancestor.to.self>"]
# @override
func generate_python_code(indent_depth: int, context: Dictionary = {}) -> String:
	#assert(has_ancestor(), "Missing identifier for ancestor node")
	if has_ancestor():
		return "%s[\"%s\"]" % [get_ancestor(), _node.get_name()]
	else:
		return context["sofa_root_identifier"]

# @override
func write_to_program(program: PyProgram, indent_depth: int, context: Dictionary = {}) -> String:
	if not has_assignee() and not has_scene_description_key():
		return ""
	if not has_ancestor():
		# no ancestor => root node
		context["sofa_root_identifier"] = program.get_sofa_root_identifier()
	return .write_to_program(program, indent_depth, context)
