tool
extends Spatial
## 
## @author: Christoph Haas
##
## @desc: Test [Spatial] for [PropertyWrapper] system
##
const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")
var registry = PropertyWrapperRegistry.new()

func _set(property: String, value) -> bool:
	return registry.handle_set(property, value)

func _get(property: String):
	return registry.handle_get(property)

func _get_property_list() -> Array:
	return registry.gen_property_list()


# basic types
# with category
var bool_prop = registry.make_bool(
	false,
	"boolean_property")\
	.category("Basic built-in types")

# with range hint
var int_prop = registry.make_int(
	1, 
	"integer_property")\
	.category("Basic built-in types")\
	.range_hint("0,255,1")

# with validation function
var float_prop = registry.make_float(
	1.0,
	"float_property")\
	.category("Basic built-in types")\
	.validate(self, "validate_float_prop")

# ensure [member float_prop] is >= -1
func validate_float_prop(property: String, value: float) -> bool:
	return value >= -1.0 

var plain_str_prop = registry.make_string(
	"plain string",
	"string/plain_string")\
	.category("Basic built-in types")

var file_str_prop = registry.make_string(
	"None",
	"string/file")\
	.category("Basic built-in types")\
	.hint(PROPERTY_HINT_FILE)\
	.hint_string("*.png")

var global_file_str_prop = registry.make_string(
	"None",
	"string/global_file")\
	.category("Basic built-in types")\
	.hint(PROPERTY_HINT_GLOBAL_FILE)

var dir_str_prop = registry.make_string(
	"./",
	"string/directory")\
	.category("Basic built-in types")\
	.hint(PROPERTY_HINT_DIR)

var gloabl_dir_str_prop = registry.make_string(
	"./",
	"string/global_directory")\
	.category("Basic built-in types")\
	.hint(PROPERTY_HINT_GLOBAL_DIR)

var multiline_str_prop = registry.make_string(
	"multiline\nstring",
	"string/multinline_string")\
	.category("Basic built-in types")\
	.hint(PROPERTY_HINT_MULTILINE_TEXT)


# vector types
var vec2_prop = registry.make_vector2(
	Vector2(1, 2), "vector_2").category("Vector built-in types")

var vec3_prop = registry.make_vector3(
	Vector3(1, 2, 3), "vector_3").category("Vector built-in types")


# engine types
# with callback function
var rgba_color_prop = registry.make_color(
	Color(0.5, 0.5, 0.5, 1.0),
	"color/rgba")\
	.category("Engine built-in types")\
	.callback(self, "on_mesh_changed")

# without alpha channel
var rgb_color_prop = registry.make_color(
	Color(1.0, 0, 0, 1.0),
	"color/rgb")\
	.category("Engine built-in types")\
	.no_alpha()

var node_path_prop = registry.make_node_path(
	NodePath("."), "node_path").category("Engine built-in types")


# container types
var array_prop = registry.make_array([
		"a",
		1, 
		2.0,
	],
	"array")\
	.category("Container built-in types")

var dict_prop = registry.make_dict({
		"a": 1,
		"b": "2",
	},
	"dictionary")\
	.category("Container built-in types")


# custom types
var enum_prop = registry.make_enum({
	"option 1": 1,
	"option 2": 2,
	"option 3": 3,
	},
	"single_choice")\
	.category("Custom types")\
	.callback(self, "on_prop_changed")

var flags_prop = registry.make_flags({
	"option 1": 1,
	"option 2": 2,
	"option 3": 3,
	},
	"multiple_choice")\
	.category("Custom types")\
	.callback(self, "on_prop_changed")

# resource types
var mesh = registry.make_mesh(
	CubeMesh.new(),
	"cube_mesh")\
	.category("Resource types")\
	.callback(self, "on_mesh_changed")


# test properties
var toogle_basic_types = registry.make_bool(
	true,
	"show_basic_built-in_types")\
	.callback(self, "on_toogle")

var toogle_string_props = registry.make_bool(
	true,
	"show_string_properties")\
	.callback(self, "on_toogle")


func _enter_tree():
	# mesh example
	update_visuals()


func on_prop_changed(source_path: String, old_value, new_value):
	print("Property: '", source_path, "' = ", new_value)
	assert(new_value == registry.get_value(source_path))


func on_toogle(source_path: String, old_value: bool, new_value: bool):
	var toogle_basic_path  = toogle_basic_types.get_inspector_path()
	var toogle_string_path = toogle_string_props.get_inspector_path()
	match source_path:
		toogle_basic_path:
			registry.toogle_category("Basic built-in types", toogle_basic_types.get_value())
			registry.toogle_path(toogle_string_path, toogle_basic_types.get_value())
		toogle_string_path:
			registry.toogle_path("string/", toogle_string_props.get_value())
	# immediately update [EditorInspector] display
	property_list_changed_notify()


func on_mesh_changed(source_path: String, old_value: Mesh, new_value: Mesh):
	print("changing mesh")
	update_visuals()

func update_visuals():
	var material = SpatialMaterial.new()
	material.albedo_color = rgba_color_prop.get_value()

	if get_node_or_null("MeshInstance") == null:
		var mesh_instance = MeshInstance.new()
		mesh_instance.mesh = mesh.get_value()
		mesh_instance.set_surface_material(0, material)
		add_child(mesh_instance)
	else:
		$MeshInstance.mesh = mesh.get_value()
		$MeshInstance.set_surface_material(0, material)
