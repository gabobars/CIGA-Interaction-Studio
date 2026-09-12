class_name CIGAInteraction
extends RefCounted


# =============================================================
# CIGA INTERACTION SYSTEM
# Godot 4.7.2
# =============================================================


# =============================================================
# SIGNALS
# =============================================================

signal configuration_changed

signal interaction_executed(
	object_data: Dictionary,
	target_name: String,
	spawn_name: String,
	force: float,
	speed: float,
	amount: int,
	scale_value: float
)


# =============================================================
# REFERENCES
# =============================================================

var object_manager: CIGAObjects

var profile_manager: CIGAProfiles


# =============================================================
# CHARACTER
# =============================================================

var active_character_id: String = ""

var active_bone_map: Dictionary = {}

var active_enabled_hitpoints: Array[String] = []


# =============================================================
# OBJECT
# =============================================================

var selected_object_id: String = ""

var random_object: bool = false


# =============================================================
# TARGET
# =============================================================

var selected_target: String = "CHEST"

var random_target: bool = false


# =============================================================
# SPAWN
# =============================================================

var selected_spawn: String = "NORTH"


# =============================================================
# PHYSICS
# =============================================================

var force: float = CIGASettings.DEFAULT_FORCE

var speed: float = CIGASettings.DEFAULT_SPEED

var amount: int = 1


# =============================================================
# SCALE
# =============================================================

var object_scale: float = 1.0


# =============================================================
# LIMITS
# =============================================================

const MIN_SCALE: float = 0.01

const MAX_SCALE: float = 10.0

const MIN_SPEED: float = 0.1

const MAX_SPEED: float = 100.0

const MIN_FORCE: float = 0.0

const MAX_FORCE: float = 100.0

const MIN_AMOUNT: int = 1

const MAX_AMOUNT: int = 100


# =============================================================
# TARGETS
# =============================================================

const TARGETS: Array[String] = [
	"CHEST",
	"HEAD",
	"LEFT SHOULDER",
	"RIGHT SHOULDER",
	"LEFT ARM",
	"RIGHT ARM",
	"LEFT LEG",
	"RIGHT LEG"
]


# =============================================================
# HITPOINT NAMES
# =============================================================

const HIT_POINT_NAMES: Array[String] = [
	"HeadHitPoint",
	"ChestHitPoint",
	"LeftShoulderHitPoint",
	"RightShoulderHitPoint",
	"LeftArmHitPoint",
	"RightArmHitPoint",
	"LeftLegHitPoint",
	"RightLegHitPoint"
]


# =============================================================
# SPAWNS
# =============================================================

const SPAWNS: Array[String] = [
	"NORTH",
	"SOUTH",
	"EAST",
	"WEST"
]


# =============================================================
# SETUP
# =============================================================

func setup(
	manager: CIGAObjects,
	profiles: CIGAProfiles = null
) -> void:

	object_manager = manager

	profile_manager = profiles

	refresh_character_mapping()


# =============================================================
# CHARACTER MAPPING
# =============================================================

func set_character_mapping(
	character_id: String,
	bone_map: Dictionary,
	enabled_hitpoints: Array[String]
) -> void:

	active_character_id = character_id

	active_bone_map = (
		bone_map.duplicate(
			true
		)
	)

	active_enabled_hitpoints.clear()


	for hitpoint_value: Variant in enabled_hitpoints:

		var hitpoint := str(
			hitpoint_value
		)


		if not HIT_POINT_NAMES.has(
			hitpoint
		):

			continue


		if not active_enabled_hitpoints.has(
			hitpoint
		):

			active_enabled_hitpoints.append(
				hitpoint
			)


	var valid_enabled: Array[String] = []


	for hitpoint: String in active_enabled_hitpoints:

		if active_bone_map.has(
			hitpoint
		):

			valid_enabled.append(
				hitpoint
			)


	active_enabled_hitpoints = (
		valid_enabled
	)


	if not is_target_available(
		selected_target
	):

		var available := (
			get_available_targets()
		)


		if not available.is_empty():

			selected_target = (
				available[0]
			)


	configuration_changed.emit()


