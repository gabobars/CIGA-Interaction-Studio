class_name CIGAProfiles
extends RefCounted


# =============================================================
# CIGA PROFILES
# Godot 4.7.2
#
# VERSÃO SINGLE-CONFIGURATION
#
# Existe apenas UMA configuração persistente.
#
#
# COMPATIBILIDADE
#
# A classe continua a expor:
#
#     profiles
#     active_profile_id
#
# para não partir código antigo.
#
#
# INTERNAMENTE:
#
#     profiles.size() == 1
#
#     active_profile_id == "profile_current"
#
#
# IMPORTANTE:
#
# Importar substitui a configuração actual.
#
# Criar configuração substitui a configuração actual.
#
# Remover configuração restaura a configuração base.
#
#
# SCALE:
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
#     base_scale × multiplier
# =============================================================


# =============================================================
# SIGNALS
# =============================================================

signal active_profile_changed(
	profile: Dictionary
)


signal profile_data_changed(
	profile: Dictionary,
	section: String,
	key: String
)


# =============================================================
# PATHS
# =============================================================

const CIGA_DATA_FOLDER: String = (
	"user://ciga"
)


const PROFILES_FOLDER: String = (
	CIGA_DATA_FOLDER
	+
	"/profiles"
)


const PROFILES_FILE: String = (
	PROFILES_FOLDER
	+
	"/profiles.json"
)


const ACTIVE_PROFILE_FILE: String = (
	PROFILES_FOLDER
	+
	"/active_profile.txt"
)


# =============================================================
# SINGLE CONFIGURATION
# =============================================================

const SINGLE_PROFILE_ID: String = (
	"profile_current"
)


const SINGLE_PROFILE_NAME: String = (
	"CIGA Configuration"
)


# =============================================================
# EXPORT
# =============================================================

const PROFILE_EXPORT_EXTENSION: String = (
	"cigaprofile"
)


const PROFILE_EXPORT_VERSION: int = 1


# =============================================================
# SCALE
# =============================================================

const MIN_PROFILE_SCALE_MULTIPLIER: float = 0.01

const MAX_PROFILE_SCALE_MULTIPLIER: float = 10.0

const MIN_EFFECTIVE_OBJECT_SCALE: float = 0.0001

const MAX_EFFECTIVE_OBJECT_SCALE: float = 100.0


# =============================================================
# LEGACY SCALE
# =============================================================

const LEGACY_MIN_VALID_SCALE: float = 0.01


# =============================================================
# VALID PAGES
# =============================================================

const VALID_PAGES: Array[String] = [

	"CHARACTER",

	"OBJECTS",

	"INTERACTION",

	"EVENTS",

	"PROFILES",

	"OUTPUT",

	"SETTINGS"
]


# =============================================================
# STATE
# =============================================================

# Mantido como Array para compatibilidade.
#
# Existe sempre exactamente UM Dictionary.
var profiles: Array[Dictionary] = []


# Mantido para compatibilidade.
#
# O valor é sempre:
#
#     profile_current
var active_profile_id: String = (
	SINGLE_PROFILE_ID
)


# =============================================================
# LOAD
# =============================================================

func load_profiles() -> void:

	print(
		"CIGA PROFILE PATH = ",
		ProjectSettings.globalize_path(
			PROFILES_FILE
		)
	)


	profiles.clear()


	active_profile_id = (
		SINGLE_PROFILE_ID
	)


	DirAccess.make_dir_recursive_absolute(
		PROFILES_FOLDER
	)


	# =========================================================
	# FILE DOES NOT EXIST
	# =========================================================

	if not FileAccess.file_exists(
		PROFILES_FILE
	):

		var configuration := (
			create_default_profile()
		)


		profiles.append(
			configuration.duplicate(
				true
			)
		)


		save_profiles()

		save_active_profile_id()


		print(
			"CIGA CONFIGURATION CREATED: ",
			SINGLE_PROFILE_NAME
		)


		return


	# =========================================================
	# OPEN
	# =========================================================

	var file := FileAccess.open(
		PROFILES_FILE,
		FileAccess.READ
	)


	if file == null:

		push_error(
			"CIGA PROFILE ERROR: Could not open profiles file."
		)


		var fallback := (
			create_default_profile()
		)


		profiles.append(
			fallback
		)


		save_profiles()


		return


	var text := (
		file.get_as_text()
	)


	file.close()


	if text.strip_edges().is_empty():

		var empty_fallback := (
			create_default_profile()
		)


		profiles.append(
			empty_fallback
		)


		save_profiles()

		save_active_profile_id()


		print(
			"CIGA CONFIGURATION FILE EMPTY | BASE CONFIGURATION CREATED"
		)


		return


	# =========================================================
	# PARSE
	# =========================================================

	var parsed: Variant = (
		JSON.parse_string(
			text
		)
	)


	# =========================================================
	# LEGACY ARRAY FORMAT
	#
	# O sistema antigo guardava:
	#
	# [
	#     profile,
	#     profile
	# ]
	#
	# Agora usamos apenas uma configuração.
	# =========================================================

	if parsed is Array:

		var parsed_array: Array = (
			parsed
			as
			Array
		)


		var selected_profile: Dictionary = {}


		# =====================================================
		# Tentar localizar a configuração anteriormente activa.
		# =====================================================

		var previous_active_id := (
			load_active_profile_id()
		)


		if not previous_active_id.is_empty():

			for entry: Variant in parsed_array:

				if not entry is Dictionary:

					continue


				var candidate := (
					(entry as Dictionary)
					.duplicate(
						true
					)
				)


				if str(
					candidate.get(
						"id",
						""
					)
				) == previous_active_id:

					selected_profile = (
						candidate
					)

					break


		# =====================================================
		# Fallback para primeiro profile válido.
		# =====================================================

		if selected_profile.is_empty():

			for entry: Variant in parsed_array:

				if not entry is Dictionary:

					continue


				selected_profile = (
					(entry as Dictionary)
					.duplicate(
						true
					)
				)


				break


		if selected_profile.is_empty():

			selected_profile = (
				create_default_profile()
			)


		# =====================================================
		# SINGLE CONFIGURATION ID
		# =====================================================

		selected_profile["id"] = (
			SINGLE_PROFILE_ID
		)


		_ensure_profile_structure(
			selected_profile
		)


		_make_profile_data_exclusive(
			selected_profile
		)


		profiles.append(
			selected_profile
		)


		active_profile_id = (
			SINGLE_PROFILE_ID
		)


		# =====================================================
		# SAVE MIGRATED CONFIGURATION
		# =====================================================

		save_profiles()

		save_active_profile_id()


		print(
			"CIGA PROFILE MIGRATED | SINGLE CONFIGURATION"
		)


		print(
			"PROFILES LOADED: 1 | ACTIVE=",
			active_profile_id
		)


		return


	# =========================================================
	# NEW SINGLE DICTIONARY FORMAT
	#
	# Também aceitamos:
	#
	# {
	#     "id": "...",
	#     ...
	# }
	#
	# =========================================================

	if parsed is Dictionary:

		var single_profile := (
			(parsed as Dictionary)
			.duplicate(
				true
			)
		)


		# =====================================================
		# Caso:
		#
		# {
		#     "profile": {...}
		# }
		# =====================================================

		if single_profile.has(
			"profile"
		):

			var profile_value: Variant = (
				single_profile.get(
					"profile",
					null
				)
			)


			if profile_value is Dictionary:

				single_profile = (
					(profile_value as Dictionary)
					.duplicate(
						true
					)
				)


		single_profile["id"] = (
			SINGLE_PROFILE_ID
		)


		_ensure_profile_structure(
			single_profile
		)


		_make_profile_data_exclusive(
			single_profile
		)


		profiles.append(
			single_profile
		)


		active_profile_id = (
			SINGLE_PROFILE_ID
		)


		save_profiles()

		save_active_profile_id()


		print(
			"PROFILES LOADED: 1 | ACTIVE=",
			active_profile_id
		)


		return


	# =========================================================
	# INVALID
	# =========================================================

	push_error(
		"CIGA PROFILE ERROR: Invalid configuration format."
	)


	var recovery_profile := (
		create_default_profile()
	)


	profiles.append(
		recovery_profile
	)


	active_profile_id = (
		SINGLE_PROFILE_ID
	)


	save_profiles()

	save_active_profile_id()


	print(
		"CIGA CONFIGURATION RECOVERED"
	)


