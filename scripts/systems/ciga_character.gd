class_name CIGACharacters
extends RefCounted


# =============================================================
# CIGA CHARACTER MANAGER
# Godot 4.7.2
#
# BIBLIOTECA GLOBAL DE AVATARES
#
# IMPORTANTE:
# -------------------------------------------------------------
# A biblioteca de personagens é GLOBAL.
#
# Os perfis NÃO possuem cópias dos avatares.
# Cada perfil apenas guarda:
#
#     character_id
#
# Exemplo:
#
# PROFILE 1 -> character_001
# PROFILE 2 -> character_002
# PROFILE 3 -> character_001
#
# Todos utilizam a mesma biblioteca global.
#
# Este manager NÃO carrega modelos 3D.
# =============================================================


# =============================================================
# SIGNALS
# =============================================================

signal character_changed(
	character: Dictionary
)


# =============================================================
# PATHS
# =============================================================

const DATA_FOLDER: String = (
	"user://ciga"
)


const CHARACTERS_FOLDER: String = (
	DATA_FOLDER
	+
	"/assets/characters"
)


const LIBRARY_FILE: String = (
	CHARACTERS_FOLDER
	+
	"/library.json"
)


# =============================================================
# FORMATS
# =============================================================

const IMPORTABLE_FORMATS: Array[String] = [
	"vrm",
	"glb",
	"gltf"
]


const RUNTIME_FORMATS: Array[String] = [
	"vrm",
	"glb",
	"gltf"
]


# =============================================================
# CHARACTER TYPES
# =============================================================

const CHARACTER_TYPE_VRM: String = "vrm"
const CHARACTER_TYPE_NATIVE_3D: String = "native_3d"

const NATIVE_AVATAR_EXTENSION: String = "cigaavatar"


# =============================================================
# STATE
# =============================================================

# Biblioteca GLOBAL.
var characters: Array[Dictionary] = []


# Isto representa apenas a seleção actual em memória.
# O perfil é que guarda permanentemente o character_id.
var active_character_id: String = ""


# =============================================================
# INITIALIZE
# =============================================================

func initialize() -> void:

	ensure_directories()

	load_library()


# =============================================================
# DIRECTORIES
# =============================================================

func ensure_directories() -> void:

	DirAccess.make_dir_recursive_absolute(
		CHARACTERS_FOLDER
	)


# =============================================================
# LOAD LIBRARY
# =============================================================

