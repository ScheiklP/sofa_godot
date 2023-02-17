tool
extends Spatial

func get_class() -> String:
	return "PivotRCM"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) or (clazz == get_class())


const DebugDraw = preload("res://addons/sofa_godot_plugin/debug_draw.gd")

var _debug_drawer: DebugDraw

func _init():
	_debug_drawer = DebugDraw.new()
	add_child(_debug_drawer)


func _process(delta):
	_debug_drawer.draw_line(
		Vector3.ZERO,
		Vector3(1,0,0),
		Color.red
	)
	_debug_drawer.draw_line(
		Vector3.ZERO,
		Vector3(0,1,0),
		Color.green
	)
	_debug_drawer.draw_line(
		Vector3.ZERO,
		Vector3(0,0,1),
		Color.blue
	)


## unscaled rcm pose
func get_rcm_pose() -> Transform:
	#var t = global_transform
	var t = transform
	var scale = t.basis.get_scale()
	var rcm_pose = Transform(
		t.basis.scaled(scale.inverse()),
		t.origin
	)
	return rcm_pose
