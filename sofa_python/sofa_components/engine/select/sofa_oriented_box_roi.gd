tool
extends Spatial
##
## @author: Christoph Haas
## @desc: SOFA oriented BoxROI
## https://github.com/sofa-framework/sofa/blob/master/Sofa/Component/Engine/Select/src/sofa/component/engine/select/BoxROI.inl
##

func get_class() -> String:
	return "SofaOrientedBoxROI"
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

const OBJECT_NAME = "oriented_box_roi"

var _box: OrientedBoxROI
var _registry = PropertyWrapperRegistry.new(self)

func _init():
	set_name(OBJECT_NAME)
	_box = OrientedBoxROI.new(self, _registry)

func _enter_tree():
	# This creates a red box, which is slightly transparent
	var box_node = MeshInstance.new()
	box_node.set_mesh(CubeMesh.new())
	box_node.set_surface_material(0, SpatialMaterial.new())
	var material = box_node.get_surface_material(0)
	material.set_feature(SpatialMaterial.FEATURE_TRANSPARENT, true)
	material.set_flag(SpatialMaterial.FLAG_UNSHADED, true)
	material.set_albedo(Color(1.0,0,0,0.2))
	add_child(box_node)

func process_python(program: PyProgram, parent_identifier: String, indent_depth: int):
	_box.process(program, parent_identifier, indent_depth)



## <assignee> = <node>.addObject("BoxROI", name=<name>, ...)
class OrientedBoxROI:
	extends "res://addons/sofa_godot_plugin/sofa_python/sofa_components/sofa_object_base.gd"

	#const MODULE = "SofaEngine"
	const MODULE = "Sofa.Component.Engine.Select"
	const TYPE = "BoxROI"

	const cat_box_roi = "Sofa Oriented BoxROI"

	func _init(node: Spatial, registry: PropertyWrapperRegistry).(TYPE, node, registry):		
		pass

	# @override
	func _setup_properties():
		## Rest position coordinates of the degrees of freedom.
		## If empty the positions from a MechanicalObject then a MeshLoader are searched in the current context.
		## If none are found the parent's context is searched for MechanicalObject.
		#_registry.make_node_path("", "position").category(cat_box_roi)
		## Whether to render the bounding box.
		_registry.make_bool(false, "drawBoxes")\
			.category(cat_box_roi)\
			.callback(self, "_on_toogle_properties")
		## Size of the rendered bounding box if show_bounding_box is True.
		_registry.make_float(1.0, "drawSize").category(cat_box_roi)

	func _on_toogle_properties(source_path: String, old_value, new_value):
		toogle_properties()

	func toogle_properties():
		_registry.toogle_path("drawSize", _registry.get_value("drawBoxes"))

	# @override
	func _setup_statement():
		add_sofa_plugin(MODULE)
		var args = arguments().with_registry(_registry)
		args.add_plain("name").position(1).bind(_node, "get_name")
		args.add_plain("orientedBox").required(true).bind(self, "get_oriented_box")
		args.add_property("drawBoxes")
		args.add_property("drawSize").default(0)

	# @override
	func get_node() -> Spatial:
		return _node as Spatial

	## List of boxes defined by 3 points (p0, p1, p2) and a depth distance.
	## A parallelogram will be defined by (p0, p1, p2, p3 = p0 + (p2-p1)).
	## The box will finally correspond to the parallelogram extrusion of depth/2 along its normal
	## and depth/2 in the opposite direction.
	func get_oriented_box() -> Array:
		#  Box in local godot frame (x right, y out, z down)
		#  
		#  p0+-----------+p1
		#    |           |
		#    |           |
		#    |     +-----+-->x
		#    |     |     |
		#    |     |     |
		#  p3+-----+-----+p2
		#          |
		#          v
		#          z
		var boxToGlobal  = get_node().get_global_transform()
		var extend = get_node().get_scale()
		var p0 = boxToGlobal * Vector3(-extend.x, 0, -extend.z)
		var p1 = boxToGlobal * Vector3( extend.x, 0, -extend.z)
		var p2 = boxToGlobal * Vector3( extend.x, 0,  extend.z)
		var depth = 2*extend.y
		#var p3 = p0 + (p2 - p1)
		return [
			p0.x, p0.y, p0.z,
			p1.x, p1.y, p1.z,
			p2.x, p2.y, p2.z,
			depth
		]
