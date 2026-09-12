class_name CIGAObjects
extends RefCounted


# =============================================================
# CIGA OBJECT MANAGER
# Godot 4.7.2
#
# RESPONSABILIDADES
#
# - biblioteca de objetos
# - importação GLB / GLTF
# - remoção
# - seleção
# - metadados
# - escala BASE global
# - auto-scale no import
# - resolução de recursos
# - cache de PackedScene
# - preparação dos recursos no boot
# - controlo da qualidade do optimizer
#
#
# SCALE ARCHITECTURE
#
# CIGAObjects:
#
#     base_scale
#
# CIGAProfiles:
#
#     scale_multipliers[object_id]
#
# FINAL:
#
#     base_scale × profile_multiplier
#
#
# OPTIMIZER ARCHITECTURE
#
# CIGAObjects:
#
#     optimizer_quality
#
# CIGAObjectOptimizer:
#
#     QUALITY
#     BALANCED
#     PERFORMANCE
#
# A qualidade do optimizer NÃO altera:
#
#     base_scale
#     profile scale
#     física
#     posição
#
# Apenas controla a preparação do recurso optimizado.
#
# =============================================================


# =============================================================
# AUTO SCALE
# =============================================================

const AUTO_SCALE_TARGET_SIZE: float = 1.0

const AUTO_SCALE_MIN: float = 0.0001

const AUTO_SCALE_MAX: float = 10.0


# =============================================================
# SCALE
# =============================================================

const DEFAULT_SCALE_MULTIPLIER: float = 1.0

const MIN_SCALE_MULTIPLIER: float = 0.01

const MAX_SCALE_MULTIPLIER: float = 10.0


# =============================================================
# OBJECT ID
# =============================================================

const OBJECT_ID_COUNTER_FILE: String = (
	"user://ciga/assets/objects/object_id_counter.json"
)


# =============================================================
# SIGNALS
# =============================================================

signal object_imported(
	object_data: Dictionary
)

signal object_removed(
	object_data: Dictionary
)

signal active_object_changed(
	object_data: Dictionary
)

signal optimizer_quality_changed(
	quality: int
)


# =============================================================
# DATA
# =============================================================

const OBJECT_FOLDER: String = (
	"user://ciga/assets/objects"
)

const LIBRARY_FILE: String = (
	"user://ciga/assets/objects/library.json"
)


# =============================================================
# SCALE LIMITS
# =============================================================

const MIN_OBJECT_SCALE: float = 0.0001

const MAX_OBJECT_SCALE: float = 100.0

const DEFAULT_OBJECT_SCALE: float = 1.0


# =============================================================
# OPTIMIZER QUALITY
#
# Estes valores correspondem directamente ao enum do
# CIGAObjectOptimizer.
# =============================================================

const OPTIMIZER_QUALITY_QUALITY: int = 0

const OPTIMIZER_QUALITY_BALANCED: int = 1

const OPTIMIZER_QUALITY_PERFORMANCE: int = 2


const DEFAULT_OPTIMIZER_QUALITY: int = (
	OPTIMIZER_QUALITY_BALANCED
)


# =============================================================
# STATE
# =============================================================

var objects: Array[Dictionary] = []

var active_object_id: String = ""

var optimizer: CIGAObjectOptimizer = null

var optimizer_quality: int = (
	DEFAULT_OPTIMIZER_QUALITY
)


# =============================================================
# PROFILE MANAGER
#
# O CIGAObjects NÃO é dono da escala por profile.
#
# Apenas consulta o profile activo quando precisa da
# escala efectiva.
#
# =============================================================

var profile_manager: CIGAProfiles = null


# =============================================================
# RUNTIME RESOURCE CACHE
#
# object_id -> PackedScene
#
# =============================================================

var packed_scene_cache: Dictionary = {}


# =============================================================
# INITIALIZE
# =============================================================

func initialize() -> void:

	ensure_directories()


	optimizer = (
		CIGAObjectOptimizer.new()
	)


	optimizer.set_quality(
		optimizer_quality
	)


	auto_resolve_profile_manager()

	load_library()


# =============================================================
# PROFILE MANAGER
# =============================================================

func set_profile_manager(
	new_profile_manager: CIGAProfiles
) -> void:

	profile_manager = (
		new_profile_manager
	)


func auto_resolve_profile_manager() -> void:

	if profile_manager != null:

		return


	var tree: SceneTree = (
		Engine.get_main_loop()
		as
		SceneTree
	)


	if tree == null:

		return


	var current_scene := (
		tree.current_scene
	)


	if current_scene == null:

		return


	var ui_nodes := (
		current_scene.find_children(
			"*",
			"CIGAUI",
			true,
			false
		)
	)


	for node: Node in ui_nodes:

		if not node is CIGAUI:

			continue


		var ui := (
			node
			as
			CIGAUI
		)


		if ui.profile_manager == null:

			continue


		profile_manager = (
			ui.profile_manager
		)


		return


# =============================================================
# DIRECTORIES
# =============================================================

func ensure_directories() -> void:

	DirAccess.make_dir_recursive_absolute(
		OBJECT_FOLDER
	)


# =============================================================
# OPTIMIZER QUALITY
#
# Pode ser ligado directamente a um OptionButton da UI.
#
# QUALITY:
#     maior fidelidade
#
# BALANCED:
#     recomendado
#
# PERFORMANCE:
#     optimização mais agressiva
#
# =============================================================

