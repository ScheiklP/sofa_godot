extends Reference
##
## @author: Christoph Haas
##
## @desc: Conveniently expose instances of [PropertyWrapper] to godot's editor inspector [EditorInspector].
## See https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_exports.html#advanced-exports
##
## Usage:
## See example in [PropertyWrapperTest] (res://addons/sofa_godot_plugin/property_wrappers/test/property_wrapper_test.gd)
##
##[codeblock]
##    tool
##    extends Spatial
##    
##    const PropertyWrapperRegistry =  preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")
##    
##    var registry = PropertyWrapperRegistry.new()
##    
##    var _my_property = registry.make_float(1.0, "path/to/my_property")\
##                               .category("My Properties")\
##                               .range_hint("-4,16,1")\
##                               .validate(self, "validate_my_property"))
##    
##    func _set(property: String, value) -> bool:
##        return registry.handle_set(property, value)
##    
##    func _get(property: String):
##        return registry.handle_get(property)
##    
##    func _get_property_list() -> Array:
##        return registry.gen_property_list()
##    
##    func validate_my_property(value: float) -> bool:
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

#class_name PropertyWrapperRegistry
func get_class() -> String:
	return "PropertyWrapperRegistry"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) || (clazz == get_class())


const PropertyWrapper         = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper.gd")
const BoolPropertyWrapper     = preload("res://addons/sofa_godot_plugin/property_wrappers/bool_property_wrapper.gd")
const IntPropertyWrapper      = preload("res://addons/sofa_godot_plugin/property_wrappers/number_property_wrapper.gd").IntPropertyWrapper
const FloatPropertyWrapper    = preload("res://addons/sofa_godot_plugin/property_wrappers/number_property_wrapper.gd").FloatPropertyWrapper
const Vector2PropertyWrapper  = preload("res://addons/sofa_godot_plugin/property_wrappers/vector_property_wrapper.gd").Vector2PropertyWrapper
const Vector3PropertyWrapper  = preload("res://addons/sofa_godot_plugin/property_wrappers/vector_property_wrapper.gd").Vector3PropertyWrapper
const StringPropertyWrapper   = preload("res://addons/sofa_godot_plugin/property_wrappers/string_property_wrapper.gd")
const NodePathPropertyWrapper = preload("res://addons/sofa_godot_plugin/property_wrappers/node_path_property_wrapper.gd")
const ColorPropertyWrapper    = preload("res://addons/sofa_godot_plugin/property_wrappers/color_property_wrapper.gd")
const ArrayPropertyWrapper   = preload("res://addons/sofa_godot_plugin/property_wrappers/array_property_wrapper.gd")
const DictionaryPropertyWrapper   = preload("res://addons/sofa_godot_plugin/property_wrappers/dictionary_property_wrapper.gd")
const EnumPropertyWrapper     = preload("res://addons/sofa_godot_plugin/property_wrappers/enum_property_wrapper.gd")
const FlagsPropertyWrapper    = preload("res://addons/sofa_godot_plugin/property_wrappers/flags_property_wrapper.gd")
const MeshPropertyWrapper     = preload("res://addons/sofa_godot_plugin/property_wrappers/mesh_property_wrapper.gd")

const UNCATEGORIZED : String = "UNCATEGORIZED"

signal property_list_changed()

var _wrapped_properties = {}
var _category_comparator: FuncRef = null

func _init(property_owner: Object = null, properties: Array = []):
	if property_owner != null:
		_add_property_list_changed_callback(property_owner)
	for property in properties:
		assert(not is_registered(property.get_inspector_path()), "property already registered")
		register(property)

## Call [method Object.property_list_changed_notify] on the property_owner in order to
## immediatly update the editor inspector display when the property was changed
## through a registry operation, e.g. [method toogle_path].
func _add_property_list_changed_callback(property_owner: Object): 
	if not self.is_connected("property_list_changed", property_owner, "property_list_changed_notify"):
		var error = self.connect("property_list_changed", property_owner, "property_list_changed_notify")
		assert(error == OK, "Connecting property list changed failed")


func register(property: PropertyWrapper) -> PropertyWrapper:
	if property == null or _wrapped_properties.has(property.get_inspector_path()):
		return null
	# issue warning if properties have a common path prefix but differ in category
	_validate_category_vs_path_compliance()
	# 'register' property by adding it to dictionary
	_wrapped_properties[property.get_inspector_path()] = property 
	#emit_signal("property_list_changed")
	return property

func unregister(path: String) -> PropertyWrapper:
	var prop = null
	if is_registered(path):
		prop = _wrapped_properties[path]
		_wrapped_properties.erase(path)
	return prop

func is_registered(path: String) -> bool:
	return _wrapped_properties.has(path)


func _get_property_wrapper(path: String) -> PropertyWrapper:
	return _wrapped_properties[path] if is_registered(path) else null


