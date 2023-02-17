extends "res://addons/sofa_godot_plugin/sofa_python/python/py_callable.gd"

const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")
const MeshNode = preload("res://addons/sofa_godot_plugin/sofa_python/properties/mesh_node.gd")
const OptionalIntProperty = preload("res://addons/sofa_godot_plugin/property_wrappers/optional_property.gd").OptionalIntProperty
const OptionalFloatProperty = preload("res://addons/sofa_godot_plugin/property_wrappers/optional_property.gd").OptionalFloatProperty

const sofa_env = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/sofa_env_modules.gd")
const PyArgumentContainer = preload("res://addons/sofa_godot_plugin/sofa_python/python/arguments/py_argument_container.gd").PyArgumentContainer

const MODULE = sofa_env.sofa_templates.collision
const FUNCTION_NAME = "add_collision_model"

const cat_col_model = "Collision Model"

var _node: Spatial
var _registry: PropertyWrapperRegistry
var _optionals: Dictionary

var _mesh_node: MeshNode

func _init(node: Spatial, registry: PropertyWrapperRegistry, partial: bool = false).(FUNCTION_NAME, partial):
	_node     = node
	_registry = registry
	_setup()

func _setup():
	_setup_properties()
	_setup_callable()

func _setup_properties():
	## Name of the collision model node.
	_registry.make_string("collision", "collision_model_node_name").category(cat_col_model)
	## Path to the surface mesh that is to be used as a collision surface.
	_mesh_node = MeshNode.new(_node, _registry, "surface_mesh_file_path")\
		.category(cat_col_model)\
		.register()
	## Types of models in the mesh to be used for collision checking.
	_registry.make_flags(MODULE.CollisionModelType, "model_types").category(cat_col_model)
	## Add the model to a collision group to disable collision checking between those models.
	_optionals["collision_group"] = OptionalIntProperty.new(_registry, "collision_group")\
		.category(cat_col_model)
	## How "strong" should the surface repel the collision before "giving in"?
	_optionals["contact_stiffness"] = OptionalFloatProperty.new(_registry, "contact_stiffness")\
		.category(cat_col_model)
	## Should only be set for rigid, immobile objects.
	## The object does not move in the scene (e.g. floor, wall) but reacts to collision.
	_registry.make_bool(false, "is_static").category(cat_col_model)
	##  Whether to check for self collision in the model.
	_registry.make_enum({
			"None":  PyContext.PY_NONE,
			"True":  true,
			"False": false,
		},
		"check_self_collision")\
		.select("None")\
		.category(cat_col_model)
	## What mapping is to be used between parent and child topology?
	_registry.make_enum(sofa_env.sofa_templates.mappings.MappingType, "mapping_type")\
		.select("BARYCENTRIC")\
		.category(cat_col_model)
	## Additional keyword arguments for the mapping_type.
	_registry.make_dict({}, "mapping_kwargs").category(cat_col_model)
	## Divide all polygons of the mesh into triangles.
	_registry.make_bool(true, "triangulate").category(cat_col_model)
	## If set to True, will add a [code]CarvingTool[/code] tag to the collision models.
	## Requires the SofaCarving plugin to be compiled.
	_registry.make_bool(false, "is_carving_tool").category(cat_col_model)

func _setup_callable():
	add_import(MODULE, FUNCTION_NAME)
	var args = PyArgumentContainer.new(self).with_registry(_registry)
	## Parent node of the collision model.
	args.add_plain("attached_to").required(true).position(0).as_identifier()
	## Path to the surface mesh that is to be used as a collision surface.
	args.add_property("surface_mesh_file_path")\
		.required(true)\
		.position(1)\
		.transform(ProjectSettings, "globalize_path")
	## Scaling factor for the imported mesh.
	args.add_plain("scale").default(Vector3.ONE).bind(_node, "get_scale")
	## Name of the collision model node.
	args.add_property("name", "collision_model_node_name")
	## RPY rotations in degrees of the collision model in relation to the parent node.
	## Order is XYZ.
	# TODO: check if euler conventions are the same for godot and sofa_env
	args.add_plain("rotation").default(Vector3.ZERO).bind(_node, "get_rotation_degrees")
	## XYZ translation of the collision model in relation to the parent node.
	args.add_plain("translation").default(Vector3.ZERO).bind(_node, "get_translation")
	args.add_property("model_types")\
		.import(MODULE, "CollisionModelType")\
		.as_identifier()
	args.add_plain("collision_group").as_identifier()\
		.bind(_optionals["collision_group"], "unwrap_or", [PyContext.PY_NONE])
	args.add_plain("contact_stiffness").as_identifier()\
		.bind(_optionals["contact_stiffness"], "unwrap_or", [PyContext.PY_NONE])
	args.add_property("is_static")
	args.add_property("check_self_collision").as_identifier()
	args.add_property("mapping_type")\
		.import(sofa_env.sofa_templates.mappings, "MappingType")\
		.as_identifier()
	## Additional keyword arguments for the mapping_type.
	args.add_dictionary("mapping_kwargs")
	args.add_property("triangulate")
	args.add_property("is_carving_tool")


func _update_mapping_kwargs():
	PyArgumentContainer.new(self).set_argument("mapping_kwargs", _registry.get_value("mapping_kwargs"), _node)

# @override
func generate_python_code(indent_depth: int, context: Dictionary = {}) -> String:
	_update_mapping_kwargs()
	return .generate_python_code(indent_depth, context)
