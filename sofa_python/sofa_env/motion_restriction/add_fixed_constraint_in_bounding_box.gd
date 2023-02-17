tool
extends Spatial
##
## @author: Christoph Haas
##
## @desc: Encapsulate sofa_env.sofa_templates.motion_restriction.add_fixed_constraint_in_bounding_box
##
##	Specify the box's center via [member translation] and its extend via [member scale].
##	Note that assignations of non-positive values to [member scale] will be rejected,
##	in order to keep the box's extend positive.
##
#class_name SofaEnvFixedConstraintInBoundingBox

func get_class() -> String:
	return "SofaEnvFixedConstraintInBoundingBox"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) || (clazz == get_class())

func _set(property: String, value) -> bool:
	return _registry.handle_set(property, value)
func _get(property: String):
	return _registry.handle_get(property)
func _get_property_list() -> Array:
	return _registry.gen_property_list()

const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")

const PyContext = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_python_context.gd")
const PyProgram = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_program.gd")
const PyCallableStatement = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_callable_statement.gd")
const PyStatementProperties = preload("res://addons/sofa_godot_plugin/sofa_python/properties/py_statement_properties.gd")

var _statement: PyCallableStatement
var _registry = PropertyWrapperRegistry.new(self)
var _py_props = PyStatementProperties.new(self, _registry)

func _init():
	set_name(AddFixedConstraintInBoundingBox.FUNCTION_NAME)
	_statement = PyCallableStatement.new(AddFixedConstraintInBoundingBox.new(self, _registry))
	_statement.add_plugin_list(AddFixedConstraintInBoundingBox.MODULE, AddFixedConstraintInBoundingBox.MODULE.plugin_list)
	_py_props.register()

func _enter_tree():
	assert(get_parent() == PyContext.get_scene_root(),
		"{type} can only be added to scene's root node".format({type=get_class()}))
	# This creates a red box, which is slightly transparent
	var aabb_node = MeshInstance.new()
	aabb_node.set_mesh(CubeMesh.new())
	aabb_node.set_surface_material(0, SpatialMaterial.new())
	var material = aabb_node.get_surface_material(0)
	material.set_feature(SpatialMaterial.FEATURE_TRANSPARENT, true)
	material.set_flag(SpatialMaterial.FLAG_UNSHADED, true)
	material.set_albedo(Color(1.0,0,0,0.2))
	add_child(aabb_node)

func _process(delta):
	rotation = Vector3.ZERO
	#get_child(0).transform = Transform(global_transform.basis.orthonormalized(), Vector3.ZERO)
	# reject non-positive scale values, since scale is associated with the box's extend
	scale.x = 1 if scale.x < 0 || is_zero_approx(scale.x) else scale.x
	scale.y = 1 if scale.y < 0 || is_zero_approx(scale.y) else scale.y
	scale.z = 1 if scale.z < 0 || is_zero_approx(scale.z) else scale.z

func get_python_identifier() -> String:
	return _py_props.get_identifier()

func process_python(program: PyProgram, parent_identifier: String, indent_depth: int):
	_py_props.update_statement(_statement)
	_statement.write_to_program(program, indent_depth)



class AddFixedConstraintInBoundingBox:
	extends "res://addons/sofa_godot_plugin/sofa_python/python/py_callable.gd"
	#extends "res://addons/sofa_godot_plugin/sofa_python/python/py_callable_statement.gd"

	const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")

	const sofa_env = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/sofa_env_modules.gd")
	const PyProgram = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_program.gd")
	const PyArgumentContainer = preload("res://addons/sofa_godot_plugin/sofa_python/python/arguments/py_argument_container.gd").PyArgumentContainer

	const MODULE = sofa_env.sofa_templates.motion_restriction
	const FUNCTION_NAME = "add_fixed_constraint_in_bounding_box"
	const cat_constraint = "Fixed Constraint in Bounding Box"

	var _node: Spatial
	var _registry: PropertyWrapperRegistry

	func _init(node: Spatial, registry: PropertyWrapperRegistry, partial: bool = false).(FUNCTION_NAME, partial):
		_node     = node
		_registry = registry
		_setup()

	func _setup():
		_setup_properties()
		_setup_callable()

	func _setup_properties():
		## Parent node of the bounding box.
		_registry.make_node_path("", "attached_to").category(cat_constraint)
		## Whether to render the bounding box.
		_registry.make_bool(false, "show_bounding_box")\
			.category(cat_constraint)\
			.callback(self, "_on_toogle_properties")
		## Size of the rendered bounding box if show_bounding_box is True.
		_registry.make_float(1.0, "show_bounding_box_scale").category(cat_constraint)
		## Which of the axis to restrict. XYZ.
		# TODO: DOFs is dependent on the template data type of the associated MechanicalObject/StateContainer,
		# e.g. Vec3d, Vec6d, Rigid2d, Rigid3d, etc.
		_registry.make_flags({
				"X axis": true,
				"Y axis": true,
				"Z axis": true,
			},
			"fixed_degrees_of_freedom")\
			.category(cat_constraint)
		toogle_properties()

	func _on_toogle_properties(source_path: String, old_value: bool, new_value: bool):
		toogle_properties()

	func toogle_properties():
		_registry.toogle_path("show_bounding_box_scale", _registry.get_value("show_bounding_box"))


	func _setup_callable():
		add_import(MODULE, FUNCTION_NAME)
		var args = PyArgumentContainer.new(self).with_registry(_registry)
		##  Parent node of the bounding box.
		args.add_path("attached_to", _node).as_sofa_access().absolute().required(true).position(0)
		## Lower limits of the bounding box.
		args.add_plain("min").required(true).bind(self, "get_aabb_min")
		## Upper limit of the bounding box.
		args.add_plain("max").required(true).bind(self, "get_aabb_max")
		#args.add_plain("bounding_box_name").default(FUNCTION_NAME).bind(_node, "get_name")
		## Whether to render the bounding box.
		args.add_property("show_bounding_box")
		## Size of the rendered bounding box if show_bounding_box is True.
		args.add_property("show_bounding_box_scale")
		## Which of the axis to restrict. XYZ.
		args.add_plain("fixed_degrees_of_freedom").default([1,1,1]).bind(self, "get_fixed_dofs")


	func get_fixed_dofs() -> Array:
		# TODO: This should return an array of booleans, however, as of v21.12.00, SOFA demands binary integers {0, 1}
		var dof_mask = []
		for direction in _registry._get_property_wrapper("fixed_degrees_of_freedom").get_selection_mask():
			dof_mask.append(1 if direction else 0)
		return dof_mask

	# AABox defined by xmin,ymin,zmin, xmax,ymax,zmax
	# assuming scale > 0, i.e. min_pt < max_pt
	# assert(scale.x > 0 && scale.y > 0 && scale.z > 0, "Box's extend must be positive.")
	func get_aabb_min() -> Vector3:
		var min_pt = _node.get_translation() - _node.get_scale()
		return min_pt

	func get_aabb_max() -> Vector3:
		var max_pt = _node.get_translation() + _node.get_scale()
		return max_pt