func set_value(path: String, value) -> bool:
	return _wrapped_properties[path].set_value(value) if is_registered(path) else false

func get_value(path: String):
	return _wrapped_properties[path].get_value() if is_registered(path) else null


## enable all properties below the specified inspector path
## for changes to take effect immediatly call [method Object.property_list_changed_notify]
func enable_path(path: String):
	toogle_path(path, true)

## disable all properties below the specified inspector path
## for changes to take effect immediatly call [method Object.property_list_changed_notify]
func disable_path(path: String):
	toogle_path(path, false)

## enable/disable all the properties belowt the specified inspector path
## for changes to take effect immediatly call [method Object.property_list_changed_notify]
func toogle_path(path: String, enable: bool):
	var signal_change = false
	for prop_path in _get_properties_below_path(path): 
		#var op = "Enabling" if enable else "Disabling"
		#print(op, " property: ", prop_path)
		signal_change = signal_change or (enable != _wrapped_properties[prop_path].is_enabled())
		_wrapped_properties[prop_path].set_enabled(enable)
	if signal_change:
		emit_signal("property_list_changed")

func _get_properties_below_path(path: String) -> Array:
	var keys_below_path = []
	for key in _wrapped_properties.keys():
		var prop : PropertyWrapper = _wrapped_properties[key]
		if prop.get_inspector_path().begins_with(path):
			keys_below_path.append(key)
	return keys_below_path


## enable all the properties belonging to the specified inspector category
## for changes to take effect immediatly call [method Object.property_list_changed_notify]
func enable_category(category: String):
	toogle_category(category, true)

## disable all the properties belonging to the specified inspector category
## for changes to take effect immediatly call [method Object.property_list_changed_notify]
func disable_category(category: String):
	toogle_category(category, false)

## enable/disable all the properties belonging to the specified inspector category
## for changes to take effect immediatly call [method Object.property_list_changed_notify]
func toogle_category(category: String, enable: bool):
	var categories = _group_by_category()
	assert(categories.has(category), "Unknown category specified")
	var signal_change = false
	for prop_path in categories[category]:
		signal_change = signal_change or (enable != _wrapped_properties[prop_path].is_enabled())
		_wrapped_properties[prop_path].set_enabled(enable)
	if signal_change:
		emit_signal("property_list_changed")

#func get_categories() -> Array:
#	return _group_by_category().keys()

## group (enabled) properties by their category
func _group_by_category(include_disabled_props: bool = true) -> Dictionary:
	var categories = {}
	for prop_path in _wrapped_properties.keys():
		var prop : PropertyWrapper = _wrapped_properties[prop_path]
		if include_disabled_props or prop.is_enabled():
			var cat: String = prop.get_inspector_category()
			assert(cat != UNCATEGORIZED, "Invalid category name")
			cat = UNCATEGORIZED if cat.empty() else cat
			if categories.has(cat):
				categories[cat].append(prop_path)
			else:
				categories[cat] = [prop_path]
	if has_category_order():
		var category_order = _category_comparator.call_func(categories.keys().duplicate(true))
		assert(category_order.size() == categories.size(), "invalid category comparator result")
		var sorted_categories = {}
		for cat in category_order:
			assert(cat in categories.keys(), "Unknown category: '" + cat + "'")
			sorted_categories[cat] = categories[cat]
		categories = sorted_categories
	return categories

func set_category_order(comparator: FuncRef):
	_category_comparator = comparator
	emit_signal("property_list_changed")

func has_category_order() -> bool:
	return _category_comparator != null

func reset_category_order():
	var changed = has_category_order()
	_category_comparator = null
	if changed:
		emit_signal("property_list_changed")

func gen_property_list() -> Array:
	# issue warning if properties have a common path prefix but differ in category
	_validate_category_vs_path_compliance()
	var properties = []
	# retrieve (enabled!) properties grouped by their respective inspector category
	var categories = _group_by_category(false)
	# ensure uncategorized properties come first
	if categories.has(UNCATEGORIZED):
		#assert(!categories[UNCATEGORIZED].empty())
		for prop_path in categories[UNCATEGORIZED]:
			properties.append(_wrapped_properties[prop_path].get_inspector_entry())
		categories.erase(UNCATEGORIZED)
	# add remaining categories in order of appearance
	for cat in categories:
		#assert(!categories[cat].empty())
		# add category entry
		properties.append(_gen_category_entry(cat))
		# add properties below category entry
		for prop_path in categories[cat]:
			properties.append(_wrapped_properties[prop_path].get_inspector_entry())
	return properties

func _gen_category_entry(category: String) -> Dictionary:
	return {
		"name": category,
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_CATEGORY | PROPERTY_USAGE_STORAGE,
	}

