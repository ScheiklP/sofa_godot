tool
extends Node
##
## @author: Christoph Haas, Pit Henrich
## @desc: SOFA VisualGrid
##
## https://github.com/sofa-framework/sofa/blob/master/Sofa/Component/Visual/src/sofa/component/visual/VisualGrid.h
##

func get_class() -> String:
	return "SofaVisualGrid"
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

const OBJECT_NAME = "visual_grid"

var _visual_grid: VisualGrid
var _registry = PropertyWrapperRegistry.new(self)

func _init():
	set_name(OBJECT_NAME)
	_visual_grid = VisualGrid.new(self, _registry)

func process_python(program: PyProgram, parent_identifier: String, indent_depth: int):
	_visual_grid.process(program, parent_identifier, indent_depth)

func _process(delta):
	_visual_grid.draw()



## <assignee> = <node>.addObject("VisualGrid", name=<name>, ...)
class VisualGrid:
	extends "res://addons/sofa_godot_plugin/sofa_python/sofa_components/sofa_object_base.gd"

	const DebugDraw = preload("res://addons/sofa_godot_plugin/debug_draw.gd")

	const MODULE = "Sofa.Component.Visual"
	const TYPE = "VisualGrid"

	const cat_visual_grid = "SOFA VisualGrid"

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
		## Plane of the grid
		_registry.make_enum({"x": "x", "y": "y", "z": "z"}, "plane").select("z").category(cat_visual_grid)
		## Size of the squared grid
		_registry.make_float(10.0, "size").category(cat_visual_grid)
		## Number of subdivisions
		_registry.make_int(16, "subdivisions").category(cat_visual_grid)
		## Color of the lines in the grid
		_registry.make_color(Color(0.34, 0.34, 0.34, 1.0), "color").category(cat_visual_grid)
		## Thickness of the lines in the grid
		_registry.make_float(1.0, "thickness").category(cat_visual_grid)
		## Display the grid or not
		_registry.make_bool(true, "draw").category(cat_visual_grid)


	# @override
	func _setup_statement():
		add_sofa_plugin(MODULE)
		var args = arguments().with_registry(_registry)
		args.add_plain("name").position(1).bind(_node, "get_name")
		## Plane of the grid
		args.add_property("plane")
		## Size of the squared grid
		args.add_property("size")
		## Number of subdivisions
		args.add_property("nbSubdiv", "subdivisions")
		## Color of the lines in the grid
		args.add_property("color")
		## Thickness of the lines in the grid
		args.add_property("thickness")
		## Display the grid or not
		args.add_property("draw")


	func draw():
		if not _registry.get_value("draw"):
			return
		var plane        = _registry.get_value("plane")
		var color        = _registry.get_value("color")
		var size         = _registry.get_value("size")
		var subdivisions = _registry.get_value("subdivisions")
		var step_size    = size / subdivisions
		for h in range (-subdivisions/2, subdivisions/2 + 1):
			var a_begin = Vector3.ZERO
			var a_end   = Vector3.ZERO
			var b_begin = Vector3.ZERO
			var b_end   = Vector3.ZERO
			match plane:
				"x":
					a_begin = Vector3(0, -size/2, h*step_size)
					a_end   = Vector3(0,  size/2, h*step_size)
					b_begin = Vector3(0, h*step_size, -size/2)
					b_end   = Vector3(0, h*step_size,  size/2)
				"y":
					a_begin = Vector3(-size/2, 0, h*step_size)
					a_end   = Vector3( size/2, 0, h*step_size)
					b_begin = Vector3(h*step_size, 0, -size/2)
					b_end   = Vector3(h*step_size, 0,  size/2)
				"z":
					a_begin = Vector3(-size/2, h*step_size, 0)
					a_end   = Vector3( size/2, h*step_size, 0)
					b_begin = Vector3(h*step_size, -size/2, 0)
					b_end   = Vector3(h*step_size,  size/2, 0)
				_:
					assert(false, "Unknonwn plane")
			_debug_drawer.draw_line(a_begin, a_end, color)
			_debug_drawer.draw_line(b_begin, b_end, color)