func set_optimizer_quality(
	quality: int,
	rebuild_existing_caches: bool = true
) -> void:

	var safe_quality: int = (
		clampi(
			quality,
			OPTIMIZER_QUALITY_QUALITY,
			OPTIMIZER_QUALITY_PERFORMANCE
		)
	)


	if safe_quality == optimizer_quality:

		if optimizer != null:

			optimizer.set_quality(
				safe_quality
			)

		return


	var previous_quality: int = (
		optimizer_quality
	)


	optimizer_quality = (
		safe_quality
	)


	if optimizer == null:

		optimizer = (
			CIGAObjectOptimizer.new()
		)


	optimizer.set_quality(
		optimizer_quality
	)


	# =========================================================
	# INVALIDATE EXISTING CACHES
	#
	# O conteúdo de um cache antigo pode ter sido criado com
	# uma qualidade diferente.
	#
	# Quando solicitado, removemos apenas o cache optimizado.
	#
	# Os GLB/GLTF originais e os metadados da library ficam
	# intactos.
	# =========================================================

	if rebuild_existing_caches:

		for index in range(
			objects.size()
		):

			var object_data: Dictionary = (
				objects[index]
			)


			var object_id: String = str(
				object_data.get(
					"id",
					""
				)
			)


			if object_id.is_empty():

				continue


			# -------------------------------------------------
			# RAM CACHE
			# -------------------------------------------------

			packed_scene_cache.erase(
				object_id
			)


			# -------------------------------------------------
			# DISK CACHE
			# -------------------------------------------------

			var optimized_path: String = str(
				object_data.get(
					"optimized_path",
					""
				)
			)


			if optimizer != null:

				optimizer.remove_cache(
					object_id
				)


			if (
				not optimized_path.is_empty()
				and
				FileAccess.file_exists(
					optimized_path
				)
			):

				DirAccess.remove_absolute(
					optimized_path
				)


			# -------------------------------------------------
			# LIBRARY METADATA
			# -------------------------------------------------

			object_data["optimized"] = false

			object_data["optimized_path"] = ""

			object_data["optimizer_quality"] = (
				optimizer_quality
			)

			object_data["optimizer_quality_name"] = (
				get_optimizer_quality_name()
			)


			objects[index] = object_data


		save_library()


	optimizer_quality_changed.emit(
		optimizer_quality
	)


	print(
		"CIGA OBJECTS | OPTIMIZER QUALITY | ",
		get_optimizer_quality_name(),
		" | previous=",
		get_optimizer_quality_name(
			previous_quality
		)
	)


# =============================================================
# GET OPTIMIZER QUALITY
# =============================================================

func get_optimizer_quality() -> int:

	return (
		optimizer_quality
	)


# =============================================================
# GET OPTIMIZER QUALITY NAME
# =============================================================

func get_optimizer_quality_name(
	quality: int = -1
) -> String:

	var value: int = (
		optimizer_quality
		if quality < 0
		else
		quality
	)


	match value:

		OPTIMIZER_QUALITY_QUALITY:

			return "QUALITY"


		OPTIMIZER_QUALITY_BALANCED:

			return "BALANCED"


		OPTIMIZER_QUALITY_PERFORMANCE:

			return "PERFORMANCE"


	return "BALANCED"


# =============================================================
# GET OPTIMIZER
# =============================================================

func get_optimizer() -> CIGAObjectOptimizer:

	if optimizer == null:

		optimizer = (
			CIGAObjectOptimizer.new()
		)


	optimizer.set_quality(
		optimizer_quality
	)


	return optimizer


# =============================================================
# LOAD LIBRARY
#
# IMPORTANTE:
#
# Aqui nunca calculamos a escala do profile.
#
# A library guarda apenas:
#
#     base_scale
#
# =============================================================

func load_library() -> void:

	objects.clear()


	if not FileAccess.file_exists(
		LIBRARY_FILE
	):

		save_library()

		return


	var file := FileAccess.open(
		LIBRARY_FILE,
		FileAccess.READ
	)


	if file == null:

		push_error(
			"CIGA OBJECTS: Could not open library."
		)

		return


	var text := (
		file.get_as_text()
	)


	file.close()


	var parsed: Variant = (
		JSON.parse_string(
			text
		)
	)


	if parsed == null:

		return


	if not parsed is Dictionary:

		push_error(
			"CIGA OBJECTS: Invalid library structure."
		)

		return


	var data := (
		parsed
		as
		Dictionary
	)


	var entries: Variant = (
		data.get(
			"objects",
			[]
		)
	)


	if not entries is Array:

		push_error(
			"CIGA OBJECTS: Invalid objects array."
		)

		return


	var library_changed := false


	for entry: Variant in entries:

		if not entry is Dictionary:

			continue


		var source_object := (
			entry
			as
			Dictionary
		)


		if not source_object.has(
			"id"
		):

			continue


		# =====================================================
		# DEVOLVER CÓPIA DEEP
		# =====================================================

		var object_data := (
			source_object
			.duplicate(
				true
			)
		)


		# =====================================================
		# NAME
		# =====================================================

		if not object_data.has(
			"name"
		):

			object_data["name"] = (
				"UNKNOWN OBJECT"
			)

			library_changed = true


		# =====================================================
		# BASE SCALE
		#
		# Migração de versões antigas.
		# =====================================================

		if not object_data.has(
			"base_scale"
		):

			var legacy_scale := float(
				object_data.get(
					"scale",
					DEFAULT_OBJECT_SCALE
				)
			)


			if not is_finite(
				legacy_scale
			):

				legacy_scale = (
					DEFAULT_OBJECT_SCALE
				)


			object_data["base_scale"] = clampf(
				legacy_scale,
				MIN_OBJECT_SCALE,
				MAX_OBJECT_SCALE
			)


			library_changed = true


		var base_scale := clampf(
			float(
				object_data.get(
					"base_scale",
					DEFAULT_OBJECT_SCALE
				)
			),
			MIN_OBJECT_SCALE,
			MAX_OBJECT_SCALE
		)


		if not is_finite(
			base_scale
		):

			base_scale = (
				DEFAULT_OBJECT_SCALE
			)

			library_changed = true


		object_data["base_scale"] = (
			base_scale
		)


		# =====================================================
		# GLOBAL SCALE MULTIPLIER LEGACY
		#
		# NÃO É MAIS FONTE DE VERDADE.
		# =====================================================

		object_data["scale_multiplier"] = (
			DEFAULT_SCALE_MULTIPLIER
		)


		library_changed = true


		# =====================================================
		# LEGACY SCALE
		# =====================================================

		if not is_equal_approx(
			float(
				object_data.get(
					"scale",
					base_scale
				)
			),
			base_scale
		):

			library_changed = true


		object_data["scale"] = (
			base_scale
		)


		# =====================================================
		# OPTIMIZATION
		# =====================================================

		if not object_data.has(
			"optimized"
		):

			object_data["optimized"] = false

			library_changed = true


		if not object_data.has(
			"optimized_path"
		):

			object_data["optimized_path"] = ""

			library_changed = true


		if not object_data.has(
			"optimizer_quality"
		):

			object_data["optimizer_quality"] = (
				optimizer_quality
			)

			library_changed = true


		if not object_data.has(
			"optimizer_quality_name"
		):

			object_data["optimizer_quality_name"] = (
				get_optimizer_quality_name()
			)

			library_changed = true


		# =====================================================
		# PATHS
		# =====================================================

		if not object_data.has(
			"source_path"
		):

			object_data["source_path"] = ""

			library_changed = true


		if not object_data.has(
			"original_path"
		):

			object_data["original_path"] = ""

			library_changed = true


		# =====================================================
		# FILE SIZE
		# =====================================================

		if not object_data.has(
			"file_size"
		):

			object_data["file_size"] = 0

			library_changed = true


		objects.append(
			object_data
		)


	if library_changed:

		save_library()