func _validate_category_vs_path_compliance():
	# editor inspector cannot handle properties with same path prefix but different categories
	# hence, properties with common path prefix must be within the same category in order to be displayed correctly
	var keys = _wrapped_properties.keys()
	for i in range(keys.size()):
		for j in range(i+1, keys.size()):
			var p1 = _wrapped_properties[keys[i]]
			var p2 = _wrapped_properties[keys[j]]
			# check common path prefix
			if p2.get_inspector_path().split("/")[0] == p1.get_inspector_path().split("/")[0]:
				# warn if categories differ
				if p2.get_inspector_category() != p1.get_inspector_category():
					var warning_msg = "Properties '"\
						+ p1.get_inspector_path() + "' and '" + p2.get_inspector_path()\
						+ "' share a common path prefix but are assigned to different categories: '"\
						+ p1.get_inspector_category() + "' != '" + p2.get_inspector_category() + "'.\n"\
						+ "This results in incorrect display of properties in the editor inspector."
					push_warning(warning_msg)


func handle_set(path: String, value) -> bool:
	if not _wrapped_properties.has(path):
		return false
	return _wrapped_properties[path].set_inspector_property(path, value)

func handle_get(path: String):
	if not _wrapped_properties.has(path):
		return null
	return _wrapped_properties[path].get_inspector_property(path)


# convenience functions for property generation

## create a wrapped [code]bool[/code] property
func make_bool(value: bool, inspector_path: String) -> BoolPropertyWrapper:
	var prop = BoolPropertyWrapper.new(inspector_path, value)
	return register(prop) as BoolPropertyWrapper

## create a wrapped [code]int[/code] property
func make_int(value: int, inspector_path: String) -> IntPropertyWrapper:
	var prop = IntPropertyWrapper.new(inspector_path, value)
	return register(prop) as IntPropertyWrapper

## create a wrapped [code]float[/code] property
func make_float(value: float, inspector_path: String) -> FloatPropertyWrapper:
	var prop = FloatPropertyWrapper.new(inspector_path, value)
	return register(prop) as FloatPropertyWrapper

## create a wrapped [Vector2] property
func make_vector2(vector: Vector2, inspector_path: String) -> Vector2PropertyWrapper:
	var prop = Vector2PropertyWrapper.new(inspector_path, vector)
	return register(prop) as Vector2PropertyWrapper

## create a wrapped [Vector3] property
func make_vector3(vector: Vector3, inspector_path: String) -> Vector3PropertyWrapper:
	var prop = Vector3PropertyWrapper.new(inspector_path, vector)
	return register(prop) as Vector3PropertyWrapper

## create a wrapped [String] property
func make_string(value: String, inspector_path: String) -> StringPropertyWrapper:
	var prop = StringPropertyWrapper.new(inspector_path, value)
	return register(prop) as StringPropertyWrapper

## create a wrapped [NodePath] property
func make_node_path(node_path: NodePath, inspector_path: String) -> NodePathPropertyWrapper:
	var prop = NodePathPropertyWrapper.new(inspector_path, node_path)
	return register(prop) as NodePathPropertyWrapper

## create a wrapped [Color] property
func make_color(color: Color, inspector_path: String) -> ColorPropertyWrapper:
	var prop = ColorPropertyWrapper.new(inspector_path, color)
	return register(prop) as ColorPropertyWrapper

## create a wrapped [Array] property
func make_array(array: Array, inspector_path) -> ArrayPropertyWrapper:
	var prop = ArrayPropertyWrapper.new(inspector_path, array)
	return register(prop) as ArrayPropertyWrapper

## create a wrapped [Dictionary] property
func make_dict(dict: Dictionary, inspector_path: String) -> DictionaryPropertyWrapper:
	var prop = DictionaryPropertyWrapper.new(inspector_path, dict)
	return register(prop) as DictionaryPropertyWrapper

## create a wrapped [code]enum[/code] property,
## i.e. choose one option among the supplied set of options
func make_enum(options: Dictionary, inspector_path: String) -> EnumPropertyWrapper:
	var prop = EnumPropertyWrapper.new(inspector_path, options)
	return register(prop) as EnumPropertyWrapper

## create a wrapped flags property,
## i.e. choose arbitrary many options among the supplied set of options
func make_flags(options: Dictionary, inspector_path: String) -> FlagsPropertyWrapper:
	var prop = FlagsPropertyWrapper.new(inspector_path, options)
	return register(prop) as FlagsPropertyWrapper

## create a wrapped [Mesh] property
func make_mesh(mesh: Mesh, inspector_path: String) -> MeshPropertyWrapper:
	var prop = MeshPropertyWrapper.new(inspector_path, mesh)
	return register(prop) as MeshPropertyWrapper

#func _make_property_wrapper(Wrapper: GDScript, value, inspector_path: String):
#	var prop = Wrapper.new(inspector_path, value)
#	return register(prop)
