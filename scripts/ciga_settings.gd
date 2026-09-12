class_name CIGASettings
extends RefCounted


# =============================================================
# CIGA SETTINGS
# Godot 4.7.2
#
# SETTINGS:
#
# GENERAL
#     OBJECT LIFETIME
#     MAX OBJECTS
#
# PHYSICS
#     DEFAULT FORCE
#     DEFAULT SPEED
#     DEFAULT BOUNCE
#     BOUNCE TIME
#     DEFAULT SPIN
#
# IMPACT
#     IMPACT MOVEMENT
#     REALISTIC MODE
# =============================================================


# =============================================================
# SIGNALS
# =============================================================

signal theme_changed

signal settings_changed(
	key: String,
	value: Variant
)


# =============================================================
# DEFAULTS
# =============================================================

const DEFAULT_OBJECT_LIFETIME: float = 5.0

const DEFAULT_MAX_OBJECTS: int = 50

const DEFAULT_FORCE: float = 1.8

const DEFAULT_SPEED: float = 5.4

const DEFAULT_BOUNCE: float = 0.2

const DEFAULT_BOUNCE_TIME: float = 0.30

const DEFAULT_SPIN: float = 0.0


# -------------------------------------------------------------
# IMPACT MOVEMENT
#
# 0.0 = sem movimento corporal
# 1.0 = comportamento normal
# 2.0 = maior reacção
# 3.0 = reacção forte
# -------------------------------------------------------------

const DEFAULT_IMPACT_MOVEMENT: float = 1.0


# -------------------------------------------------------------
# REALISTIC MODE
#
# false = resposta normal CIGA
# true  = resposta distribuída / mais orgânica
# -------------------------------------------------------------

const DEFAULT_REALISTIC_MODE: bool = false


# =============================================================
# LIMITS
# =============================================================

const MIN_IMPACT_MOVEMENT: float = 0.0

const MAX_IMPACT_MOVEMENT: float = 5.0


# =============================================================
# KEYS
# =============================================================

const KEY_OBJECT_LIFETIME: String = (
	"object_lifetime"
)

const KEY_MAX_OBJECTS: String = (
	"max_objects"
)

const KEY_DEFAULT_FORCE: String = (
	"default_force"
)

const KEY_DEFAULT_SPEED: String = (
	"default_speed"
)

const KEY_DEFAULT_BOUNCE: String = (
	"default_bounce"
)

const KEY_BOUNCE_TIME: String = (
	"bounce_time"
)

const KEY_DEFAULT_SPIN: String = (
	"default_spin"
)

const KEY_IMPACT_MOVEMENT: String = (
	"impact_movement"
)

const KEY_REALISTIC_MODE: String = (
	"realistic_mode"
)


# =============================================================
# STATE
# =============================================================

var object_lifetime: float = (
	DEFAULT_OBJECT_LIFETIME
)

var max_objects: int = (
	DEFAULT_MAX_OBJECTS
)

var default_force: float = (
	DEFAULT_FORCE
)

var default_speed: float = (
	DEFAULT_SPEED
)

var default_bounce: float = (
	DEFAULT_BOUNCE
)

var bounce_time: float = (
	DEFAULT_BOUNCE_TIME
)

var default_spin: float = (
	DEFAULT_SPIN
)

var impact_movement: float = (
	DEFAULT_IMPACT_MOVEMENT
)

var realistic_mode: bool = (
	DEFAULT_REALISTIC_MODE
)


# =============================================================
# REFERENCES
# =============================================================

var profile_manager: CIGAProfiles = null


# =============================================================
# INIT
# =============================================================

func _init() -> void:

	reset_to_defaults()


# =============================================================
# RESET
# =============================================================

func reset_to_defaults() -> void:

	object_lifetime = (
		DEFAULT_OBJECT_LIFETIME
	)

	max_objects = (
		DEFAULT_MAX_OBJECTS
	)

	default_force = (
		DEFAULT_FORCE
	)

	default_speed = (
		DEFAULT_SPEED
	)

	default_bounce = (
		DEFAULT_BOUNCE
	)

	bounce_time = (
		DEFAULT_BOUNCE_TIME
	)

	default_spin = (
		DEFAULT_SPIN
	)

	impact_movement = (
		DEFAULT_IMPACT_MOVEMENT
	)

	realistic_mode = (
		DEFAULT_REALISTIC_MODE
	)


# =============================================================
# LOAD ACTIVE PROFILE
# =============================================================

func load_from_active_profile(
	profiles: CIGAProfiles = null
) -> void:

	reset_to_defaults()


	if profiles == null:

		return


	profile_manager = profiles


	var profile: Dictionary = (
		profiles.get_active_profile()
	)


	if profile.is_empty():

		return


	load_from_profile(
		profile
	)


