tool
extends Node
##
## @author: Christoph Haas
##
## @desc: Encapsulate sofa_env.sofa_templates.scene_header.add_scene_header
##
##
class_name SofaEnvSceneHeader

func get_class() -> String:
	return "SofaEnvSceneHeader"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) || (clazz == get_class())

func _get_property_list() -> Array:
	return _registry.gen_property_list()
func _set(property: String, value) -> bool:
	return _registry.handle_set(property, value)
func _get(property: String):
	return _registry.handle_get(property)

const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")
const PyProgram = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_program.gd")

var _add_scene_header: AddSceneHeader
var _registry = PropertyWrapperRegistry.new(self)

func _init():
	set_name(AddSceneHeader.FUNCTION_NAME)
	_add_scene_header = AddSceneHeader.new(self, _registry)

func _enter_tree():
	assert(get_parent().is_class("SofaPythonRoot"), "scene header may only be added as direct child of root node")
	_add_scene_header.toogle_properties()

func process_python(program: PyProgram, parent_identifier: String, indent_depth: int):
	assert(parent_identifier == program.get_sofa_root_identifier(), "Expected root node as parent")
	_add_scene_header.get_argument("root_node").set_value(parent_identifier)
	_add_scene_header.write_to_program(program, indent_depth)

func get_animation_loop() -> String:
	return _registry.get_value("animation_loop")



