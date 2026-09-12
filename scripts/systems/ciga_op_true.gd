class_name CIGAOPTrue
extends Node


# =============================================================
# CIGA OP TRUE
# Godot 4.7.2
#
# Controla a optimização dos objectos fora da UI.
#
# CIGAObjectsUI
#      ↓
# CIGAOPTrue
#      ↓
# Thread
#      ↓
# CIGAObjectOptimizer
#
#
# IMPORTANTE:
#
# Este node NÃO calcula Auto Scale.
#
# O Auto Scale acontece durante a importação em CIGAObjects.
#
#
# OPTIMIZER QUALITY
#
# QUALITY      = 0
# BALANCED     = 1
# PERFORMANCE  = 2
#
# A qualidade é definida pela UI antes de iniciar a thread.
# A thread captura a qualidade actual e usa essa mesma qualidade
# durante toda a optimização.
# =============================================================


# =============================================================
# SIGNALS
# =============================================================

signal optimization_started(
	object_id: String
)

signal optimization_finished(
	object_id: String,
	result: Dictionary
)


# =============================================================
# QUALITY
# =============================================================

const QUALITY_QUALITY := 0

const QUALITY_BALANCED := 1

const QUALITY_PERFORMANCE := 2

const DEFAULT_QUALITY := QUALITY_BALANCED


# =============================================================
# STATE
# =============================================================

var worker_thread: Thread = null

var optimization_running: bool = false

var current_object_id: String = ""

var current_source_path: String = ""

var optimizer_quality: int = DEFAULT_QUALITY


# =============================================================
# SET OPTIMIZER QUALITY
# =============================================================

func set_optimizer_quality(
	quality: int
) -> void:

	optimizer_quality = clampi(
		quality,
		QUALITY_QUALITY,
		QUALITY_PERFORMANCE
	)


	print(
		"CIGA OP TRUE | QUALITY SET | ",
		get_optimizer_quality_name(),
		" | ID=",
		optimizer_quality
	)


# =============================================================
# GET OPTIMIZER QUALITY
# =============================================================

func get_optimizer_quality() -> int:

	return optimizer_quality


# =============================================================
# GET OPTIMIZER QUALITY NAME
# =============================================================

func get_optimizer_quality_name() -> String:

	match optimizer_quality:

		QUALITY_QUALITY:

			return "QUALITY"


		QUALITY_BALANCED:

			return "BALANCED"


		QUALITY_PERFORMANCE:

			return "PERFORMANCE"


	return "BALANCED"


# =============================================================
# OPTIMIZE
# =============================================================

func optimize_async(
	source_path: String,
	object_id: String
) -> bool:

	if optimization_running:

		print(
			"CIGA OP TRUE | ALREADY RUNNING"
		)

		return false


	if source_path.is_empty():

		print(
			"CIGA OP TRUE | EMPTY SOURCE PATH"
		)

		return false


	if object_id.is_empty():

		print(
			"CIGA OP TRUE | EMPTY OBJECT ID"
		)

		return false


	if not FileAccess.file_exists(
		source_path
	):

		print(
			"CIGA OP TRUE | SOURCE NOT FOUND | ",
			source_path
		)

		return false


	optimization_running = true

	current_object_id = (
		object_id
	)

	current_source_path = (
		source_path
	)


	print(
		"CIGA OP TRUE | START | ",
		object_id
	)

	print(
		"CIGA OP TRUE | QUALITY | ",
		get_optimizer_quality_name(),
		" | ID=",
		optimizer_quality
	)


	optimization_started.emit(
		object_id
	)


	worker_thread = Thread.new()


	var error := (
		worker_thread.start(
			Callable(
				self,
				"_optimization_thread"
			)
		)
	)


	if error != OK:

		print(
			"CIGA OP TRUE | THREAD START FAILED | ",
			error_string(
				error
			)
		)


		optimization_running = false

		current_object_id = ""

		current_source_path = ""

		worker_thread = null

		return false


	return true


# =============================================================
# THREAD
# =============================================================

func _optimization_thread() -> void:

	var object_id := (
		current_object_id
	)

	var source_path := (
		current_source_path
	)

	var selected_quality := (
		optimizer_quality
	)


	print(
		"CIGA OP TRUE | THREAD RUNNING | ",
		object_id
	)

	print(
		"CIGA OP TRUE | THREAD QUALITY | ",
		_get_quality_name(
			selected_quality
		),
		" | ID=",
		selected_quality
	)


	# =========================================================
	# CREATE OPTIMIZER
	# =========================================================

	var optimizer := (
		CIGAObjectOptimizer.new()
	)


	# =========================================================
	# APPLY QUALITY
	#
	# Importante:
	# isto acontece DENTRO da thread, no optimizer que vai
	# efectivamente processar o ficheiro.
	# =========================================================

	optimizer.set_quality(
		selected_quality
	)


	# =========================================================
	# OPTIMIZE
	# =========================================================

	var result: Dictionary = (
		optimizer.optimize_file(
			source_path,
			object_id
		)
	)


	# =========================================================
	# ATTACH QUALITY INFORMATION
	#
	# Mesmo que o optimizer não devolva estes campos,
	# garantimos que o UI recebe informação sobre a qualidade
	# realmente utilizada nesta operação.
	# =========================================================

	result["quality_id"] = (
		selected_quality
	)

	result["quality"] = (
		_get_quality_name(
			selected_quality
		)
	)


	call_deferred(
		"_finish_optimization",
		object_id,
		result
	)


# =============================================================
# FINISH
# =============================================================

func _finish_optimization(
	object_id: String,
	result: Dictionary
) -> void:

	if worker_thread != null:

		worker_thread.wait_to_finish()

		worker_thread = null


	optimization_running = false

	current_object_id = ""

	current_source_path = ""


	var success := bool(
		result.get(
			"success",
			false
		)
	)


	var quality_id := int(
		result.get(
			"quality_id",
			DEFAULT_QUALITY
		)
	)


	var quality_name := str(
		result.get(
			"quality",
			_get_quality_name(
				quality_id
			)
		)
	)


	print(
		"CIGA OP TRUE | FINISHED | ",
		object_id,
		" | SUCCESS=",
		success,
		" | QUALITY=",
		quality_name
	)


	optimization_finished.emit(
		object_id,
		result
	)


# =============================================================
# QUALITY NAME HELPER
# =============================================================

func _get_quality_name(
	quality: int
) -> String:

	match quality:

		QUALITY_QUALITY:

			return "QUALITY"


		QUALITY_BALANCED:

			return "BALANCED"


		QUALITY_PERFORMANCE:

			return "PERFORMANCE"


	return "BALANCED"


# =============================================================
# STATUS
# =============================================================

func is_optimizing() -> bool:

	return optimization_running


# =============================================================
# EXIT
# =============================================================

func _exit_tree() -> void:

	if worker_thread != null:

		worker_thread.wait_to_finish()

		worker_thread = null


	optimization_running = false

	current_object_id = ""

	current_source_path = ""
