tool
extends Spatial

func get_class() -> String:
	return "PivotTarget"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) or (clazz == get_class())


var _mesh_node: MeshInstance

func _init():
	_mesh_node = MeshInstance.new()
	_mesh_node.set_mesh(SphereMesh.new())
	_mesh_node.set_surface_material(0, SpatialMaterial.new())
	var material = _mesh_node.get_surface_material(0)
	material.set_feature(SpatialMaterial.FEATURE_TRANSPARENT, true)
	material.set_flag(SpatialMaterial.FLAG_UNSHADED, true)
	material.set_albedo(Color(1.0,0,0,0.2))
	add_child(_mesh_node)


func get_target() -> Vector3:
	return transform.origin
	#return global_transform.origin

#func set_target(target: Vector3):
#	transform.origin = target