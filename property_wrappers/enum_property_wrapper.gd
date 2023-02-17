extends "res://addons/sofa_godot_plugin/property_wrappers/property_wrapper.gd"
##
## @author: Christoph Haas
##
## @desc:
##	Single choice property exposed to the editor inspector as [code]PROPERTY_HINT_ENUM[/code]
##

#class_name EnumPropertyWrapper
func get_class() -> String:
	return "EnumPropertyWrapper"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) || (clazz == get_class())

var _options: Dictionary
var _selection: String


func _init(inspector_path: String, options: Dictionary, key: String = "").(inspector_path):
	_options = options.duplicate(true)
	assert(not _options.empty(), "empty dictionary")

	if key.empty():
		_selection = _options.keys()[0]
	else:
		assert(_options.has(key), "unknown key")
		_selection = key

## intended for builder pattern use, e.g.
## [codeblock]
##    var property = EnumPropertyWrapper
##        .new("path/to/property", {"a":1, "b":2})
##        .select("a")
## [/codeblock]
func select(key: String):
	assert(_options.has(key), "unknown key")
	_selection = key
	return self

## select option by value
## if option values are not unique then first matching key is selected
## unless uniquness is required by setting assert_unique
func select_option_by_value(option_value, assert_unique: bool = false):
	var idx = _options.values().find(option_value)
	assert(idx != -1, "Unknown option value")
	# assert that option values are unique
	if assert_unique:
		var last  = _options.values().find_last(option_value)
		assert(idx == last, "option values are not unique")
	select(_options.keys()[idx])
	return self

## return the key of the selected option
func get_selected_option_key() -> String:
	return _selection


## return all the available option keys
func get_options_keys() -> Array:
	return _options.keys()

## _set via string key but _get yields arbitrary type
func _set_value(key: String) -> bool:
	if !_options.has(key):
		return false
	else:
		_selection = key
		return true


func get_value(): # typeof(value) never specified explicitly
	return _options[_selection]


func get_inspector_property(path: String):
	return get_selected_option_key() if path == get_inspector_path() else null

func set_inspector_property(path: String, key: String) -> bool:
	return set_value(key) if path == get_inspector_path() else false


func get_inspector_entry() -> Dictionary:
	var keys = get_options_keys()
	var option_str: String = ""
	for idx in range(keys.size()):
		option_str += keys[idx]
		if idx < keys.size() - 1:
			option_str += ","

	return {
		"name":  get_inspector_path(),
		"usage": _get_default_usage(),
		"type":  TYPE_STRING,
		"hint":  PROPERTY_HINT_ENUM,
		"hint_string": option_str
	}
