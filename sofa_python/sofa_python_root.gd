tool
extends Node
##
## @author: Christoph Haas
##
## @desc: Entry point for SofaPython3 and sofa_env scenes
##
#class_name SofaPythonRoot

func get_class() -> String:
	return "SofaPythonRoot"
func is_class(clazz: String) -> bool:
	return .is_class(clazz) || (clazz == get_class())

func _get_property_list() -> Array:
	return _registry.gen_property_list()
func _set(property: String, value) -> bool:
	return _registry.handle_set(property, value)
func _get(property: String):
	return _registry.handle_get(property)

const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")

const PyContext = preload("res://addons/sofa_godot_plugin/sofa_python/sofa_python_context.gd")
const PyProgram = preload("res://addons/sofa_godot_plugin/sofa_python/python/py_program.gd")

const FUNCTION_NAME = "create_scene"
const cat_sofa_python  = "SofaPython3"

var _executor: PyExecutor
var _registry = PropertyWrapperRegistry.new(self)

func _init():
	set_name(FUNCTION_NAME)
	## The python identifier of the SOFA scene's root node.
	_registry.make_string("root_node", "root_node_identifier").category(cat_sofa_python)
	## The python identifier of the SOFA scene description dictionary.
	_registry.make_string("scene_description", "scene_description_identifier").category(cat_sofa_python)
	## The key of the scene description dictionary for the root node
	_registry.make_string("root_node", "scene_description_root_node_key").category(cat_sofa_python)
	# python executor
	_executor = PyExecutor.new(self, _registry)

	if Engine.is_editor_hint():
		ProjectSettings.set_setting("network/limits/debugger_stdout/max_chars_per_second", 2048*100)
		ProjectSettings.set_setting("network/limits/debugger_stdout/max_messages_per_frame", 10*100)
		ProjectSettings.save()


func _ready():
	assert(self == PyContext.get_scene_root(), "SofaPythonRoot must be root of Godot scene")
	if Engine.is_editor_hint():
		return
	# process sofa_python nodes
	var code_depth = 1
	var program = PyProgram.new(
		_registry.get_value("root_node_identifier"),
		_registry.get_value("scene_description_identifier"),
		_registry.get_value("scene_description_root_node_key")
	)
	for child_node in get_children():
		if child_node.has_method("process_python"):
			program.append_code("\n" + "\t".repeat(code_depth) + "# " + child_node.get_name())
			child_node.process_python(program, program.get_sofa_root_identifier(), code_depth)
	# store generated python code
	var python_code = program.get_code()
	_executor.store_python_code(python_code)
	# optionally format and view python code
	_executor.format_python()
	_executor.open_editor()
	# open generated scene in sofa
	_executor.run_sofa()

func _process(delta):
	if Engine.is_editor_hint():
		return
	_executor.print_run_sofa_log()

func _exit_tree():
	if Engine.is_editor_hint():
		return
	_executor.kill_sofa()

func get_python_identifier():
	return _registry.get_value("root_node_identifier")

