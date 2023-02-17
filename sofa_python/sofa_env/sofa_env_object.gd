const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")

const sofa_env = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/sofa_env_modules.gd")
const PyContext = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_python_context.gd")
const SofaEnvSceneHeader = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/scene_header/sofa_env_scene_header.gd")

static func get_animation_loop_type(registry: PropertyWrapperRegistry, property_path: String = "animation_loop") -> String:
	match registry.get_value(property_path):
		"use_scene_header":
			if PyContext.is_scene_tree_ready():
				var root_node = PyContext.get_scene_root()
				if root_node != null:
					for child in root_node.get_children():
						if child is SofaEnvSceneHeader:
							return child.get_animation_loop()
			#push_warning("Cannot infer animation_loop_type: No SofaEnvSceneHeader present")
			return sofa_env.sofa_templates.scene_header.AnimationLoopType["DEFAULT"]
		var type:
			return type

## get object pose as array containing translation followed by orientation as quaternion
static func get_pose(node: Spatial) -> Array:
	var t = node.transform.origin
	var q = node.transform.basis.get_rotation_quat()
	return [t.x, t.y, t.z, q.x, q.y, q.z, q.w]