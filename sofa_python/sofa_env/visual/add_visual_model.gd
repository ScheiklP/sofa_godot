extends "res://addons/sofa_godot_plugin/sofa_python/python/py_callable.gd"

const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")
const MeshNode = preload("res://addons/sofa_godot_plugin/sofa_python/properties/mesh_node.gd")

const sofa_env = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/sofa_env_modules.gd")
const PyArgumentContainer = preload("res://addons/sofa_godot_plugin/sofa_python/python/arguments/py_argument_container.gd").PyArgumentContainer

const MODULE = sofa_env.sofa_templates.visual
const FUNCTION_NAME = "add_visual_model"

const cat_visual_model = "Visual Model"

var _node: Spatial
var _registry: PropertyWrapperRegistry

var _mesh_node: MeshNode

func _init(node: Spatial, registry: PropertyWrapperRegistry, partial: bool = false).(FUNCTION_NAME, partial):
	_node     = node
	_registry = registry
	_setup()

func _setup():
	_setup_properties()
	_setup_callable()

func _setup_properties():
	## Name of the viusal model node.
	_registry.make_string("visual", "visual_model_node_name").category(cat_visual_model)
	## Path to the surface mesh that is to be used as a visual surface.
	_mesh_node = MeshNode.new(_node, _registry, "surface_mesh_file_path")\
		.with_texture("texture_file_path")\
		.with_rgba_color("color", Color(202.0/255.0, 203.0/255.0, 207.0/255.0))\
		.category(cat_visual_model)\
		.register()
	## What mapping is to be used between parent and child topology?
	_registry.make_enum(sofa_env.sofa_templates.mappings.MappingType, "mapping_type")\
		.select("BARYCENTRIC")\
		.category(cat_visual_model)
	## Additional keyword arguments for the mapping_type.
	_registry.make_dict({}, "mapping_kwargs").category(cat_visual_model)
	## Divide all polygons of the mesh into triangles.
	_registry.make_bool(true, "triangulate").category(cat_visual_model)
	## duplicate vertices when texture coordinates are present
	## (as it is possible that one vertex has multiple texture coordinates).
	_registry.make_bool(true, "handle_seams").category(cat_visual_model)

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
	## Name of the viusal model node.
	args.add_property("name", "visual_model_node_name")
	## RPY rotations in degrees of the collision model in relation to the parent node.
	## Order is XYZ.
	# TODO: check if euler conventions are the same for godot and sofa_env
	args.add_plain("rotation").default(Vector3.ZERO).bind(_node, "get_rotation_degrees")
	## XYZ translation of the collision model in relation to the parent node.
	args.add_plain("translation").default(Vector3.ZERO).bind(_node, "get_translation")
	## RGB values between 0 and 1 for the mesh.
	args.add_plain("color").bind(_mesh_node, "get_mesh_color_rgb")
	## Transparency of the mesh between 0 and 1.
	args.add_plain("transparency").default(0.0).bind(_mesh_node, "get_mesh_color_transparency")
	## What mapping is to be used between parent and child topology?
	args.add_property("mapping_type")\
		.import(sofa_env.sofa_templates.mappings, "MappingType")\
		.as_identifier()
	## Additional keyword arguments for the mapping_type.
	args.add_dictionary("mapping_kwargs")
	## Divide all polygons of the mesh into triangles.
	args.add_property("triangulate")
	## Path to the texture file that is to be used as a texture for the visual surface.
	args.add_property("texture_file_path").transform(ProjectSettings, "globalize_path")
	## duplicate vertices when texture coordinates are present
	args.add_property("handle_seams")

func _update_mapping_kwargs():
	PyArgumentContainer.new(self).set_argument("mapping_kwargs", _registry.get_value("mapping_kwargs"), _node)

# @override
func generate_python_code(indent_depth: int, context: Dictionary = {}) -> String:
	_update_mapping_kwargs()
	return .generate_python_code(indent_depth, context)
