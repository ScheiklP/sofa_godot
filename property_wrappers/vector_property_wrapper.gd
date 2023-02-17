##
## @author: Christoph Haas
##
## @desc: Encapsulate [Vector2] property
##
class Vector2PropertyWrapper: 
	extends "res://addons/sofa_godot_plugin/property_wrappers/property_wrapper.gd"

	#class_name Vector2PropertyWrapper
	func get_class() -> String:
		return "Vector2PropertyWrapper"
	func is_class(clazz: String) -> bool:
		return .is_class(clazz) || (clazz == get_class())

	var _number_val: Vector2

	func _init(inspector_path: String, value: Vector2).(inspector_path):
		_number_val = value


	func _set_value(value: Vector2) -> bool:
		_number_val = value
		return true


	func get_value() -> Vector2:
		return _number_val


	func set_inspector_property(path: String, value: Vector2) -> bool:
		return set_value(value) if path == get_inspector_path() else false


	func get_inspector_entry() -> Dictionary:
		return {
			"name":  get_inspector_path(),
			"usage": _get_default_usage(),
			"type":  TYPE_VECTOR2,
		}


##
## @author: Christoph Haas
##
## @desc: Encapsulate [Vector3] property
##
class Vector3PropertyWrapper: 
	extends "res://addons/sofa_godot_plugin/property_wrappers/property_wrapper.gd"

	#class_name Vector3PropertyWrapper
	func get_class() -> String:
		return "Vector3PropertyWrapper"
	func is_class(clazz: String) -> bool:
		return .is_class(clazz) || (clazz == get_class())

	var _number_val: Vector3

	func _init(inspector_path: String, value: Vector3).(inspector_path):
		_number_val = value


	func _set_value(value: Vector3) -> bool:
		_number_val = value
		return true


	func get_value() -> Vector3:
		return _number_val


	func set_inspector_property(path: String, value: Vector3) -> bool:
		return set_value(value) if path == get_inspector_path() else false


	func get_inspector_entry() -> Dictionary:
		return {
			"name":  get_inspector_path(),
			"usage": _get_default_usage(),
			"type":  TYPE_VECTOR3,
		}