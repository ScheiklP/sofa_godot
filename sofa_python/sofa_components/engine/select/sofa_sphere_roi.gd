tool
extends Spatial
##
## @author: Christoph Haas
## @desc: SOFA SphereROI
## Find all the points/edges/triangles/tetrahedra located inside a given sphere.
##
## https://github.com/sofa-framework/sofa/blob/master/Sofa/Component/Engine/Select/src/sofa/component/engine/select/SphereROI.h
##

func get_class() -> String:
	return "SofaSphereROI"
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

const OBJECT_NAME = "sphere_roi"

var _roi: SphereROI
var _sphere_node: MeshInstance
var _registry = PropertyWrapperRegistry.new(self)

func _init():
	set_name(OBJECT_NAME)
	_roi = SphereROI.new(self, _registry)

func _enter_tree():
	# This creates a red sphere, which is slightly transparent
	_sphere_node = MeshInstance.new()
	_sphere_node.set_mesh(SphereMesh.new())
	_sphere_node.set_surface_material(0, SpatialMaterial.new())
	var material = _sphere_node.get_surface_material(0)
	material.set_feature(SpatialMaterial.FEATURE_TRANSPARENT, true)
	material.set_flag(SpatialMaterial.FLAG_UNSHADED, true)
	material.set_albedo(Color(1.0,0,0,0.2))
	add_child(_sphere_node)

func _process(delta):
	var r = _roi.get_radius()
	var target_scale = Vector3(r, r, r)
	var global_scale = global_transform.basis.get_scale()
	transform.basis = transform.basis.scaled((target_scale/global_scale).abs())

func process_python(program: PyProgram, parent_identifier: String, indent_depth: int):
	_roi.process(program, parent_identifier, indent_depth)



## <assignee> = <node>.addObject("SphereROI", name=<name>, ...)
class SphereROI:
	extends "res://addons/sofa_godot_plugin/sofa_python/sofa_components/sofa_object_base.gd"

	const MODULE = "Sofa.Component.Engine.Select"
	const TYPE = "SphereROI"

	const cat_sphere_roi = "Sofa SphereROI"

	func _init(node: Spatial, registry: PropertyWrapperRegistry).(TYPE, node, registry):		
		pass

	# @override
	func _setup_properties():
		## Radius(i) of the sphere(s)
		_registry.make_float(1.0, "radius").category(cat_sphere_roi)
		## Edge direction(if edgeAngle > 0)
		_registry.make_vector3(Vector3.ZERO, "direction").category(cat_sphere_roi)
		## Normal direction of the triangles (if triAngle > 0)
		_registry.make_vector3(Vector3.ZERO, "normal").category(cat_sphere_roi)
		## Max angle between the direction of the selected edges and the specified direction
		_registry.make_float(0, "edgeAngle").category(cat_sphere_roi)
		## Max angle between the normal of the selected triangle and the specified normal direction
		_registry.make_float(0, "triAngle").category(cat_sphere_roi)
		## Rest position coordinates of the degrees of freedom
		_registry.make_node_path("", "position").category(cat_sphere_roi)
		## Draw shpere(s)
		_registry.make_bool(false, "drawSphere").category(cat_sphere_roi)
		## Draw Points
		_registry.make_bool(false, "drawPoints").category(cat_sphere_roi)
		## Rendering size for box and topological elements
		_registry.make_float(1.0, "drawSize").category(cat_sphere_roi)
		## Edge Topology
		_registry.make_node_path("", "edge_topology/edges").category(cat_sphere_roi)
		## If true, will compute edge list and index list inside the ROI.
		_registry.make_bool(true, "edge_topology/computeEdges").category(cat_sphere_roi)
		## Draw Edges
		_registry.make_bool(false, "edge_topology/drawEdges").category(cat_sphere_roi)
		## Triangle Topology
		_registry.make_node_path("", "triangle_topology/triangles").category(cat_sphere_roi)
		## If true, will compute triangle list and index list inside the ROI.
		_registry.make_bool(true, "triangle_topology/computeTriangles").category(cat_sphere_roi)
		## Draw Triangles
		_registry.make_bool(false, "triangle_topology/drawTriangles").category(cat_sphere_roi)
		## Quads Topology
		_registry.make_node_path("", "quad_topology/quads").category(cat_sphere_roi)
		## If true, will compute quad list and index list inside the ROI.
		_registry.make_bool(true, "quad_topology/computeQuads").category(cat_sphere_roi)
		## Draw Quads
		_registry.make_bool(false, "quad_topology/drawQuads").category(cat_sphere_roi)
		## Tetrahedron Topology
		_registry.make_node_path("", "tetrahedron_topology/tetrahedra").category(cat_sphere_roi)
		## If true, will compute tetrahedra list and index list inside the ROI.
		_registry.make_bool(true, "tetrahedron_topology/computeTetrahedra").category(cat_sphere_roi)
		## Draw Tetrahedra
		_registry.make_bool(false, "tetrahedron_topology/drawTetrahedra").category(cat_sphere_roi)


	# @override
	func _setup_statement():
		add_sofa_plugin(MODULE)
		var args = arguments().with_registry(_registry)
		args.add_plain("name").position(1).bind(_node, "get_name")
		## Center(s) of the sphere(s)
		args.add_plain("centers", Vector3.ZERO).bind(self, "get_center").required(true)
		## Radius(i) of the sphere(s)
		args.add_property("radii", "radius").required(true)
		## Edge direction(if edgeAngle > 0)
		args.add_property("direction")
		## Normal direction of the triangles (if triAngle > 0)
		args.add_property("normal")
		## Max angle between the direction of the selected edges and the specified direction
		args.add_property("edgeAngle")
		## Max angle between the normal of the selected triangle and the specified normal direction
		args.add_property("triAngle")
		## Rest position coordinates of the degrees of freedom
		args.add_path("position", _node).as_sofa_link().access(".position")
		# visu
		args.add_property("drawSphere")
		args.add_property("drawPoints")
		args.add_property("drawSize")
		# edge topology
		args.add_path("edges", _node, "edge_topology/edges").as_sofa_link().access(".edges")
		args.add_property("computeEdges", "edge_topology/computeEdges")
		args.add_property("drawEdges", "edge_topology/drawEdges")
		# triangle topology
		args.add_path("triangles", _node, "triangle_topology/triangles").as_sofa_link().access(".triangles")
		args.add_property("computeTriangles", "triangle_topology/computeTriangles")
		args.add_property("drawTriangles", "triangle_topology/drawTriangles")
		# quad topology
		args.add_path("quads", _node, "quad_topology/quads").as_sofa_link().access(".quads")
		args.add_property("computeQuads", "quad_topology/computeQuads")
		args.add_property("drawQuads", "quad_topology/drawQuads")
		# Tetrahedron topology
		args.add_path("tetrahedra", _node, "tetrahedron_topology/tetrahedra").as_sofa_link().access(".tetrahedra")
		args.add_property("computeTetrahedra", "tetrahedron_topology/computeTetrahedra")
		args.add_property("drawTetrahedra", "tetrahedron_topology/drawTetrahedra")


	# @override
	func get_node() -> Spatial:
		return _node as Spatial

	func get_radius() -> float:
		return _registry.get_value("radius")

	func get_center() -> Vector3:
		return get_node().global_transform.origin
