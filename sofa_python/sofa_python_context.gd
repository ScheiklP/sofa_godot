extends Reference

const PY_NONE: String = "None"

static func make_module_import(module, name: String = "") -> String:
	var module_path: String
	match typeof(module):
		TYPE_STRING:
			module_path = module
		TYPE_OBJECT:
			assert(module.get("path") != null, "Missing property 'path'")
			module_path = module.path
	assert(not module_path.empty(), "Empty module path")
	if name.empty():
		return "import {module}".format({module=module_path})
	else:
		return "from {module} import {name}".format({module=module_path, name=name})

static func make_plugin_import(module, plugin_list: String) -> String:
	assert(not plugin_list.empty(), "Empty plugin list")
	return make_module_import(module, plugin_list)

# SceneTree is not ready during _init() of root node
static func is_scene_tree_ready() -> bool:
	return Engine.get_main_loop() != null

static func add_or_get_child(parent: Node, child_script: GDScript, child_name: String) -> Node:
	assert(is_scene_tree_ready(), "SceneTree is not ready to be modified")
	if parent.has_node(child_name):
		return parent.get_node(child_name)
	else:
		var node = child_script.new()
		parent.add_child(node)
		node.set_name(child_name)
		node.set_owner(get_scene_root())
		return node

static func get_scene_root() -> Node:
	assert(is_scene_tree_ready(), "SceneTree is not ready to be modified")
	assert(Engine.get_main_loop() is SceneTree)
	if Engine.is_editor_hint():
		return Engine.get_main_loop().get_edited_scene_root()
	else:
		var root: Node = Engine.get_main_loop().get_root()
		assert(root.get_child_count() == 1, "Expected single child node")
		return root.get_child(0)


## Get the relative link path between the specified nodes
## A Link allows you to access a sofa component from another one anywhere in the simulation graph.
## https://github.com/sofa-framework/SofaPython3/blob/master/bindings/Sofa/src/SofaPython3/Sofa/Core/Binding_Base.cpp#L390
static func get_relative_sofa_link_path(from: Node, to: Node) -> String:
	assert(from.is_inside_tree(), "{from} not in scene tree".format({from=from.get_name()}))
	assert(to.is_inside_tree(), "{to} not in scene tree".format({to=to.get_name()}))
	var path: String = str(from.get_path_to(to))
	# same parent
	if from.get_parent() == to.get_parent():
		assert(path.begins_with("../"))
		return "@./" + path.substr(3)
	elif from.get_parent() == get_scene_root():
		assert(path.begins_with("../"))
		return "@./" + path.substr(3)
	else:
		return "@" + path

## Get the abosulte link path to the specified node, e.g. "@/child1/<node>"
static func get_sofa_link_path(node: Node) -> String:
	assert(node.is_inside_tree(), "{node} not in scene tree".format({node=node.get_name()}))
	if node == get_scene_root():
		return "@/"
	else:
		return "@/" + str(get_scene_root().get_path_to(node))


## Get relative path for use with the generalized access API, e.g. <from>["child1.child2.<to>"]
## Contrary to [get_relative_sofa_link_path] this requires <from> to be a parent of <to>.
# https://github.com/sofa-framework/SofaPython3/blob/master/bindings/Sofa/src/SofaPython3/Sofa/Core/Binding_Node_doc.h#L86
static func get_relative_sofa_access_path(from: Node, to: Node) -> String:
	assert(from.is_inside_tree(), "{from} not in scene tree".format({from=from.get_name()}))
	assert(to.is_inside_tree(), "{to} not in scene tree".format({to=to.get_name()}))
	assert(from.is_a_parent_of(to),
		"{from} is not a parent of {to}".format({from=from.get_name(), to=to.get_name()}))
	return str(from.get_path_to(to)).replace("/", ".")

## Get absoulte path for use with the generalized access API, e.g. <root_node>["child1.child2"]
static func get_sofa_root_access_path(node: Node) -> String:
	return get_relative_sofa_access_path(get_scene_root(), node)

## python identifier of the root Sofa.Core.Node object
static func get_sofa_root_identifier() -> String:
	#assert(get_scene_root().is_class("SofaPythonRoot"))
	var identifier = get_scene_root().get("root_node_identifier")
	assert(typeof(identifier) == TYPE_STRING)
	return identifier

## python identifer of the scene description dictionary
static func get_sofa_scene_description_identifier() -> String:
	#assert(get_scene_root().is_class("SofaPythonRoot"))
	var identifier = get_scene_root().get("scene_description_identifier")
	assert(typeof(identifier) == TYPE_STRING)
	return identifier

## Access sofa node from root through generalized access API, e.g. <root_node>["child1.child2.<node>"]
static func get_sofa_root_access(node: Node) -> String:
	assert(node != null, "Node is null")
	assert(node.is_inside_tree(), "{name} not in scene tree".format({name=node.get_name()}))
	if node == get_scene_root():
		return get_sofa_root_identifier()
	else:
		return "{root_node}[\"{path}\"]".format({root_node=get_sofa_root_identifier(), path=get_sofa_root_access_path(node)})

static func find_closest_identifiable_node(node: Node) -> Node:
	assert(node != null, "Node is null")
	assert(node.is_inside_tree(), "{name} not in scene tree".format({name=node.get_name()}))
	if node == get_scene_root():
		return node
	elif node.has_method("get_python_identifier"):
		if not node.get_python_identifier().empty():
			return node
	return find_closest_identifiable_node(node.get_parent())

## access node via relative path from the closest identifiable(!) sofa node to the specified node
static func get_sofa_relative_access(node: Node) -> String:
	var accessor = find_closest_identifiable_node(node)
	if accessor == get_scene_root():
		return get_sofa_root_access(node)
	elif accessor == node:
		return node.get_python_identifier()
	else:
		return "{parent}[\"{path}\"]"\
			.format({parent=accessor.get_python_identifier(), path=get_relative_sofa_access_path(accessor, node)})
