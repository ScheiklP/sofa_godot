tool
extends EditorPlugin
##
## @author: Pit Henrich, Christoph Haas
## @desc: A plugin for creating SOFA scenes in Godot.
##

const SofaPropertyFilter = preload("res://addons/sofa_godot_plugin/sofa_python/properties/sofa_property_filter.gd")

func _enter_tree():
	# property filters
	add_inspector_plugin(SofaPropertyFilter.make_plugin())

	add_custom_type(
		"SofaPythonRoot",
		"Node",
		preload("res://addons/sofa_godot_plugin/sofa_python/sofa_python_root.gd"),
		preload("icons/sofa_python_icon.png")
	)

	add_custom_type(
		"SofaCoreNode",
		"Node",
		preload("res://addons/sofa_godot_plugin/sofa_python/sofa_core/sofa_core_node.gd"),
		preload("icons/sofa_node_icon.png")
	)

	add_custom_type(
		"SofaCoreObject",
		"Node",
		preload("res://addons/sofa_godot_plugin/sofa_python/sofa_core/sofa_core_object.gd"),
		preload("icons/sofa_object_icon.png")
	)

	add_custom_type(
		"SofaRequiredPlugin",
		"Node",
		preload("res://addons/sofa_godot_plugin/sofa_python/sofa_components/simulation/sofa_required_plugin.gd"),
		preload("icons/sofa_object_icon.png")
	)

	add_custom_type(
		"SofaVisualGrid",
		"Node",
		preload("res://addons/sofa_godot_plugin/sofa_python/sofa_components/visual/sofa_visual_grid.gd"),
		preload("icons/sofa_visual_grid_icon.png")
	)

	add_custom_type(
		"SofaLineAxis",
		"Node",
		preload("res://addons/sofa_godot_plugin/sofa_python/sofa_components/visual/sofa_line_axis.gd"),
		preload("icons/sofa_visual_grid_icon.png")
	)

	add_custom_type(
		"SofaDirectionalLight",
		"DirectionalLight",
		preload("res://addons/sofa_godot_plugin/sofa_python/sofa_components/gl/shader/sofa_directional_light.gd"),
		preload("icons/sofa_directional_light_icon.png")
	)

	add_custom_type(
		"SofaSphereROI",
		"Spatial",
		preload("res://addons/sofa_godot_plugin/sofa_python/sofa_components/engine/select/sofa_sphere_roi.gd"),
		preload("icons/sofa_aa_sphere_roi_icon.png")
	)

	add_custom_type(
		"SofaOrientedBoxROI",
		"Spatial",
		preload("res://addons/sofa_godot_plugin/sofa_python/sofa_components/engine/select/sofa_oriented_box_roi.gd"),
		preload("icons/sofa_aa_box_roi_icon.png")
	)

	add_custom_type(
		"SofaNearestPointROI",
		"Node",
		preload("res://addons/sofa_godot_plugin/sofa_python/sofa_components/engine/select/sofa_nearest_point_roi.gd"),
		preload("icons/sofa_aa_sphere_roi_icon.png")
	)

	add_custom_type(
		"SofaFixedConstraint",
		"Node",
		preload("res://addons/sofa_godot_plugin/sofa_python/sofa_components/constraint/projective/sofa_fixed_constraint.gd"),
		preload("icons/sofa_fixed_constraint_icon.png")
	)

	add_custom_type(
		"SofaPartialFixedConstraint",
		"Node",
		preload("res://addons/sofa_godot_plugin/sofa_python/sofa_components/constraint/projective/sofa_partial_fixed_constraint.gd"),
		preload("icons/sofa_fixed_constraint_icon.png")
	)

	add_custom_type(
		"SofaAttachConstraint",
		"Node",
		preload("res://addons/sofa_godot_plugin/sofa_python/sofa_components/constraint/projective/sofa_attach_constraint.gd"),
		preload("icons/sofa_attach_constraint_icon.png")
	)

	add_custom_type(
		"SofaEnvCamera",
		"Camera",
		preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/camera/sofa_env_camera.gd"),
		preload("icons/sofa_env_camera_icon.png")
	)

	add_custom_type(
		"SofaEnvPluginNode",
		"Node",
		preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/scene_header/sofa_env_plugin_node.gd"),
		preload("icons/python_icon.png")
	)

	add_custom_type(
		"SofaEnvSceneHeader",
		"Node",
		preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/scene_header/sofa_env_scene_header.gd"),
		preload("icons/python_icon.png")
	)

	add_custom_type(
		"SofaEnvSolver",
		"Node",
		preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/solver/sofa_env_solver.gd"),
		preload("icons/python_icon.png")
	)

	add_custom_type(
		"SofaEnvVisualModel",
		"Spatial",
		preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/visual/sofa_env_visual_model.gd"),
		preload("icons/python_icon.png")
	)

	add_custom_type(
		"SofaEnvCollisionModel",
		"Spatial",
		preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/collision/sofa_env_collision_model.gd"),
		preload("icons/python_icon.png")
	)

	add_custom_type(
		"SofaEnvRigidObject",
		"Spatial",
		preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/rigid/rigid_object.gd"),
		preload("icons/sofa_python_icon.png")
	)

	add_custom_type(
		"SofaEnvControllableRigidObject",
		"Spatial",
		preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/rigid/controllable_rigid_object.gd"),
		preload("icons/sofa_python_icon.png")
	)

	add_custom_type(
		"SofaEnvDeformableObject",
		"Spatial",
		preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/deformable/deformable_object.gd"),
		preload("icons/sofa_python_icon.png")
	)

	add_custom_type(
		"SofaEnvCuttableDeformableObject",
		"Spatial",
		preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/deformable/cuttable_deformable_object.gd"),
		preload("icons/sofa_python_icon.png")
	)

	add_custom_type(
		"SofaEnvFixedConstraintInBoundingBox",
		"Spatial",
		preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/motion_restriction/add_fixed_constraint_in_bounding_box.gd"),
		preload("icons/python_icon.png")
	)

	add_custom_type(
		"SofaEnvCauter",
		"Node",
		preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/instruments/cauter/cauter.gd"),
		preload("icons/sofa_python_icon.png")
	)

func _exit_tree():
	remove_custom_type("SofaPythonRoot")

	remove_custom_type("SofaCoreNode")
	remove_custom_type("SofaCoreObject")

	remove_custom_type("SofaRequiredPlugin")

	remove_custom_type("SofaVisualGrid")
	remove_custom_type("SofaLineAxis")

	remove_custom_type("SofaDirectionalLight")
	
	remove_custom_type("SofaSphereROI")
	remove_custom_type("SofaOrientedBoxROI")
	remove_custom_type("SofaNearestPointROI")

	remove_custom_type("SofaFixedConstraint")
	remove_custom_type("SofaPartialFixedConstraint")
	remove_custom_type("SofaAttachConstraint")

	remove_custom_type("SofaEnvPluginNode")
	remove_custom_type("SofaEnvSceneHeader")
	remove_custom_type("SofaEnvCamera")

	remove_custom_type("SofaEnvSolver")
	remove_custom_type("SofaEnvVisualModel")
	remove_custom_type("SofaEnvCollisionModel")

	remove_custom_type("SofaEnvRigidObject")
	remove_custom_type("SofaEnvControllableRigidObject")
	remove_custom_type("SofaEnvDeformableObject")
	remove_custom_type("SofaEnvCuttableDeformableObject")
	remove_custom_type("SofaEnvCauter")