# =============================================================
# REFRESH CHARACTER MAPPING
# =============================================================

func refresh_character_mapping() -> void:

	active_character_id = ""

	active_bone_map.clear()

	active_enabled_hitpoints.clear()


	if profile_manager == null:

		return


	var profile := (
		profile_manager.get_active_profile()
	)


	if profile.is_empty():

		return


	active_character_id = str(
		profile.get(
			"character_id",
			""
		)
	)


	if active_character_id.is_empty():

		return


	var mapping := (
		profile_manager.get_active_avatar_mapping(
			active_character_id
		)
	)


	if mapping.is_empty():

		return


	var bone_map: Variant = (
		mapping.get(
			"bone_map",
			{}
		)
	)


	if bone_map is Dictionary:

		active_bone_map = (
			(bone_map as Dictionary).duplicate(
				true
			)
		)


	var enabled: Variant = (
		mapping.get(
			"enabled_hitpoints",
			[]
		)
	)


	if enabled is Array:

		for value: Variant in enabled:

			var hitpoint := str(
				value
			)


			if active_bone_map.has(
				hitpoint
			):

				active_enabled_hitpoints.append(
					hitpoint
				)


# =============================================================
# AVAILABLE TARGETS
# =============================================================

func get_available_targets() -> Array[String]:

	var result: Array[String] = []


	if active_bone_map.is_empty():

		for target_name: String in TARGETS:

			result.append(
				target_name
			)

		return result


	for hitpoint: String in active_enabled_hitpoints:

		if not active_bone_map.has(
			hitpoint
		):

			continue


		var target_name := (
			hitpoint_to_target(
				hitpoint
			)
		)


		if target_name.is_empty():

			continue


		if not result.has(
			target_name
		):

			result.append(
				target_name
			)


	return result


# =============================================================
# HITPOINT → TARGET
# =============================================================

func hitpoint_to_target(
	hitpoint_name: String
) -> String:

	match hitpoint_name:

		"HeadHitPoint":

			return "HEAD"

		"ChestHitPoint":

			return "CHEST"

		"LeftShoulderHitPoint":

			return "LEFT SHOULDER"

		"RightShoulderHitPoint":

			return "RIGHT SHOULDER"

		"LeftArmHitPoint":

			return "LEFT ARM"

		"RightArmHitPoint":

			return "RIGHT ARM"

		"LeftLegHitPoint":

			return "LEFT LEG"

		"RightLegHitPoint":

			return "RIGHT LEG"


	return ""


# =============================================================
# TARGET → HITPOINT
# =============================================================

func target_to_hitpoint(
	target_name: String
) -> String:

	match target_name:

		"HEAD":

			return "HeadHitPoint"

		"CHEST":

			return "ChestHitPoint"

		"LEFT SHOULDER":

			return "LeftShoulderHitPoint"

		"RIGHT SHOULDER":

			return "RightShoulderHitPoint"

		"LEFT ARM":

			return "LeftArmHitPoint"

		"RIGHT ARM":

			return "RightArmHitPoint"

		"LEFT LEG":

			return "LeftLegHitPoint"

		"RIGHT LEG":

			return "RightLegHitPoint"


	return ""


# =============================================================
# TARGET AVAILABLE
# =============================================================

func is_target_available(
	target_name: String
) -> bool:

	if not TARGETS.has(
		target_name
	):

		return false


	if active_bone_map.is_empty():

		return true


	var hitpoint := (
		target_to_hitpoint(
			target_name
		)
	)


	if hitpoint.is_empty():

		return false


	if not active_enabled_hitpoints.has(
		hitpoint
	):

		return false


	return active_bone_map.has(
		hitpoint
	)


# =============================================================
# RANDOM TARGET
# =============================================================

func get_random_target() -> String:

	var available := (
		get_available_targets()
	)


	if available.is_empty():

		return selected_target


	return (
		available[
			randi_range(
				0,
				available.size() - 1
			)
		]
	)


