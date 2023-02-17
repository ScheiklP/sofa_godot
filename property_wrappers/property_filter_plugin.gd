extends EditorInspectorPlugin
##
## @author: Christoph Haas
##
## @desc: Hide properties of godot [Object]s
## https://docs.godotengine.org/en/stable/tutorials/plugins/editor/inspector_plugins.html
##
#class_name PropertyFilterPlugin

var _filters: Dictionary = {}

func _init(filters: Dictionary):
	for Type in filters.keys():
		add_filter(Type, filters[Type])
	
func find_type(property_owner) -> GDScript:
	for Type in _filters.keys():
		if property_owner is Type:
			return Type
	return null

func add_filter(Type: GDScript, discarded_properties: Array):
	_filters[Type] = discarded_properties.duplicate(true)

func can_handle(property_owner) -> bool:
	return find_type(property_owner) != null
	
# return true if this [EditorInspectorPlugin] should handle the property at path
func parse_property(property_owner, type: int, path: String, hint: int, hint_text: String, usage: int) -> bool:
	var Type = find_type(property_owner)
	return false if Type == null else (path in _filters[Type]) 
