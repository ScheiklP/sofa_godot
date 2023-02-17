tool
extends Camera
##
## @author: Christoph Haas
##
## @desc: Encapsulate sofa_env [code]Camera[/code].
## 
##
#class_name SofaEnvCamera

func get_class() -> String:
	return "SofaEnvCamera"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) || (clazz == get_class())

func _set(property: String, value) -> bool:
	return _registry.handle_set(property, value)
func _get(property: String):
	return _registry.handle_get(property)
func _get_property_list() -> Array:
	return _registry.gen_property_list()

const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")
const PyStatementProperties = preload("res://addons/sofa_godot_plugin/sofa_python/properties/py_statement_properties.gd")

const sofa_env            = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/sofa_env_modules.gd")
const PyProgram           = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_program.gd")
const PyCallable          = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_callable.gd")
const PyCallableStatement = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_callable_statement.gd")

## see [SofaPropertyFilter]
const DISCARDED_PROPERTIES = [
	"h_offset",
	"v_offset",
	"environment",
	"cull_mask",
	"current",
	"doppler_tracking",
	"projection",
	"keep_aspect"
]

const MODULE = sofa_env.sofa_templates.camera
const CLASS_NAME = "Camera"
const OBJECT_NAME = "camera"
const cat_camera = "sofa_env Camera"

var _camera:    PyCallableStatement
var _registry = PropertyWrapperRegistry.new(self)
var _py_props = PyStatementProperties.new(self, _registry)

func _init():
	set_name(OBJECT_NAME)
	_setup_properties()
	_setup_camera()

func _enter_tree():
	_update_viewport()

func get_python_identifier() -> String:
	return _py_props.get_identifier()

func process_python(program: PyProgram, parent_identifier: String, indent_depth: int):
	assert(parent_identifier == program.get_sofa_root_identifier(), "Expected root node as parent")
	_py_props.update_statement(_camera)
	_camera.get_argument("root_node").set_value(parent_identifier)
	_camera.write_to_program(program, indent_depth)

func _setup_properties():
	fov = 45 # default value
	_registry.make_int(320, "width_viewport")\
		.range_hint("0,16384")\
		.category(cat_camera)\
		.callback(self, "_on_update_viewport")
	_registry.make_int(320, "height_viewport")\
		.range_hint("0,16384")\
		.category(cat_camera)\
		.callback(self, "_on_update_viewport")
	_registry.make_float(250, "zoomSpeed").category(cat_camera)
	_registry.make_float(0.1, "panSpeed").category(cat_camera)
	_registry.make_float(2, "pivot").category(cat_camera)
	_py_props.register()

func _on_update_viewport(source_path: String, old_value: int, new_value: int):
	_update_viewport()

func _update_viewport():
	ProjectSettings.set_setting("display/window/size/width",  _registry.get_value("width_viewport"))
	ProjectSettings.set_setting("display/window/size/height", _registry.get_value("height_viewport"))

func _setup_camera():
	_camera = PyCallableStatement.new(PyCallable.new(CLASS_NAME))
	_camera.add_import(MODULE, CLASS_NAME)
	_camera.add_plugin_list(MODULE, MODULE.plugin_list)
	var args = _camera.arguments().with_registry(_registry)
	## The SOFA node to which the `InteractiveCamera object is added. Should be the root node.
	args.add_plain("root_node").required(true).position(0).as_identifier()
	## Dictionary to specify the initial placement of the camera.
	var placement_kwargs = args.add_dictionary("placement_kwargs")
	placement_kwargs.add_plain("position", Vector3.ZERO).bind(self, "get_translation").required(true)
	placement_kwargs.add_plain("lookAt",   Vector3.ZERO).bind(self, "get_look_at").required(true)
	# TODO: SOFA complains about 'too many missing parameters...' when orientation is set
	#placement_kwargs.add_plain("orientation", Quat.IDENTITY).bind(self, "get_orientation")
	#placement_kwargs.add_property("distance").required(true)
	placement_kwargs.add_property("zoomSpeed").required(true)
	placement_kwargs.add_property("panSpeed").required(true)
	placement_kwargs.add_property("pivot").required(true)
	## The vertical field of view in degrees of the camera.
	## The horizontal field of view is determined by the aspect ratio through width and height of the viewport.
	args.add_plain("vertical_field_of_view", fov).bind(self, "get_vertical_fov").required(true)
	## Minimum distance of objects to the camera. Objects that are closer than this value will not be rendered.
	args.add_plain("z_near", near).bind(self, "get_z_near").required(true)
	## Maximum distance of objects to the camera. Objects further away than this value will not be rendered.
	args.add_plain("z_far", far).bind(self, "get_z_far").required(true)
	## Width of the rendered images.
	args.add_property("width_viewport").required(true)
	## Height of the rendered images.
	args.add_property("height_viewport").required(true)


func get_vertical_fov() -> int:
	return int(round(fov))

func get_position() -> Vector3:
	return translation

func get_look_at() -> Vector3:
	return get_global_transform().basis.z

func get_orientation() -> Quat:
	return transform.basis.get_rotation_quat()

func get_z_near() -> float:
	return near

func get_z_far() -> float:
	return far

