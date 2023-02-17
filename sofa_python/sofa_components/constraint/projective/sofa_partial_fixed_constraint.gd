tool
extends Node
##
## @author: Christoph Haas
## @desc: SOFA PartialFixedConstraint
##
## https://github.com/sofa-framework/sofa/blob/master/Sofa/Component/Constraint/Projective/src/sofa/component/constraint/projective/PartialFixedConstraint.h
##

func get_class() -> String:
	return "SofaPartialFixedConstraint"
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

const OBJECT_NAME = "partial_fixed_constraint"

var _fixed_constraint: PartialFixedConstraint
var _registry = PropertyWrapperRegistry.new(self)

func _init():
	set_name(OBJECT_NAME)
	_fixed_constraint = PartialFixedConstraint.new(self, _registry)

func process_python(program: PyProgram, parent_identifier: String, indent_depth: int):
	_fixed_constraint.process(program, parent_identifier, indent_depth)



## <assignee> = <node>.addObject("PartialFixedConstraint", name=<name>, ...)
class PartialFixedConstraint:
	extends "res://addons/sofa_godot_plugin/sofa_python/sofa_components/constraint/projective/sofa_fixed_constraint.gd".FixedConstraint

	const FlagsPropertyWrapper = preload("res://addons/sofa_godot_plugin/property_wrappers/flags_property_wrapper.gd")

	const DOFS_TEMPLATE = {
		"Vec1": {"1": false},
		"Vec2": {"1": false, "2": false},
		"Vec3": {"1": false, "2": false, "3": false},
		"Vec6": {"1": false, "2": false, "3": false, "4": false, "5": false, "6": false},
		"Rigid2":
		{
			"translation x": false, "translation y": false,
			"rotation x": false,    "rotation y": false
		},
		"Rigid3":
		{
			"translation x": false, "translation y": false, "translation z": false,
			"rotation x": false,    "rotation y": false,    "rotation z": false
		}
	}

	func _init(node: Node, registry: PropertyWrapperRegistry).(node, registry, "PartialFixedConstraint"):
		pass

	# @override
	func setup():
		.setup()
		# remove inherited property, superseeded by "projectVelocity"
		arguments().remove_argument("activate_projectVelocity")
		_registry.unregister("activate_projectVelocity")

	# @override
	func _setup_properties():
		._setup_properties()
		_registry._get_property_wrapper("fixAll").callback(self, "_on_toogle_dofs")
		## project velocity to ensure no drift of the fixed point
		_registry.make_bool(false, "projectVelocity").category(cat_fixed_constraint)
		_registry.make_enum(DOFS_TEMPLATE, "dofs/template")\
			.category(cat_fixed_constraint)\
			.select("Rigid3")\
			.callback(self, "_on_select_dofs")
		_select_dofs()
		_toogle_dofs()

	# @override
	func _setup_statement():
		._setup_statement()
		var args = arguments().with_registry(_registry)
		## for each direction, true if fixed, false if free
		args.add_plain("fixedDirections").default([]).bind(self, "get_fixed_dofs")
		## project velocity to ensure no drift of the fixed point
		args.add_property("projectVelocity")

	func get_fixed_dofs() -> Array:
		# TODO: This should return an array of booleans, however, as of v21.12.00, SOFA demands binary integers {0, 1}.
		# This is dependent on the templated DOF data type of the associated mechanical object
		if _registry.get_value("fixAll"):
			return []
		var dof_mask = []
		var directions =  _registry._get_property_wrapper("dofs/fixedDirections") as FlagsPropertyWrapper
		for direction in directions.get_selection_mask():
			dof_mask.append(1 if direction else 0)
		return dof_mask

	func _on_toogle_dofs(source_path: String, old_value, new_value):
		_toogle_dofs()

	func _toogle_dofs():
		_registry.toogle_path("dofs/", not _registry.get_value("fixAll"))

	func _on_select_dofs(source_path: String, old_value, new_value):
		_select_dofs()

	func _select_dofs():
		var dofs = FlagsPropertyWrapper.new("dofs/fixedDirections", _registry.get_value("dofs/template"))\
			.select([])\
			.category(cat_fixed_constraint)\
			.enable(not _registry.get_value("fixAll"))
		if _registry.is_registered("dofs/fixedDirections"):
			_registry.unregister("dofs/fixedDirections")
		_registry.register(dofs)
		_registry.emit_signal("property_list_changed")
