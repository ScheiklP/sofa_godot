tool
extends DirectionalLight
##
## @author: René Chlebecek, Christoph Haas
## @desc: SOFA directional light
##
## https://github.com/sofa-framework/sofa/blob/master/Sofa/GL/Component/Shader/src/sofa/gl/component/shader/Light.h
##

func get_class() -> String:
	return "SofaDirectionalLight"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) or (clazz == get_class())

func _get_property_list() -> Array:
	return _registry.gen_property_list()
func _set(property: String, value) -> bool:
	return _registry.handle_set(property, value)
func _get(property: String):
	return _registry.handle_get(property)

const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")
const PyProgram = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_program.gd")

## see [SofaPropertyFilter]
const DISCARDED_PROPERTIES = [
	"directional_shadow_bias_split_scale",
	"directional_shadow_blend_splits",
	"directional_shadow_depth_range",
	"directional_shadow_max_distance",
	"directional_shadow_mode",
	"directional_shadow_normal_bias",
	"directional_shadow_split_1",
	"directional_shadow_split_2",
	"directional_shadow_split_3",
	"light_energy",
	"light_indirect_energy",
	"light_negative",
	"light_specular",
	"light_bake_mode",
	"light_cull_mask",
	"shadow_enabled",
	"shadow_color",
	"shadow_bias",
	"shadow_contact",
	"shadow_reverse_cull_face",
	"editor_only",
	"layers",
	"portal_mode",
	"include_in_bound",
	"autoplace_priority",
]

var _registry = PropertyWrapperRegistry.new(self)
var _light: DirectionalLightObject

func _init():
	_light = DirectionalLightObject.new(self, _registry)

func process_python(program: PyProgram, parent_identifier: String, indent_depth: int):
	_light.process(program, parent_identifier, indent_depth)



## <assignee> = <node>.addObject("DirectionalLight", name=<name>, ...)
class DirectionalLightObject:
	extends "res://addons/sofa_godot_plugin/sofa_python/sofa_components/sofa_object_base.gd"

	const MODULE = "Sofa.GL.Component.Shader"
	const TYPE = "DirectionalLight"

	const cat_light = "Sofa Directional Light"

	func _init(node: DirectionalLight, registry: PropertyWrapperRegistry).(TYPE, node, registry):
		pass

	# @override
	func _setup_statement():
		var args = arguments().with_registry(_registry)
		args.add_plain("name").position(1).bind(_node, "get_name")
		args.add_plain("color").required(true).bind(_node, "get_color")
		args.add_plain("direction").required(true).bind(self, "get_light_direction")

	# @override
	func get_node() -> DirectionalLight:
		return _node as DirectionalLight

	func get_light_direction() -> Vector3:
		# Careful: self.rotation_degrees doesn't work for SOFA as no compatibility with euler angles is given.
		# a directional vector has to be used as input for the SOFA object
		# the original orientation of the light when added to GODOT is [0,0,-1] hence the transformation
		# of this vector
		# In this case the orientation has to be inverted, to work as intented -> [0,0,1]
		var light_direction = get_node().transform.basis * Vector3(0,0,1)
		return light_direction