# =============================================================
# OBJECT
# =============================================================

func set_object(
	object_id: String
) -> bool:

	if object_manager == null:

		return false


	if object_id.is_empty():

		selected_object_id = ""

		object_scale = 1.0

		configuration_changed.emit()

		return true


	var object_data: Dictionary = (
		object_manager.get_object(
			object_id
		)
	)


	if object_data.is_empty():

		return false


	selected_object_id = object_id


	object_scale = (
		get_object_library_scale(
			object_data
		)
	)


	configuration_changed.emit()

	return true


# =============================================================
# OBJECT LIBRARY SCALE
# =============================================================

func get_object_library_scale(
	object_data: Dictionary
) -> float:

	if object_data.is_empty():

		return 1.0


	var library_scale := float(
		object_data.get(
			"scale",
			1.0
		)
	)


	return clampf(
		library_scale,
		MIN_SCALE,
		MAX_SCALE
	)


# =============================================================
# RANDOM OBJECT
# =============================================================

func set_random_object(
	enabled: bool
) -> void:

	random_object = enabled


	if not enabled:

		var selected := (
			get_selected_object()
		)


		if not selected.is_empty():

			object_scale = (
				get_object_library_scale(
					selected
				)
			)


	configuration_changed.emit()


# =============================================================
# TARGET
# =============================================================

func set_target(
	target_name: String
) -> bool:

	if not is_target_available(
		target_name
	):

		return false


	selected_target = target_name

	configuration_changed.emit()

	return true


# =============================================================
# RANDOM TARGET
# =============================================================

func set_random_target(
	enabled: bool
) -> void:

	random_target = enabled

	configuration_changed.emit()


# =============================================================
# SPAWN
# =============================================================

func set_spawn(
	spawn_name: String
) -> bool:

	if not SPAWNS.has(
		spawn_name
	):

		return false


	selected_spawn = spawn_name

	configuration_changed.emit()

	return true


# =============================================================
# FORCE
# =============================================================

func set_force(
	value: float
) -> void:

	force = clampf(
		value,
		MIN_FORCE,
		MAX_FORCE
	)

	configuration_changed.emit()


# =============================================================
# SPEED
# =============================================================

func set_speed(
	value: float
) -> void:

	speed = clampf(
		value,
		MIN_SPEED,
		MAX_SPEED
	)

	configuration_changed.emit()


# =============================================================
# AMOUNT
# =============================================================

func set_amount(
	value: int
) -> void:

	amount = clampi(
		value,
		MIN_AMOUNT,
		MAX_AMOUNT
	)

	configuration_changed.emit()


# =============================================================
# SCALE
# =============================================================

func set_object_scale(
	value: float
) -> void:

	object_scale = clampf(
		value,
		MIN_SCALE,
		MAX_SCALE
	)

	configuration_changed.emit()


# =============================================================
# SELECTED OBJECT
# =============================================================

func get_selected_object() -> Dictionary:

	if object_manager == null:

		return {}


	if selected_object_id.is_empty():

		return {}


	return (
		object_manager.get_object(
			selected_object_id
		)
	)


# =============================================================
# EFFECTIVE OBJECT
# =============================================================

func get_effective_object() -> Dictionary:

	if object_manager == null:

		return {}


	if object_manager.objects.is_empty():

		return {}


	if random_object:

		var index := randi_range(
			0,
			object_manager.objects.size() - 1
		)


		return (
			object_manager.objects[
				index
			]
		)


	return (
		get_selected_object()
	)


# =============================================================
# EFFECTIVE OBJECT SCALE
# =============================================================

func get_effective_object_scale(
	object_data: Dictionary
) -> float:

	if object_data.is_empty():

		return clampf(
			object_scale,
			MIN_SCALE,
			MAX_SCALE
		)


	if random_object:

		return (
			get_object_library_scale(
				object_data
			)
		)


	return clampf(
		object_scale,
		MIN_SCALE,
		MAX_SCALE
	)


# =============================================================
# EFFECTIVE TARGET
# =============================================================