# =============================================================
# LOAD PROFILE
# =============================================================

func load_from_profile(
	profile: Dictionary
) -> void:

	reset_to_defaults()


	if profile.is_empty():

		emit_settings_changed()

		return


	var settings_value: Variant = (
		profile.get(
			"settings",
			{}
		)
	)


	if not settings_value is Dictionary:

		emit_settings_changed()

		return


	var settings: Dictionary = (
		settings_value
		as
		Dictionary
	)


	# =========================================================
	# GENERAL
	# =========================================================

	object_lifetime = clampf(
		float(
			settings.get(
				KEY_OBJECT_LIFETIME,
				DEFAULT_OBJECT_LIFETIME
			)
		),
		0.1,
		60.0
	)


	max_objects = clampi(
		int(
			settings.get(
				KEY_MAX_OBJECTS,
				DEFAULT_MAX_OBJECTS
			)
		),
		1,
		500
	)


	# =========================================================
	# PHYSICS
	# =========================================================

	default_force = clampf(
		float(
			settings.get(
				KEY_DEFAULT_FORCE,
				DEFAULT_FORCE
			)
		),
		0.0,
		100.0
	)


	default_speed = clampf(
		float(
			settings.get(
				KEY_DEFAULT_SPEED,
				DEFAULT_SPEED
			)
		),
		0.1,
		100.0
	)


	default_bounce = clampf(
		float(
			settings.get(
				KEY_DEFAULT_BOUNCE,
				DEFAULT_BOUNCE
			)
		),
		0.0,
		1.0
	)


	bounce_time = clampf(
		float(
			settings.get(
				KEY_BOUNCE_TIME,
				DEFAULT_BOUNCE_TIME
			)
		),
		0.0,
		10.0
	)


	default_spin = clampf(
		float(
			settings.get(
				KEY_DEFAULT_SPIN,
				DEFAULT_SPIN
			)
		),
		-100.0,
		100.0
	)


	# =========================================================
	# IMPACT
	# =========================================================

	impact_movement = clampf(
		float(
			settings.get(
				KEY_IMPACT_MOVEMENT,
				DEFAULT_IMPACT_MOVEMENT
			)
		),
		MIN_IMPACT_MOVEMENT,
		MAX_IMPACT_MOVEMENT
	)


	realistic_mode = bool(
		settings.get(
			KEY_REALISTIC_MODE,
			DEFAULT_REALISTIC_MODE
		)
	)


	emit_settings_changed()


# =============================================================
# SAVE
# =============================================================

func save_to_active_profile() -> bool:

	if profile_manager == null:

		return false


	var profile: Dictionary = (
		profile_manager.get_active_profile()
	)


	if profile.is_empty():

		return false


	apply_to_profile(
		profile
	)


	return profile_manager.save_profiles()


# =============================================================
# DICTIONARY
# =============================================================

func to_dictionary() -> Dictionary:

	return {

		KEY_OBJECT_LIFETIME:
			object_lifetime,

		KEY_MAX_OBJECTS:
			max_objects,

		KEY_DEFAULT_FORCE:
			default_force,

		KEY_DEFAULT_SPEED:
			default_speed,

		KEY_DEFAULT_BOUNCE:
			default_bounce,

		KEY_BOUNCE_TIME:
			bounce_time,

		KEY_DEFAULT_SPIN:
			default_spin,

		KEY_IMPACT_MOVEMENT:
			impact_movement,

		KEY_REALISTIC_MODE:
			realistic_mode
	}


# =============================================================
# APPLY TO PROFILE
# =============================================================

func apply_to_profile(
	profile: Dictionary
) -> void:

	if profile.is_empty():

		return


	profile["settings"] = (
		to_dictionary()
	)


# =============================================================
# SET VALUE
# =============================================================

func set_value(
	key: String,
	value: Variant
) -> bool:

	var changed: bool = true


	match key:

		# =====================================================
		# GENERAL
		# =====================================================

		KEY_OBJECT_LIFETIME:

			object_lifetime = clampf(
				float(value),
				0.1,
				60.0
			)


		KEY_MAX_OBJECTS:

			max_objects = clampi(
				int(value),
				1,
				500
			)


		# =====================================================
		# PHYSICS
		# =====================================================

		KEY_DEFAULT_FORCE:

			default_force = clampf(
				float(value),
				0.0,
				100.0
			)


		KEY_DEFAULT_SPEED:

			default_speed = clampf(
				float(value),
				0.1,
				100.0
			)


		KEY_DEFAULT_BOUNCE:

			default_bounce = clampf(
				float(value),
				0.0,
				1.0
			)


		KEY_BOUNCE_TIME:

			bounce_time = clampf(
				float(value),
				0.0,
				10.0
			)


		KEY_DEFAULT_SPIN:

			default_spin = clampf(
				float(value),
				-100.0,
				100.0
			)


		# =====================================================
		# IMPACT
		# =====================================================

		KEY_IMPACT_MOVEMENT:

			impact_movement = clampf(
				float(value),
				MIN_IMPACT_MOVEMENT,
				MAX_IMPACT_MOVEMENT
			)


		KEY_REALISTIC_MODE:

			realistic_mode = bool(
				value
			)


		# =====================================================
		# UNKNOWN
		# =====================================================

		_:

			changed = false


	if not changed:

		return false


	var current_value: Variant = (
		get_value(
			key
		)
	)


	settings_changed.emit(
		key,
		current_value
	)


	save_to_active_profile()


	return true


