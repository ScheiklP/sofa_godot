extends "res://addons/sofa_godot_plugin/property_wrappers/property_wrapper.gd"
##
## @author: Christoph Haas
##
## @desc:
##	Multiple choice property exposed to the editor inspector as [code]PROPERTY_HINT_FLAGS[/code]
##

#class_name FlagsPropertyWrapper
func get_class() -> String:
	return "FlagsPropertyWrapper"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) || (clazz == get_class())

var _options: Dictionary
var _selection: Array


func _init(inspector_path: String, options: Dictionary, keys: Array = []).(inspector_path):
	_options = options.duplicate(true)
	assert(!_options.empty(), "empty dictionary")
	if keys.size() == 0:
		# default: select all available options
		_selection = _options.keys().duplicate(true)
	else:
		_selection = []
		for option_key in keys:
			#assert(typeof(key) == TYPE_STRING)
			assert(_options.has(option_key), "Unknown option")
			assert(not option_key in _selection, "Duplicate option")
			_selection.append(option_key)


## intended for builder pattern use, e.g.
## [codeblock]
##    var property = FlagsPropertyWrapper
##        .new("path/to/property", {"a":1, "b":2})
##        .select(["a"])
## [/codeblock]
func select(options: Array):
	_selection.clear()
	for option_key in options:
		#assert(typeof(key) == TYPE_STRING)
		assert(has_option(option_key), "Unknown option")
		assert(not option_key in _selection, "Duplicate option")
		_selection.append(option_key)
	return self

## return the keys of selected options
func get_selected_keys() -> Array:
	return _selection.duplicate(true)

## check if option is among the available choices
func has_option(option) -> bool:
	return _options.has(option)

## check if option is selected
func is_selected(option) -> bool:
	assert(has_option(option), "Unknown option")
	return option in _selection

## return all the available option keys
func get_options_keys() -> Array:
	return _options.keys()

## returns a list of booleans specifying for each available option if it is selected or not
func get_selection_mask() -> Array:
	var mask = []
	for option in _options.keys():
		mask.append(is_selected(option))
	return mask


func _set_value(selected_keys: Array) -> bool:
	# ensure the specified options are available
	for key in selected_keys:
		if !(key in get_options_keys()):
			push_warning("[FlagsPropertyWrapper::_set_value]: invalid option key")
			return false

	_selection = selected_keys.duplicate(true)
	return true

func get_value() -> Array:
	var selected_options = []
	for key in _selection:
		selected_options.append(_options[key])
	return selected_options


func get_inspector_property(path: String):
	if path != get_inspector_path():
		return null
	var flag : int = 0
	var keys = get_options_keys()
	for idx in range(keys.size()):
		# if identifier selected then set corresponding bit
		if keys[idx] in _selection:
			flag = flag | (1 << idx)
	return flag

func set_inspector_property(path: String, value: int) -> bool:
	if path != get_inspector_path():
		return false
	var flag : int = value
	var keys = get_options_keys()
	var selected_keys = []
	for idx in range(keys.size()):
		# if bit set then append corresponding string identifier
		if (flag & (1 << idx)):
			selected_keys.append(keys[idx])
	#_selection = selected_keys
	set_value(selected_keys)
	return true

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
		"type":  TYPE_INT,
		"hint":  PROPERTY_HINT_FLAGS,
		"hint_string": option_str
	}