# =============================================================
# SAVE LIBRARY
#
# IMPORTANTE:
#
# Nunca guardar aqui o multiplier do profile.
#
# =============================================================

func save_library() -> bool:

	ensure_directories()


	var file := FileAccess.open(
		LIBRARY_FILE,
		FileAccess.WRITE
	)


	if file == null:

		push_error(
			"CIGA OBJECTS: Could not save library."
		)

		return false


	var data: Dictionary = {
		"objects":
			objects
	}


	file.store_string(
		JSON.stringify(
			data,
			"\t"
		)
	)


	file.close()


	return true


# =============================================================
# SCAN HIGHEST ID IN FILE
# =============================================================

func _get_highest_object_id_from_file(
	file_path: String
) -> int:

	if file_path.is_empty():

		return 0


	if not FileAccess.file_exists(
		file_path
	):

		return 0


	var file := FileAccess.open(
		file_path,
		FileAccess.READ
	)


	if file == null:

		return 0


	var text := (
		file.get_as_text()
	)


	file.close()


	var highest := 0


	var regex := RegEx.new()


	var compile_error := regex.compile(
		"object_(\\d+)"
	)


	if compile_error != OK:

		return 0


	var matches := (
		regex.search_all(
			text
		)
	)


	for match: RegExMatch in matches:

		if match == null:

			continue


		var number_text := (
			match.get_string(
				1
			)
		)


		if not number_text.is_valid_int():

			continue


		highest = max(
			highest,
			int(
				number_text
			)
		)


	return highest


# =============================================================
# SCAN HIGHEST ID IN OBJECT FILES
# =============================================================

func _get_highest_object_id_from_folder() -> int:

	var highest := 0


	var directory := DirAccess.open(
		OBJECT_FOLDER
	)


	if directory == null:

		return highest


	directory.list_dir_begin()


	var file_name := (
		directory.get_next()
	)


	while not file_name.is_empty():

		if directory.current_is_dir():

			file_name = (
				directory.get_next()
			)

			continue


		var basename := (
			file_name
			.get_basename()
		)


		if not basename.begins_with(
			"object_"
		):

			file_name = (
				directory.get_next()
			)

			continue


		var number_text := (
			basename.trim_prefix(
				"object_"
			)
		)


		if number_text.is_valid_int():

			highest = max(
				highest,
				int(
					number_text
				)
			)


		file_name = (
			directory.get_next()
		)


	directory.list_dir_end()


	return highest


# =============================================================
# GET HIGHEST OBJECT ID
# =============================================================

func _get_highest_known_object_id() -> int:

	var highest := 0


	# =========================================================
	# OBJECT LIBRARY
	# =========================================================

	for object_data: Dictionary in objects:

		var object_id := str(
			object_data.get(
				"id",
				""
			)
		)


		if not object_id.begins_with(
			"object_"
		):

			continue


		var number_text := (
			object_id.trim_prefix(
				"object_"
			)
		)


		if not number_text.is_valid_int():

			continue


		highest = max(
			highest,
			int(
				number_text
			)
		)


	# =========================================================
	# LIBRARY FILE
	# =========================================================

	highest = max(
		highest,
		_get_highest_object_id_from_file(
			LIBRARY_FILE
		)
	)


	# =========================================================
	# PROFILE FILE
	# =========================================================

	var profiles_file := (
		"user://ciga/profiles/profiles.json"
	)


	highest = max(
		highest,
		_get_highest_object_id_from_file(
			profiles_file
		)
	)


	# =========================================================
	# REAL FILES
	# =========================================================

	highest = max(
		highest,
		_get_highest_object_id_from_folder()
	)


	return highest


# =============================================================
# GENERATE ID
# =============================================================

