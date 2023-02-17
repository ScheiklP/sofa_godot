##
## @author: Christoph Haas
##
## @desc: Adds properties to display an external mesh file.
## Optionally with texture and color.
##
## 
extends Reference

const StringPropertyWrapper   = preload("res://addons/sofa_godot_plugin/property_wrappers/string_property_wrapper.gd")
const ColorPropertyWrapper    = preload("res://addons/sofa_godot_plugin/property_wrappers/color_property_wrapper.gd")
const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")
const PyContext = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_python_context.gd")

const mesh_node_name = "mesh_node"

var _node: Spatial
var _registry: PropertyWrapperRegistry

var _path_prefix: String = ""
var _mesh_prop_name: String

var _texture_prop_name: String = ""
var _default_texture: String

var _color_prop_name: String = ""
var _color_with_alpha: bool = false
var _default_color: Color

var _category: String = ""
var _enabled: bool = true
var _file_hint: int = PROPERTY_HINT_FILE

var _mesh_file_path: StringPropertyWrapper
var _texture_file_path: StringPropertyWrapper
var _mesh_color: ColorPropertyWrapper

func _init(node: Spatial, registry: PropertyWrapperRegistry, property_name: String = "mesh_file_path"):
	_node = node
	_registry = registry
	_mesh_prop_name = property_name

func prefix(path_prefix: String):
	_path_prefix = path_prefix
	return self

func category(category: String):
	_category = category
	return self

## global file paths instead of local file paths (res://)
func globalized():
	_file_hint = PROPERTY_HINT_GLOBAL_FILE
	return self

func with_texture(property_name: String = "texture_file_path", texture_file_path: String = PyContext.PY_NONE):
	_texture_prop_name = property_name
	_default_texture = texture_file_path
	return self

func with_rgb_color(property_name: String = "mesh_color", mesh_color: Color = Color(0, 0, 0)):
	_color_prop_name = property_name
	_default_color = mesh_color
	_color_with_alpha = false
	return self

func with_rgba_color(property_name: String = "mesh_color", mesh_color: Color = Color(0, 0, 0, 1)):
	_color_prop_name = property_name
	_default_color = mesh_color
	_color_with_alpha = true
	return self

func register():
	_setup_properties()
	return self


func _setup_properties():
	# mesh file path
	var mesh_file_path_prop = _mesh_prop_name if _path_prefix.empty() else _path_prefix + "/" + _mesh_prop_name
	_mesh_file_path = _registry.make_string(PyContext.PY_NONE, mesh_file_path_prop)\
		.hint(_file_hint)\
		.hint_string("*.obj")\
		.callback(self, "_on_update_mesh")
	if not _category.empty():
		_mesh_file_path.set_inspector_category(_category)
	# texture file path
	var has_texture = not _texture_prop_name.empty()
	if has_texture:
		var texture_file_path_prop = _texture_prop_name if _path_prefix.empty() else _path_prefix + "/" + _texture_prop_name
		_texture_file_path = _registry.make_string(_default_texture, texture_file_path_prop)\
			.hint(_file_hint)\
			.callback(self, "_on_update_mesh_texture")
		if not _category.empty():
			_texture_file_path.set_inspector_category(_category)
	# color
	var has_color = not _color_prop_name.empty()
	if has_color:
		var color_prop = _color_prop_name if _path_prefix.empty() else _path_prefix + "/" + _color_prop_name
		_mesh_color = _registry.make_color(_default_color, color_prop)\
			.no_alpha(not _color_with_alpha)\
			.callback(self, "_on_update_mesh_color")
		if not _category.empty():
			_mesh_color.set_inspector_category(_category)
	# initial update
	_update_mesh()


func _on_update_mesh(property: String, old_value, new_value):
	_update_mesh()

func _on_update_mesh_texture(property: String, old_value, new_value):
	_update_mesh_texture()

func _on_update_mesh_color(property: String, old_value, new_value):
	_update_mesh_color()


