tool
extends Node
##
## @author: Christoph Haas
##
## @desc: Encapsulate the cauter from the tissue dissection scene
##
##

const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")
const PyStatementProperties = preload("res://addons/sofa_godot_plugin/sofa_python/properties/py_statement_properties.gd")

const PivotTarget = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/instruments/cauter/pivot_target.gd")
const PivotRCM = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/instruments/cauter/pivot_rcm.gd")

const PyContext = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_python_context.gd")
const PyProgram = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_program.gd")

func get_class() -> String:
	return "SofaEnvCauter"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) or (clazz == get_class())

func _get_property_list() -> Array:
	return _registry.gen_property_list()
func _set(property: String, value) -> bool:
	return _registry.handle_set(property, value)
func _get(property: String):
	return _registry.handle_get(property)

const OBJECT_NAME = "pivotized_cauter"

var _pivot_rcm: PivotRCM
var _pivot_target: PivotTarget

var _cauter_node: Spatial
var _cauter: PivotizedCauter

var _registry = PropertyWrapperRegistry.new(self)
var _py_props = PyStatementProperties.new(self, _registry)

func _init():
	set_name(OBJECT_NAME)

	_cauter_node = Spatial.new()
	_cauter_node.set_name("cauter_node")
	add_child(_cauter_node)

	_cauter = PivotizedCauter.new(_cauter_node, _registry)

	_py_props.register()


func get_python_identifier() -> String:
	return _py_props.get_identifier()

func process_python(program: PyProgram, parent_identifier: String, indent_depth: int):
	assert(not parent_identifier.empty(), "No parent node specified for " + get_name())
	_py_props.update_statement(_cauter)
	_cauter.get_argument("parent_node").set_value(parent_identifier)
	_cauter.write_to_program(program, indent_depth)
	# retrieve identifier
	var identifier = _cauter.get_identifier(self, program)
	identifier = identifier + ".node" if identifier == get_python_identifier() else identifier
	for child in get_children():
		if child.has_method("process_python"):
			child.process_python(program, identifier, indent_depth)

func _enter_tree():
	_pivot_rcm = PyContext.add_or_get_child(self, PivotRCM, "pivot_rcm")
	_pivot_target = PyContext.add_or_get_child(self, PivotTarget, "pivot_target")
	_update_cauter()

func _process(delta):
	_update_cauter()

func _update_cauter():
	var target = _pivot_target.get_target()
	var rcm = _pivot_rcm.get_rcm_pose()
	var reachability = _cauter.set_pivot_pose(target, rcm)
	match reachability:
		PivotizedCauter.Reachability.UNREACHABLE:
			push_warning("pivot target is unreachable")
		PivotizedCauter.Reachability.PTSD_STATE_LIMIT:
			push_warning("pivot target violates ptsd state limit")
		PivotizedCauter.Reachability.WORKSPACE_LIMIT:
			push_warning("pivot target violates workspace limit")
		PivotizedCauter.Reachability.REACHABLE:
			pass
		_:
			push_warning("unknown reachability")