func generate_object_id() -> String:

	var next_id := 1


	if FileAccess.file_exists(
		OBJECT_ID_COUNTER_FILE
	):

		var file := FileAccess.open(
			OBJECT_ID_COUNTER_FILE,
			FileAccess.READ
		)


		if file != null:

			var text := (
				file.get_as_text()
			)

			file.close()


			var parsed: Variant = (
				JSON.parse_string(
					text
				)
			)


			if parsed is Dictionary:

				var stored_next_id := int(
					(
						parsed
						as
						Dictionary
					).get(
						"next_id",
						1
					)
				)


				next_id = max(
					stored_next_id,
					1
				)


	var highest_known_id := (
		_get_highest_known_object_id()
	)


	next_id = max(
		next_id,
		highest_known_id + 1
	)


	var counter_file := FileAccess.open(
		OBJECT_ID_COUNTER_FILE,
		FileAccess.WRITE
	)


	if counter_file != null:

		counter_file.store_string(
			JSON.stringify(
				{
					"next_id":
						next_id + 1
				},
				"\t"
			)
		)

		counter_file.close()


	var generated_id := (
		"object_%03d"
		%
		next_id
	)


	return generated_id


# =============================================================
# IMPORT OBJECT
# =============================================================

func import_object(
	source_path: String,
	auto_scale_enabled: bool = true
) -> Dictionary:

	if source_path.is_empty():

		return {}


	var extension := (
		source_path
		.get_extension()
		.to_lower()
	)


	if (
		extension != "glb"
		and
		extension != "gltf"
	):

		push_error(
			"CIGA OBJECTS: Unsupported format: "
			+
			extension
		)

		return {}


	if not FileAccess.file_exists(
		source_path
	):

		push_error(
			"CIGA OBJECTS: File not found: "
			+
			source_path
		)

		return {}


	var bytes := (
		FileAccess.get_file_as_bytes(
			source_path
		)
	)


	if bytes.is_empty():

		push_error(
			"CIGA OBJECTS: File is empty."
		)

		return {}


	# =========================================================
	# ID
	# =========================================================

	var object_id := (
		generate_object_id()
	)


	# =========================================================
	# NAME
	# =========================================================

	var original_name := (
		source_path
		.get_file()
		.get_basename()
	)


	# =========================================================
	# DESTINATION
	# =========================================================

	var destination := (
		OBJECT_FOLDER
		+
		"/"
		+
		object_id
		+
		"."
		+
		extension
	)


	var file := FileAccess.open(
		destination,
		FileAccess.WRITE
	)


	if file == null:

		push_error(
			"CIGA OBJECTS: Could not create destination file."
		)

		return {}


	file.store_buffer(
		bytes
	)


	file.close()


	# =========================================================
	# AUTO SCALE
	# =========================================================

	var auto_scale := (
		DEFAULT_OBJECT_SCALE
	)


	if auto_scale_enabled:

		auto_scale = (
			calculate_auto_import_scale(
				destination
			)
		)


	# =========================================================
	# OBJECT DATA
	# =========================================================

	var object_data: Dictionary = {

		"id":
			object_id,

		"name":
			original_name,

		"extension":
			extension,

		"file_name":
			object_id
			+
			"."
			+
			extension,

		"source_path":
			destination,

		"original_path":
			source_path,

		"optimized_path":
			"",

		"optimized":
			false,

		"optimizer_quality":
			optimizer_quality,

		"optimizer_quality_name":
			get_optimizer_quality_name(),

		"file_size":
			bytes.size(),

		"base_scale":
			auto_scale,

		# Legacy compatibility only.
		"scale_multiplier":
			DEFAULT_SCALE_MULTIPLIER,

		# "scale" is the BASE scale in library data.
		"scale":
			auto_scale,

		"auto_scale":
			auto_scale_enabled
	}


	objects.append(
		object_data
	)


	active_object_id = (
		object_id
	)


	if not save_library():

		objects.pop_back()

		active_object_id = ""


		if FileAccess.file_exists(
			destination
		):

			DirAccess.remove_absolute(
				destination
			)


		return {}


	object_imported.emit(
		object_data.duplicate(
			true
		)
	)


	active_object_changed.emit(
		object_data.duplicate(
			true
		)
	)


	return (
		object_data.duplicate(
			true
		)
	)


# =============================================================
# PREPARE OBJECT FOR STARTUP
# =============================================================

func prepare_object_for_startup(
	object_id: String
) -> Dictionary:

	if object_id.is_empty():

		return {}


	var index := (
		find_object_index(
			object_id
		)
	)


	if index < 0:

		return {}


	var object_data := (
		objects[index]
	)


	# =========================================================
	# ENSURE OPTIMIZER
	# =========================================================

	if optimizer == null:

		optimizer = (
			CIGAObjectOptimizer.new()
		)


	optimizer.set_quality(
		optimizer_quality
	)


	# =========================================================
	# CHECK CURRENT CACHE
	# =========================================================

	var optimized_path := str(
		object_data.get(
			"optimized_path",
			""
		)
	)


	var cached_quality := int(
		object_data.get(
			"optimizer_quality",
			-1
		)
	)


	# =========================================================
	# CACHE VALID
	#
	# O cache só é considerado compatível se:
	#
	# 1. existir
	# 2. estiver marcado como optimizado
	# 3. a qualidade coincidir
	# =========================================================

	if (
		not optimized_path.is_empty()
		and
		FileAccess.file_exists(
			optimized_path
		)
		and
		bool(
			object_data.get(
				"optimized",
				false
			)
		)
		and
		cached_quality
		==
		optimizer_quality
	):

		return (
			object_data.duplicate(
				true
			)
		)


	# =========================================================
	# CACHE GLOBAL DO OPTIMIZER
	#
	# Mesmo que a library ainda não tenha o caminho guardado,
	# procuramos o cache padrão.
	# =========================================================

	var cache_path := (
		optimizer.get_cache_path(
			object_id
		)
	)


	if (
		not cache_path.is_empty()
		and
		FileAccess.file_exists(
			cache_path
		)
	):

		if cached_quality == optimizer_quality:

			object_data["optimized_path"] = (
				cache_path
			)

			object_data["optimized"] = true

			object_data["optimizer_quality"] = (
				optimizer_quality
			)

			object_data["optimizer_quality_name"] = (
				get_optimizer_quality_name()
			)

			objects[index] = object_data


			save_library()


			return (
				object_data.duplicate(
					true
				)
			)


	# =========================================================
	# QUALITY CHANGED
	#
	# O cache existe, mas pertence a outra qualidade.
	# Removemos apenas o cache optimizado.
	# =========================================================

	if (
		FileAccess.file_exists(
			cache_path
		)
	):

		optimizer.remove_cache(
			object_id
		)


	packed_scene_cache.erase(
		object_id
	)


	object_data["optimized"] = false

	object_data["optimized_path"] = ""

	object_data["optimizer_quality"] = (
		optimizer_quality
	)

	object_data["optimizer_quality_name"] = (
		get_optimizer_quality_name()
	)


	objects[index] = object_data


	save_library()


	# =========================================================
	# SOURCE
	# =========================================================

	var source_path := str(
		object_data.get(
			"source_path",
			""
		)
	)


	if source_path.is_empty():

		return (
			object_data.duplicate(
				true
			)
		)


	if not FileAccess.file_exists(
		source_path
	):

		return (
			object_data.duplicate(
				true
			)
		)


	# =========================================================
	# NOTA
	#
	# A criação real do cache continua a ser feita pelo
	# CIGAObjectOptimizer quando o import/runtime o solicita.
	#
	# Aqui apenas garantimos que o estado da library corresponde
	# à qualidade actualmente seleccionada.
	# =========================================================

	return (
		object_data.duplicate(
			true
		)
	)


