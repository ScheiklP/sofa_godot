tool
extends Spatial
##
## @author: Christoph Haas
##
## @desc: Encapsulates sofa_env.sofa_templates.deformable.DeformableObject
##
#class_name SofaEnvDeformableObject

const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")
const PyStatementProperties = preload("res://addons/sofa_godot_plugin/sofa_python/properties/py_statement_properties.gd")

const PyProgram   = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_program.gd")
const PyCallableStatement = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_callable_statement.gd")

func get_class() -> String:
	return "SofaEnvDeformableObject"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) or (clazz == get_class())

func _get_property_list() -> Array:
	return _registry.gen_property_list()
func _set(property: String, value) -> bool:
	return _registry.handle_set(property, value)
func _get(property: String):
	return _registry.handle_get(property)

const OBJECT_NAME = "deformable_object"

var _statement: PyCallableStatement
var _registry = PropertyWrapperRegistry.new(self)
var _py_props = PyStatementProperties.new(self, _registry)

func _init():
	set_name(OBJECT_NAME)
	_statement = PyCallableStatement.new(DeformableObject.new(self, _registry))
	_statement.add_plugin_list(DeformableObject.MODULE, DeformableObject.MODULE.plugin_list)
	_py_props.register()

func _enter_tree():
	_statement.get_callable().update()


func get_python_identifier() -> String:
	return _py_props.get_identifier()

func process_python(program: PyProgram, parent_identifier: String, indent_depth: int):
	assert(not parent_identifier.empty(), "No parent node specified for " + get_name())
	_py_props.update_statement(_statement)
	_statement.get_argument("parent_node").set_value(parent_identifier)
	_statement.write_to_program(program, indent_depth)
	# retrieve identifier
	var identifier = _statement.get_identifier(self, program)
	identifier = identifier + ".node" if identifier == get_python_identifier() else identifier
	for child in get_children():
		if child.has_method("process_python"):
			child.process_python(program, identifier, indent_depth)



class DeformableObject:
	extends "res://addons/sofa_godot_plugin/sofa_python/python/py_callable.gd"

	const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")
	const PyArgumentContainer = preload("res://addons/sofa_godot_plugin/sofa_python/python/arguments/py_argument_container.gd").PyArgumentContainer

	const sofa_env = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/sofa_env_modules.gd")
	const SofaEnvObject = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/sofa_env_object.gd")
	const AddSolverFunc = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/solver/add_solver_func.gd")
	const AddCollisionModelFunc = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/collision/add_collision_model_func.gd")
	const AddVisualModelFunc = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/visual/add_visual_model_func.gd")
	#const MaterialArgument = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/materials/material_argument.gd")
	#const AddDeformationModelFunc = preload()

	func get_class() -> String:
		return "DeformableObject"
	func is_class(clazz: String) -> bool:
		return .is_class(clazz) or (clazz == get_class())

	const MODULE = sofa_env.sofa_templates.deformable
	const CLASS_NAME = "DeformableObject"
	
	const cat_deformable = "Deformable Object"
	const cat_material   = "Material"

	#var material_node:    MaterialArgument
	#var deformation_node: AddDeformationModelFunc
	var solver_node:      AddSolverFunc
	var visual_node:      AddVisualModelFunc
	var collision_node:   AddCollisionModelFunc

	var _node: Spatial
	var _registry = PropertyWrapperRegistry.new(self)

	func _init(node: Spatial, registry: PropertyWrapperRegistry, partial: bool = false).(CLASS_NAME, partial):
		_node     = node
		_registry = registry
		_setup()

	func _setup():
		_setup_properties()
		_setup_callable()

	func update():
		update_argument_nodes()
		update_mesh()
		toogle_properties()
	
	func update_argument_nodes():
		# add required child nodes if not already present
		solver_node    = PyContext.add_or_get_child(_node, AddSolverFunc,         AddSolverFunc.ARGUMENT_NAME)
		collision_node = PyContext.add_or_get_child(_node, AddCollisionModelFunc, AddCollisionModelFunc.ARGUMENT_NAME) 
		visual_node    = PyContext.add_or_get_child(_node, AddVisualModelFunc,    AddVisualModelFunc.ARGUMENT_NAME)
		get_argument(AddSolverFunc.ARGUMENT_NAME        ).set_callable(solver_node.get_callable())
		get_argument(AddCollisionModelFunc.ARGUMENT_NAME).set_callable(collision_node.get_callable())
		get_argument(AddVisualModelFunc.ARGUMENT_NAME   ).set_callable(visual_node.get_callable())
#		_manage_material_node()

#	func _on_manage_material_node(source_path: String, old_value: bool, new_value: bool):
#		_manage_material_node()