# =============================================================
# MAKE PROFILE DATA EXCLUSIVE
# =============================================================

func _make_profile_data_exclusive(
	profile: Dictionary
) -> void:

	if profile.is_empty():

		return


	var sections: Array[String] = [

		"character",

		"objects",

		"interaction",

		"events",

		"output",

		"settings",

		"camera",

		"viewport"
	]


	for section_name: String in sections:

		var section_value: Variant = (
			profile.get(
				section_name,
				{}
			)
		)


		if section_value is Dictionary:

			profile[section_name] = (
				(section_value as Dictionary)
				.duplicate(
					true
				)
			)


# =============================================================
# SAVE ACTIVE PROFILE ID
#
# Mantido para compatibilidade.
# =============================================================

func save_active_profile_id() -> void:

	DirAccess.make_dir_recursive_absolute(
		PROFILES_FOLDER
	)


	var file := FileAccess.open(
		ACTIVE_PROFILE_FILE,
		FileAccess.WRITE
	)


	if file == null:

		push_error(
			"CIGA PROFILE ERROR: Could not save active configuration."
		)

		return


	file.store_string(
		SINGLE_PROFILE_ID
	)


	file.close()


# =============================================================
# LOAD ACTIVE PROFILE ID
#
# Nesta versão retorna sempre o ID único.
# =============================================================

func load_active_profile_id() -> String:

	if not FileAccess.file_exists(
		ACTIVE_PROFILE_FILE
	):

		return (
			SINGLE_PROFILE_ID
		)


	var file := FileAccess.open(
		ACTIVE_PROFILE_FILE,
		FileAccess.READ
	)


	if file == null:

		return (
			SINGLE_PROFILE_ID
		)


	var stored_id := (
		file
		.get_as_text()
		.strip_edges()
	)


	file.close()


	if stored_id.is_empty():

		return (
			SINGLE_PROFILE_ID
		)


	return (
		SINGLE_PROFILE_ID
	)


# =============================================================
# ENSURE PROFILE
# =============================================================

func _ensure_profile_structure(
	profile: Dictionary
) -> bool:

	var changed := false


	# =========================================================
	# GENERAL
	# =========================================================

	if not profile.has(
		"id"
	):

		profile["id"] = (
			SINGLE_PROFILE_ID
		)

		changed = true

	else:

		if str(
			profile["id"]
		) != SINGLE_PROFILE_ID:

			profile["id"] = (
				SINGLE_PROFILE_ID
			)

			changed = true