# =============================================================
# PREPARE ALL OBJECTS
# =============================================================

func prepare_all_objects_for_startup() -> Array[Dictionary]:

	var prepared: Array[Dictionary] = []


	for object_data: Dictionary in objects:

		var object_id := str(
			object_data.get(
				"id",
				""
			)
		)


		if object_id.is_empty():

			continue


		var result := (
			prepare_object_for_startup(
				object_id
			)
		)


		if not result.is_empty():

			prepared.append(
				result
			)


	return prepared


# =============================================================
# REMOVE
# =============================================================

func remove_object(
	object_id: String
) -> bool:

	if object_id.is_empty():

		return false


	var index := (
		find_object_index(
			object_id
		)
	)


	if index < 0:

		return false


	var object_data := (
		objects[index]
		.duplicate(
			true
		)
	)


	var stored_path := str(
		object_data.get(
			"source_path",
			""
		)
	)


	clear_runtime_object_cache(
		object_id
	)


	# =========================================================
	# ORIGINAL
	# =========================================================

	if not stored_path.is_empty():

		if FileAccess.file_exists(
			stored_path
		):

			var remove_error := (
				DirAccess.remove_absolute(
					stored_path
				)
			)


			if remove_error != OK:

				push_error(
					"CIGA OBJECTS: Could not remove file: "
					+
					error_string(
						remove_error
					)
				)


	# =========================================================
	# OPTIMIZED CACHE
	# =========================================================

	if optimizer != null:

		optimizer.remove_cache(
			object_id
		)


	var optimized_path := str(
		object_data.get(
			"optimized_path",
			""
		)
	)


	if (
		not optimized_path.is_empty()
		and
		FileAccess.file_exists(
			optimized_path
		)
	):

		DirAccess.remove_absolute(
			optimized_path
		)


	# =========================================================
	# LIBRARY
	# =========================================================

	objects.remove_at(
		index
	)


	if active_object_id == object_id:

		active_object_id = ""


	save_library()


	object_removed.emit(
		object_data
	)


	active_object_changed.emit(
		{}
	)


	return true


# =============================================================
# ACTIVE OBJECT
# =============================================================

func set_active_object(
	object_id: String
) -> bool:

	if object_id.is_empty():

		active_object_id = ""


		active_object_changed.emit(
		{}
		)


		return true


	var object_data := (
		get_object(
			object_id
		)
	)


	if object_data.is_empty():

		return false


	active_object_id = (
		object_id
	)


	active_object_changed.emit(
		object_data
	)


	return true


# =============================================================
# INTERNAL RAW OBJECT
# =============================================================

func _get_raw_object(
	object_id: String
) -> Dictionary:

	if object_id.is_empty():

		return {}


	for object_data: Dictionary in objects:

		if str(
			object_data.get(
				"id",
				""
			)
		) != object_id:

			continue


		return (
			object_data
			.duplicate(
				true
			)
		)


	return {}


# =============================================================
# GET OBJECT
# =============================================================

func get_object(
	object_id: String
) -> Dictionary:

	var object_data := (
		_get_raw_object(
			object_id
		)
	)


	if object_data.is_empty():

		return {}


	var base_scale := clampf(
		float(
			object_data.get(
				"base_scale",
				DEFAULT_OBJECT_SCALE
			)
		),
		MIN_OBJECT_SCALE,
		MAX_OBJECT_SCALE
	)


	if not is_finite(
		base_scale
	):

		base_scale = (
			DEFAULT_OBJECT_SCALE
		)


	var multiplier := (
		_get_profile_scale_multiplier(
			object_id,
			base_scale
		)
	)


	var effective_scale := clampf(
		base_scale
		*
		multiplier,
		MIN_OBJECT_SCALE,
		MAX_OBJECT_SCALE
	)


	object_data["base_scale"] = (
		base_scale
	)

	object_data["scale_multiplier"] = (
		multiplier
	)

	object_data["profile_scale_multiplier"] = (
		multiplier
	)

	object_data["scale"] = (
		effective_scale
	)

	object_data["effective_scale"] = (
		effective_scale
	)


	return object_data


# =============================================================
# GET ACTIVE
# =============================================================

func get_active_object() -> Dictionary:

	if active_object_id.is_empty():

		return {}


	return get_object(
		active_object_id
	)


