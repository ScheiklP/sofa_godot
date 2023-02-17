tool
extends Node
##
## @author: Christoph Haas
## @desc: SOFA FixedConstraint
##
## https://github.com/sofa-framework/sofa/blob/master/Sofa/Component/Constraint/Projective/src/sofa/component/constraint/projective/FixedConstraint.h
##

func get_class() -> String:
	return "SofaFixedConstraint"
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

const OBJECT_NAME = "fixed_constraint"

var _fixed_constraint: FixedConstraint
var _registry = PropertyWrapperRegistry.new(self)

func _init():
	set_name(OBJECT_NAME)
	_fixed_constraint = FixedConstraint.new(self, _registry)

func process_python(program: PyProgram, parent_identifier: String, indent_depth: int):
	_fixed_constraint.process(program, parent_identifier, indent_depth)



## <assignee> = <node>.addObject("FixedConstraint", name=<name>, ...)
class FixedConstraint:
	extends "res://addons/sofa_godot_plugin/sofa_python/sofa_components/sofa_object_base.gd"

	const MODULE = "Sofa.Component.Constraint.Projective"
	#const TYPE = "FixedConstraint"

	const cat_fixed_constraint = "SOFA FixedConstraint"

	func _init(node: Node, registry: PropertyWrapperRegistry, type: String = "FixedConstraint").(type, node, registry):		
		pass

	# @override
	func _setup_properties():
		## Indices of the fixed points
		_registry.make_node_path("", "indices").category(cat_fixed_constraint)
		## draw or not the fixed constraints
		_registry.make_bool(true, "showObject").category(cat_fixed_constraint).callback(self, "_on_toogle_properties")
		## =0 => point based rendering, >0 => radius of spheres
		_registry.make_float(1.0, "drawSize").range_hint("0").category(cat_fixed_constraint)
		## filter all the DOF to implement a fixed object
		_registry.make_bool(false, "fixAll").category(cat_fixed_constraint)
		## activate project velocity to set velocity
		_registry.make_bool(false, "activate_projectVelocity").category(cat_fixed_constraint)
		## link to the topology container
		#_registry.make_node_path("", "topology").category(cat_fixed_constraint)

	func _on_toogle_properties(source_path: String, old_value, new_value):
		toogle_properties()

	func toogle_properties():
		_registry.toogle_path("drawSize", _registry.get_value("showObject"))


	# @override
	func _setup_statement():
		add_sofa_plugin(MODULE)
		var args = arguments().with_registry(_registry)
		args.add_plain("name").position(1).bind(_node, "get_name")
		## Indices of the fixed points
		#args.add_plain("indices").required(true).bind(self, "get_indices")
		args.add_path("indices", _node).as_sofa_link().access(".indices").required(true)
		## draw or not the fixed constraints
		args.add_property("showObject")
		## =0 => point based rendering, >0 => radius of spheres
		args.add_property("drawSize").default(0.0)
		## filter all the DOF to implement a fixed object
		args.add_property("fixAll")
		## activate project velocity to set velocity
		args.add_property("activate_projectVelocity")
		## link to the topology container
		#args.add_plain("topology").default("").bind(self, "get_topology")

	#func get_topology() -> String:
	#	push_warning("Not implemented yet")
	#	return ""
