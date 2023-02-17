tool
extends Node
##
## @author: Christoph Haas, Pit Henrich
## @desc: SOFA LineAxis
##
## https://github.com/sofa-framework/sofa/blob/master/Sofa/Component/Visual/src/sofa/component/visual/LineAxis.h
##

func get_class() -> String:
	return "SofaLineAxis"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) or (clazz == get_class())

func _get_property_list() -> Array:
	return _registry.gen_property_list()
func _set(property: String, value) -> bool:
	return _registry.handle_set(property, value)
func _get(property: String):
	return _registry.handle_get(property)

const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")
const PyProgram = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_program.gd")

const OBJECT_NAME = "line_axis"

var _line_axis: LineAxis
var _registry = PropertyWrapperRegistry.new(self)

func _init():
	set_name(OBJECT_NAME)
	_line_axis = LineAxis.new(self, _registry)

func process_python(program: PyProgram, parent_identifier: String, indent_depth: int):
	_line_axis.process(program, parent_identifier, indent_depth)

func _process(delta):
	_line_axis.draw()



## <assignee> = <node>.addObject("LineAxis", name=<name>, ...)
class LineAxis:
	extends "res://addons/sofa_godot_plugin/sofa_python/sofa_components/sofa_object_base.gd"

	const DebugDraw = preload("res://addons/sofa_godot_plugin/debug_draw.gd")

	const MODULE = "Sofa.Component.Visual"
	const TYPE = "LineAxis"

	const cat_line_axis = "SOFA LineAxis"

	var _debug_drawer: DebugDraw

	func _init(node: Node, registry: PropertyWrapperRegistry).(TYPE, node, registry):
		pass

	# @override
	func setup():
		_debug_drawer = DebugDraw.new()
		_node.add_child(_debug_drawer)
		.setup()

	# @override
	func _setup_properties():
		## Axis to draw
		_registry.make_flags({"x": "x", "y": "y", "z": "z"}, "axis").category(cat_line_axis)
		## Size of the squared grid
		_registry.make_float(10.0, "size").category(cat_line_axis)
		## Thickness of the lines in the grid
		_registry.make_float(1.0, "thickness").category(cat_line_axis)
		## Display the grid or not
		_registry.make_bool(true, "draw").category(cat_line_axis)


	# @override
	func _setup_statement():
		add_sofa_plugin(MODULE)
		var args = arguments().with_registry(_registry)
		args.add_plain("name").position(1).bind(_node, "get_name")
		## Plane of the grid
		args.add_property("axis").transform(self, "_get_axis_to_draw")
		## Size of the squared grid
		args.add_property("size")
		## Thickness of the lines in the grid
		args.add_property("thickness")
		## Display the grid or not
		args.add_property("draw")


	func _get_axis_to_draw(flags: Array) -> String:
		var axis_to_draw = ""
		for axis in flags:
			axis_to_draw += axis
		return axis_to_draw


	func draw():
		if not _registry.get_value("draw"):
			return
		var size = _registry.get_value("size")
		var axis_to_draw = _registry.get_value("axis")
		if "x" in axis_to_draw:
			_debug_drawer.draw_line(Vector3(-size/2,       0,       0), Vector3(size/2,      0,      0), Color.red)
		if "y" in axis_to_draw: 
			_debug_drawer.draw_line(Vector3(      0, -size/2,       0), Vector3(     0, size/2,      0), Color.green)
		if "z" in axis_to_draw:
			_debug_drawer.draw_line(Vector3(      0,       0, -size/2), Vector3(     0,      0, size/2), Color.blue)