class PivotizedCauter:
	extends "res://addons/sofa_godot_plugin/sofa_python/python/py_callable_statement.gd"

	const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")

	const OptionalIntProperty = preload("res://addons/sofa_godot_plugin/property_wrappers/optional_property.gd").OptionalIntProperty
	const OptionalFloatProperty = preload("res://addons/sofa_godot_plugin/property_wrappers/optional_property.gd").OptionalFloatProperty

	const sofa_env = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/sofa_env_modules.gd")
	const SofaEnvObject = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/sofa_env_object.gd")
	const MathHelper = preload("res://addons/sofa_godot_plugin/sofa_python/utils/math_helper.gd")

	const MeshNode = preload("res://addons/sofa_godot_plugin/sofa_python/properties/mesh_node.gd")

	#const PivotTarget = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/instruments/cauter/pivot_target.gd")

	func get_class() -> String:
		return "PivotizedCauter"
	func is_class(clazz: String) -> bool:
		return .is_class(clazz) or (clazz == get_class())

	const MODULE = "sofa_env.scenes.tissue_dissection.sofa_objects.cauter"
	const CLASS_NAME = "PivotizedCauter"

	const cat_cauter = "Pivotized Cauter"

	enum Reachability {
		UNREACHABLE,
		PTSD_STATE_LIMIT,
		WORKSPACE_LIMIT,
		REACHABLE,
	}

	var _node: Spatial
	var _registry = PropertyWrapperRegistry.new(self)
	var _optionals: Dictionary = {}

	#var _pivot_target: PivotTarget
	var _rcm_pose: Transform = Transform.IDENTITY

	var _mesh_node: MeshNode


	func _init(node: Spatial, registry: PropertyWrapperRegistry).(PyCallable.new(CLASS_NAME)):
		_node = node
		_registry = registry
		_setup()

	func _setup():
		_setup_properties()
		_setup_callable()


	func _setup_properties():
		## visual mesh
		_mesh_node = MeshNode.new(_node, _registry, "visual_mesh_path")\
			.with_rgb_color()\
			.category(cat_cauter)\
			.register()
		## scale
		_registry.make_vector3(Vector3.ONE, "visual_mesh_scale").callback(self, "_on_scale_changed").category(cat_cauter)
		## total mass
		_optionals["total_mass"] = OptionalFloatProperty.new(_registry, "total_mass").category(cat_cauter)
		## The animation loop of the scene.
		## Required to determine if objects for constraint correction should be added.
		_registry.make_enum(sofa_env.sofa_templates.scene_header.AugmentedAnimationLoopType(), "animation_loop")\
			.select_option_by_value("use_scene_header")\
			.category(cat_cauter)
		## Whether to render the nodes.
		_registry.make_bool(false, "show_object").category(cat_cauter).callback(self, "_on_toogle_properties")
		## Render size of the node if show_object is True.
		_registry.make_float(1.0, "show_object_scale").category(cat_cauter)
		## Whether to use RestShapeSpringsForceField or AttachConstraint to 
		## combine controllable and non-controllable part of the object.
		_registry.make_enum(sofa_env.sofa_templates.rigid.MechanicalBinding, "mechanical_binding")\
			.select("ATTACH")\
			.category(cat_cauter)\
			.callback(self, "_on_toogle_properties")
		## Spring stiffness of the RestShapeSpringsForceField.
		_registry.make_float(2e10, "spring_stiffness").category(cat_cauter)
		## Angular spring stiffness of the RestShapeSpringsForceField.
		_registry.make_float(2e10, "angular_spring_stiffness").category(cat_cauter)
		_optionals["collision_group"] = OptionalIntProperty.new(_registry, "collision_group").category(cat_cauter)
		## ptsd state
		_registry.make_float(0.0, "state/pan")\
			.validate(self, "_validate_ptsd_state")\
			.callback(self, "_on_update_ptsd_state")\
			.category(cat_cauter)
		_registry.make_float(0.0, "state/tilt")\
			.validate(self, "_validate_ptsd_state")\
			.callback(self, "_on_update_ptsd_state")\
			.category(cat_cauter)
		_registry.make_float(0.0, "state/spin")\
			.validate(self, "_validate_ptsd_state")\
			.callback(self, "_on_update_ptsd_state")\
			.category(cat_cauter)
		_registry.make_float(0.0, "state/depth")\
			.validate(self, "_validate_ptsd_state")\
			.callback(self, "_on_update_ptsd_state")\
			.category(cat_cauter)

		_registry.make_vector3(Vector3(-INF, -INF, -INF), "cartesian_workspace/low").category(cat_cauter)
		_registry.make_vector3(Vector3(INF, INF, INF),    "cartesian_workspace/high").category(cat_cauter)
		#ptsd_reset_noise: Optional[Union[np.ndarray, Dict[str, np.ndarray]]] = None,
		#rcm_reset_noise: Optional[Union[np.ndarray, Dict[str, np.ndarray]]] = None,
		_registry.make_float(-90.0, "state_limits/pan/low").category(cat_cauter)
		_registry.make_float( 90.0, "state_limits/pan/high").category(cat_cauter)
		_registry.make_float(-90.0, "state_limits/tilt/low").category(cat_cauter)
		_registry.make_float( 90.0, "state_limits/tilt/high").category(cat_cauter)
		_registry.make_float(-90.0, "state_limits/spin/low").category(cat_cauter)
		_registry.make_float( 90.0, "state_limits/spin/high").category(cat_cauter)
		_registry.make_float(  0.0, "state_limits/depth/low").category(cat_cauter)
		_registry.make_float(100.0, "state_limits/depth/high").category(cat_cauter)
		# update properties
		toogle_properties()


	func _setup_callable():
		# imports
		_add_import("import numpy as np")
		add_import(MODULE, CLASS_NAME)
		add_plugin_list(MODULE, "CAUTER_PLUGIN_LIST")
		var args = arguments().with_registry(_registry)
		## Parent node of the object.
		args.add_plain("parent_node").required(true).position(0).as_identifier()
		## Name of the.range_hint("-360,360,1"). object.
		args.add_plain("name").required(true).position(1).bind(_node, "get_name")
		## Total mass of the rigid object.
		args.add_plain("total_mass")\
			.bind(_optionals["total_mass"], "unwrap_or", [PyContext.PY_NONE])\
			.as_identifier()
		## Path to the visual surface mesh.
		## Scale factor for loading the meshes.
		args.add_property("scale", "visual_mesh_scale")
		args.add_property("visual_mesh_path")\
			.required(true)\
			.transform(ProjectSettings, "globalize_path")
		## The animation loop of the scene.
		## Required to determine if objects for constraint correction should be added.
		args.add_plain("animation_loop_type")\
			.import(sofa_env.sofa_templates.scene_header, "AnimationLoopType")\
			.default("AnimationLoopType.DEFAULT")\
			.bind(SofaEnvObject, "get_animation_loop_type", [_registry])\
			.as_identifier()
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

		args.add_plain("collision_group")\
			.bind(_optionals["collision_group"], "unwrap_or", [PyContext.PY_NONE])\
			.as_identifier()

		args.add_plain("ptsd_state")\
			.default("np.zeros(4)")\
			.bind(self, "_get_ptsd_state_arg")\
			.as_identifier()

		args.add_plain("rcm_pose")\
			.default("np.zeros(6)")\
			.bind(self, "_get_rcm_pose_arg")\
			.as_identifier()

		var cartesian_workspace = args.add_dictionary("cartesian_workspace")
		cartesian_workspace.add_property("low",  "cartesian_workspace/low")
		cartesian_workspace.add_property("high", "cartesian_workspace/high")

		var state_limits = args.add_dictionary("state_limits")
		state_limits.add_plain("low").bind(self, "_get_state_limits_low_arg").as_identifier()
		state_limits.add_plain("high").bind(self, "_get_state_limits_high_arg").as_identifier()


	func _on_toogle_properties(source_path: String, old_value, new_value):
		toogle_properties()

	func toogle_properties():
		var mechanical_binding = _registry._get_property_wrapper("mechanical_binding").get_selected_option_key()
		_registry.toogle_path("show_object_scale", _registry.get_value("show_object"))
		_registry.toogle_path("spring_stiffness",         mechanical_binding == "SPRING")
		_registry.toogle_path("angular_spring_stiffness", mechanical_binding == "SPRING")

	func _on_scale_changed(source_path: String, old_value, new_value):
		_update_pivot_pose()

	func _on_update_ptsd_state(source_path: String, old_value, new_value):
		#if not has_pivot_target():
		#	return
		#var pivot_target = get_pivot_target()
		#var target = ptsd_to_pose(get_ptsd_state(), get_rcm_pose()).origin
		#pivot_target.set_target(target)
		_update_pivot_pose()

	#func set_pivot_target(pivot_target: PivotTarget):
	#	_pivot_target = _pivot_target
	
	#func get_pivot_target() -> PivotTarget:
	#	return _pivot_target

	#func has_pivot_target() -> bool:
	#	return _pivot_target != null

	func _update_pivot_pose():
		_node.transform = get_pivot_pose()

	func get_pivot_pose() -> Transform:
		return ptsd_to_pose(get_ptsd_state(), get_rcm_pose())

	func set_pivot_pose(target: Vector3, rcm_pose: Transform) -> int:
		set_rcm_pose(rcm_pose)

		var ptsd = get_ptsd_for_target(target, get_rcm_pose())
		if ptsd.empty():
			return Reachability.UNREACHABLE

		var valid_ptsd = is_valid_ptsd_state(ptsd)
		set_ptsd_state(ptsd)

		return valid_ptsd


	func set_ptsd_state(ptsd: Dictionary):
		# do not trigger callbacks/validation
		_registry._get_property_wrapper("state/pan")._set_value(ptsd["p"])
		_registry._get_property_wrapper("state/tilt")._set_value(ptsd["t"])
		_registry._get_property_wrapper("state/spin")._set_value(ptsd["s"])
		_registry._get_property_wrapper("state/depth")._set_value(ptsd["d"])
		#_registry.emit_signal("property_list_changed")
		_update_pivot_pose()

	func get_ptsd_state() -> Dictionary:
		return {
			"p": _registry.get_value("state/pan"),
			"t": _registry.get_value("state/tilt"),
			"s": _registry.get_value("state/spin"),
			"d": _registry.get_value("state/depth"),
		}

	func _get_ptsd_state_arg() -> String:
		return "np.array([{p}, {t}, {s}, {d}])".format(get_ptsd_state())

	func _validate_ptsd_state(property: String, value: float) -> bool:
		var ptsd = get_ptsd_state()
		match property:
			"state/pan":
				ptsd["p"] = value
			"state/tilt":
				ptsd["t"] = value
			"state/spin":
				ptsd["s"] = value
			"state/depth":
				ptsd["d"] = value
			_:
				return false
		return is_valid_ptsd_state(ptsd) == Reachability.REACHABLE

	func is_valid_ptsd_state(ptsd: Dictionary) -> int:
		# check state limits
		var ptsd_low  = _get_state_limits_low()
		var ptsd_high = _get_state_limits_high()
		for k in ptsd:
			if ptsd[k] < ptsd_low[k] or ptsd[k] > ptsd_high[k]:
				return Reachability.PTSD_STATE_LIMIT

		# check workspace limits
		var ws_low  = _get_workspace_limits_low()
		var ws_high = _get_workspace_limits_high()
		var pos = ptsd_to_pose(ptsd, get_rcm_pose()).origin
		for i in range(3):
			if pos[i] < ws_low[i] or pos[i] > ws_high[i]:
				return  Reachability.WORKSPACE_LIMIT

		return  Reachability.REACHABLE


	func set_rcm_pose(pose: Transform):
		_rcm_pose = Transform(pose)

	func get_rcm_pose() -> Transform:
		return _rcm_pose

	func _get_rcm_pose_arg() -> String:
		var rcm = get_rcm_pose()
		var t = rcm.origin
		var r = MathHelper.quat_to_euler(rcm.basis.get_rotation_quat())
		var rcm_pose = "np.array([{tx}, {ty}, {tz}, {rx}, {ry}, {rz}])".format({
			"tx": t.x,
			"ty": t.y,
			"tz": t.z,
			"rx": r.x,		
			"ry": r.y,
			"rz": r.z,
		})
		return rcm_pose


	func _get_workspace_limits_low() -> Vector3:
		return _registry.get_value("cartesian_workspace/low")
	
	func _get_workspace_limits_high() -> Vector3:
		return _registry.get_value("cartesian_workspace/high")


	func _get_state_limits_low() -> Dictionary:
		return {
			"p": _registry.get_value("state_limits/pan/low"),
			"t": _registry.get_value("state_limits/tilt/low"),
			"s": _registry.get_value("state_limits/spin/low"),
			"d": _registry.get_value("state_limits/depth/low"),
		}

	func _get_state_limits_low_arg() -> String:
		return "np.array([{p}, {t}, {s}, {d}])".format(_get_state_limits_low())


	func _get_state_limits_high() -> Dictionary:
		return {
			"p": _registry.get_value("state_limits/pan/high"),
			"t": _registry.get_value("state_limits/tilt/high"),
			"s": _registry.get_value("state_limits/spin/high"),
			"d": _registry.get_value("state_limits/depth/high"),
		}

	func _get_state_limits_high_arg() -> String:
		return "np.array([{p}, {t}, {s}, {d}])".format(_get_state_limits_high())


	func ptsd_to_pose(ptsd: Dictionary, rcm_pose: Transform) -> Transform:
		var tool_euler_angles = Vector3(ptsd["t"], ptsd["p"], ptsd["s"])
		var tool_rotation = Transform(MathHelper.euler_to_rotation_matrix(tool_euler_angles))

		var tool_translation = Transform()
		tool_translation.origin = Vector3(0.0, 0.0, ptsd["d"])

		var tool_scale = Transform.IDENTITY.scaled(_registry.get_value("visual_mesh_scale"))

		# tool to global
		var tool_pose = ((rcm_pose * tool_rotation) * tool_translation) * tool_scale

		return tool_pose


	## calculate the required ptsd state to reach a Cartesian target point
	func get_ptsd_for_target(
		target_point: Vector3,
		rcm_pose: Transform,
		tool_dir: Vector3 = Vector3(0, 0, 1),
		link_offset: Vector3 = Vector3.ZERO
	) -> Dictionary:

		# desired tool pose wrt. global frame
		var target_dir = target_point + link_offset - rcm_pose.origin
		if target_dir.length() < 1e-6:
			return {}
		var target_orientation = MathHelper.rotation_matrix_from_vectors(tool_dir, target_dir)
		var target_position = target_point + link_offset
		var target_pose_global = Transform(target_orientation, target_position)
		# desired tool pose wrt. RCM frame
		var global_to_rcm = rcm_pose.affine_inverse()
		var target_pose_rcm = global_to_rcm * target_pose_global

		#var tool_scale = _registry.get_value("visual_mesh_scale")
		#var target_pose_tool = Transform.IDENTITY.scaled(tool_scale) * target_pose_rcm

		#(tilt, pan, spin)
		var euler_angles = MathHelper.rotation_matrix_to_euler(target_pose_rcm.basis)

		# prevent division by zero
		if abs(target_pose_rcm[2][0]) < 1e-6:
			return {}
		var depth_x = target_pose_rcm[3][0] / target_pose_rcm[2][0]

		var ptsd = {
			"p": euler_angles.y,
			"t": euler_angles.x,
			"s": euler_angles.z,
			"d": depth_x,
		}
		return ptsd