func _update_mesh():
	var mesh_node = _node.get_node_or_null(mesh_node_name)
	var mesh_path = _mesh_file_path.get_value()
	var valid_path = ResourceLoader.exists(mesh_path, "Mesh")
	if not valid_path:
		if mesh_path != PyContext.PY_NONE:
			push_warning("Cannot load mesh from file path: " + mesh_path)
		if mesh_node != null:
			_node.remove_child(mesh_node)
		return
	if mesh_node == null:
		mesh_node = MeshInstance.new()
		mesh_node.set_name(mesh_node_name)
		_node.add_child(mesh_node)
	var mesh = ResourceLoader.load(mesh_path, "Mesh", true)
	assert(mesh != null, "Loading mesh failed")
	mesh_node.set_mesh(mesh)
	mesh_node.set_surface_material(0, SpatialMaterial.new())
	_update_mesh_texture()
	_update_mesh_color()

func _update_mesh_texture():
	if not has_texture():
		return
	var mesh_node = _node.get_node_or_null(mesh_node_name)
	var texture_path = _texture_file_path.get_value()
	var valid_path = ResourceLoader.exists(texture_path, "Texture")
	if not valid_path:
		if texture_path != PyContext.PY_NONE:
			push_warning("Cannot load texture from file path: " + texture_path)
		# texture path changed remove current texture
		if mesh_node != null:
			mesh_node.set_surface_material(0, SpatialMaterial.new())
			_update_mesh_color()
		return
	if mesh_node == null:
		return
	var texture = ResourceLoader.load(texture_path, "Texture", true)
	assert(texture != null, "Loading texture failed")
	var material = mesh_node.get_surface_material(0)
	material.set_texture(SpatialMaterial.TEXTURE_ALBEDO, texture)
	_update_mesh_color()

func _update_mesh_color():
	if not has_color():
		return
	var mesh_node = _node.get_node_or_null(mesh_node_name)
	if mesh_node != null:
		var material = mesh_node.get_surface_material(0)
		material.set_albedo(_mesh_color.get_value())
		material.set_feature(SpatialMaterial.FEATURE_TRANSPARENT, _color_with_alpha)
		material.set_depth_draw_mode(SpatialMaterial.DEPTH_DRAW_ALWAYS)


func disable():
	_enabled = false
	_registry.disable_path(_mesh_file_path.get_inspector_path())
	if has_texture():
		_registry.disable_path(_texture_file_path.get_inspector_path())
	if has_color():
		_registry.disable_path(_mesh_color.get_inspector_path())

func enable():
	_enabled = true
	_registry.enable_path(_mesh_file_path.get_inspector_path())
	if has_texture():
		_registry.enable_path(_texture_file_path.get_inspector_path())
	if has_color():
		_registry.enable_path(_mesh_color.get_inspector_path())

func is_enabled() -> bool:
	return _enabled


func set_mesh_file_path(mesh_file_path: String):
	_mesh_file_path.set_value(mesh_file_path)

func get_mesh_file_path() -> String:
	return _mesh_file_path.get_value()

func clear_mesh_file_path():
	set_mesh_file_path(PyContext.PY_NONE)


func has_texture() -> bool:
	return _texture_file_path != null

func set_texture_file_path(texture_file_path: String):
	assert(has_texture(), "texture property not available")
	_texture_file_path.set_value(texture_file_path)

func get_texture_file_path() -> String:
	assert(has_texture(), "texture property not available")
	return _texture_file_path.get_value()

func clear_texture_file_path():
	set_texture_file_path(PyContext.PY_NONE)


func has_color() -> bool:
	return _mesh_color != null

func set_mesh_color(color: Color):
	assert(has_color(), "color property not available")
	_mesh_color.set_value(color)

func get_mesh_color() -> Color:
	assert(has_color(), "color property not available")
	return _mesh_color.get_value()

func get_mesh_color_rgb() -> Vector3:
	var color = get_mesh_color()
	return Vector3(color.r, color.g, color.b)

func get_mesh_color_opacity() -> float:
	return get_mesh_color().a

func get_mesh_color_transparency() -> float:
	var t = 1.0 - get_mesh_color_opacity()
	if t < 0.0:
		return 0.0
	if t > 1.0:
		return 1.0
	return t