# =========================================================
# CONFIGURATION NAME
#
# Existe apenas uma configuração.
# O nome é sempre fixo.
# =========================================================

	if str(
	profile.get(
		"name",
		""
	)
) != SINGLE_PROFILE_NAME:

		profile["name"] = (
		SINGLE_PROFILE_NAME
	)

	changed = true


	if not profile.has(
		"character_id"
	):

		profile["character_id"] = ""

		changed = true


	if not profile.has(
		"last_page"
	):

		profile["last_page"] = "CHARACTER"

		changed = true


	if not VALID_PAGES.has(
		str(
			profile["last_page"]
		)
	):

		profile["last_page"] = "CHARACTER"

		changed = true


	# =========================================================
	# CHARACTER
	# =========================================================

	if not profile.has(
		"character"
	):

		profile["character"] = {}

		changed = true


	if not profile["character"] is Dictionary:

		profile["character"] = {}

		changed = true


	var character_section := (
		profile["character"]
		as
		Dictionary
	)


	if not character_section.has(
		"load_on_launch"
	):

		character_section["load_on_launch"] = false

		changed = true


	if not character_section.has(
		"mapped"
	):

		character_section["mapped"] = false

		changed = true


	if not character_section.has(
		"enabled_hitpoints"
	):

		character_section["enabled_hitpoints"] = [

			"HeadHitPoint",

			"ChestHitPoint",

			"LeftShoulderHitPoint",

			"RightShoulderHitPoint",

			"LeftArmHitPoint",

			"RightArmHitPoint"
		]

		changed = true


	if not character_section[
		"enabled_hitpoints"
	] is Array:

		character_section[
			"enabled_hitpoints"
		] = []

		changed = true


	if not character_section.has(
		"bone_map"
	):

		character_section["bone_map"] = {}

		changed = true


	if not character_section[
		"bone_map"
	] is Dictionary:

		character_section[
			"bone_map"
		] = {}

		changed = true


	if not character_section.has(
		"avatar_mappings"
	):

		character_section[
			"avatar_mappings"
		] = {}

		changed = true


	if not character_section[
		"avatar_mappings"
	] is Dictionary:

		character_section[
			"avatar_mappings"
		] = {}

		changed = true


	profile["character"] = (
		character_section
		.duplicate(
			true
		)
	)


	# =========================================================
	# OBJECTS
	# =========================================================

	if not profile.has(
		"objects"
	):

		profile["objects"] = {}

		changed = true


	if not profile["objects"] is Dictionary:

		profile["objects"] = {}

		changed = true


	var object_section := (
		profile["objects"]
		as
		Dictionary
	)


	# =========================================================
	# SCALE MULTIPLIERS
	# =========================================================

	if not object_section.has(
		"scale_multipliers"
	):

		object_section[
			"scale_multipliers"
		] = {}

		changed = true


	if not object_section[
		"scale_multipliers"
	] is Dictionary:

		object_section[
			"scale_multipliers"
		] = {}

		changed = true


	# =========================================================
	# LEGACY SCALES
	# =========================================================

	if not object_section.has(
		"scales"
	):

		object_section["scales"] = {}

		changed = true


	if not object_section[
		"scales"
	] is Dictionary:

		object_section["scales"] = {}

		changed = true


	# =========================================================
	# SELECTED OBJECT
	# =========================================================

	if not object_section.has(
		"selected_object_id"
	):

		object_section[
			"selected_object_id"
		] = ""

		changed = true


	# =========================================================
	# CLEAN MULTIPLIERS
	# =========================================================

	var multiplier_source := (
		object_section[
			"scale_multipliers"
		]
		as
		Dictionary
	)


	var cleaned_multipliers: Dictionary = {}


	for object_id_value: Variant in multiplier_source.keys():

		var object_id := str(
			object_id_value
		)


		if object_id.is_empty():

			changed = true

			continue


		var raw_multiplier := float(
			multiplier_source.get(
				object_id_value,
				1.0
			)
		)


		if not is_finite(
			raw_multiplier
		):

			raw_multiplier = 1.0

			changed = true


		var safe_multiplier := clampf(
			raw_multiplier,
			MIN_PROFILE_SCALE_MULTIPLIER,
			MAX_PROFILE_SCALE_MULTIPLIER
		)


		if not is_equal_approx(
			raw_multiplier,
			safe_multiplier
		):

			changed = true


		cleaned_multipliers[
			object_id
		] = (
			safe_multiplier
		)


	object_section[
		"scale_multipliers"
	] = (
		cleaned_multipliers
	)


	# =========================================================
	# CLEAN LEGACY
	# =========================================================

	var legacy_source := (
		object_section[
			"scales"
		]
		as
		Dictionary
	)


	var cleaned_legacy: Dictionary = {}


	for object_id_value: Variant in legacy_source.keys():

		var object_id := str(
			object_id_value
		)


		if object_id.is_empty():

			changed = true

			continue


		var raw_scale := float(
			legacy_source.get(
				object_id_value,
				LEGACY_MIN_VALID_SCALE
			)
		)


		if not is_finite(
			raw_scale
		):

			changed = true

			continue


		if raw_scale < LEGACY_MIN_VALID_SCALE:

			changed = true

			continue


		cleaned_legacy[
			object_id
		] = clampf(
			raw_scale,
			LEGACY_MIN_VALID_SCALE,
			MAX_EFFECTIVE_OBJECT_SCALE
		)


	object_section["scales"] = (
		cleaned_legacy
	)


	profile["objects"] = (
		object_section
		.duplicate(
			true
		)
	)


	# =========================================================
	# INTERACTION
	# =========================================================

	if not profile.has(
		"interaction"
	):

		profile["interaction"] = {}

		changed = true


	if not profile["interaction"] is Dictionary:

		profile["interaction"] = {}

		changed = true


	var interaction_section := (
		profile["interaction"]
		as
		Dictionary
	)


	var interaction_defaults := {

		"object_id":
			"",

		"random_object":
			false,

		"target":
			"CHEST",

		"random_target":
			false,

		"spawn":
			"CENTER",

		"force":
			1.8,

		"speed":
			5.4,

		"amount":
			1,

		"scale":
			1.0,

		"object_scales":
			{}
	}


	for key: String in interaction_defaults:

		if not interaction_section.has(
			key
		):

			var default_value: Variant = (
				interaction_defaults[
					key
				]
			)


			if (
				default_value is Dictionary
				or
				default_value is Array
			):

				interaction_section[key] = (
					default_value
					.duplicate(
						true
					)
				)

			else:

				interaction_section[key] = (
					default_value
				)


			changed = true


	var interaction_object_scales: Variant = (
		interaction_section.get(
			"object_scales",
			{}
		)
	)


	if interaction_object_scales is Dictionary:

		interaction_section[
			"object_scales"
		] = (
			(interaction_object_scales as Dictionary)
			.duplicate(
				true
			)
		)

	else:

		interaction_section[
			"object_scales"
		] = {}

		changed = true


	profile["interaction"] = (
		interaction_section
		.duplicate(
			true
		)
	)


	# =========================================================
	# EVENTS
	# =========================================================

	if not profile.has(
		"events"
	):

		profile["events"] = {}

		changed = true


	if not profile["events"] is Dictionary:

		profile["events"] = {}

		changed = true


	profile["events"] = (
		(profile["events"] as Dictionary)
		.duplicate(
			true
		)
	)


# =========================================================
# OUTPUT
# =========================================================

	if not profile.has(
	"output"
):

		profile["output"] = {}

		changed = true


	if not profile["output"] is Dictionary:

		profile["output"] = {}

		changed = true


	var output_section := (
	profile["output"]
	as
	Dictionary
)


# =========================================================
# OUTPUT MODE
# =========================================================

	if not output_section.has(
	"mode"
):

		output_section["mode"] = "internal"

		changed = true


# =========================================================
# OUTPUT SOURCES
# =========================================================

	if not output_section.has(
	"sources"
):

		output_section["sources"] = {}

		changed = true


	if not output_section["sources"] is Dictionary:

		output_section["sources"] = {}

		changed = true


	var output_sources := (
	output_section["sources"]
	as
	Dictionary
)


# =========================================================
# CIGAIS WORKER
# =========================================================

	if not output_sources.has(
	"CIGAIS_WORKER"
):

		output_sources["CIGAIS_WORKER"] = {

		"guild_id":
			""
	}

		changed = true


	if not output_sources["CIGAIS_WORKER"] is Dictionary:

		output_sources["CIGAIS_WORKER"] = {

		"guild_id":
			""
	}

		changed = true


	var cigais_worker_config := (
	output_sources["CIGAIS_WORKER"]
	as
	Dictionary
)