# =============================================================
# FIND INDEX
# =============================================================

func find_object_index(
	object_id: String
) -> int:

	if object_id.is_empty():

		return -1


	for index in range(
		objects.size()
	):

		if str(
			objects[index].get(
				"id",
				""
			)
		) == object_id:

			return index


	return -1


# =============================================================
# GET RAW BASE SCALE
# =============================================================

func _get_raw_base_scale(
	object_id: String
) -> float:

	var object_data := (
		_get_raw_object(
			object_id
		)
	)


	if object_data.is_empty():

		return DEFAULT_OBJECT_SCALE


	var base_scale := float(
		object_data.get(
			"base_scale",
			DEFAULT_OBJECT_SCALE
		)
	)


	if not is_finite(
		base_scale
	):

		base_scale = (
			DEFAULT_OBJECT_SCALE
		)


	return clampf(
		base_scale,
		MIN_OBJECT_SCALE,
		MAX_OBJECT_SCALE
	)


# =============================================================
# SET OBJECT SCALE
# =============================================================

func set_object_scale(
	object_id: String,
	value: float
) -> bool:

	if object_id.is_empty():

		return false


	auto_resolve_profile_manager()


	if profile_manager == null:

		return false


	var base_scale := (
		_get_raw_base_scale(
			object_id
		)
	)


	if base_scale <= 0.0:

		base_scale = (
			DEFAULT_OBJECT_SCALE
		)


	var safe_scale := clampf(
		float(
			value
		),
		MIN_OBJECT_SCALE,
		MAX_OBJECT_SCALE
	)


	var multiplier := (
		safe_scale
		/
		base_scale
	)


	if not is_finite(
		multiplier
	):

		multiplier = (
			DEFAULT_SCALE_MULTIPLIER
		)


	multiplier = clampf(
		multiplier,
		MIN_SCALE_MULTIPLIER,
		MAX_SCALE_MULTIPLIER
	)


	var saved := (
		profile_manager
		.set_active_object_scale_multiplier(
			object_id,
			multiplier
		)
	)


	return saved


# =============================================================
# SET SCALE MULTIPLIER
# =============================================================

func set_object_scale_multiplier(
	object_id: String,
	multiplier: float
) -> bool:

	if object_id.is_empty():

		return false


	auto_resolve_profile_manager()


	if profile_manager == null:

		return false


	var safe_multiplier := float(
		multiplier
	)


	if not is_finite(
		safe_multiplier
	):

		safe_multiplier = (
			DEFAULT_SCALE_MULTIPLIER
		)


	safe_multiplier = clampf(
		safe_multiplier,
		MIN_SCALE_MULTIPLIER,
		MAX_SCALE_MULTIPLIER
	)


	var result := (
		profile_manager
		.set_active_object_scale_multiplier(
			object_id,
			safe_multiplier
		)
	)


	return result


# =============================================================
# GET SCALE
# =============================================================

func get_object_scale(
	object_id: String
) -> float:

	return get_effective_object_scale(
		object_id
	)


# =============================================================
# GET EFFECTIVE SCALE
# =============================================================

func get_effective_object_scale(
	object_id: String
) -> float:

	if object_id.is_empty():

		return DEFAULT_OBJECT_SCALE


	var base_scale := (
		_get_raw_base_scale(
			object_id
		)
	)


	if base_scale <= 0.0:

		base_scale = (
			DEFAULT_OBJECT_SCALE
		)


	var multiplier := (
		_get_profile_scale_multiplier(
			object_id,
			base_scale
		)
	)


	return clampf(
		base_scale
		*
		multiplier,
		MIN_OBJECT_SCALE,
		MAX_OBJECT_SCALE
	)


# =============================================================
# GET BASE SCALE
# =============================================================

func get_object_base_scale(
	object_id: String
) -> float:

	return (
		_get_raw_base_scale(
			object_id
		)
	)


# =============================================================
# INTERNAL PROFILE SCALE MULTIPLIER
# =============================================================

func _get_profile_scale_multiplier(
	object_id: String,
	base_scale: float = 1.0
) -> float:

	if object_id.is_empty():

		return DEFAULT_SCALE_MULTIPLIER


	auto_resolve_profile_manager()


	if profile_manager == null:

		return DEFAULT_SCALE_MULTIPLIER


	var multiplier := float(
		profile_manager
		.get_active_object_scale_multiplier(
			object_id,
			base_scale
		)
	)


	if not is_finite(
		multiplier
	):

		multiplier = (
			DEFAULT_SCALE_MULTIPLIER
		)


	return clampf(
		multiplier,
		MIN_SCALE_MULTIPLIER,
		MAX_SCALE_MULTIPLIER
	)


# =============================================================
# GET SCALE MULTIPLIER
# =============================================================

func get_object_scale_multiplier(
	object_id: String
) -> float:

	if object_id.is_empty():

		return DEFAULT_SCALE_MULTIPLIER


	var base_scale := (
		_get_raw_base_scale(
			object_id
		)
	)


	return (
		_get_profile_scale_multiplier(
			object_id,
			base_scale
		)
	)


# =============================================================
# OBJECT PATH
# =============================================================

func get_object_path(
	object_id: String
) -> String:

	var object_data := (
		_get_raw_object(
			object_id
		)
	)


	if object_data.is_empty():

		return ""


	return str(
		object_data.get(
			"source_path",
			""
		)
	)


# =============================================================
# OBJECT LOAD PATH
# =============================================================

