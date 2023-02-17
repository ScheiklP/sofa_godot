tool
extends Spatial
##
## @author: Christoph Haas
##
## @desc: Encapsulates sofa_env.sofa_templates.rigid.ControllableRigidObject
##
#class_name SofaEnvControllableRigidObject

const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")
const PyStatementProperties = preload("res://addons/sofa_godot_plugin/sofa_python/properties/py_statement_properties.gd")

const PyProgram   = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_program.gd")
const PyCallableStatement = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_callable_statement.gd")

func get_class() -> String:
	return "SofaEnvControllableRigidObject"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) or (clazz == get_class())

func _get_property_list() -> Array:
	return _registry.gen_property_list()
func _set(property: String, value) -> bool:
	return _registry.handle_set(property, value)
func _get(property: String):
	return _registry.handle_get(property)

const OBJECT_NAME = "controllable_rigid_object"

var _statement: PyCallableStatement
var _registry = PropertyWrapperRegistry.new(self)
var _py_props = PyStatementProperties.new(self, _registry)

func _init():
	set_name(OBJECT_NAME)
	_statement = PyCallableStatement.new(ControllableRigidObject.new(self, _registry))
	_statement.add_plugin_list(ControllableRigidObject.MODULE, ControllableRigidObject.MODULE.plugin_list)
	_py_props.register()

func _enter_tree():
	_statement.get_callable().update()

func get_python_identifier() -> String:
	return _py_props.get_identifier()

func process_python(program: PyProgram, parent_identifier: String, indent_depth: int):
	assert(not parent_identifier.empty(), "No parent node specified for " + get_name())
	#_statement.get_callable().update()
	_py_props.update_statement(_statement)
	_statement.get_argument("parent_node").set_value(parent_identifier)
	_statement.write_to_program(program, indent_depth)
	# retrieve identifier
	var identifier = _statement.get_identifier(self, program)
	identifier = identifier + ".node" if identifier == get_python_identifier() else identifier
	for child in get_children():
		if child.has_method("process_python"):
			child.process_python(program, identifier, indent_depth)