# =========================================================
# GUILD ID
# =========================================================

	if not cigais_worker_config.has(
	"guild_id"
):

		cigais_worker_config["guild_id"] = ""

		changed = true


	output_sources["CIGAIS_WORKER"] = (
	cigais_worker_config
	.duplicate(
		true
	)
)


	output_section["sources"] = (
	output_sources
	.duplicate(
		true
	)
)


	profile["output"] = (
	output_section
	.duplicate(
		true
	)
)


	# =========================================================
	# SETTINGS
	# =========================================================

	if not profile.has(
		"settings"
	):

		profile["settings"] = {}

		changed = true


	if not profile["settings"] is Dictionary:

		profile["settings"] = {}

		changed = true


	var settings_section := (
		profile["settings"]
		as
		Dictionary
	)


	var setting_defaults := {

		"object_lifetime":
			5.0,

		"max_objects":
			50,

		"default_force":
			1.8,

		"default_speed":
			5.4,

		"default_bounce":
			0.2,

		"default_spin":
			0.0,

		"ui_mode":
			"dark",

		"streamer_mode":
			false
	}


	for key: String in setting_defaults:

		if not settings_section.has(
			key
		):

			settings_section[key] = (
				setting_defaults[key]
			)

			changed = true


	profile["settings"] = (
		settings_section
		.duplicate(
			true
		)
	)


	# =========================================================
	# CAMERA
	# =========================================================

	if not profile.has(
		"camera"
	):

		profile["camera"] = {}

		changed = true


	if not profile["camera"] is Dictionary:

		profile["camera"] = {}

		changed = true


	var camera_section := (
		profile["camera"]
		as
		Dictionary
	)


	var camera_defaults := {

		"x":
			0.0,

		"y":
			1.4,

		"z":
			4.0,

		"fov":
			40.0,

		"flipped":
			false
	}


	for key: String in camera_defaults:

		if not camera_section.has(
			key
		):

			camera_section[key] = (
				camera_defaults[key]
			)

			changed = true


	profile["camera"] = (
		camera_section
		.duplicate(
			true
		)
	)


	# =========================================================
	# VIEWPORT
	# =========================================================

	if not profile.has(
		"viewport"
	):

		profile["viewport"] = {}

		changed = true


	if not profile["viewport"] is Dictionary:

		profile["viewport"] = {}

		changed = true


	var viewport_section := (
		profile["viewport"]
		as
		Dictionary
	)


	var viewport_defaults := {

		"width":
			1920,

		"height":
			1080,

		"window_mode":
			"windowed",

		"edge_left_top":
			true,

		"edge_left_bottom":
			true,

		"edge_right_top":
			true,

		"edge_right_bottom":
			true,

		"edge_top_center":
			true,

		"edge_bottom_center":
			true,

		"impact_orientation_flipped":
			false,

		"streamer_mode":
			false
	}


	for key: String in viewport_defaults:

		if not viewport_section.has(
			key
		):

			viewport_section[key] = (
				viewport_defaults[key]
			)

			changed = true


	profile["viewport"] = (
		viewport_section
		.duplicate(
			true
		)
	)


	# =========================================================
	# FINAL COPY
	# =========================================================

	_make_profile_data_exclusive(
		profile
	)


	return changed


# =============================================================
# BASE CONFIGURATION
#
# Mantemos o nome da função create_default_profile()
# para compatibilidade com código existente.
#
# O nome visível da configuração NÃO é "Default".
# =============================================================

func create_default_profile() -> Dictionary:

	var profile: Dictionary = {

		"id":
			SINGLE_PROFILE_ID,

		"name":
			SINGLE_PROFILE_NAME,

		"character_id":
			"",

		"last_page":
			"CHARACTER",


		"character": {

			"load_on_launch":
				false,

			"mapped":
				false,

			"enabled_hitpoints": [

				"HeadHitPoint",

				"ChestHitPoint",

				"LeftShoulderHitPoint",

				"RightShoulderHitPoint",

				"LeftArmHitPoint",

				"RightArmHitPoint"
			],

			"bone_map":
				{},

			"avatar_mappings":
				{}
		},


		"objects": {

			"scale_multipliers":
				{},

			"scales":
				{},

			"selected_object_id":
				""
		},


		"interaction": {

			"object_id":
				"",

			"random_object":
				false,

			"target":
				"CHEST",

			"random_target":
				false,

			"spawn":
				"CENTER",

			"force":
				1.8,

			"speed":
				5.4,

			"amount":
				1,

			"scale":
				1.0,

			"object_scales":
				{}
		},


		"events":
			{},


		"output": {

			"mode":
				"internal",

		"sources": {

			"CIGAIS_WORKER": {

				"guild_id":
					""
		}
	}
},

		"settings": {

			"object_lifetime":
				5.0,

			"max_objects":
				50,

			"default_force":
				1.8,

			"default_speed":
				5.4,

			"default_bounce":
				0.2,

			"default_spin":
				0.0,

			"ui_mode":
				"dark",

			"streamer_mode":
				false
		},


		"camera": {

			"x":
				0.0,

			"y":
				1.4,

			"z":
				4.0,

			"fov":
				40.0,

			"flipped":
				false
		},


		"viewport": {

			"width":
				1920,

			"height":
				1080,

			"window_mode":
				"windowed",

			"edge_left_top":
				true,

			"edge_left_bottom":
				true,

			"edge_right_top":
				true,

			"edge_right_bottom":
				true,

			"edge_top_center":
				true,

			"edge_bottom_center":
				true,

			"impact_orientation_flipped":
				false,

			"streamer_mode":
				false
		}
	}


	var result := (
		profile.duplicate(
			true
		)
	)


	_ensure_profile_structure(
		result
	)


	_make_profile_data_exclusive(
		result
	)


	return result


# =============================================================
# SAVE
#
# Guardamos apenas UMA configuração.
#
# Mantemos o formato Array para compatibilidade.
#
# Resultado:
#
# [
#     {
#         "id": "profile_current",
#         ...
#     }
# ]
# =============================================================

func save_profiles() -> bool:

	DirAccess.make_dir_recursive_absolute(
		PROFILES_FOLDER
	)


	if profiles.is_empty():

		profiles.append(
			create_default_profile()
		)


	var current_profile := (
		profiles[0]
	)


	current_profile["id"] = (
		SINGLE_PROFILE_ID
	)


	_ensure_profile_structure(
		current_profile
	)


	_make_profile_data_exclusive(
		current_profile
	)


	profiles[0] = (
		current_profile
	)


	var file := FileAccess.open(
		PROFILES_FILE,
		FileAccess.WRITE
	)


	if file == null:

		push_error(
			"CIGA PROFILE ERROR: Could not save configuration."
		)

		return false


	var stored_data: Array = [

		current_profile.duplicate(
			true
		)
	]


	file.store_string(
		JSON.stringify(
			stored_data,
			"\t"
		)
	)


	file.close()


	active_profile_id = (
		SINGLE_PROFILE_ID
	)


	save_active_profile_id()


	return true


# =============================================================
# GET ACTIVE
# =============================================================