func get_object_load_path(
	object_id: String
) -> String:

	if object_id.is_empty():

		return ""


	var object_data := (
		_get_raw_object(
			object_id
		)
	)


	if object_data.is_empty():

		return ""


	var optimized_path := str(
		object_data.get(
			"optimized_path",
			""
		)
	)


	if (
		not optimized_path.is_empty()
		and
		FileAccess.file_exists(
			optimized_path
		)
	):

		return optimized_path


	if optimizer == null:

		optimizer = (
			CIGAObjectOptimizer.new()
		)


	optimizer.set_quality(
		optimizer_quality
	)


	var cache_path := (
		optimizer.get_cache_path(
			object_id
		)
	)


	if (
		not cache_path.is_empty()
		and
		FileAccess.file_exists(
			cache_path
		)
	):

		var index := (
			find_object_index(
				object_id
			)
		)


		if index >= 0:

			objects[index]["optimized_path"] = (
				cache_path
			)

			objects[index]["optimized"] = true

			objects[index]["optimizer_quality"] = (
				optimizer_quality
			)

			objects[index]["optimizer_quality_name"] = (
				get_optimizer_quality_name()
			)

			save_library()


		return cache_path


	var source_path := str(
		object_data.get(
			"source_path",
			""
		)
	)


	if (
		not source_path.is_empty()
		and
		FileAccess.file_exists(
			source_path
		)
	):

		return source_path


	return ""


# =============================================================
# GET CACHED PACKED SCENE
# =============================================================

func get_cached_packed_scene(
	object_id: String
) -> PackedScene:

	if object_id.is_empty():

		return null


	if packed_scene_cache.has(
		object_id
	):

		var cached_value: Variant = (
			packed_scene_cache[
				object_id
			]
		)


		if cached_value is PackedScene:

			return (
				cached_value
				as
				PackedScene
			)


		packed_scene_cache.erase(
			object_id
		)


	var load_path := (
		get_object_load_path(
			object_id
		)
	)


	if load_path.is_empty():

		return null


	# =========================================================
	# TSCN
	# =========================================================

	if load_path.to_lower().ends_with(
		".tscn"
	):

		var resource: Resource = (
			load(
				load_path
			)
		)


		if resource == null:

			return null


		if not resource is PackedScene:

			return null


		var packed_scene := (
			resource
			as
			PackedScene
		)


		packed_scene_cache[
			object_id
		] = (
			packed_scene
		)


		return packed_scene


	# =========================================================
	# GLB / GLTF
	# =========================================================

	var packed_from_model := (
		_load_glb_as_packed_scene(
			load_path
		)
	)


	if packed_from_model == null:

		return null


	packed_scene_cache[
		object_id
	] = (
		packed_from_model
	)


	return packed_from_model


# =============================================================
# LOAD GLB AS PACKED SCENE
# =============================================================

func _load_glb_as_packed_scene(
	path: String
) -> PackedScene:

	if path.is_empty():

		return null


	if not FileAccess.file_exists(
		path
	):

		return null


	var extension := (
		path
		.get_extension()
		.to_lower()
	)


	if (
		extension != "glb"
		and
		extension != "gltf"
	):

		return null


	var document := (
		GLTFDocument.new()
	)


	var state := (
		GLTFState.new()
	)


	var error := (
		document.append_from_file(
			path,
			state
		)
	)


	if error != OK:

		push_error(
			"CIGA OBJECT GLTF IMPORT FAILED | "
			+
			error_string(
				error
			)
		)

		return null


	var generated: Node = (
		document.generate_scene(
			state
		)
	)


	if generated == null:

		push_error(
			"CIGA OBJECT GLTF GENERATE FAILED | "
			+
			path
		)

		return null


	if not generated is Node3D:

		generated.queue_free()

		push_error(
			"CIGA OBJECT GLTF ROOT INVALID | "
			+
			path
		)

		return null


	var model := (
		generated
		as
		Node3D
	)


	var packed_scene := (
		PackedScene.new()
	)


	_set_owner_recursive(
		model,
		model
	)


	var pack_error := (
		packed_scene.pack(
			model
		)
	)


	if pack_error != OK:

		push_error(
			"CIGA OBJECT GLTF PACK FAILED | "
			+
			error_string(
				pack_error
			)
		)

		model.free()

		return null


	model.free()


	return packed_scene


# =============================================================
# AUTO SCALE
# =============================================================

func calculate_auto_import_scale(
	source_path: String
) -> float:

	if source_path.is_empty():

		return DEFAULT_OBJECT_SCALE


	if not FileAccess.file_exists(
		source_path
	):

		return DEFAULT_OBJECT_SCALE


	var model := (
		_load_glb_scene_for_scale(
			source_path
		)
	)


	if model == null:

		return DEFAULT_OBJECT_SCALE


	var bounds := (
		_calculate_model_bounds(
			model
		)
	)


	model.free()


	if bounds.size == Vector3.ZERO:

		return DEFAULT_OBJECT_SCALE


	var maximum_dimension := maxf(
		bounds.size.x,
		maxf(
			bounds.size.y,
			bounds.size.z
		)
	)


	if maximum_dimension <= 0.00001:

		return DEFAULT_OBJECT_SCALE


	var calculated_scale := (
		AUTO_SCALE_TARGET_SIZE
		/
		maximum_dimension
	)


	calculated_scale = clampf(
		calculated_scale,
		AUTO_SCALE_MIN,
		AUTO_SCALE_MAX
	)


	return calculated_scale


# =============================================================
# LOAD TEMPORARY GLTF
# =============================================================

func _load_glb_scene_for_scale(
	path: String
) -> Node3D:

	var document := (
		GLTFDocument.new()
	)


	var state := (
		GLTFState.new()
	)


	var error := (
		document.append_from_file(
			path,
			state
		)
	)


	if error != OK:

		push_error(
			"CIGA AUTO SCALE GLTF LOAD FAILED | "
			+
			error_string(
				error
			)
		)

		return null


	var generated := (
		document.generate_scene(
			state
		)
	)


	if generated == null:

		return null


	if not generated is Node3D:

		generated.free()

		return null


	return (
		generated
		as
		Node3D
	)