func load_library() -> void:

	characters.clear()

	if not FileAccess.file_exists(
		LIBRARY_FILE
	):

		return


	var file := FileAccess.open(
		LIBRARY_FILE,
		FileAccess.READ
	)


	if file == null:

		push_error(
			"CIGA CHARACTER: Could not open library."
		)

		return


	var text := file.get_as_text()

	file.close()


	var parsed: Variant = (
		JSON.parse_string(
			text
		)
	)


	if not parsed is Dictionary:

		push_error(
			"CIGA CHARACTER: Invalid library JSON."
		)

		return


	var data := (
		parsed as Dictionary
	)


	var entries: Variant = (
		data.get(
			"characters",
			[]
		)
	)


	if not entries is Array:

		return


	# =========================================================
	# DEDUPLICATION
	# =========================================================

	var seen_ids: Dictionary = {}
	var seen_paths: Dictionary = {}


	for entry: Variant in entries:

		if not entry is Dictionary:

			continue


		var character := (
			entry as Dictionary
		)


		var character_id := str(
			character.get(
				"id",
				""
			)
		)


		var character_name := str(
			character.get(
				"name",
				""
			)
		)


		var source_path := str(
			character.get(
				"source_path",
				""
			)
		)


		# -----------------------------------------------------
		# ID inválido
		# -----------------------------------------------------

		if character_id.is_empty():

			continue


		# -----------------------------------------------------
		# PATH inválido
		# -----------------------------------------------------

		if source_path.is_empty():

			continue


		# -----------------------------------------------------
		# PATH que deixou de existir
		#
		# Não deixamos lixo na biblioteca.
		# -----------------------------------------------------

		if not FileAccess.file_exists(
			source_path
		):

			continue


		# -----------------------------------------------------
		# Nome vazio
		# -----------------------------------------------------

		if character_name.is_empty():

			character_name = (
				source_path
				.get_file()
				.get_basename()
			)


		if character_name.is_empty():

			character_name = character_id


		character["name"] = character_name


		# -----------------------------------------------------
		# Duplicado por ID
		# -----------------------------------------------------

		if seen_ids.has(
			character_id
		):

			continue


		# -----------------------------------------------------
		# Duplicado por ficheiro
		# -----------------------------------------------------

		var normalized_path := (
			source_path.to_lower()
		)


		if seen_paths.has(
			normalized_path
		):

			continue


		seen_ids[character_id] = true
		seen_paths[normalized_path] = true


		# =====================================================
		# CHARACTER TYPE
		# =====================================================
		#
		# IMPORTANTE:
		# Isto tem de ser resolvido ANTES dos outros defaults.
		#
		# Personagens antigas que não tinham character_type
		# continuam a ser tratadas como personagens importadas.
		# =====================================================

		if not character.has(
			"character_type"
		):

			character["character_type"] = CHARACTER_TYPE_VRM


		var character_type := str(
			character.get(
				"character_type",
				CHARACTER_TYPE_VRM
			)
		)


		# =====================================================
		# EXTENSION
		# =====================================================

		if not character.has(
			"extension"
		):

			character["extension"] = (
				source_path
				.get_extension()
				.to_lower()
			)


		var extension := str(
			character.get(
				"extension",
				""
			)
		).to_lower()


		# =====================================================
		# ORIGINAL FORMAT
		# =====================================================

		if not character.has(
			"original_format"
		):

			if character_type == CHARACTER_TYPE_NATIVE_3D:

				character["original_format"] = "native"

			else:

				character["original_format"] = extension


		# =====================================================
		# RUNTIME FORMAT
		# =====================================================

		if not character.has(
			"runtime_format"
		):

			if character_type == CHARACTER_TYPE_NATIVE_3D:

				character["runtime_format"] = "native"

			else:

				character["runtime_format"] = extension


		# =====================================================
		# FILE NAME
		# =====================================================

		if not character.has(
			"file_name"
		):

			character["file_name"] = (
				source_path.get_file()
			)


		# =====================================================
		# FILE SIZE
		# =====================================================

		if not character.has(
			"file_size"
		):

			character["file_size"] = (
				FileAccess
				.get_file_as_bytes(
					source_path
				)
				.size()
			)


		# =====================================================
		# RUNTIME SUPPORTED
		# =====================================================

		if not character.has(
			"runtime_supported"
		):

			if character_type == CHARACTER_TYPE_NATIVE_3D:

				character["runtime_supported"] = true

			else:

				character["runtime_supported"] = (
					RUNTIME_FORMATS.has(
						extension
					)
				)


		# =====================================================
		# ADD
		# =====================================================

		characters.append(
			character
		)


	# =========================================================
	# SAVE CLEANED LIBRARY
	# =========================================================

	save_library()


# =============================================================
# SAVE LIBRARY
# =============================================================