#	func _manage_material_node():
#		var material  = MaterialArgument.ARGUMENT_NAME
#		var enable    = _registry.get_value(material)
#		material_node = PyContext.add_or_get_child(_node, MaterialArgument, material)
#		material_node.set_visible(enable)
#		get_argument(material).set_callable(material_node.get_callable())
#		get_argument(material).set_enabled(enable)

	func _setup_properties():
		## Path to the volume mesh.
		_registry.make_string(PyContext.PY_NONE, "volume_mesh_path")\
			.hint(PROPERTY_HINT_FILE)\
			.hint_string("*.msh")\
			.category(cat_deformable)
		## Total mass of the deformable object.
		_registry.make_float(1.0, "total_mass").category(cat_deformable)
		## whether to use a common mesh for visual model and collision model
		_registry.make_bool(true, "use_common_mesh").category(cat_deformable).callback(self, "_on_toogle_properties")
		## path of common mesh used for visual model and collision model
		_registry.make_string(PyContext.PY_NONE, "common_mesh_path")\
			.hint(PROPERTY_HINT_FILE)\
			.hint_string("*.obj")\
			.category(cat_deformable)\
			.callback(self, "_on_update_mesh")
		## Path to the visual surface mesh.
		_registry.make_string(PyContext.PY_NONE, "visual_mesh_path")\
			.hint(PROPERTY_HINT_FILE)\
			.hint_string("*.obj")\
			.category(cat_deformable)\
			.callback(self, "_on_update_mesh")
		## Path to the collision surface mesh.
		_registry.make_string(PyContext.PY_NONE, "collision_mesh_path")\
			.hint(PROPERTY_HINT_FILE)\
			.hint_string("*.obj")\
			.category(cat_deformable)\
			.callback(self, "_on_update_mesh")
		## Type of the volume mesh
		_registry.make_enum(sofa_env.sofa_templates.topology.TopologyTypes, "volume_mesh_type")\
			.select("TETRA")\
			.category(cat_deformable)
		## Description of the material behavior
		_registry.make_bool(false, "material").category(cat_deformable).callback(self, "_on_toogle_properties")
		_registry.make_enum(sofa_env.sofa_templates.materials.ConstitutiveModel, "constitutive_model")\
			.select("COROTATED")\
			.category(cat_material)
		_registry.make_float(0.3, "poisson_ratio").category(cat_material)
		_registry.make_int(4000, "young_modulus").category(cat_material)
		## The animation loop of the scene.
		## Required to determine if objects for constraint correction should be added.
		_registry.make_enum(sofa_env.sofa_templates.scene_header.AugmentedAnimationLoopType(), "animation_loop")\
			.select_option_by_value("use_scene_header")\
			.category(cat_deformable)\
			.callback(self, "_on_toogle_properties")
		## Type of constraint correction for the object, when animation_loop_type is AnimationLoopType.FREEMOTION.
		_registry.make_enum(sofa_env.sofa_templates.solver.ConstraintCorrectionType, "constraint_correction_type")\
			.select("PRECOMPUTED")\
			.category(cat_deformable)
		## Whether to render the nodes of the volume mesh.
		_registry.make_bool(false, "show_object").category(cat_deformable).callback(self, "_on_toogle_properties")
		## Render size of the nodes of the volume mesh if show_object is True.
		_registry.make_float(7.0, "show_object_scale").category(cat_deformable)
		## RGB values of the nodes of the volume mesh if show_object is True.
		_registry.make_color(Color(1, 0, 1), "show_object_color").no_alpha(true).category(cat_deformable)
		# update properties
		toogle_properties()
		update_mesh()


	func _on_update_mesh(source_path: String, old_value, new_value):
		update_mesh()

	func update_mesh():
		if collision_node == null or visual_node == null:
			return
		if use_common_mesh():
			var common_mesh_path = _registry.get_value("common_mesh_path")
			visual_node.set_mesh_file_path(common_mesh_path)
			collision_node.set_mesh_file_path(common_mesh_path)
		else:
			var visual_mesh_path    = _registry.get_value("visual_mesh_path")
			var collision_mesh_path = _registry.get_value("collision_mesh_path")
			visual_node.set_mesh_file_path(visual_mesh_path)
			collision_node.set_mesh_file_path(collision_mesh_path)


	func _on_toogle_properties(source_path: String, old_value, new_value):
		toogle_properties()
		if source_path == "use_common_mesh":
			update_mesh()

	func toogle_properties():
		# common_mesh
		_registry.toogle_path("common_mesh_path",        use_common_mesh())
		_registry.toogle_path("visual_mesh_path",    not use_common_mesh())
		_registry.toogle_path("collision_mesh_path", not use_common_mesh())
		# material
		_registry.toogle_category(cat_material, _registry.get_value("material"))
		# animation_loop_type
		var freemotion = sofa_env.sofa_templates.scene_header.AnimationLoopType["FREEMOTION"]
		var is_freemotion = SofaEnvObject.get_animation_loop_type(_registry) == freemotion
		_registry.toogle_path("constraint_correction_type", is_freemotion)
		# show_object
		var show_object = _registry.get_value("show_object")
		_registry.toogle_path("show_object_scale", show_object)
		_registry.toogle_path("show_object_color", show_object)


	func _setup_callable():
		add_import(MODULE, CLASS_NAME)
		var args = PyArgumentContainer.new(self).with_registry(_registry)
		## Parent node of the object.
		args.add_plain("parent_node").required(true).position(0).as_identifier()
		## Name of the object.
		args.add_plain("name").required(true).position(1).bind(_node, "get_name")
		## Path to the volume mesh.
		args.add_property("volume_mesh_path")\
			.required(true)\
			.transform(ProjectSettings, "globalize_path")
		## Total mass of the deformable object.
		args.add_property("total_mass").required(true)
		## Path to the visual surface mesh.
		args.add_plain("visual_mesh_path")\
			.bind(self, "get_visual_mesh_path")\
			.transform(ProjectSettings, "globalize_path")
		## Path to the collision surface mesh.
		args.add_plain("collision_mesh_path")\
			.bind(self, "get_collision_mesh_path")\
			.transform(ProjectSettings, "globalize_path")
		## RPY rotations in degrees of the collision model in relation to the parent node. Order is X*Y*Z.
		# TODO: check if euler conventions are the same for godot and sofa_env
		args.add_plain("rotation", Vector3.ZERO).bind(_node, "get_rotation_degrees")
		## XYZ translation of the collision model in relation to the parent node.
		args.add_plain("translation", Vector3.ZERO).bind(_node, "get_translation")
		## Scale factor for loading the meshes.
		args.add_plain("scale").default(Vector3.ONE).bind(_node, "get_scale")
		## Type of the volume mesh (e.g. TopologyTypes.TETRA for Tetraeder).
		args.add_property("volume_mesh_type")
		## Description of the material behavior.
		# TODO: implement via MaterialArgument child node
		var material = args.add_callable("material", "Material")\
			.import(sofa_env.sofa_templates.materials, "Material")
		material.add_property("constitutive_model")\
			.import(sofa_env.sofa_templates.materials, "ConstitutiveModel")\
			.as_identifier()
		material.add_property("poisson_ratio")
		material.add_property("young_modulus")
		## Function that can be used to add other deformation forcefields tham add_fem_force_field_from_material that uses the material to create an FEM force field.
		# TODO: implement via AddDeformationModelFunc child node
		args.add_partial_func("add_deformation_model_func", "add_fem_force_field_from_material")\
			.import(sofa_env.sofa_templates.materials, "add_fem_force_field_from_material")
		## Function that adds the numeric solvers to the object.
		args.add_partial_func(AddSolverFunc.ARGUMENT_NAME, "add_solver")
		## Function that defines how the collision surface from collision_mesh_path is added to the object.
		args.add_partial_func(AddCollisionModelFunc.ARGUMENT_NAME, "add_collision_model")
		## Function that defines how the visual surface from visual_mesh_path is added to the object.
		args.add_partial_func(AddVisualModelFunc.ARGUMENT_NAME, "add_visual_model")
		## The animation loop of the scene.
		## Required to determine if objects for constraint correction should be added.
		args.add_plain("animation_loop_type")\
			.import(sofa_env.sofa_templates.scene_header, "AnimationLoopType")\
			.default("AnimationLoopType.DEFAULT")\
			.bind(SofaEnvObject, "get_animation_loop_type", [_registry])\
			.as_identifier()
		## Type of constraint correction for the object, when animation_loop_type is AnimationLoopType.FREEMOTION.
		args.add_property("constraint_correction_type")\
			.import(sofa_env.sofa_templates.solver, "ConstraintCorrectionType")\
			.as_identifier()
		## Whether to render the nodes of the volume mesh.
		args.add_property("show_object")
		## Render size of the nodes of the volume mesh if show_object is True.
		args.add_property("show_object_scale")
		## RGB values of the nodes of the volume mesh if show_object is True.
		args.add_property("show_object_color")


	func use_common_mesh() -> bool:
		return _registry.get_value("use_common_mesh")

	func get_collision_mesh_path() -> String:
		return PyContext.NONE if collision_node == null else collision_node.get_mesh_file_path()

	func get_visual_mesh_path() -> String:
		return PyContext.NONE if visual_node == null else visual_node.get_mesh_file_path()