# =============================================================
# GET VALUE
# =============================================================

func get_value(
	key: String,
	default_value: Variant = null
) -> Variant:

	match key:

		KEY_OBJECT_LIFETIME:

			return object_lifetime


		KEY_MAX_OBJECTS:

			return max_objects


		KEY_DEFAULT_FORCE:

			return default_force


		KEY_DEFAULT_SPEED:

			return default_speed


		KEY_DEFAULT_BOUNCE:

			return default_bounce


		KEY_BOUNCE_TIME:

			return bounce_time


		KEY_DEFAULT_SPIN:

			return default_spin


		KEY_IMPACT_MOVEMENT:

			return impact_movement


		KEY_REALISTIC_MODE:

			return realistic_mode


	return default_value


# =============================================================
# COMPATIBILITY SETTERS
# =============================================================

func set_object_lifetime(
	value: float
) -> bool:

	return set_value(
		KEY_OBJECT_LIFETIME,
		value
	)


func set_max_objects(
	value: int
) -> bool:

	return set_value(
		KEY_MAX_OBJECTS,
		value
	)


func set_default_force(
	value: float
) -> bool:

	return set_value(
		KEY_DEFAULT_FORCE,
		value
	)


func set_default_speed(
	value: float
) -> bool:

	return set_value(
		KEY_DEFAULT_SPEED,
		value
	)


func set_default_bounce(
	value: float
) -> bool:

	return set_value(
		KEY_DEFAULT_BOUNCE,
		value
	)


func set_bounce_time(
	value: float
) -> bool:

	return set_value(
		KEY_BOUNCE_TIME,
		value
	)


func set_default_spin(
	value: float
) -> bool:

	return set_value(
		KEY_DEFAULT_SPIN,
		value
	)


func set_impact_movement(
	value: float
) -> bool:

	return set_value(
		KEY_IMPACT_MOVEMENT,
		value
	)


func set_realistic_mode(
	value: bool
) -> bool:

	return set_value(
		KEY_REALISTIC_MODE,
		value
	)


# =============================================================
# RESTORE DEFAULTS
# =============================================================

func restore_defaults() -> void:

	reset_to_defaults()

	save_to_active_profile()

	emit_settings_changed()


# =============================================================
# THEME COMPATIBILITY
# =============================================================

func notify_theme_changed() -> void:

	theme_changed.emit()


func is_light_mode() -> bool:

	return false


# =============================================================
# EMIT ALL
# =============================================================

func emit_settings_changed() -> void:

	settings_changed.emit(
		KEY_OBJECT_LIFETIME,
		object_lifetime
	)


	settings_changed.emit(
		KEY_MAX_OBJECTS,
		max_objects
	)


	settings_changed.emit(
		KEY_DEFAULT_FORCE,
		default_force
	)


	settings_changed.emit(
		KEY_DEFAULT_SPEED,
		default_speed
	)


	settings_changed.emit(
		KEY_DEFAULT_BOUNCE,
		default_bounce
	)


	settings_changed.emit(
		KEY_BOUNCE_TIME,
		bounce_time
	)


	settings_changed.emit(
		KEY_DEFAULT_SPIN,
		default_spin
	)


	settings_changed.emit(
		KEY_IMPACT_MOVEMENT,
		impact_movement
	)


	settings_changed.emit(
		KEY_REALISTIC_MODE,
		realistic_mode
	)


# =============================================================
# GETTERS
# =============================================================

func get_object_lifetime() -> float:

	return object_lifetime


func get_max_objects() -> int:

	return max_objects


func get_default_force() -> float:

	return default_force


func get_default_speed() -> float:

	return default_speed


func get_default_bounce() -> float:

	return default_bounce


func get_bounce_time() -> float:

	return bounce_time


func get_default_spin() -> float:

	return default_spin


func get_impact_movement() -> float:

	return impact_movement


func get_realistic_mode() -> bool:

	return realistic_mode
