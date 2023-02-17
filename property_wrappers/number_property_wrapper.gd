##
## @author: Christoph Haas
##
## @desc:
##	Encapsulate [code]int[/code] property
##
class IntPropertyWrapper: 
	extends "res://addons/sofa_godot_plugin/property_wrappers/property_wrapper.gd"

	#class_name IntPropertyWrapper
	func get_class() -> String:
		return "IntPropertyWrapper"
	func is_class(clazz: String) -> bool:
		return .is_class(clazz) || (clazz == get_class())

	var _number_val: int
	var _range_hint: String


	func _init(inspector_path: String, value: int, range_hint = "").(inspector_path):
		_number_val = value
		_range_hint = range_hint

	## intended for builder pattern use, e.g.
	## [codeblock]
	##    var property = IntPropertyWrapper
	##        .new("path/to/property", 0)
	##        .range_hint("-360,360,1,or_greater,or_lesser")
	## [/codeblock]
	func range_hint(range_hint: String):
		_range_hint = range_hint
		return self

	func _set_value(value: int) -> bool:
		_number_val = value
		return true


	func get_value() -> int:
		return _number_val


	func set_inspector_property(path: String, value: int) -> bool:
		return set_value(value) if path == get_inspector_path() else false


	func get_inspector_entry() -> Dictionary:
		var entry = {
			"name":  get_inspector_path(),
			"usage": _get_default_usage(),
			"type":  TYPE_INT,
		}
		# add range hint if present
		# example hint: "-360,360,1,or_greater,or_lesser"
		if !_range_hint.empty():
			entry["hint"] = PROPERTY_HINT_RANGE
			entry["hint_string"] = _range_hint
		else:
			entry["hint"] = PROPERTY_HINT_NONE
		return entry


##
## @author: Christoph Haas
##
## @desc: Encapsulate [code]float[/code] property
##
class FloatPropertyWrapper: 
	extends "res://addons/sofa_godot_plugin/property_wrappers/property_wrapper.gd"

	#class_name FloatPropertyWrapper
	func get_class() -> String:
		return "FloatPropertyWrapper"
	func is_class(clazz: String) -> bool:
		return .is_class(clazz) || (clazz == get_class())

	var _number_val: float
	var _range_hint: String


	func _init(inspector_path: String, value: float, range_hint = "").(inspector_path):
		_number_val = value
		_range_hint = range_hint

	## [code]PROPERTY_HINT_RANGE[/code]
	func range_hint(range_hint: String):
		_range_hint = range_hint
		return self


	func _set_value(value: float) -> bool:
		_number_val = value
		return true


	func get_value() -> float:
		return _number_val


	func set_inspector_property(path: String, value: float) -> bool:
		return set_value(value) if path == get_inspector_path() else false


	func get_inspector_entry() -> Dictionary:
		var entry = {
			"name":  get_inspector_path(),
			"usage": _get_default_usage(),
			"type":  TYPE_REAL,
		}
		# add range hint if present
		# example hint: "-360,360,1,or_greater,or_lesser"
		if !_range_hint.empty():
			entry["hint"] = PROPERTY_HINT_RANGE
			entry["hint_string"] = _range_hint
		else:
			entry["hint"] = PROPERTY_HINT_NONE
		return entry