func get_active_profile() -> Dictionary:

	# =========================================================
	# AUTO-CREATE
	# =========================================================

	if profiles.is_empty():

		var new_profile := (
			create_default_profile()
		)


		profiles.append(
			new_profile
		)


		active_profile_id = (
			SINGLE_PROFILE_ID
		)


		return (
			profiles[0]
		)


	# =========================================================
	# FORCE SINGLE PROFILE
	# =========================================================

	if profiles.size() > 1:

		var current := (
			profiles[0]
			.duplicate(
				true
			)
		)


		profiles.clear()


		profiles.append(
			current
		)


	# =========================================================
	# NORMALIZE
	# =========================================================

	var profile := (
		profiles[0]
	)


	profile["id"] = (
		SINGLE_PROFILE_ID
	)


	_ensure_profile_structure(
		profile
	)


	_make_profile_data_exclusive(
		profile
	)


	active_profile_id = (
		SINGLE_PROFILE_ID
	)


	return profile


# =============================================================
# GET PROFILE
#
# Compatibilidade.
#
# Como só existe uma configuração:
# qualquer ID resolve para a configuração actual.
# =============================================================

func get_profile(
	profile_id: String
) -> Dictionary:

	if profile_id.is_empty():

		return {}


	if profile_id != SINGLE_PROFILE_ID:

		print(
			"CIGA LEGACY CONFIGURATION ID RESOLVED | ",
			profile_id,
			" -> ",
			SINGLE_PROFILE_ID
		)


	return (
		get_active_profile()
	)


# =============================================================
# SET ACTIVE PROFILE
#
# Compatibilidade.
#
# Não existe mudança real de profile.
# =============================================================

func set_active_profile(
	_profile_id: String
) -> bool:

	active_profile_id = (
		SINGLE_PROFILE_ID
	)


	var profile := (
		get_active_profile()
	)


	if profile.is_empty():

		return false


	active_profile_changed.emit(
		profile
	)


	print(
		"CIGA ACTIVE CONFIGURATION | ",
		SINGLE_PROFILE_ID
	)


	return true


# =============================================================
# RESET CURRENT CONFIGURATION
# =============================================================

func reset_current_profile() -> Dictionary:

	var new_configuration := (
		create_default_profile()
	)


	profiles.clear()


	profiles.append(
		new_configuration.duplicate(
			true
		)
	)


	active_profile_id = (
		SINGLE_PROFILE_ID
	)


	if not save_profiles():

		return {}


	print(
		"CIGA CONFIGURATION RESET"
	)


	var result := (
		profiles[0].duplicate(
			true
		)
	)


	active_profile_changed.emit(
		result
	)


	return result


# =============================================================
# CREATE PROFILE
#
# Compatibilidade.
#
# Agora simplesmente substitui a configuração actual.
# =============================================================

func create_profile(
	profile_name: String
) -> Dictionary:

	var clean_name := (
		profile_name
		.strip_edges()
	)


	if clean_name.is_empty():

		clean_name = (
			SINGLE_PROFILE_NAME
		)


	var profile := (
		create_default_profile()
	)


	profile["name"] = (
		clean_name
	)


	profile["id"] = (
		SINGLE_PROFILE_ID
	)


	_ensure_profile_structure(
		profile
	)


	_make_profile_data_exclusive(
		profile
	)


	profiles.clear()


	profiles.append(
		profile
	)


	active_profile_id = (
		SINGLE_PROFILE_ID
	)


	if not save_profiles():

		return {}


	print(
		"CIGA CONFIGURATION REPLACED | NAME=",
		clean_name
	)


	var result := (
		profile.duplicate(
			true
		)
	)


	active_profile_changed.emit(
		result
	)


	return result


# =============================================================
# REMOVE PROFILE
#
# Compatibilidade.
#
# Não elimina a configuração.
# Restaura a configuração base.
# =============================================================

func remove_profile(
	_profile_id: String
) -> bool:

	var result := (
		reset_current_profile()
	)


	return not result.is_empty()


# =============================================================
# UNIVERSAL GET
# =============================================================

func get_active_value(
	section_name: String,
	key: String,
	default_value: Variant = null
) -> Variant:

	var profile := (
		get_active_profile()
	)


	if profile.is_empty():

		return default_value


	var section_value: Variant = (
		profile.get(
			section_name,
			null
		)
	)


	if not section_value is Dictionary:

		return default_value


	var section := (
		section_value
		as
		Dictionary
	)


	return section.get(
		key,
		default_value
	)


# =============================================================
# UNIVERSAL SET
# =============================================================

func set_active_value(
	section_name: String,
	key: String,
	value: Variant
) -> bool:

	var profile := (
		get_active_profile()
	)


	if profile.is_empty():

		return false


	var section_value: Variant = (
		profile.get(
			section_name,
			null
		)
	)


	var section: Dictionary = {}


	if section_value is Dictionary:

		section = (
			(section_value as Dictionary)
			.duplicate(
				true
			)
		)


	if (
		value is Dictionary
		or
		value is Array
	):

		section[key] = (
			value.duplicate(
				true
			)
		)

	else:

		section[key] = (
			value
		)


	profile[section_name] = (
		section
	)


	profile["id"] = (
		SINGLE_PROFILE_ID
	)


	_ensure_profile_structure(
		profile
	)


	_make_profile_data_exclusive(
		profile
	)


	profiles[0] = (
		profile
	)


	var saved := (
		save_profiles()
	)


	if saved:

		profile_data_changed.emit(
			profile,
			section_name,
			key
		)


	return saved


# =============================================================
# UNIVERSAL SECTION GET
# =============================================================

func get_active_section(
	section_name: String
) -> Dictionary:

	var profile := (
		get_active_profile()
	)


	if profile.is_empty():

		return {}


	var section_value: Variant = (
		profile.get(
			section_name,
			{}
		)
	)


	if not section_value is Dictionary:

		return {}


	return (
		(section_value as Dictionary)
		.duplicate(
			true
		)
	)


# =============================================================
# UNIVERSAL SECTION SET
# =============================================================

func set_active_section(
	section_name: String,
	data: Dictionary
) -> bool:

	var profile := (
		get_active_profile()
	)


	if profile.is_empty():

		return false


	profile[section_name] = (
		data.duplicate(
			true
		)
	)


	profile["id"] = (
		SINGLE_PROFILE_ID
	)


	_ensure_profile_structure(
		profile
	)


	_make_profile_data_exclusive(
		profile
	)


	profiles[0] = (
		profile
	)


	var saved := (
		save_profiles()
	)


	if saved:

		profile_data_changed.emit(
			profile,
			section_name,
			"*"
		)


	return saved


# =============================================================
# LAST PAGE
# =============================================================

