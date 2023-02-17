extends "res://addons/sofa_godot_plugin/sofa_python/python/py_callable.gd"

const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")

const sofa_env = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_env/sofa_env_modules.gd")
const PyArgumentContainer = preload("res://addons/sofa_godot_plugin/sofa_python/python/arguments/py_argument_container.gd").PyArgumentContainer

const MODULE = sofa_env.sofa_templates.solver
const FUNCTION_NAME = "add_solver"
const cat_ode_solver = "ODE Solver"
const cat_linear_solver = "Linear Solver"

var _node: Node
var _registry: PropertyWrapperRegistry

func _init(node: Node, registry: PropertyWrapperRegistry, partial: bool = false).(FUNCTION_NAME, partial):
	_node     = node
	_registry = registry
	_setup()

func _setup():
	_setup_properties()
	_setup_callable()

func _setup_properties():
	# Numerical method to find the approximate solution for ordinary differential equations
	_registry.make_enum(MODULE.OdeSolverType, "ode_solver_type")\
		.select("IMPLICITEULER")\
		.callback(self, "_on_ode_solver_type_changed")\
		.category(cat_ode_solver)
	# Rayleigh damping may be used to stabilize or ease convergence of the simulation
	_registry.make_float(0.1, "ode_solver_rayleigh_stiffness").category(cat_ode_solver)
	_registry.make_float(0.1, "ode_solver_rayleigh_mass").category(cat_ode_solver)
	# Numerical method that solves the matrix system Ax=b that is built by the OdeSolver
	_registry.make_enum(MODULE.LinearSolverType, "linear_solver_type")\
		.select("CG")\
		.callback(self, "_on_linear_solver_type_changed")\
		.category(cat_linear_solver)
	## Additional keyword arguments to the LinearSolverType
	_setup_linear_solver_kwargs()


func _setup_callable():
	add_import(MODULE, FUNCTION_NAME)
	var args = PyArgumentContainer.new(self).with_registry(_registry)
	args.add_plain("attached_to").required(true).position(0).as_identifier()
	# Numerical method to find the approximate solution for ordinary differential equations
	args.add_property("ode_solver_type").import(MODULE, "OdeSolverType").as_identifier()
	# Rayleigh damping may be used to stabilize or ease convergence of the simulation
	args.add_property("ode_solver_rayleigh_stiffness")
	args.add_property("ode_solver_rayleigh_mass")
	# Numerical method that solves the matrix system Ax=b that is built by the OdeSolver
	args.add_property("linear_solver_type").import(MODULE, "LinearSolverType").as_identifier()
	## Additional keyword arguments to the LinearSolverType
	args.add_dictionary("linear_solver_kwargs")
	_update_linear_solver_kwargs()


func get_ode_solver_type() -> String:
	return _registry._get_property_wrapper("ode_solver_type").get_selected_option_key()

func _on_ode_solver_type_changed(source_path: String, old_value, new_value):
	_toogle_ode_solver_properties()

func _toogle_ode_solver_properties():
	var ode_solver = get_ode_solver_type()
	match ode_solver:
		"EXPLICITEULER":
			_registry.disable_path("ode_solver_rayleigh_stiffness")
			_registry.disable_path("ode_solver_rayleigh_mass")
		"IMPLICITEULER":
			_registry.enable_path("ode_solver_rayleigh_stiffness")
			_registry.enable_path("ode_solver_rayleigh_mass")
		_:
			assert(false, "Unknown ode_solver_type")


func get_linear_solver_type() -> String:
	return _registry._get_property_wrapper("linear_solver_type").get_selected_option_key()

func _setup_linear_solver_kwargs():
	# CG
	_registry.make_int(25,     "cg/iterations").category(cat_linear_solver)
	_registry.make_float(1e-9, "cg/threshold").category(cat_linear_solver)
	_registry.make_float(1e-9, "cg/tolerance").category(cat_linear_solver)
	# SPARSELDL
	_registry.make_string("CompressedRowSparseMatrixMat3x3d", "sparseldl/template").category(cat_linear_solver)
	# ASYNCSPARSELDL
	# BTD
	_registry.make_string("BTDMatrix6d", "btd/template").category(cat_linear_solver)
	# update properties
	_toogle_linear_solver_kwargs()

func _on_linear_solver_type_changed(source_path: String, old_value, new_value):
	_toogle_linear_solver_kwargs()

func _toogle_linear_solver_kwargs():
	var linear_solver = get_linear_solver_type()
	_registry.toogle_path("cg/",        linear_solver == "CG")
	_registry.toogle_path("sparseldl/", linear_solver == "SPARSELDL")
	_registry.toogle_path("btd/",       linear_solver == "BTD")
	#_registry.toogle_path("asyncsparseldl/", linear_solver == "ASYNCSPARSELDL")

func _update_linear_solver_kwargs():
	var kwargs = PyArgumentContainer.new(get_argument("linear_solver_kwargs")).with_registry(_registry)
	kwargs.clear()
	var linear_solver = get_linear_solver_type()
	match linear_solver:
		"CG":
			kwargs.add_property("iterations", "cg/iterations").default(25).required(true)
			kwargs.add_property("threshold",  "cg/threshold").default(1e-9).required(true)
			kwargs.add_property("tolerance",  "cg/tolerance").default(1e-9).required(true)
		"SPARSELDL":
			kwargs.add_property("template", "sparseldl/template").default("CompressedRowSparseMatrixMat3x3d").required(true)
		"ASYNCSPARSELDL":
			pass
		"BTD":
			kwargs.add_property("template", "btd/template").default("BTDMatrix6d").required(true)
		_:
			assert(false, "Unknown linear_solver_type")


# @override
func generate_python_code(indent_depth: int, context: Dictionary = {}) -> String:
	_update_linear_solver_kwargs()
	return .generate_python_code(indent_depth, context)