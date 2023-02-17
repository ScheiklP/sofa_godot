tool
extends Node
##
## @author: Christoph Haas
## @desc: SOFA AttachConstraint
## Attach given pair of particles, projecting the positions of the second particles to the first ones.
##
## https://github.com/sofa-framework/sofa/blob/master/Sofa/Component/Constraint/Projective/src/sofa/component/constraint/projective/AttachConstraint.h
##

func get_class() -> String:
	return "SofaAttachConstraint"
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

const OBJECT_NAME = "attach_constraint"

var _attach_constraint: AttachConstraint
var _registry = PropertyWrapperRegistry.new(self)

func _init():
	set_name(OBJECT_NAME)
	_attach_constraint = AttachConstraint.new(self, _registry)

func process_python(program: PyProgram, parent_identifier: String, indent_depth: int):
	_attach_constraint.process(program, parent_identifier, indent_depth)



## <assignee> = <node>.addObject("AttachConstraint", name=<name>, ...)
class AttachConstraint:
	extends "res://addons/sofa_godot_plugin/sofa_python/sofa_components/sofa_object_base.gd"

	const MODULE = "Sofa.Component.Constraint.Projective"
	const TYPE = "AttachConstraint"

	const cat_attach_constraint = "SOFA AttachConstraint"

	func _init(node: Node, registry: PropertyWrapperRegistry).(TYPE, node, registry):
		pass

	# @override
	func _setup_properties():
		## first model (mechanical state)
		_registry.make_node_path("", "model_1/object").category(cat_attach_constraint)
		## Indices of the source points on the first model
		_registry.make_node_path("", "model_1/indices").category(cat_attach_constraint)
		## indices field name of the first model
		_registry.make_string(".indices1", "model_1/indices_field").category(cat_attach_constraint)
		## second model (mechanical state)
		_registry.make_node_path("", "model_2/object").category(cat_attach_constraint)
		## Indices of the fixed points on the second model
		_registry.make_node_path("", "model_2/indices").category(cat_attach_constraint)
		## indices field name of the first model
		_registry.make_string(".indices2", "model_2/indices_field").category(cat_attach_constraint)
		## true if forces should be projected back from model2 to model1
		_registry.make_bool(false, "twoWay").category(cat_attach_constraint)
		## true to keep rotations free (only used for Rigid DOFs)
		_registry.make_bool(false, "freeRotations").category(cat_attach_constraint)
		## true to keep rotation of the last attached point free (only used for Rigid DOFs)
		_registry.make_bool(false, "lastFreeRotation").category(cat_attach_constraint)
		## "true to use rest rotations local offsets (only used for Rigid DOFs)"
		_registry.make_bool(false, "restRotations").category(cat_attach_constraint)
		## position at which the attach constraint should become inactive
		_registry.make_vector3(Vector3.ZERO, "lastPos").category(cat_attach_constraint)
		## direction from lastPos at which the attach coustraint should become inactive
		_registry.make_vector3(Vector3.ZERO, "lastDir").category(cat_attach_constraint)
		## true to clamp particles at lastPos instead of freeing them
		_registry.make_bool(false, "clamp").category(cat_attach_constraint)
		## the constraint become inactive if the distance between the points attached is bigger than minDistance.
		_registry.make_float(-1.0, "minDistance")\
			.range_hint("0,1000,1,or_greater,or_lesser")\
			.category(cat_attach_constraint)
		## Factor applied to projection of position
		_registry.make_float(1.0, "positionFactor").category(cat_attach_constraint)
		## Factor applied to projection of velocity
		_registry.make_float(1.0, "velocityFactor").category(cat_attach_constraint)
		## Factor applied to projection of force/acceleration
		_registry.make_float(1.0, "responseFactor").category(cat_attach_constraint)
		## Constraint factor per pair of points constrained.
		## 0 -> the constraint is released. 1 -> the constraint is fully constrained
		#_registry.make_array([], "constraintFactor")

	# @override
	func _setup_statement():
		add_sofa_plugin(MODULE)
		var args = arguments().with_registry(_registry)
		args.add_plain("name").position(1).bind(_node, "get_name")
		## first model (mechanical state)
		args.add_path("object1", _node, "model_1/object").as_sofa_link().required(true)
		## second model (mechanical state)
		args.add_path("object2", _node, "model_2/object").as_sofa_link().required(true)
		## Indices of the source points on the first model
		args.add_path("indices1", _node, "model_1/indices")\
			.as_sofa_link()\
			.bind_access(self, "_access_indices1")\
			.required(true)
		## Indices of the fixed points on the second model
		args.add_path("indices2", _node, "model_2/indices")\
			.as_sofa_link()\
			.bind_access(self, "_access_indices2")\
			.required(true)
		## true if forces should be projected back from model2 to model1
		args.add_property("twoWay")
		## true to keep rotations free (only used for Rigid DOFs)
		args.add_property("freeRotations")
		## true to keep rotation of the last attached point free (only used for Rigid DOFs)
		args.add_property("lastFreeRotation")
		## "true to use rest rotations local offsets (only used for Rigid DOFs)"
		args.add_property("restRotations")
		## position at which the attach constraint should become inactive
		args.add_property("lastPos")
		## direction from lastPos at which the attach coustraint should become inactive
		args.add_property("lastDir")
		## true to clamp particles at lastPos instead of freeing them
		args.add_property("clamp")
		## the constraint become inactive if the distance between the points attached is bigger than minDistance.
		args.add_property("minDistance")
		## Factor applied to projection of position
		args.add_property("positionFactor")
		## Factor applied to projection of velocity
		args.add_property("velocityFactor")
		## Factor applied to projection of force/acceleration
		args.add_property("responseFactor")

	func _access_indices1() -> String:
		return _registry.get_value("model_1/indices_field")
	
	func _access_indices2() -> String:
		return _registry.get_value("model_2/indices_field")