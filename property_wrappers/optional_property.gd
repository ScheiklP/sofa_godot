##
## @author: Christoph Haas
##
## @desc: Wrap python Optional[<type>] 
##
class OptionalProperty:
	extends Reference

	# TODO: use PROPERTY_USAGE_CHECKABLE in inspector_entry and connect to [signal property_toggled] of EditorInterface.get_inspector

	func get_class() -> String:
		return "OptionalProperty"
	func is_class(clazz: String) -> bool:
		return .is_class(clazz) || (clazz == get_class())

	const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")
	const PropertyWrapper = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper.gd")
	const EnumPropertyWrapper = preload("res://addons/sofa_godot_plugin/property_wrappers/enum_property_wrapper.gd")

	enum OPTION {
		NONE,
		SOME
	}

	const OPTIONAL = {
		"None": OPTION.NONE,
		"Some": OPTION.SOME
	}

	var _path: String
	var _property: PropertyWrapper
	var _option: EnumPropertyWrapper
	var _registry: PropertyWrapperRegistry
	
	func _init(registry: PropertyWrapperRegistry, PropertyType: GDScript, path: String, initial_value):
		assert(not registry.is_registered(path), "path already taken")
		_registry = registry
		_path     = path
		_option   = _registry.make_enum(OPTIONAL, _path + "/optional").callback(self, "_on_option_selected")
		_property = _registry.register(PropertyType.new(_path + "/value", initial_value))
		_update_optional()

	func _on_option_selected(source_path: String, old_value: int, new_value: int):
		_update_optional()

	func _update_optional():
		_registry.toogle_path(_property.get_inspector_path(), is_some() and is_enabled())

	func category(category: String):
		_option.category(category)
		_property.category(category)
		_registry.emit_signal("property_list_changed")
		return self

	func get_category() -> String:
		return _option.get_inspector_category()

	func enabled(enabled: bool):
		set_enabled(enabled)
		return self

	func is_enabled() -> bool:
		return _option.is_enabled()

	func set_enabled(enabled: bool):
		_registry.toogle_path(_option.get_inspector_path(), enabled)
		_update_optional()

	func is_some() -> bool:
		return _option.get_value() == OPTION.SOME

	func is_none() -> bool:
		return _option.get_value() == OPTION.NONE

	# panics with a generic message
	func unwrap():
		assert(is_some(), "optional is none")
		return _property.get_value()

	func unwrap_or(default):
		if is_none():
			return default
		else:
			return unwrap()

	func get_inspector_path() -> String:
		return _path

	func _get_option() -> EnumPropertyWrapper:
		return _option

	func _get_property():
		return _property


## Wrap python's Optional[int]
class OptionalIntProperty:
	extends OptionalProperty

	const IntPropertyWrapper = preload("res://addons/sofa_godot_plugin/property_wrappers/number_property_wrapper.gd").IntPropertyWrapper

	func get_class() -> String:
		return "OptionalIntProperty"
	func is_class(clazz: String) -> bool:
		return .is_class(clazz) || (clazz == get_class())

	func _init(registry: PropertyWrapperRegistry, path: String, initial_value: int = 0)\
		.(registry, IntPropertyWrapper, path, initial_value):
		pass

	func range_hint(range_hint: String) -> OptionalIntProperty:
		_get_property().range_hint(range_hint)
		return self

	func unwrap() -> int:
		return .unwrap()

	func _get_property() -> IntPropertyWrapper:
		return _property as IntPropertyWrapper


## Wrap python's Optional[float]
class OptionalFloatProperty:
	extends OptionalProperty

	const FloatPropertyWrapper = preload("res://addons/sofa_godot_plugin/property_wrappers/number_property_wrapper.gd").FloatPropertyWrapper

	func get_class() -> String:
		return "OptionalFloatProperty"
	func is_class(clazz: String) -> bool:
		return .is_class(clazz) || (clazz == get_class())

	func _init(registry: PropertyWrapperRegistry, path: String, initial_value: float = 0.0)\
		.(registry, FloatPropertyWrapper, path, initial_value):
		pass

	func range_hint(range_hint: String) -> OptionalFloatProperty:
		_get_property().range_hint(range_hint)
		return self

	func unwrap() -> float:
		return .unwrap()

	func _get_property() -> FloatPropertyWrapper:
		return _property as FloatPropertyWrapper