func get_effective_target() -> String:

	if not random_target:

		return selected_target


	return get_random_target()


# =============================================================
# EFFECTIVE AMOUNT
# =============================================================

func get_effective_amount() -> int:

	return clampi(
		amount,
		MIN_AMOUNT,
		MAX_AMOUNT
	)


# =============================================================
# VALIDATE
# =============================================================

func validate() -> bool:

	if object_manager == null:

		return false


	if object_manager.objects.is_empty():

		return false


	if get_effective_object().is_empty():

		return false


	if not TARGETS.has(
		selected_target
	):

		return false


	if not is_target_available(
		selected_target
	):

		if not random_target:

			return false


	if get_available_targets().is_empty():

		return false


	if not SPAWNS.has(
		selected_spawn
	):

		return false


	if force < MIN_FORCE:

		return false


	if speed < MIN_SPEED:

		return false


	if get_effective_amount() < MIN_AMOUNT:

		return false


	if object_scale < MIN_SCALE:

		return false


	return true


# =============================================================
# EXECUTE
# =============================================================

func execute() -> bool:

	if not validate():

		return false


	var object_data: Dictionary = (
		get_effective_object()
	)


	if object_data.is_empty():

		return false


	var target_name := (
		get_effective_target()
	)


	if target_name.is_empty():

		return false


	var effective_amount := (
		get_effective_amount()
	)


	var effective_scale := (
		get_effective_object_scale(
			object_data
		)
	)


	interaction_executed.emit(
		object_data,
		target_name,
		selected_spawn,
		force,
		speed,
		effective_amount,
		effective_scale
	)


	return true


# =============================================================
# SERIALIZE
# =============================================================

func to_dictionary() -> Dictionary:

	return {
		"object_id":
			selected_object_id,

		"random_object":
			random_object,

		"target":
			selected_target,

		"random_target":
			random_target,

		"spawn":
			selected_spawn,

		"force":
			force,

		"speed":
			speed,

		"amount":
			get_effective_amount(),

		"scale":
			object_scale
	}


# =============================================================
# LOAD DICTIONARY
# =============================================================

func from_dictionary(
	data: Dictionary
) -> void:

	selected_object_id = str(
		data.get(
			"object_id",
			""
		)
	)


	random_object = bool(
		data.get(
			"random_object",
			false
		)
	)


	selected_target = str(
		data.get(
			"target",
			"CHEST"
		)
	)


	if not TARGETS.has(
		selected_target
	):

		selected_target = "CHEST"


	random_target = bool(
		data.get(
			"random_target",
			false
		)
	)


	selected_spawn = str(
		data.get(
			"spawn",
			"NORTH"
		)
	)


	if not SPAWNS.has(
		selected_spawn
	):

		selected_spawn = "NORTH"


	force = clampf(
		float(
			data.get(
				"force",
				CIGASettings.DEFAULT_FORCE
			)
		),
		MIN_FORCE,
		MAX_FORCE
	)


	speed = clampf(
		float(
			data.get(
				"speed",
				CIGASettings.DEFAULT_SPEED
			)
		),
		MIN_SPEED,
		MAX_SPEED
	)


	amount = clampi(
		int(
			data.get(
				"amount",
				1
			)
		),
		MIN_AMOUNT,
		MAX_AMOUNT
	)


	object_scale = clampf(
		float(
			data.get(
				"scale",
				1.0
			)
		),
		MIN_SCALE,
		MAX_SCALE
	)


	refresh_character_mapping()


	if not random_object:

		var selected := (
			get_selected_object()
		)


		if not selected.is_empty():

			var library_scale := (
				get_object_library_scale(
					selected
				)
			)


			if profile_manager != null:

				object_scale = (
					profile_manager
					.get_active_object_scale(
						selected_object_id,
						library_scale
					)
				)

			else:

				object_scale = (
					library_scale
				)


	if not is_target_available(
		selected_target
	):

		var available := (
			get_available_targets()
		)


		if not available.is_empty():

			selected_target = (
				available[0]
			)


	configuration_changed.emit()