class ControllableRigidObject:
	extends "res://addons/sofa_godot_plugin/sofa_python/python/py_callable.gd"

	const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")
	const OptionalIntProperty = preload("res://addons/sofa_godot_plugin/property_wrappers/optional_property.gd").OptionalIntProperty
	const OptionalFloatProperty = preload("res://addons/sofa_godot_plugin/property_wrappers/optional_property.gd").OptionalFloatProperty

	const PyArgumentContainer = preload("res://addons/sofa_godot_plugin/sofa_python/python/arguments/py_argument_container.gd").PyArgumentContainer

	const sofa_env = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/sofa_env_modules.gd")
	const SofaEnvObject = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/sofa_env_object.gd")
	const AddSolverFunc = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/solver/add_solver_func.gd")
	const AddCollisionModelFunc = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/collision/add_collision_model_func.gd")
	const AddVisualModelFunc = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/visual/add_visual_model_func.gd")
	
	func get_class() -> String:
		return "ControllableRigidObject"
	func is_class(clazz: String) -> bool:
		return .is_class(clazz) or (clazz == get_class())

	const MODULE = sofa_env.sofa_templates.rigid
	const CLASS_NAME = "ControllableRigidObject"

	const cat_rigid   = "Controllable Rigid Object"

	var solver_node:    AddSolverFunc
	var visual_node:    AddVisualModelFunc
	var collision_node: AddCollisionModelFunc

	var _node: Spatial
	var _registry = PropertyWrapperRegistry.new(self)
	var _optionals: Dictionary = {}

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
		solver_node    = PyContext.add_or_get_child(_node, AddSolverFunc, AddSolverFunc.ARGUMENT_NAME)
		collision_node = PyContext.add_or_get_child(_node, AddCollisionModelFunc, AddCollisionModelFunc.ARGUMENT_NAME) 
		visual_node    = PyContext.add_or_get_child(_node, AddVisualModelFunc, AddVisualModelFunc.ARGUMENT_NAME)
		get_argument(AddSolverFunc.ARGUMENT_NAME        ).set_callable(solver_node.get_callable())
		get_argument(AddCollisionModelFunc.ARGUMENT_NAME).set_callable(collision_node.get_callable())
		get_argument(AddVisualModelFunc.ARGUMENT_NAME   ).set_callable(visual_node.get_callable())

	func _setup_properties():
		## whether to use a common mesh for visual model and collision model
		_registry.make_bool(true, "use_common_mesh").category(cat_rigid).callback(self, "_on_toogle_properties")
		## path of common mesh used for visual model and collision model
		_registry.make_string(PyContext.PY_NONE, "common_mesh_path")\
			.hint(PROPERTY_HINT_FILE)\
			.hint_string("*.obj")\
			.category(cat_rigid)\
			.callback(self, "_on_update_mesh")
		## Path to the visual surface mesh.
		_registry.make_string(PyContext.PY_NONE, "visual_mesh_path")\
			.hint(PROPERTY_HINT_FILE)\
			.hint_string("*.obj")\
			.category(cat_rigid)\
			.callback(self, "_on_update_mesh")
		## Path to the collision surface mesh.
		_registry.make_string(PyContext.PY_NONE, "collision_mesh_path")\
			.hint(PROPERTY_HINT_FILE)\
			.hint_string("*.obj")\
			.category(cat_rigid)\
			.callback(self, "_on_update_mesh")
		## Total mass of the rigid object.
		_optionals["total_mass"] = OptionalFloatProperty.new(_registry, "total_mass").category(cat_rigid)
		## The animation loop of the scene.
		## Required to determine if objects for constraint correction should be added.
		_registry.make_enum(sofa_env.sofa_templates.scene_header.AugmentedAnimationLoopType(), "animation_loop")\
			.select_option_by_value("use_scene_header")\
			.category(cat_rigid)
		## If set to True, will add a [code]CarvingTool[/code] tag to the collision models.
		## Requires the [code]SofaCarving[/code] plugin to be compiled.
		_registry.make_bool(false, "is_carving_tool").category(cat_rigid)
		## Whether to render the nodes.
		_registry.make_bool(false, "show_object").category(cat_rigid).callback(self, "_on_toogle_properties")
		## Render size of the node if show_object is True.
		_registry.make_float(1.0, "show_object_scale").category(cat_rigid)
		## Whether to use RestShapeSpringsForceField or AttachConstraint to 
		## combine controllable and non-controllable part of the object.
		_registry.make_enum(MODULE.MechanicalBinding, "mechanical_binding")\
			.select("ATTACH")\
			.category(cat_rigid)\
			.callback(self, "_on_toogle_properties")
		## Spring stiffness of the RestShapeSpringsForceField.
		_registry.make_float(2e10, "spring_stiffness").category(cat_rigid)
		## Angular spring stiffness of the RestShapeSpringsForceField.
		_registry.make_float(2e10, "angular_spring_stiffness").category(cat_rigid)
		_optionals["collision_group"] = OptionalIntProperty.new(_registry, "collision_group").category(cat_rigid)
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
		var mechanical_binding = _registry._get_property_wrapper("mechanical_binding").get_selected_option_key()
		_registry.toogle_path("common_mesh_path",        use_common_mesh())
		_registry.toogle_path("visual_mesh_path",    not use_common_mesh())
		_registry.toogle_path("collision_mesh_path", not use_common_mesh())
		_registry.toogle_path("show_object_scale", _registry.get_value("show_object"))
		_registry.toogle_path("spring_stiffness",         mechanical_binding == "SPRING")
		_registry.toogle_path("angular_spring_stiffness", mechanical_binding == "SPRING")


	func _setup_callable():
		add_import(MODULE, CLASS_NAME)
		var args = PyArgumentContainer.new(self).with_registry(_registry)
		## Parent node of the object.
		args.add_plain("parent_node").required(true).position(0).as_identifier()
		## Name of the object.
		args.add_plain("name").required(true).position(1).bind(_node, "get_name")
		## 6D pose of the object described as Cartesian position and quaternion.
		args.add_plain("pose").required(true).position(2).bind(SofaEnvObject, "get_pose", [_node])
		## Total mass of the rigid object.
		args.add_plain("total_mass").bind(_optionals["total_mass"], "unwrap_or", [PyContext.PY_NONE]).as_identifier()
		## Path to the visual surface mesh.
		args.add_plain("visual_mesh_path")\
			.bind(self, "get_visual_mesh_path")\
			.transform(ProjectSettings, "globalize_path")
		## Path to the collision surface mesh.
		args.add_plain("collision_mesh_path")\
			.bind(self, "get_collision_mesh_path")\
			.transform(ProjectSettings, "globalize_path")
		## Scale factor for loading the meshes.
		args.add_plain("scale").default(Vector3.ONE).bind(_node, "get_scale")
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
		## If set to True, will add a 'CarvingTool' tag to the collision models.
		## Requires the SofaCarving plugin to be compiled.
		args.add_property("is_carving_tool")
		## Whether to render the nodes.
		args.add_property("show_object")
		## Render size of the node if show_object is True.
		args.add_property("show_object_scale")
		## Whether to use "RestShapeSpringsForceField" or "AttachConstraint"
		## to combine controllable and non-controllable part of the object.
		args.add_property("mechanical_binding").import(MODULE, "MechanicalBinding").as_identifier()
		## stiffness of the "RestShapeSpringsForceField"
		args.add_property("spring_stiffness")
		## Angular spring stiffness of the "RestShapeSpringsForceField".
		args.add_property("angular_spring_stiffness")
		args.add_plain("collision_group").bind(_optionals["collision_group"], "unwrap_or", [PyContext.PY_NONE]).as_identifier()

	func use_common_mesh() -> bool:
		return _registry.get_value("use_common_mesh")

	func get_collision_mesh_path() -> String:
		return PyContext.NONE if collision_node == null else collision_node.get_mesh_file_path()

	func get_visual_mesh_path() -> String:
		return PyContext.NONE if visual_node == null else visual_node.get_mesh_file_path()