func save_library() -> bool:

	ensure_directories()


	var file := FileAccess.open(
		LIBRARY_FILE,
		FileAccess.WRITE
	)


	if file == null:

		push_error(
			"CIGA CHARACTER: Could not save library."
		)

		return false


	var data := {
		"characters":
			characters
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
# ID
# =============================================================

func generate_character_id() -> String:

	var highest_id := 0


	for character: Dictionary in characters:

		var raw_id := str(
			character.get(
				"id",
				""
			)
		)


		if not raw_id.begins_with(
			"character_"
		):

			continue


		var number_text := (
			raw_id.trim_prefix(
				"character_"
			)
		)


		if number_text.is_valid_int():

			highest_id = max(
				highest_id,
				int(
					number_text
				)
			)


	return (
		"character_%03d"
		%
		(
			highest_id + 1
		)
	)


# =============================================================
# IMPORT CHARACTER
# =============================================================

func import_character(
	source_path: String
) -> Dictionary:

	if source_path.is_empty():

		return {}


	if not FileAccess.file_exists(
		source_path
	):

		push_error(
			"CIGA CHARACTER: Source file does not exist."
		)

		return {}


	var extension := (
		source_path
		.get_extension()
		.to_lower()
	)


	# =========================================================
	# NATIVE CIGA AVATAR
	# =========================================================

	if extension == NATIVE_AVATAR_EXTENSION:

		print(
			"CIGA CHARACTER: BLOCKED NATIVE IMPORT | "
			+
			source_path
		)

		return {}


	# =========================================================
	# IMPORTABLE FORMATS
	# =========================================================

	if not IMPORTABLE_FORMATS.has(
		extension
	):

		push_error(
			"CIGA CHARACTER: Unsupported format: "
			+
			extension
		)

		return {}

	# =========================================================
	# DUPLICATE SOURCE CHECK
	# =========================================================

	var normalized_source := (
		source_path
		.to_lower()
	)


	for existing: Dictionary in characters:

		var existing_original := str(
			existing.get(
				"original_path",
				""
			)
		).to_lower()


		var existing_source := str(
			existing.get(
				"source_path",
				""
			)
		).to_lower()


		if (
			existing_original == normalized_source
			or
			existing_source == normalized_source
		):

			return (
				existing.duplicate(
					true
				)
			)


	# =========================================================
	# READ
	# =========================================================

	var bytes := (
		FileAccess.get_file_as_bytes(
			source_path
		)
	)


	if bytes.is_empty():

		push_error(
			"CIGA CHARACTER: File is empty."
		)

		return {}


	# =========================================================
	# ID
	# =========================================================

	var character_id := (
		generate_character_id()
	)


	var file_name := (
		character_id
		+
		"."
		+
		extension
	)


	var destination := (
		CHARACTERS_FOLDER
		+
		"/"
		+
		file_name
	)


	# =========================================================
	# COPY FILE
	# =========================================================

	var file := FileAccess.open(
		destination,
		FileAccess.WRITE
	)


	if file == null:

		push_error(
			"CIGA CHARACTER: Could not create destination."
		)

		return {}


	file.store_buffer(
		bytes
	)

	file.close()


	# =========================================================
	# NAME
	# =========================================================

	var character_name := (
		source_path
		.get_file()
		.get_basename()
	)


	if character_name.is_empty():

		character_name = character_id


	# =========================================================
	# RUNTIME
	# =========================================================

	var runtime_supported := (
		RUNTIME_FORMATS.has(
			extension
		)
	)


	# =========================================================
	# RECORD
	# =========================================================

	var character := {

		"id":
			character_id,

		"name":
			character_name,

		"character_type":
			CHARACTER_TYPE_VRM,

		"extension":
			extension,

		"original_format":
			extension,

		"runtime_format":
			(
				extension
				if runtime_supported
				else
				""
			),

		"file_name":
			file_name,

		"source_path":
			destination,

		"original_path":
			source_path,

		"file_size":
			bytes.size(),

		"runtime_supported":
			runtime_supported
	}


	characters.append(
		character
	)


	# =========================================================
	# SAVE
	# =========================================================

	if not save_library():

		characters.pop_back()


		if FileAccess.file_exists(
			destination
		):

			DirAccess.remove_absolute(
				destination
			)

		return {}


	return (
		character.duplicate(
			true
		)
	)
# =============================================================
# CREATE NATIVE 3D CHARACTER
# =============================================================
#
# Cria um personagem CIGA nativo.
#
# Este personagem NÃO depende de:
#
#     VRM
#     GLB
#     GLTF
#     Skeleton3D
#
# O ficheiro .cigaavatar guarda apenas a definição
# persistente do avatar.
# =============================================================

func create_native_character(
	character_name: String
) -> Dictionary:

	# =========================================================
	# NAME
	# =========================================================

	if character_name.strip_edges().is_empty():

		character_name = "CIGA Avatar"


	character_name = character_name.strip_edges()


	# =========================================================
	# ID
	# =========================================================

	var character_id := (
		generate_character_id()
	)


	# =========================================================
	# FILE
	# =========================================================

	var file_name := (
		character_id
		+
		"."
		+
		NATIVE_AVATAR_EXTENSION
	)


	var destination := (
		CHARACTERS_FOLDER
		+
		"/"
		+
		file_name
	)


	# =========================================================
	# DEFAULT AVATAR DEFINITION
	# =========================================================
	#
	# Version 2 corresponde à estrutura atual do
	# CIGACalibrationAvatar.
	# =========================================================

	var definition := {

		"version":
			2,

		"character_type":
			CHARACTER_TYPE_NATIVE_3D,

		"avatar":
			{
				"body_scale":
					1.0,

				"head_scale":
					1.0,

				"arm_length":
					1.0,

				"leg_length":
					1.0,

				"body_width":
					1.0,

				"shoulder_width":
					1.0
			},

		"pose":
			{
				"head_rotation":
					{
						"x": 0.0,
						"y": 0.0,
						"z": 0.0
					},

				"left_arm":
					0.0,

				"right_arm":
					0.0,

				"left_arm_rotation":
					0.0,

				"right_arm_rotation":
					0.0,

				"left_eye":
					true,

				"right_eye":
					true,

				"mouth":
					false
			},

		"tail":
			{
				"enabled":
					false,

				"length":
					0.55
			}
	}


	# =========================================================
	# CREATE FILE
	# =========================================================

	var file := FileAccess.open(
		destination,
		FileAccess.WRITE
	)


	if file == null:

		push_error(
			"CIGA CHARACTER: Could not create native avatar file."
		)

		return {}


	file.store_string(
		JSON.stringify(
			definition,
			"\t"
		)
	)

	file.close()


	# =========================================================
	# FILE SIZE
	# =========================================================

	var file_size := (
		FileAccess
		.get_file_as_bytes(
			destination
		)
		.size()
	)


	# =========================================================
	# CHARACTER RECORD
	# =========================================================

	var character := {

		"id":
			character_id,

		"name":
			character_name,

		"character_type":
			CHARACTER_TYPE_NATIVE_3D,

		"extension":
			NATIVE_AVATAR_EXTENSION,

		"original_format":
			"native",

		"runtime_format":
			"native",

		"file_name":
			file_name,

		"source_path":
			destination,

		"original_path":
			"",

		"file_size":
			file_size,

		"runtime_supported":
			true
	}


	# =========================================================
	# ADD TO LIBRARY
	# =========================================================

	characters.append(
		character
	)


	# =========================================================
	# SAVE LIBRARY
	# =========================================================

	if not save_library():

		characters.pop_back()


		if FileAccess.file_exists(
			destination
		):

			DirAccess.remove_absolute(
				destination
			)


		return {}


	# =========================================================
	# RETURN COPY
	# =========================================================

	return (
		character.duplicate(
			true
		)
	)


# =============================================================
# REMOVE
# =============================================================

func remove_character(
	character_id: String
) -> bool:

	if character_id.is_empty():

		return false


	var index := (
		find_character_index(
			character_id
		)
	)


	if index < 0:

		return false


	var character := (
		characters[index]
	)


	var source_path := str(
		character.get(
			"source_path",
			""
		)
	)


	# =========================================================
	# REMOVE FILE
	# =========================================================

	if (
		not source_path.is_empty()
		and
		FileAccess.file_exists(
			source_path
		)
	):

		var remove_error := (
			DirAccess.remove_absolute(
				source_path
			)
		)


		if remove_error != OK:

			push_error(
				"CIGA CHARACTER: Could not remove file: "
				+
				error_string(
					remove_error
				)
			)

			return false


	# =========================================================
	# REMOVE RECORD
	# =========================================================

	characters.remove_at(
		index
	)


	if active_character_id == character_id:

		active_character_id = ""


	save_library()


	character_changed.emit(
		{}
	)


	return true


# =============================================================
# FIND INDEX
# =============================================================

func find_character_index(
	character_id: String
) -> int:

	if character_id.is_empty():

		return -1


	for index in range(
		characters.size()
	):

		var character := (
			characters[index]
		)


		var current_id := str(
			character.get(
				"id",
				""
			)
		)


		if current_id == character_id:

			return index


	return -1


# =============================================================
# SET ACTIVE
# =============================================================

func set_active_character(
	character_id: String
) -> bool:

	# ---------------------------------------------------------
	# Limpar seleção.
	# ---------------------------------------------------------

	if character_id.is_empty():

		active_character_id = ""


		character_changed.emit(
			{}
		)


		return true


	# ---------------------------------------------------------
	# Validar contra a biblioteca GLOBAL.
	# ---------------------------------------------------------

	var character := (
		get_character(
			character_id
		)
	)


	if character.is_empty():

		active_character_id = ""


		character_changed.emit(
			{}
		)


		return false


	active_character_id = (
		character_id
	)


	character_changed.emit(
		character
	)


	return true


# =============================================================
# GET ACTIVE
# =============================================================

func get_active_character() -> Dictionary:

	if active_character_id.is_empty():

		return {}


	return get_character(
		active_character_id
	)


# =============================================================
# GET CHARACTER
# =============================================================

func get_character(
	character_id: String
) -> Dictionary:

	if character_id.is_empty():

		return {}


	for character: Dictionary in characters:

		if str(
			character.get(
				"id",
				""
			)
		) == character_id:

			return character


	return {}


# =============================================================
# CHARACTER TYPE
# =============================================================

func is_native_character(
	character: Dictionary
) -> bool:

	if character.is_empty():

		return false


	return (
		str(
			character.get(
				"character_type",
				""
			)
		)
		==
		CHARACTER_TYPE_NATIVE_3D
	)


# =============================================================
# EXISTS
# =============================================================

func has_character(
	character_id: String
) -> bool:

	return not get_character(
		character_id
	).is_empty()


# =============================================================
# RUNTIME SUPPORT
# =============================================================

func character_can_load_runtime(
	character: Dictionary
) -> bool:

	if character.is_empty():

		return false


	# ---------------------------------------------------------
	# NATIVE 3D
	# ---------------------------------------------------------

	if is_native_character(
		character
	):

		return true


	# ---------------------------------------------------------
	# IMPORTED CHARACTER
	# ---------------------------------------------------------

	return bool(
		character.get(
			"runtime_supported",
			false
		)
	)


# =============================================================
# RUNTIME PATH
# =============================================================

func get_runtime_path(
	character: Dictionary
) -> String:

	if character.is_empty():

		return ""


	# ---------------------------------------------------------
	# NATIVE CHARACTER
	#
	# Native avatars são construídos pelo
	# CIGACalibrationAvatar.
	#
	# Não são enviados para o loader VRM.
	# ---------------------------------------------------------

	if is_native_character(
		character
	):

		return ""


	# ---------------------------------------------------------
	# IMPORTED MODEL
	# ---------------------------------------------------------

	var path := str(
		character.get(
			"source_path",
			""
		)
	)


	if path.is_empty():

		return ""


	var extension := (
		path
		.get_extension()
		.to_lower()
	)


	if not RUNTIME_FORMATS.has(
		extension
	):

		return ""


	if not FileAccess.file_exists(
		path
	):

		return ""


	return path


# =============================================================
# LOAD NATIVE AVATAR DEFINITION
# =============================================================

func load_native_avatar_definition(
	character: Dictionary
) -> Dictionary:

	if character.is_empty():

		return {}


	if not is_native_character(
		character
	):

		return {}


	var path := str(
		character.get(
			"source_path",
			""
		)
	)


	if path.is_empty():

		return {}


	if not FileAccess.file_exists(
		path
	):

		push_error(
			"CIGA CHARACTER: Native avatar file does not exist."
		)

		return {}


	var file := FileAccess.open(
		path,
		FileAccess.READ
	)


	if file == null:

		push_error(
			"CIGA CHARACTER: Could not open native avatar."
		)

		return {}


	var text := file.get_as_text()

	file.close()


	var parsed: Variant = (
		JSON.parse_string(
			text
		)
	)


	if not parsed is Dictionary:

		push_error(
			"CIGA CHARACTER: Invalid native avatar definition."
		)

		return {}


	var definition := (
		parsed as Dictionary
	)


	if str(
		definition.get(
			"character_type",
			""
		)
	) != CHARACTER_TYPE_NATIVE_3D:

		push_error(
			"CIGA CHARACTER: Invalid native avatar type."
		)

		return {}


	return definition


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
