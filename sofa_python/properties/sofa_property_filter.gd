##
## @author: Christoph Haas
##
## @desc: Disable properties of godot types which the respective sofa(_env) type does not have a counterpart to
## 
extends Reference

const PropertyFilterPlugin = preload("res://addons/sofa_godot_plugin/property_wrappers/property_filter_plugin.gd")

const SofaEnvCamera        = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/camera/sofa_env_camera.gd")
const DirectionalLight     = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_components/gl/shader/sofa_directional_light.gd")

## [PropertyFilterPlugin] for SOFA components
static func make_plugin() -> PropertyFilterPlugin:
	return PropertyFilterPlugin.new(
		{
			SofaEnvCamera:    SofaEnvCamera.DISCARDED_PROPERTIES,
			DirectionalLight: DirectionalLight.DISCARDED_PROPERTIES,
		}
	)