# =============================================================
# CALCULATE MODEL BOUNDS
# =============================================================

func _calculate_model_bounds(
	root: Node3D
) -> AABB:

	if root == null:

		return AABB()


	var result := (
		_calculate_model_bounds_recursive(
			root,
			Transform3D.IDENTITY
		)
	)


	return result.get(
		"bounds",
		AABB()
	)


# =============================================================
# CALCULATE MODEL BOUNDS RECURSIVE
# =============================================================

func _calculate_model_bounds_recursive(
	node: Node3D,
	parent_transform: Transform3D
) -> Dictionary:

	var combined := AABB()

	var valid := false


	if node == null:

		return {
			"bounds":
				combined,

			"valid":
				false
		}


	var current_transform := (
		parent_transform
		*
		node.transform
	)


	# =========================================================
	# MESH
	# =========================================================

	if node is MeshInstance3D:

		var mesh_instance := (
			node
			as
			MeshInstance3D
		)


		if mesh_instance.mesh != null:

			var mesh_aabb := (
				mesh_instance.mesh.get_aabb()
			)


			var transformed_aabb := (
				_transform_aabb(
					mesh_aabb,
					current_transform
				)
			)


			combined = (
				transformed_aabb
			)

			valid = true


	# =========================================================
	# CHILDREN
	# =========================================================

	for child: Node in node.get_children():

		if not child is Node3D:

			continue


		var child_result := (
			_calculate_model_bounds_recursive(
				child
				as
				Node3D,
				current_transform
			)
		)


		if not bool(
			child_result.get(
				"valid",
				false
			)
		):

			continue


		var child_bounds: AABB = (
			child_result.get(
				"bounds",
				AABB()
			)
		)


		if not valid:

			combined = (
				child_bounds
			)

			valid = true

		else:

			combined = (
				combined.merge(
					child_bounds
				)
			)


	return {
		"bounds":
			combined,

		"valid":
			valid
	}


# =============================================================
# TRANSFORM AABB
# =============================================================

func _transform_aabb(
	aabb: AABB,
	transform: Transform3D
) -> AABB:

	var points := [

		aabb.position,

		aabb.position
		+
		Vector3(
			aabb.size.x,
			0.0,
			0.0
		),

		aabb.position
		+
		Vector3(
			0.0,
			aabb.size.y,
			0.0
		),

		aabb.position
		+
		Vector3(
			0.0,
			0.0,
			aabb.size.z
		),

		aabb.position
		+
		Vector3(
			aabb.size.x,
			aabb.size.y,
			0.0
		),

		aabb.position
		+
		Vector3(
			aabb.size.x,
			0.0,
			aabb.size.z
		),

		aabb.position
		+
		Vector3(
			0.0,
			aabb.size.y,
			aabb.size.z
		),

		aabb.end
	]


	var result := AABB(
		transform
		*
		points[0],
		Vector3.ZERO
	)


	for index in range(
		1,
		points.size()
	):

		result = (
			result.expand(
				transform
				*
				points[index]
			)
		)


	return result


# =============================================================
# OWNER
# =============================================================

func _set_owner_recursive(
	node: Node,
	owner: Node
) -> void:

	if node == null:

		return


	if node != owner:

		node.owner = owner


	for child: Node in node.get_children():

		_set_owner_recursive(
			child,
			owner
		)


# =============================================================
# OPTIMIZED CHECK
# =============================================================

func object_has_optimized_cache(
	object_id: String
) -> bool:

	if object_id.is_empty():

		return false


	var object_data := (
		_get_raw_object(
			object_id
		)
	)


	if object_data.is_empty():

		return false


	var optimized_path := str(
		object_data.get(
			"optimized_path",
			""
		)
	)


	var cached_quality := int(
		object_data.get(
			"optimizer_quality",
			-1
		)
	)


	if (
		not optimized_path.is_empty()
		and
		FileAccess.file_exists(
			optimized_path
		)
		and
		bool(
			object_data.get(
				"optimized",
				false
			)
		)
		and
		cached_quality
		==
		optimizer_quality
	):

		return true


	if optimizer != null:

		var cache_path := (
			optimizer.get_cache_path(
				object_id
			)
		)


		if FileAccess.file_exists(
			cache_path
		):

			return (
				cached_quality
				==
				optimizer_quality
			)


	return false


# =============================================================
# HAS OBJECT
# =============================================================

func has_object(
	object_id: String
) -> bool:

	return not (
		_get_raw_object(
			object_id
		)
	).is_empty()


# =============================================================
# SUPPORTED FILE
# =============================================================

func is_supported_file(
	path: String
) -> bool:

	var extension := (
		path
		.get_extension()
		.to_lower()
	)


	return (
		extension == "glb"
		or
		extension == "gltf"
	)


# =============================================================
# FILE SIZE
# =============================================================

func format_file_size(
	size_bytes: int
) -> String:

	if size_bytes < 1024:

		return (
			str(
				size_bytes
			)
			+
			" B"
		)


	if size_bytes < 1024 * 1024:

		return (
			"%.2f KB"
			%
			(
				float(
					size_bytes
				)
				/
				1024.0
			)
		)


	if size_bytes < 1024 * 1024 * 1024:

		return (
			"%.2f MB"
			%
			(
				float(
					size_bytes
				)
				/
				1048576.0
			)
		)


	return (
		"%.2f GB"
		%
		(
			float(
				size_bytes
			)
			/
			1073741824.0
		)
	)


# =============================================================
# CLEAR RESOURCE CACHE
# =============================================================

func clear_runtime_resource_cache() -> void:

	packed_scene_cache.clear()


# =============================================================
# REMOVE ONE RESOURCE CACHE
# =============================================================

func clear_runtime_object_cache(
	object_id: String
) -> void:

	if object_id.is_empty():

		return


	packed_scene_cache.erase(
		object_id
	)