func get_active_last_page() -> String:

	var profile := (
		get_active_profile()
	)


	if profile.is_empty():

		return "CHARACTER"


	var page := str(
		profile.get(
			"last_page",
			"CHARACTER"
		)
	)


	if not VALID_PAGES.has(
		page
	):

		return "CHARACTER"


	return page


func set_active_last_page(
	page_name: String
) -> bool:

	if not VALID_PAGES.has(
		page_name
	):

		page_name = "CHARACTER"


	var profile := (
		get_active_profile()
	)


	if profile.is_empty():

		return false


	profile["last_page"] = (
		page_name
	)


	profiles[0] = (
		profile
	)


	var saved := (
		save_profiles()
	)


	if saved:

		profile_data_changed.emit(
			profile,
			"",
			"last_page"
		)


	return saved


# =============================================================
# CHARACTER
# =============================================================

func get_active_character_config() -> Dictionary:

	return (
		get_active_section(
			"character"
		)
	)


func set_active_character_config(
	data: Dictionary
) -> bool:

	return (
		set_active_section(
			"character",
			data
		)
	)


# =============================================================
# LOAD ON LAUNCH
# =============================================================

func get_active_character_load_on_launch() -> bool:

	return bool(
		get_active_value(
			"character",
			"load_on_launch",
			false
		)
	)


func set_active_character_load_on_launch(
	enabled: bool
) -> bool:

	return (
		set_active_value(
			"character",
			"load_on_launch",
			enabled
		)
	)


# =============================================================
# AVATAR MAPPINGS
# =============================================================

func get_active_avatar_mappings() -> Dictionary:

	var value: Variant = (
		get_active_value(
			"character",
			"avatar_mappings",
			{}
		)
	)


	if not value is Dictionary:

		return {}


	return (
		(value as Dictionary)
		.duplicate(
			true
		)
	)


func get_active_avatar_mapping(
	character_id: String
) -> Dictionary:

	if character_id.is_empty():

		return {}


	var mappings := (
		get_active_avatar_mappings()
	)


	var value: Variant = (
		mappings.get(
			character_id,
			{}
		)
	)


	if not value is Dictionary:

		return {}


	return (
		(value as Dictionary)
		.duplicate(
			true
		)
	)


func set_active_avatar_mapping(
	character_id: String,
	bone_map: Dictionary,
	enabled_hitpoints: Array[String]
) -> bool:

	if character_id.is_empty():

		return false


	var mappings := (
		get_active_avatar_mappings()
	)


	mappings[character_id] = {

		"bone_map":
			bone_map.duplicate(
				true
			),

		"enabled_hitpoints":
			enabled_hitpoints.duplicate(),

		"mapped":
			true
	}


	return (
		set_active_value(
			"character",
			"avatar_mappings",
			mappings
		)
	)


func remove_active_avatar_mapping(
	character_id: String
) -> bool:

	if character_id.is_empty():

		return false


	var mappings := (
		get_active_avatar_mappings()
	)


	if not mappings.has(
		character_id
	):

		return false


	mappings.erase(
		character_id
	)


	return (
		set_active_value(
			"character",
			"avatar_mappings",
			mappings
		)
	)


# =============================================================
# CHARACTER MAP
# =============================================================

func set_active_character_map(
	bone_map: Dictionary
) -> bool:

	var profile := (
		get_active_profile()
	)


	if profile.is_empty():

		return false


	var character_id := str(
		profile.get(
			"character_id",
			""
		)
	)


	if character_id.is_empty():

		return false


	var enabled := (
		get_active_enabled_hitpoints()
	)


	return (
		set_active_avatar_mapping(
			character_id,
			bone_map,
			enabled
		)
	)


# =============================================================
# ENABLED HITPOINTS
# =============================================================

func set_active_enabled_hitpoints(
	hitpoints: Array[String]
) -> bool:

	var profile := (
		get_active_profile()
	)


	if profile.is_empty():

		return false


	var character_id := str(
		profile.get(
			"character_id",
			""
		)
	)


	if character_id.is_empty():

		return false


	var mapping := (
		get_active_avatar_mapping(
			character_id
		)
	)


	var clean: Array[String] = []


	for hitpoint: String in hitpoints:

		if not clean.has(
			hitpoint
		):

			clean.append(
				hitpoint
			)


	mapping["enabled_hitpoints"] = (
		clean
	)


	if not mapping.has(
		"bone_map"
	):

		mapping["bone_map"] = {}


	if not mapping.has(
		"mapped"
	):

		mapping["mapped"] = false


	var mappings := (
		get_active_avatar_mappings()
	)


	mappings[character_id] = (
		mapping.duplicate(
			true
		)
	)


	return (
		set_active_value(
			"character",
			"avatar_mappings",
			mappings
		)
	)


func get_active_enabled_hitpoints() -> Array[String]:

	var profile := (
		get_active_profile()
	)


	if profile.is_empty():

		return []


	var character_id := str(
		profile.get(
			"character_id",
			""
		)
	)


	if character_id.is_empty():

		return []


	var mapping := (
		get_active_avatar_mapping(
			character_id
		)
	)


	var value: Variant = (
		mapping.get(
			"enabled_hitpoints",
			[]
		)
	)


	var result: Array[String] = []


	if not value is Array:

		return result


	for item: Variant in value:

		result.append(
			str(
				item
			)
		)


	return result


# =============================================================
# INTERACTION
# =============================================================

func get_active_interaction() -> Dictionary:

	return (
		get_active_section(
			"interaction"
		)
	)


func set_active_interaction(
	data: Dictionary
) -> bool:

	return (
		set_active_section(
			"interaction",
			data
		)
	)


# =============================================================
# OBJECT SCALE MULTIPLIERS
# =============================================================

func get_active_object_scale_multipliers() -> Dictionary:

	var value: Variant = (
		get_active_value(
			"objects",
			"scale_multipliers",
			{}
		)
	)


	if not value is Dictionary:

		return {}


	var source := (
		(value as Dictionary)
		.duplicate(
			true
		)
	)


	var result: Dictionary = {}


	for object_id_value: Variant in source.keys():

		var object_id := str(
			object_id_value
		)


		if object_id.is_empty():

			continue


		var raw_multiplier := float(
			source.get(
				object_id_value,
				1.0
			)
		)


		if not is_finite(
			raw_multiplier
		):

			raw_multiplier = 1.0


		result[object_id] = clampf(
			raw_multiplier,
			MIN_PROFILE_SCALE_MULTIPLIER,
			MAX_PROFILE_SCALE_MULTIPLIER
		)


	return result


# =============================================================
# GET SCALE MULTIPLIER
# =============================================================