class AddSceneHeader:
	extends "res://addons/sofa_godot_plugin/sofa_python/python/py_callable_statement.gd"

	const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")
	const sofa_env = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/sofa_env_modules.gd")

	const MODULE = sofa_env.sofa_templates.scene_header
	const FUNCTION_NAME = "add_scene_header"

	# property categories
	const cat_scene             = "Scene"
	const cat_constraint_solver = "Constraint Solver"
	const cat_visu              = "Visualization"
	const cat_collision         = "Collision Detection"
	const cat_cutting           = "Cutting"

	var _node: Node
	var _registry: PropertyWrapperRegistry

	func _init(node: Node, registry: PropertyWrapperRegistry).(PyCallable.new(FUNCTION_NAME)):
		_node     = node
		_registry = registry
		_setup()

	func _setup():
		_setup_properties()
		_setup_callable()

	func _setup_properties():
		_registry.make_vector3(Vector3(0, 0, 0), "gravity").category(cat_scene)
		_registry.make_float(0.02, "simulation_time_step").category(cat_scene)
		_registry.make_enum(MODULE.AnimationLoopType, "animation_loop")\
			.select("DEFAULT")\
			.category(cat_scene)\
			.callback(self, "_on_toogle_properties")
		# constraint solver
		_registry.make_enum(MODULE.ConstraintSolverType, "constraint_solver")\
			.select("GENERIC")\
			.callback(self, "_on_constraint_solver_changed")\
			.category(cat_constraint_solver)
		# constraint solver kwargs
		_setup_constraint_solver_kwargs()
		# visualization
		_registry.make_enum(MODULE.VISUAL_STYLES, "visual_style_flags")\
			.select("normal")\
			.category(cat_visu)
		_registry.make_color(Color(0.0, 0.0, 0.0, 1.0), "background_color").category(cat_visu)
		# collision
		_registry.make_bool(true, "scene_has_collisions")\
			.category(cat_scene)\
			.callback(self, "_on_toogle_properties")
		_registry.make_int(15, "collision_pipeline_depth").category(cat_collision)
		_registry.make_enum(MODULE.ContactManagerResponse, "collision_response")\
			.select("DEFAULT")\
			.category(cat_collision)
		# collision detection method
		_registry.make_enum(MODULE.IntersectionMethod, "collision_detection_method")\
			.select("NEWPROXIMITY")\
			.callback(self, "_on_collision_detection_method_changed")\
			.category(cat_collision)
		# collision detection method kwargs
		_setup_collision_detection_method_kwargs()
		# cutting
		_registry.make_bool(false, "scene_has_cutting")\
			.category(cat_collision)\
			.callback(self, "_on_toogle_properties")
		_registry.make_float(1.2, "cutting_distance").category(cat_cutting)
		# initial toogle
		toogle_properties()


	func get_constraint_solver() -> String:
		return _registry._get_property_wrapper("constraint_solver").get_selected_option_key()

	func _setup_constraint_solver_kwargs():
		# GenericConstraintSolver
		_registry.make_float(1000,  "generic/maxIterations").category(cat_constraint_solver)
		_registry.make_float(0.001, "generic/tolerance").category(cat_constraint_solver)
		_registry.make_bool(false,  "generic/computeConstraintForces").category(cat_constraint_solver)
		_registry.make_bool(false,  "generic/scaleTolerance").category(cat_constraint_solver)
		_registry.make_bool(false,  "generic/multithreading").category(cat_constraint_solver)
		# LCPConstraintSolver
		_registry.make_float(0.001, "lcp/tolerance").category(cat_constraint_solver)
		_registry.make_float(1000,  "lcp/maxIt").category(cat_constraint_solver)
		_registry.make_bool(false,  "lcp/initial_guess").category(cat_constraint_solver)
		_registry.make_bool(false,  "lcp/build_lcp").category(cat_constraint_solver)
		_registry.make_float(0.2,   "lcp/mu").category(cat_constraint_solver)
		# update properties
		_toogle_constraint_solver_kwargs()

	func _on_constraint_solver_changed(source_path: String, old_value, new_value):
		_toogle_constraint_solver_kwargs()

	func _toogle_constraint_solver_kwargs():
		var solver_type = get_constraint_solver()
		#_registry.toogle_path("automatic/", solver_type == "AUTOMATIC")
		_registry.toogle_path("generic/", solver_type == "GENERIC")
		_registry.toogle_path("lcp/",     solver_type == "LCP")


	func get_collision_detection_method() -> String:
		return _registry._get_property_wrapper("collision_detection_method").get_selected_option_key()

	func _setup_collision_detection_method_kwargs():
		# MinProximityIntersection
		_registry.make_float(1.0, "min_proximity/alarmDistance").category(cat_collision)
		_registry.make_float(0.5, "min_proximity/contactDistance").category(cat_collision)
		# LocalMinDistance
		_registry.make_float(1.0, "local_min/alarmDistance").category(cat_collision)
		_registry.make_float(0.5, "local_min/contactDistance").category(cat_collision)
		_registry.make_float(0.0, "local_min/angleCone").category(cat_collision)
		# NewProximityIntersection
		_registry.make_float(1.0, "new_proximity/alarmDistance").category(cat_collision)
		_registry.make_float(0.5, "new_proximity/contactDistance").category(cat_collision)
		# update properties
		_toogle_collision_detection_method_kwargs()

	func _on_collision_detection_method_changed(source_path: String, old_value, new_value):
		_toogle_collision_detection_method_kwargs()

	func _toogle_collision_detection_method_kwargs():
		var coll_method = get_collision_detection_method()
		_registry.toogle_path("min_proximity/", coll_method == "MINPROXIMITY")
		_registry.toogle_path("local_min/",     coll_method == "LOCALMIN")
		_registry.toogle_path("new_proximity/", coll_method == "NEWPROXIMITY")
		#_registry.toogle_path("discrete/",      coll_method == "DISCRETE")


	func _on_toogle_properties(source_path: String, old_value, new_value):
		toogle_properties()

	func toogle_properties():
		# constraint solver
		var animation_loop_key = _registry._get_property_wrapper("animation_loop").get_selected_option_key()
		var enable_constraint_solver = animation_loop_key == "FREEMOTION"
		_registry.toogle_category(cat_constraint_solver, enable_constraint_solver)
		if enable_constraint_solver:
			_toogle_constraint_solver_kwargs()
		# collision
		var enable_collisions = _registry.get_value("scene_has_collisions")
		_registry.toogle_category(cat_collision, enable_collisions)
		if enable_collisions:
			_toogle_collision_detection_method_kwargs()
		# cutting
		var enable_cutting = _registry.get_value("scene_has_cutting")
		_registry.toogle_category(cat_cutting, enable_collisions and enable_cutting)
	

	func _setup_callable():
		add_import(MODULE, FUNCTION_NAME)
		add_plugin_list(MODULE, MODULE.plugin_list)
		# arguments
		var args = arguments().with_registry(_registry) 
		## The scene's root node.
		args.add_plain("root_node").required(true).position(0).as_identifier()
		## Plugin names to load.
		## Note that PLUGINS refers to the variable defined in [PyProgram]
		args.add_plain("plugin_list", "PLUGINS").required(true).position(1).as_identifier()
		## A vector to specify the scenes gravity.
		args.add_property("gravity")
		## Time step of the simulation.
		args.add_property("dt", "simulation_time_step")
		## Which animation loop to use to simulate the scene.
		args.add_property("animation_loop").import(MODULE, "AnimationLoopType").as_identifier()
		## Which solver to use if animation_loop is AnimationLoopType.FREEMOTION.
		args.add_property("constraint_solver").import(MODULE, "ConstraintSolverType").as_identifier()
		## Which solver to use to solve constraints if animation_loop is AnimationLoopType.FREEMOTION.
		args.add_dictionary("constraint_solver_kwargs")
		_update_constraint_solver_kwargs()
		## List of flags that specify what is rendered.
		args.add_property("visual_style_flags").import(MODULE, "VISUAL_STYLES").as_identifier()
		## RGBA value of the scene's background.
		args.add_property("background_color")
		## Whether components to detect and react to collisions should be added.
		args.add_property("scene_has_collisions")
		## ?
		args.add_property("collision_pipeline_depth")
		## Which physical response to use when collisions are detected if scene_has_collisions is true.
		args.add_property("collision_response").import(MODULE, "ContactManagerResponse").as_identifier()
		## The algorithm used to detect collisions if scene_has_collisions is true.
		args.add_property("collision_detection_method").import(MODULE, "IntersectionMethod").as_identifier()
		## Additional kwargs for the collision detection algorithm if scene_has_collisions is true.
		args.add_dictionary("collision_detection_method_kwargs")
		_update_collision_detection_method_kwargs()
		## Whether the scene should simulate cutting.
		args.add_property("scene_has_cutting")
		## Distance of objects at which cutting (removing volume mesh elements) should be triggered.
		args.add_property("cutting_distance")


	func _update_constraint_solver_kwargs():
		var kwargs = PyArgumentContainer.new(get_argument("constraint_solver_kwargs")).with_registry(_registry)
		kwargs.clear()
		var solver_type = get_constraint_solver()
		match solver_type:
			"GENERIC":
				kwargs.add_property("maxIterations",           "generic/maxIterations").default(1000).required(true)
				kwargs.add_property("tolerance",               "generic/tolerance").default(0.001).required(true)
				kwargs.add_property("computeConstraintForces", "generic/computeConstraintForces").default(false).required(true)
				kwargs.add_property("scaleTolerance",          "generic/scaleTolerance").default(false).required(true)
				kwargs.add_property("multithreading",          "generic/multithreading").default(false).required(true)
			"LCP":
				kwargs.add_property("tolerance",     "lcp/tolerance").default(0.001).required(true)
				kwargs.add_property("maxIt",         "lcp/maxIt").default(1000).required(true)
				kwargs.add_property("initial_guess", "lcp/initial_guess").default(false).required(true)
				kwargs.add_property("build_lcp",     "lcp/build_lcp").default(false).required(true)
				kwargs.add_property("mu",            "lcp/mu").default(0.2).required(true)
			"AUTOMATIC":
				pass
			_:
				assert(false, "Unknown constraint_solver type")
		#for arg in get_argument("constraint_solver_kwargs").arguments().get_arguments():
		#	print(arg.get_name(), " is default: ", arg.is_default(), " default value ", arg._default_value)

	func _update_collision_detection_method_kwargs():
		var kwargs = PyArgumentContainer.new(get_argument("collision_detection_method_kwargs")).with_registry(_registry)
		kwargs.clear()
		var coll_method = get_collision_detection_method()
		match coll_method:
			"MINPROXIMITY":
				kwargs.add_property("alarmDistance",   "min_proximity/alarmDistance").default(1.0).required(true)
				kwargs.add_property("contactDistance", "min_proximity/contactDistance").default(0.5).required(true)
			"LOCALMIN":
				kwargs.add_property("alarmDistance",   "local_min/alarmDistance").default(1.0).required(true)
				kwargs.add_property("contactDistance", "local_min/contactDistance").default(0.5).required(true)
				kwargs.add_property("angleCone",       "local_min/angleCone").default(0.0).required(true)
			"NEWPROXIMITY":
				kwargs.add_property("alarmDistance",   "new_proximity/alarmDistance").default(1.0).required(true)
				kwargs.add_property("contactDistance", "new_proximity/contactDistance").default(0.5).required(true)
			"DISCRETE":
				pass
			_:
				assert(false, "Unknown collision_detection_method")


	# @override
	func generate_python_code(indent_depth: int, context: Dictionary = {}) -> String:
		_update_constraint_solver_kwargs()
		_update_collision_detection_method_kwargs()
		return .generate_python_code(indent_depth, context)
