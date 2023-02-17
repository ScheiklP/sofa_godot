tool
extends Node
##
## @author: Christoph Haas
## @desc: SOFA NearestPointROI
## 
## Given two mechanical states, find correspondance between degrees of freedom, based on the minimal distance.
## Project all the points from the second mechanical state on the first one.
## This done by finding the point in the first mechanical state closest to each point in the second mechanical state.
## If the distance is less than a provided distance (named radius), the indices of the degrees of freedom in their respective mechanical states is added to an output list.
##
## https://github.com/sofa-framework/sofa/blob/master/Sofa/Component/Engine/Select/src/sofa/component/engine/select/NearestPointROI.h
##

func get_class() -> String:
	return "SofaNearestPointROI"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) or (clazz == get_class())

func _get_property_list() -> Array:
	return _registry.gen_property_list()
func _set(property: String, value) -> bool:
	return _registry.handle_set(property, value)
func _get(property: String):
	return _registry.handle_get(property)

const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")
const PyProgram = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_program.gd")

const OBJECT_NAME = "nearest_point_roi"

var _roi: NearestPointROI
var _registry = PropertyWrapperRegistry.new(self)

func _init():
	set_name(OBJECT_NAME)
	_roi = NearestPointROI.new(self, _registry)

func process_python(program: PyProgram, parent_identifier: String, indent_depth: int):
	_roi.process(program, parent_identifier, indent_depth)


## <assignee> = <node>.addObject("NearestPointROI", name=<name>, ...)
class NearestPointROI:
	extends "res://addons/sofa_godot_plugin/sofa_python/sofa_components/sofa_object_base.gd"

	const SofaTypes = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_core/sofa_types.gd")

	const MODULE = "Sofa.Component.Engine.Select"
	const TYPE = "NearestPointROI"

	const cat_roi = "SOFA NearestPointROI"

	func _init(node: Node, registry: PropertyWrapperRegistry).(TYPE, node, registry):
		pass

	# @override
	func _setup_properties():
		_registry.make_enum(SofaTypes.DOF_TEMPLATE, "template")\
			.select_option_by_value(SofaTypes.DOF_DATA_TYPE.VEC_3_D)\
			.category(cat_roi)
		## first mechanical object
		_registry.make_node_path("", "object1").category(cat_roi)
		## second mechanical object
		_registry.make_node_path("", "object2").category(cat_roi)
		## Indices of the points to consider on the first model
		#_registry.make_array([], "inputIndices1")
		## Indices of the points to consider on the second model
		#_registry.make_array([], "inputIndices2")
		## Radius to search corresponding fixed point
		_registry.make_float(1.0, "radius").category(cat_roi)
		## If true will use restPosition only at init
		_registry.make_bool(true, "useRestPosition").category(cat_roi)


	# @override
	func _setup_statement():
		add_sofa_plugin(MODULE)
		var args = arguments().with_registry(_registry)
		args.add_plain("name").bind(_node, "get_name")
		args.add_property("template").transform(SofaTypes, "dof_template_to_string").required(true)
		args.add_path("object1", _node).as_sofa_link().required(true)
		args.add_path("object2", _node).as_sofa_link().required(true)
		args.add_property("radius").required(true)
		args.add_property("useRestPosition")