class PyExecutor:
	extends Reference

	const PropertyWrapperRegistry = preload("res://addons/sofa_godot_plugin/property_wrappers/property_wrapper_registry.gd")
	const cat_exec  = "Execution"

	var _node: Node
	var _registry: PropertyWrapperRegistry

	const RUN_SOFA_LOG_FILE_PATH = "/tmp/sofa_godot_out.txt"

	var _run_sofa_pid: int = 0
	var _run_sofa_started: bool = false
	var _run_sofa_log_file_pos: int = 0

	func _init(node: Node, registry: PropertyWrapperRegistry):
		_node     = node
		_registry = registry
		_setup_properties()

	func _setup_properties():
		## file path to store the generated python program
		_registry.make_string("/tmp/sofa_python_scene.py", "output_file_path")\
			.hint(PROPERTY_HINT_GLOBAL_FILE)\
			.hint_string("*.py")\
			.category(cat_exec)\
		## path to run_sofa binary
		_registry.make_string(PyContext.PY_NONE, "sofa_binary")\
			.hint(PROPERTY_HINT_GLOBAL_FILE)\
			.category(cat_exec)
		## path to anaconda/miniconda binary
		_registry.make_string("$HOME/miniconda3/condabin/conda", "conda_binary")\
			.hint(PROPERTY_HINT_GLOBAL_FILE)\
			.category(cat_exec)\
			.callback(self, "_on_update_conda")
		## name of conda environment
		make_conda_env_enum("conda_env", cat_exec)
		## optional python formatter
		_registry.make_enum({"None":"None", "black":"black"}, "python_formatter")\
			.category(cat_exec)
		## optional editor to open generated python code in
		_registry.make_enum({"None":"None", "Visual Studio Code":"code", "Gedit":"gedit"}, "python_editor")\
			.category(cat_exec)

	func _on_update_conda(source_path: String, old_value: String, new_value: String):
		if _registry.is_registered("conda_env"):
			_registry.unregister("conda_env")
		make_conda_env_enum("conda_env", cat_exec)

	func make_conda_env_enum(property_path: String, property_category: String = ""):
		var conda_binary = _registry.get_value("conda_binary")
		var out = []
		var exit_code = OS.execute(conda_binary, ["env", "list"], true, out)
		if exit_code != 0:
			return {"None": ""}
		assert(out.size() == 1, "conda env list failed")
		var envs = {}
		var selected_env = ""
		for line in out[0].split("\n", false):
			if not line.begins_with("#"):
				var env = line.split(" ", false)[0]
				envs[env] = env
				if env.to_lower() == "sofa":
					selected_env = env
		var env_enum = _registry.make_enum(envs, property_path)
		if not selected_env.empty():
			env_enum.select(selected_env)
		if not property_category.empty():
			env_enum.set_inspector_category(property_category)
		return env_enum


	## save python code to file
	func store_python_code(python_code: String):
		var file_path = _registry.get_value("output_file_path")
		var file = File.new()
		file.open(file_path, File.WRITE)
		file.store_string(python_code)
		file.close()
		print("Python code saved to: ", file_path)


	## conda run -n {sofa_env} --no-capture-output {formatter} {file_path}
	func format_python():
		var formatter = _registry.get_value("python_formatter")
		if formatter == "None":
			return
		OS.execute(get_conda_binary(),
			[
				"run", "-n", get_conda_env(), "--no-capture-output",
				formatter, get_python_file_path()
			],
			true
		)


	func open_editor():
		var editor = _registry.get_value("python_editor")
		if editor == "None":
			return
		OS.execute(editor, [get_python_file_path()], false)


	## conda run -n {sofa_env} --no-capture-output {run_script} {runSofa} {file_path}
	func run_sofa():
		_run_sofa_started = false
		_run_sofa_log_file_pos = 0

		# run non_blocking
		_run_sofa_pid = OS.execute(
			get_conda_binary(),
			[
				"run", "-n", get_conda_env(), "--no-capture-output",
				get_conda_run_sofa_script(),
				get_sofa_binary(), get_python_file_path(), RUN_SOFA_LOG_FILE_PATH
			],
			false
		)

		if is_sofa_running():
			yield(_node.get_tree().create_timer(3.0), "timeout")
			_run_sofa_started = true
			print("sofa_run started under process group: ", _run_sofa_pid, "\n")


	func is_sofa_running() -> bool:
		return _is_process_running(_run_sofa_pid)


	func kill_sofa():
		# need to kill entire process group
		var kill_out = []
		var kill_exit_code = OS.execute("kill", ["--", -_run_sofa_pid], true, kill_out, true)
		for line in kill_out:
			print(line)


	func print_run_sofa_log():
		if not _run_sofa_started:
			return
		var log_file = File.new()
		if log_file.file_exists(RUN_SOFA_LOG_FILE_PATH):
			log_file.open(RUN_SOFA_LOG_FILE_PATH, File.READ)
			log_file.seek(_run_sofa_log_file_pos)
			var num_bytes = log_file.get_len() - log_file.get_position()
			if num_bytes > 0:
				# unfortunately we cannot use printraw to print to editor
				# hence, we get some additional new lines added to the output
				print(log_file.get_buffer(num_bytes).get_string_from_utf8())
				_run_sofa_log_file_pos += num_bytes 
			log_file.close()


	func get_pyhton_code_editor() -> String:
		return _registry.get_value("python_editor")

	func get_python_code_formatter() -> String:
		return _registry.get_value("python_formatter")

	func get_python_file_path() -> String:
		var file_path = _registry.get_value("output_file_path")
		assert(File.new().file_exists(file_path), "File path does not exist")
		return file_path
	
	func get_conda_binary() -> String:
		var conda_binary = _registry.get_value("conda_binary")
		assert(File.new().file_exists(conda_binary), "Conda binary does not exist")
		return conda_binary

	func get_sofa_binary() -> String:
		var sofa_binary = _registry.get_value("sofa_binary")
		assert(File.new().file_exists(sofa_binary), "Sofa binary does not exist")
		return sofa_binary

	func get_conda_env() -> String:
		return _registry.get_value("conda_env")

	func get_conda_run_sofa_script() -> String:
		return ProjectSettings.globalize_path("res://addons/sofa_godot_plugin/scripts/conda_run_sofa.sh")
		#return ProjectSettings.globalize_path(_node.get_script().get_path().get_base_dir() + "/../scripts/conda_run_sofa.sh")


	func _is_process_running(pid: int) -> bool:
		# https://stackoverflow.com/a/33979279
		var process_running = false

		var ps_out = []
		var ps_exit_code = OS.execute(
			"ps",
			["-q", pid, "-o", "state", "--no-headers"],
			true,
			ps_out,
			true
		)

		if ps_exit_code > 0 or ps_out.empty():
			process_running = false
		else:
			assert(ps_out.size() == 1, "unexpected ps output")
			process_running = not (ps_out[0] in ["T", "X", "Z"])

		return process_running