func get_active_object_scale_multiplier(
	object_id: String,
	base_scale: float = 1.0
) -> float:

	if object_id.is_empty():

		return (
			1.0
		)


	var multipliers := (
		get_active_object_scale_multipliers()
	)


	if multipliers.has(
		object_id
	):

		var multiplier := float(
			multipliers.get(
				object_id,
				1.0
			)
		)


		if not is_finite(
			multiplier
		):

			return (
				1.0
			)


		return clampf(
			multiplier,
			MIN_PROFILE_SCALE_MULTIPLIER,
			MAX_PROFILE_SCALE_MULTIPLIER
		)


	# =========================================================
	# LEGACY FALLBACK
	# =========================================================

	var legacy_scales := (
		get_active_object_scales()
	)


	if legacy_scales.has(
		object_id
	):

		var legacy_final_scale := float(
			legacy_scales.get(
				object_id,
				0.0
			)
		)


		if not is_finite(
			legacy_final_scale
		):

			return (
				1.0
			)


		if legacy_final_scale < LEGACY_MIN_VALID_SCALE:

			return (
				1.0
			)


		if base_scale <= 0.000001:

			return (
				1.0
			)


		var converted_multiplier := (
			legacy_final_scale
			/
			base_scale
		)


		if not is_finite(
			converted_multiplier
		):

			return (
				1.0
			)


		return clampf(
			converted_multiplier,
			MIN_PROFILE_SCALE_MULTIPLIER,
			MAX_PROFILE_SCALE_MULTIPLIER
		)


	return (
		1.0
	)


# =============================================================
# SET SCALE MULTIPLIER
# =============================================================

func set_active_object_scale_multiplier(
	object_id: String,
	multiplier: float
) -> bool:

	if object_id.is_empty():

		return false


	var profile := (
		get_active_profile()
	)


	if profile.is_empty():

		return false


	var safe_multiplier := float(
		multiplier
	)


	if not is_finite(
		safe_multiplier
	):

		safe_multiplier = (
			1.0
		)


	safe_multiplier = clampf(
		safe_multiplier,
		MIN_PROFILE_SCALE_MULTIPLIER,
		MAX_PROFILE_SCALE_MULTIPLIER
	)


	var object_section_value: Variant = (
		profile.get(
			"objects",
			{}
		)
	)


	var object_section: Dictionary = {}


	if object_section_value is Dictionary:

		object_section = (
			(object_section_value as Dictionary)
			.duplicate(
				true
			)
		)


	var multipliers_value: Variant = (
		object_section.get(
			"scale_multipliers",
			{}
		)
	)


	var multipliers: Dictionary = {}


	if multipliers_value is Dictionary:

		multipliers = (
			(multipliers_value as Dictionary)
			.duplicate(
				true
			)
		)


	multipliers[object_id] = (
		safe_multiplier
	)


	object_section[
		"scale_multipliers"
	] = (
		multipliers
	)


	var legacy_value: Variant = (
		object_section.get(
			"scales",
			{}
		)
	)


	var legacy_scales: Dictionary = {}


	if legacy_value is Dictionary:

		legacy_scales = (
			(legacy_value as Dictionary)
			.duplicate(
				true
			)
		)


	if legacy_scales.has(
		object_id
	):

		legacy_scales.erase(
			object_id
		)


	object_section["scales"] = (
		legacy_scales
	)


	profile["objects"] = (
		object_section
	)


	profile["id"] = (
		SINGLE_PROFILE_ID
	)


	_ensure_profile_structure(
		profile
	)


	_make_profile_data_exclusive(
		profile
	)


	profiles[0] = (
		profile
	)


	var saved := (
		save_profiles()
	)


	if not saved:

		return false


	print(
		"CIGA CONFIG SCALE SAVED | OBJECT=",
		object_id,
		" | MULTIPLIER=",
		safe_multiplier
	)


	profile_data_changed.emit(
		profile,
		"objects",
		"scale_multipliers"
	)


	return true


# =============================================================
# REMOVE SCALE MULTIPLIER
# =============================================================

func remove_active_object_scale_multiplier(
	object_id: String
) -> bool:

	if object_id.is_empty():

		return false


	var multipliers := (
		get_active_object_scale_multipliers()
	)


	if not multipliers.has(
		object_id
	):

		return false


	multipliers.erase(
		object_id
	)


	return (
		set_active_value(
			"objects",
			"scale_multipliers",
			multipliers
		)
	)


# =============================================================
# LEGACY OBJECT SCALES
# =============================================================

func get_active_object_scales() -> Dictionary:

	var value: Variant = (
		get_active_value(
			"objects",
			"scales",
			{}
		)
	)


	if not value is Dictionary:

		return {}


	return (
		(value as Dictionary)
		.duplicate(
			true
		)
	)


# =============================================================
# LEGACY OVERRIDE
# =============================================================

func get_active_object_scale_override(
	object_id: String
) -> float:

	if object_id.is_empty():

		return -1.0


	var scales := (
		get_active_object_scales()
	)


	if not scales.has(
		object_id
	):

		return -1.0


	var raw_value := float(
		scales.get(
			object_id,
			-1.0
		)
	)


	if not is_finite(
		raw_value
	):

		return -1.0


	if raw_value < LEGACY_MIN_VALID_SCALE:

		return -1.0


	return clampf(
		raw_value,
		LEGACY_MIN_VALID_SCALE,
		MAX_EFFECTIVE_OBJECT_SCALE
	)


# =============================================================
# GET ACTIVE OBJECT SCALE
# =============================================================

func get_active_object_scale(
	object_id: String,
	base_scale: float
) -> float:

	if object_id.is_empty():

		return clampf(
			base_scale,
			MIN_EFFECTIVE_OBJECT_SCALE,
			MAX_EFFECTIVE_OBJECT_SCALE
		)


	var safe_base_scale := float(
		base_scale
	)


	if not is_finite(
		safe_base_scale
	):

		safe_base_scale = (
			1.0
		)


	safe_base_scale = clampf(
		safe_base_scale,
		CIGAObjects.MIN_OBJECT_SCALE,
		CIGAObjects.MAX_OBJECT_SCALE
	)


	var multiplier := (
		get_active_object_scale_multiplier(
			object_id,
			safe_base_scale
		)
	)


	var final_scale := (
		safe_base_scale
		*
		multiplier
	)


	if not is_finite(
		final_scale
	):

		final_scale = (
			safe_base_scale
		)


	return clampf(
		final_scale,
		MIN_EFFECTIVE_OBJECT_SCALE,
		MAX_EFFECTIVE_OBJECT_SCALE
	)


# =============================================================
# LEGACY SET OBJECT SCALE
# =============================================================

