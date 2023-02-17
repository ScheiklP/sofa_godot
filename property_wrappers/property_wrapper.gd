extends Reference
##
## @author: Christoph Haas
##
## @desc: Common wrapper interface for properties [code]export[/code]ed to the [EditorInspector].
## see: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_exports.html#advanced-exports
##
## Usage:
##[codeblock]
##    tool
##    extends Spatial
##    
##    const FloatPropertyWrapper = preload("res://addons/sofa_godot_plugin/property_wrappers/number_property_wrapper.gd").FloatPropertyWrapper
##    
##    var _my_property = FloatPropertyWrapper\
##        .new("path/to/my_property", 1.0)\
##        .validate(self, "validate_my_property"))
##    
##    func _set(property: String, value) -> bool:
##        if property == _my_property.get_inspector_path():
##            return _my_property.set_inspector_property(value)
##        return false
##    
##    func _get(property: String):
##        if property == _my_property.get_inspector_path():
##            return _my_property.get_inspector_property(property, value)
##        return null
##    
##    func _get_property_list() -> Array:
##        var properties = []
##        properties.append(_my_property.get_inspector_entry())
##        return properties
##    
##    func validate_my_property(property: String, value: float) -> bool:
##       return value > 0
##    
##    func _enter_tree():
##        _my_property.connect("property_wrapper_changed", self, "_on_my_property_changed")
##    
##    func _on_my_property_changed(source_path, old_value, new_value):
##       print("Property '", source_path, "' set to: ", new_value)
##       property_list_changed_notify()
##
##    func _process(delta):
##       var old = _my_property.get_value()
##       _my_property.set_value(delta)
##
##[/codeblock]
##

#class_name PropertyWrapper
func get_class() -> String:
	return "PropertyWrapper"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) || (clazz == get_class())

#signal property_wrapper_enabled(source_path, enabled)
signal property_wrapper_changed(source_path, old_value, new_value)

var _inspector_path: String = ""
var _inspector_category: String = ""
var _enabled: bool = true
var _validate: FuncRef = null

func _init(inspector_path: String):
	assert(!inspector_path.empty(), "empty inspector path")
	_inspector_path = inspector_path

# simplified builder patterns
func category(category: String):
	set_inspector_category(category)
	return self

func enable(enable: bool):
	set_enabled(enable)
	return self

func validate(instance: Object, funcname: String):
	set_validation_func(funcref(instance, funcname))
	return self

# ENHANCEMENT: readonly property, i.e. only modifiable through script
#func readonly(readonly: bool):
#	set_readonly(readonly)
#	return self

## connect [signal property_wrapper_changed] to specified method on target
func callback(target: Object, method: String):
	if not self.is_connected("property_wrapper_changed", target, method):
		var error = self.connect("property_wrapper_changed", target, method)
		assert(error == OK, "Failed to connect property callback")
	return self

## return the value of the wrapped property (override in subclass)
func get_value():
	return null

## set the value of the wrapped property and return [code]true[/code] on success
func set_value(value) -> bool:
	if _validate != null and not _validate.call_func(get_inspector_path(), value):
		#push_warning("Validation failed")
		return false
	var old_value = get_value()
	var success = _set_value(value)
	if success:
		emit_signal("property_wrapper_changed", get_inspector_path(), old_value, get_value())
	return success

## implementation of setting/changing the property's value
## returns [code]true[/code] on success
func _set_value(value) -> bool:
	return false


## return the path of the property within the editor inspector
func get_inspector_path() -> String:
	return _inspector_path


## set the category of the property within the editor inspector
## (use in conjunction with [PropertyWrapperRegistry])
func set_inspector_category(inspector_category: String):
	_inspector_category = inspector_category

## return the category of the property within the editor inspector
## (use in conjunction with [PropertyWrapperRegistry])
func get_inspector_category() -> String:
	return _inspector_category

## enable/disable property
## (use in conjunction with [PropertyWrapperRegistry])
func set_enabled(enable: bool):
	_enabled = enable
#	emit_signal("property_wrapper_enabled", get_inspector_path(), is_enabled())

## check if property is enabled
## (use in conjunction with [PropertyWrapperRegistry])
func is_enabled() -> bool:
	return _enabled


## set a validation function that is to be called before setting the value via [method set_value]
## if [code]validate(new_value)[/code] returns [code]false[/code] then 
## [method set_value] will return [code]false[/code]) while leaving the property's value unchanged
func set_validation_func(validate: FuncRef):
	_validate = validate

func get_validation_func() -> FuncRef:
	return _validate


## handle the call to [method Object._get]
func get_inspector_property(path: String):
	return get_value() if path == get_inspector_path() else null

## handle the call to [method Object._set]
func set_inspector_property(path: String, value) -> bool:
	return false


## handle the call to [method Object._get_property_list]
func get_inspector_entry():
	# return {"usage": _get_default_usage()}
	return {}


## return default usage flag for inspector entry
func _get_default_usage() -> int:
	#	return PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
		return PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_STORAGE