func set_active_object_scale(
	object_id: String,
	scale_value: float
) -> bool:

	if object_id.is_empty():

		return false


	var safe_scale := float(
		scale_value
	)


	if not is_finite(
		safe_scale
	):

		safe_scale = (
			1.0
		)


	safe_scale = clampf(
		safe_scale,
		LEGACY_MIN_VALID_SCALE,
		MAX_EFFECTIVE_OBJECT_SCALE
	)


	var base_scale := 1.0


	var tree: SceneTree = (
		Engine.get_main_loop()
		as
		SceneTree
	)


	if tree != null:

		var current_scene := (
			tree.current_scene
		)


		if current_scene != null:

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


				if ui.object_manager == null:

					continue


				base_scale = (
					ui.object_manager
					.get_object_base_scale(
						object_id
					)
				)


				break


	if base_scale <= 0.000001:

		base_scale = (
			1.0
		)


	var multiplier := (
		safe_scale
		/
		base_scale
	)


	multiplier = clampf(
		multiplier,
		MIN_PROFILE_SCALE_MULTIPLIER,
		MAX_PROFILE_SCALE_MULTIPLIER
	)


	return (
		set_active_object_scale_multiplier(
			object_id,
			multiplier
		)
	)


# =============================================================
# REMOVE LEGACY SCALE
# =============================================================

func remove_active_object_scale(
	object_id: String
) -> bool:

	if object_id.is_empty():

		return false


	var scales := (
		get_active_object_scales()
	)


	if not scales.has(
		object_id
	):

		return false


	scales.erase(
		object_id
	)


	return (
		set_active_value(
			"objects",
			"scales",
			scales
		)
	)


# =============================================================
# RENAME CONFIGURATION
#
# Mantido para compatibilidade.
# =============================================================

func rename_profile(
	_profile_id: String,
	new_name: String
) -> bool:

	var clean_name := (
		new_name
		.strip_edges()
	)


	if clean_name.is_empty():

		return false


	var profile := (
		get_active_profile()
	)


	if profile.is_empty():

		return false


	profile["name"] = (
		clean_name
	)


	profile["id"] = (
		SINGLE_PROFILE_ID
	)


	profiles[0] = (
		profile
	)


	return (
		save_profiles()
	)


# =============================================================
# EXPORT ACTIVE CONFIGURATION
# =============================================================

func export_active_profile(
	file_path: String
) -> bool:

	if file_path.is_empty():

		return false


	var profile := (
		get_active_profile()
	)


	if profile.is_empty():

		return false


	var export_profile := (
		profile.duplicate(
			true
		)
	)


	export_profile["id"] = (
		SINGLE_PROFILE_ID
	)


	var export_data: Dictionary = {

		"format":
			"CIGA_PROFILE",

		"version":
			PROFILE_EXPORT_VERSION,

		"profile":
			export_profile
	}


	var file := FileAccess.open(
		file_path,
		FileAccess.WRITE
	)


	if file == null:

		push_error(
			"CIGA PROFILE ERROR: Could not create export file."
		)

		return false


	file.store_string(
		JSON.stringify(
			export_data,
			"\t"
		)
	)


	file.close()


	print(
		"CIGA CONFIGURATION EXPORTED | ",
		file_path
	)


	return true


# =============================================================
# IMPORT ACTIVE CONFIGURATION
#
# IMPORTANTE:
#
# NÃO cria uma nova configuração.
#
# SUBSTITUI a configuração actual.
# =============================================================

func import_profile(
	file_path: String
) -> Dictionary:

	if file_path.is_empty():

		return {}


	if not FileAccess.file_exists(
		file_path
	):

		push_error(
			"CIGA PROFILE ERROR: Import file does not exist."
		)

		return {}


	var file := FileAccess.open(
		file_path,
		FileAccess.READ
	)


	if file == null:

		push_error(
			"CIGA PROFILE ERROR: Could not open import file."
		)

		return {}


	var text := (
		file.get_as_text()
	)


	file.close()


	if text.strip_edges().is_empty():

		push_error(
			"CIGA PROFILE ERROR: Import file is empty."
		)

		return {}


	var parsed: Variant = (
		JSON.parse_string(
			text
		)
	)


	if not parsed is Dictionary:

		push_error(
			"CIGA PROFILE ERROR: Invalid import file."
		)

		return {}


	var export_data := (
		parsed
		as
		Dictionary
	)


	if str(
		export_data.get(
			"format",
			""
		)
	) != "CIGA_PROFILE":

		push_error(
			"CIGA PROFILE ERROR: Invalid CIGA profile format."
		)

		return {}


	var version := int(
		export_data.get(
			"version",
			0
		)
	)


	if version != PROFILE_EXPORT_VERSION:

		push_error(
			"CIGA PROFILE ERROR: Unsupported profile version: "
			+
			str(
				version
			)
		)

		return {}


	var profile_value: Variant = (
		export_data.get(
			"profile",
			null
		)
	)


	if not profile_value is Dictionary:

		push_error(
			"CIGA PROFILE ERROR: Missing profile data."
		)

		return {}


	# =========================================================
	# DEEP COPY
	# =========================================================

	var imported_profile := (
		(profile_value as Dictionary)
		.duplicate(
			true
		)
	)


	# =========================================================
	# SINGLE CONFIGURATION ID
	# =========================================================

	imported_profile["id"] = (
		SINGLE_PROFILE_ID
	)


	# =========================================================
	# NAME
	# =========================================================

	var imported_name := str(
		imported_profile.get(
			"name",
			SINGLE_PROFILE_NAME
		)
	)


	if imported_name.strip_edges().is_empty():

		imported_name = (
			SINGLE_PROFILE_NAME
		)


	imported_profile["name"] = (
		imported_name
	)


	# =========================================================
	# NORMALIZE
	# =========================================================

	_ensure_profile_structure(
		imported_profile
	)


	_make_profile_data_exclusive(
		imported_profile
	)


	# =========================================================
	# REPLACE CURRENT CONFIGURATION
	# =========================================================

	profiles.clear()


	profiles.append(
		imported_profile
	)


	active_profile_id = (
		SINGLE_PROFILE_ID
	)


	# =========================================================
	# SAVE
	# =========================================================

	if not save_profiles():

		profiles.clear()


		profiles.append(
			create_default_profile()
		)


		active_profile_id = (
			SINGLE_PROFILE_ID
		)


		return {}


	# =========================================================
	# SIGNAL
	# =========================================================

	var result := (
		imported_profile.duplicate(
			true
		)
	)


	active_profile_changed.emit(
		result
	)


	print(
		"CIGA CONFIGURATION IMPORTED AND APPLIED | ",
		imported_name,
		" | ID=",
		SINGLE_PROFILE_ID
	)


	return result
