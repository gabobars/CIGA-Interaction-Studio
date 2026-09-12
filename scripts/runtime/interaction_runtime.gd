class_name CIGAInteractionRuntime
extends Node


# =============================================================
# CIGA INTERACTION RUNTIME
# Godot 4.7.2
#
# RESPONSABILIDADE:
#
#   CIGA EVENTS
#        ↓
#   EVENT ACTION
#        ↓
#   CIGA INTERACTION RUNTIME
#        ↓
#   CRIA LAUNCH DATA
#        ↓
#   interaction_burst_started
#        ↓
#   CIGA VIEWPORT RUNTIME
#
# NÃO contém a física.
# NÃO cria ThrowableObject directamente.
#
# Apenas transforma configurações em pedidos de lançamento.
# =============================================================


# =============================================================
# SIGNALS
# =============================================================

signal interaction_started(
	object_data: Dictionary,
	target_name: String,
	spawn_name: String,
	force: float,
	speed: float,
	amount: int,
	scale_value: float
)


signal interaction_burst_started(
	launches: Array
)


# =============================================================
# REFERENCES
# =============================================================

var object_manager: CIGAObjects = null

var profile_manager: CIGAProfiles = null


# =============================================================
# STATE
# =============================================================

var ready_for_execution: bool = false

var executing: bool = false


# =============================================================
# SETUP
# =============================================================

func setup(
	manager: CIGAObjects,
	profiles: CIGAProfiles = null
) -> void:

	object_manager = manager

	profile_manager = profiles

	ready_for_execution = (
		object_manager != null
	)


# =============================================================
# EXECUTE CONFIGURATION
# =============================================================

func execute_configuration(
	interaction: CIGAInteraction,
	skip_validation: bool = false
) -> bool:

	# =========================================================
	# INTERACTION
	# =========================================================

	if interaction == null:

		push_warning(
			"[CIGA INTERACTION] EXECUTION FAILED | INTERACTION NULL"
		)

		return false


	# =========================================================
	# OBJECT MANAGER
	# =========================================================

	if object_manager == null:

		push_warning(
			"[CIGA INTERACTION] EXECUTION FAILED | OBJECT MANAGER NULL"
		)

		return false


	# =========================================================
	# OBJECT LIBRARY
	# =========================================================

	if object_manager.objects.is_empty():

		push_warning(
			"[CIGA INTERACTION] EXECUTION FAILED | OBJECT LIBRARY EMPTY"
		)

		return false


	# =========================================================
	# VALIDATION
	# =========================================================

	if not skip_validation:

		if not interaction.validate():

			push_warning(
				"[CIGA INTERACTION] EXECUTION FAILED | VALIDATION"
			)

			return false


	# =========================================================
	# SAFE VALUES
	# =========================================================

	var safe_amount: int = clampi(
		interaction.amount,
		1,
		100
	)


	var safe_force: float = maxf(
		0.0,
		interaction.force
	)


	var safe_speed: float = maxf(
		0.1,
		interaction.speed
	)


	# =========================================================
	# STATE
	# =========================================================

	executing = true


	# =========================================================
	# LAUNCH ARRAY
	# =========================================================

	var launches: Array = []


	# =========================================================
	# CREATE LAUNCH DATA
	# =========================================================

	for index: int in range(
		safe_amount
	):

		# =====================================================
		# OBJECT
		# =====================================================

		var object_data: Dictionary = (
			_resolve_object(
				interaction
			)
		)


		if object_data.is_empty():

			continue


		# =====================================================
		# TARGET
		# =====================================================

		var target_name: String = (
			_resolve_target(
				interaction
			)
		)


		if target_name.is_empty():

			continue


		# =====================================================
		# SCALE
		# =====================================================

		var scale_value: float = (
			_resolve_scale(
				interaction,
				object_data
			)
		)


		# =====================================================
		# SPAWN
		# =====================================================

		var spawn_name: String = str(
			_get_property_if_exists(
				interaction,
				"selected_spawn",
				"RANDOM"
			)
		)


		if spawn_name.is_empty():

			spawn_name = "RANDOM"


		# =====================================================
		# LAUNCH DATA
		# =====================================================

		var launch_data: Dictionary = {

			"object_data":
				object_data.duplicate(true),

			"target":
				target_name,

			"spawn":
				spawn_name,

			"force":
				safe_force,

			"speed":
				safe_speed,

			"scale":
				scale_value,

			"index":
				index
		}


		launches.append(
			launch_data
		)


	# =========================================================
	# EMPTY RESULT
	# =========================================================

	if launches.is_empty():

		executing = false

		push_warning(
			"[CIGA INTERACTION] EXECUTION FAILED | ZERO LAUNCHES"
		)

		return false


	# =========================================================
	# EMIT BURST
	# =========================================================

	interaction_burst_started.emit(
		launches
	)


	# =========================================================
	# FIRST INTERACTION SIGNAL
	# =========================================================

	var first_launch: Dictionary = (
		launches[0]
	)


	interaction_started.emit(
		first_launch.get(
			"object_data",
			{}
		),
		str(
			first_launch.get(
				"target",
				"ChestHitPoint"
			)
		),
		str(
			first_launch.get(
				"spawn",
				"RANDOM"
			)
		),
		float(
			first_launch.get(
				"force",
				safe_force
			)
		),
		float(
			first_launch.get(
				"speed",
				safe_speed
			)
		),
		launches.size(),
		float(
			first_launch.get(
				"scale",
				1.0
			)
		)
	)


	executing = false

	return true


# =============================================================
# RESOLVE OBJECT
# =============================================================

func _resolve_object(
	interaction: CIGAInteraction
) -> Dictionary:

	if interaction == null:

		return {}


	# =========================================================
	# RANDOM OBJECT
	# =========================================================

	if interaction.random_object:

		if object_manager == null:

			return {}


		if object_manager.objects.is_empty():

			return {}


		var random_index: int = randi_range(
			0,
			object_manager.objects.size() - 1
		)


		var random_object: Dictionary = (
			object_manager.objects[
				random_index
			]
		)


		return (
			random_object
			.duplicate(true)
		)


	# =========================================================
	# FIXED OBJECT
	# =========================================================

	var selected_object_id: String = str(
		_get_property_if_exists(
			interaction,
			"selected_object_id",
			""
		)
	)


	if not selected_object_id.is_empty():

		var fixed_object: Dictionary = (
			_find_object_by_id(
				selected_object_id
			)
		)


		if not fixed_object.is_empty():

			return fixed_object


	# =========================================================
	# FALLBACK
	# =========================================================

	if interaction.has_method(
		"get_selected_object"
	):

		var value: Variant = (
			interaction.get_selected_object()
		)


		if value is Dictionary:

			var result: Dictionary = (
				value
				as
				Dictionary
			)


			if not result.is_empty():

				return (
					result
					.duplicate(true)
				)


	return {}


# =============================================================
# RESOLVE TARGET
# =============================================================

func _resolve_target(
	interaction: CIGAInteraction
) -> String:

	if interaction == null:

		return "ChestHitPoint"


	# =========================================================
	# RANDOM TARGET
	# =========================================================

	if interaction.random_target:

		# =====================================================
		# RANDOM FROM SELECTED
		# =====================================================

		var selected_targets_value: Variant = (
			_get_property_if_exists(
				interaction,
				"selected_targets",
				[]
			)
		)


		if selected_targets_value is Array:

			var selected_targets: Array = (
				selected_targets_value
				as
				Array
			)


			if not selected_targets.is_empty():

				var selected_target: String = str(
					selected_targets.pick_random()
				)


				if not selected_target.is_empty():

					return (
						_normalize_hit_point_name(
							selected_target
						)
					)


		# =====================================================
		# RANDOM FROM AVAILABLE
		# =====================================================

		if interaction.has_method(
			"get_available_targets"
		):

			var available_value: Variant = (
				interaction.get_available_targets()
			)


			if available_value is Array:

				var available: Array = (
					available_value
					as
					Array
				)


				if not available.is_empty():

					var available_target: String = str(
						available.pick_random()
					)


					return (
						_normalize_hit_point_name(
							available_target
						)
					)


		# =====================================================
		# FINAL RANDOM FALLBACK
		# =====================================================

		var fallback_targets: Array[String] = [

			"HeadHitPoint",

			"ChestHitPoint",

			"LeftShoulderHitPoint",

			"RightShoulderHitPoint",

			"LeftArmHitPoint",

			"RightArmHitPoint",

			"LeftLegHitPoint",

			"RightLegHitPoint"
		]


		return fallback_targets.pick_random()


	# =========================================================
	# FIXED TARGET
	# =========================================================

	var selected_target: String = str(
		_get_property_if_exists(
			interaction,
			"selected_target",
			"ChestHitPoint"
		)
	)


	return (
		_normalize_hit_point_name(
			selected_target
		)
	)


# =============================================================
# NORMALIZE HIT POINT
# =============================================================

func _normalize_hit_point_name(
	value: String
) -> String:

	var normalized: String = (
		value
		.strip_edges()
	)


	if normalized.is_empty():

		return "ChestHitPoint"


	var compact: String = (
		normalized
		.to_upper()
		.replace(
			"_",
			""
		)
		.replace(
			" ",
			""
		)
	)


	if compact == "HEAD":
		return "HeadHitPoint"

	if compact == "HEADHITPOINT":
		return "HeadHitPoint"


	if compact == "CHEST":
		return "ChestHitPoint"

	if compact == "CHESTHITPOINT":
		return "ChestHitPoint"


	if compact == "LEFTSHOULDER":
		return "LeftShoulderHitPoint"

	if compact == "LEFTSHOULDERHITPOINT":
		return "LeftShoulderHitPoint"


	if compact == "RIGHTSHOULDER":
		return "RightShoulderHitPoint"

	if compact == "RIGHTSHOULDERHITPOINT":
		return "RightShoulderHitPoint"


	if compact == "LEFTARM":
		return "LeftArmHitPoint"

	if compact == "LEFTARMHITPOINT":
		return "LeftArmHitPoint"


	if compact == "RIGHTARM":
		return "RightArmHitPoint"

	if compact == "RIGHTARMHITPOINT":
		return "RightArmHitPoint"


	if compact == "LEFTLEG":
		return "LeftLegHitPoint"

	if compact == "LEFTLEGHITPOINT":
		return "LeftLegHitPoint"


	if compact == "RIGHTLEG":
		return "RightLegHitPoint"

	if compact == "RIGHTLEGHITPOINT":
		return "RightLegHitPoint"


	push_warning(
		"[CIGA INTERACTION] UNKNOWN HITPOINT | DEFAULTING TO ChestHitPoint | "
		+ value
	)

	return "ChestHitPoint"


# =============================================================
# RESOLVE SCALE
# =============================================================

func _resolve_scale(
	interaction: CIGAInteraction,
	object_data: Dictionary
) -> float:

	if interaction == null:

		return 1.0


	var object_id: String = str(
		object_data.get(
			"id",
			""
		)
	)


	# =========================================================
	# PROFILE OVERRIDE
	# =========================================================

	if profile_manager != null:

		if not object_id.is_empty():

			if profile_manager.has_method(
				"get_active_object_scale_override"
			):

				var override_scale: float = (
					profile_manager
					.get_active_object_scale_override(
						object_id
					)
				)


				if override_scale > 0.0:

					return clampf(
						override_scale,
						0.01,
						100.0
					)


	# =========================================================
	# RANDOM OBJECT
	# =========================================================

	if interaction.random_object:

		return clampf(
			float(
				object_data.get(
					"scale",
					1.0
				)
			),
			0.01,
			100.0
		)


	# =========================================================
	# NORMAL OBJECT
	# =========================================================

	return clampf(
		interaction.object_scale,
		0.01,
		100.0
	)


# =============================================================
# STATUS
# =============================================================

func is_ready() -> bool:

	return ready_for_execution


func is_executing() -> bool:

	return executing


# =============================================================
# EXECUTE EVENT ACTION
#
# CIGA EVENTS → CIGA INTERACTION
#
# =============================================================

func execute_event_action(
	action: Dictionary
) -> bool:

	# =========================================================
	# VALIDATION
	# =========================================================

	if action.is_empty():

		push_warning(
			"[CIGA INTERACTION] EVENT ACTION FAILED | ACTION EMPTY"
		)

		return false


	# =========================================================
	# ACTION TYPE
	# =========================================================

	var action_type: String = (
		str(
			action.get(
				"action_type",
				"INTERACTION"
			)
		)
		.to_upper()
		.strip_edges()
	)


	# =========================================================
	# DISPLAY IMAGE
	#
	# Não cria física.
	# Apenas envia a configuração através do mesmo canal de
	# eventos que o Viewport Runtime já utiliza.
	# =========================================================

	if action_type == "DISPLAY_IMAGE":

		var image_path: String = (
			str(
				action.get(
					"image_path",
					""
				)
			)
			.strip_edges()
		)


		if image_path.is_empty():

			push_warning(
				"[CIGA INTERACTION] DISPLAY IMAGE FAILED | IMAGE PATH EMPTY"
			)

			return false


		var image_name: String = (
			str(
				action.get(
					"image_name",
					""
				)
			)
			.strip_edges()
		)


		var image_target: String = (
			_normalize_hit_point_name(
				str(
					action.get(
						"image_target",
						"HEAD"
					)
				)
			)
		)


		var image_duration: float = clampf(
			float(
				action.get(
					"image_duration",
					300.0
				)
			),
			0.1,
			3600.0
		)


		var image_scale: float = clampf(
			float(
				action.get(
					"image_scale",
					1.0
				)
			),
			0.01,
			10.0
		)


		var image_offset_x: float = clampf(
			float(
				action.get(
					"image_offset_x",
					0.0
				)
			),
			-10.0,
			10.0
		)


		var image_offset_y: float = clampf(
			float(
				action.get(
					"image_offset_y",
					0.0
				)
			),
			-10.0,
			10.0
		)


		var image_offset_z: float = clampf(
			float(
				action.get(
					"image_offset_z",
					0.0
				)
			),
			-10.0,
			10.0
		)


		var image_rotation_x: float = clampf(
			float(
				action.get(
					"image_rotation_x",
					0.0
				)
			),
			-360.0,
			360.0
		)


		var image_rotation_y: float = clampf(
			float(
				action.get(
					"image_rotation_y",
					0.0
				)
			),
			-360.0,
			360.0
		)


		var image_rotation_z: float = clampf(
			float(
				action.get(
					"image_rotation_z",
					0.0
				)
			),
			-360.0,
			360.0
		)


		var image_mirror_h: bool = bool(
			action.get(
				"image_mirror_h",
				false
			)
		)


		var image_mirror_v: bool = bool(
			action.get(
				"image_mirror_v",
				false
			)
		)


		var image_request: Dictionary = {

			"action_type":
				"DISPLAY_IMAGE",

			"image_path":
				image_path,

			"image_name":
				image_name,

			"image_target":
				image_target,

			"image_duration":
				image_duration,

			"image_scale":
				image_scale,

			"image_offset":
				Vector3(
					image_offset_x,
					image_offset_y,
					image_offset_z
				),

			"image_offset_x":
				image_offset_x,

			"image_offset_y":
				image_offset_y,

			"image_offset_z":
				image_offset_z,

			"image_rotation_x":
				image_rotation_x,

			"image_rotation_y":
				image_rotation_y,

			"image_rotation_z":
				image_rotation_z,

			"image_mirror_h":
				image_mirror_h,

			"image_mirror_v":
				image_mirror_v
		}


		interaction_burst_started.emit(
			[
				image_request
			]
		)


		print(
			"[CIGA INTERACTION] DISPLAY IMAGE REQUEST | ",
			image_name,
			" | TARGET=",
			image_target,
			" | DURATION=",
			image_duration,
			" | SCALE=",
			image_scale
		)


		return true


	# =========================================================
	# DISPLAY IMAGE LIVE
	#
	# Este tipo NÃO contém a imagem real.
	#
	# O evento apenas informa:
	#
	#   - onde a imagem deve aparecer
	#   - quanto tempo deve ficar
	#   - escala
	#   - offsets
	#   - rotação
	#   - mirror
	#
	# A imagem real será recebida posteriormente pelo
	# CIGAOutput através do CIGAIS Worker.
	#
	# O Viewport Runtime guarda este pedido numa fila FIFO
	# até chegar a imagem correspondente.
	# =========================================================

	if action_type == "DISPLAY_IMAGE_LIVE":

		# =====================================================
		# TARGET
		# =====================================================

		var live_target: String = (
			_normalize_hit_point_name(
				str(
					action.get(
						"image_live_target",
						action.get(
							"image_target",
							"HEAD"
						)
					)
				)
			)
		)


		# =====================================================
		# DURATION
		# =====================================================

		var live_duration: float = clampf(
			float(
				action.get(
					"image_live_duration",
					5.0
				)
			),
			0.1,
			3600.0
		)


		# =====================================================
		# SCALE MODE
		# =====================================================

		var live_scale_mode: String = (
			str(
				action.get(
					"image_live_scale_mode",
					"FIXED"
				)
			)
			.to_upper()
			.strip_edges()
		)


		if live_scale_mode != "RANDOM":

			live_scale_mode = "FIXED"


		# =====================================================
		# SCALE
		# =====================================================

		var live_scale: float = clampf(
			float(
				action.get(
					"image_live_scale",
					1.0
				)
			),
			0.01,
			100.0
		)


		var live_scale_min: float = clampf(
			float(
				action.get(
					"image_live_scale_min",
					live_scale
				)
			),
			0.01,
			100.0
		)


		var live_scale_max: float = clampf(
			float(
				action.get(
					"image_live_scale_max",
					live_scale
				)
			),
			0.01,
			100.0
		)


		if live_scale_min > live_scale_max:

			var temporary_scale: float = (
				live_scale_min
			)

			live_scale_min = live_scale_max
			live_scale_max = temporary_scale


		# =====================================================
		# OFFSET X
		# =====================================================

		var live_offset_x_mode: String = (
			str(
				action.get(
					"image_live_offset_x_mode",
					"FIXED"
				)
			)
			.to_upper()
			.strip_edges()
		)


		if live_offset_x_mode != "RANDOM":

			live_offset_x_mode = "FIXED"


		var live_offset_x: float = clampf(
			float(
				action.get(
					"image_live_offset_x",
					0.0
				)
			),
			-100.0,
			100.0
		)


		var live_offset_x_min: float = clampf(
			float(
				action.get(
					"image_live_offset_x_min",
					live_offset_x
				)
			),
			-100.0,
			100.0
		)


		var live_offset_x_max: float = clampf(
			float(
				action.get(
					"image_live_offset_x_max",
					live_offset_x
				)
			),
			-100.0,
			100.0
		)


		if live_offset_x_min > live_offset_x_max:

			var temporary_offset_x: float = (
				live_offset_x_min
			)

			live_offset_x_min = live_offset_x_max
			live_offset_x_max = temporary_offset_x


		# =====================================================
		# OFFSET Y
		# =====================================================

		var live_offset_y_mode: String = (
			str(
				action.get(
					"image_live_offset_y_mode",
					"FIXED"
				)
			)
			.to_upper()
			.strip_edges()
		)


		if live_offset_y_mode != "RANDOM":

			live_offset_y_mode = "FIXED"


		var live_offset_y: float = clampf(
			float(
				action.get(
					"image_live_offset_y",
					0.0
				)
			),
			-100.0,
			100.0
		)


		var live_offset_y_min: float = clampf(
			float(
				action.get(
					"image_live_offset_y_min",
					live_offset_y
				)
			),
			-100.0,
			100.0
		)


		var live_offset_y_max: float = clampf(
			float(
				action.get(
					"image_live_offset_y_max",
					live_offset_y
				)
			),
			-100.0,
			100.0
		)


		if live_offset_y_min > live_offset_y_max:

			var temporary_offset_y: float = (
				live_offset_y_min
			)

			live_offset_y_min = live_offset_y_max
			live_offset_y_max = temporary_offset_y


		# =====================================================
		# OFFSET Z
		# =====================================================

		var live_offset_z_mode: String = (
			str(
				action.get(
					"image_live_offset_z_mode",
					"FIXED"
				)
			)
			.to_upper()
			.strip_edges()
		)


		if live_offset_z_mode != "RANDOM":

			live_offset_z_mode = "FIXED"


		var live_offset_z: float = clampf(
			float(
				action.get(
					"image_live_offset_z",
					0.0
				)
			),
			-100.0,
			100.0
		)


		var live_offset_z_min: float = clampf(
			float(
				action.get(
					"image_live_offset_z_min",
					live_offset_z
				)
			),
			-100.0,
			100.0
		)


		var live_offset_z_max: float = clampf(
			float(
				action.get(
					"image_live_offset_z_max",
					live_offset_z
				)
			),
			-100.0,
			100.0
		)


		if live_offset_z_min > live_offset_z_max:

			var temporary_offset_z: float = (
				live_offset_z_min
			)

			live_offset_z_min = live_offset_z_max
			live_offset_z_max = temporary_offset_z


		# =====================================================
		# ROTATION X
		# =====================================================

		var live_rotation_x_mode: String = (
			str(
				action.get(
					"image_live_rotation_x_mode",
					"FIXED"
				)
			)
			.to_upper()
			.strip_edges()
		)


		if live_rotation_x_mode != "RANDOM":

			live_rotation_x_mode = "FIXED"


		var live_rotation_x: float = clampf(
			float(
				action.get(
					"image_live_rotation_x",
					0.0
				)
			),
			-360.0,
			360.0
		)


		var live_rotation_x_min: float = clampf(
			float(
				action.get(
					"image_live_rotation_x_min",
					live_rotation_x
				)
			),
			-360.0,
			360.0
		)


		var live_rotation_x_max: float = clampf(
			float(
				action.get(
					"image_live_rotation_x_max",
					live_rotation_x
				)
			),
			-360.0,
			360.0
		)


		if live_rotation_x_min > live_rotation_x_max:

			var temporary_rotation_x: float = (
				live_rotation_x_min
			)

			live_rotation_x_min = live_rotation_x_max
			live_rotation_x_max = temporary_rotation_x


		# =====================================================
		# ROTATION Y
		# =====================================================

		var live_rotation_y_mode: String = (
			str(
				action.get(
					"image_live_rotation_y_mode",
					"FIXED"
				)
			)
			.to_upper()
			.strip_edges()
		)


		if live_rotation_y_mode != "RANDOM":

			live_rotation_y_mode = "FIXED"


		var live_rotation_y: float = clampf(
			float(
				action.get(
					"image_live_rotation_y",
					0.0
				)
			),
			-360.0,
			360.0
		)


		var live_rotation_y_min: float = clampf(
			float(
				action.get(
					"image_live_rotation_y_min",
					live_rotation_y
				)
			),
			-360.0,
			360.0
		)


		var live_rotation_y_max: float = clampf(
			float(
				action.get(
					"image_live_rotation_y_max",
					live_rotation_y
				)
			),
			-360.0,
			360.0
		)


		if live_rotation_y_min > live_rotation_y_max:

			var temporary_rotation_y: float = (
				live_rotation_y_min
			)

			live_rotation_y_min = live_rotation_y_max
			live_rotation_y_max = temporary_rotation_y


		# =====================================================
		# ROTATION Z
		# =====================================================

		var live_rotation_z_mode: String = (
			str(
				action.get(
					"image_live_rotation_z_mode",
					"FIXED"
				)
			)
			.to_upper()
			.strip_edges()
		)


		if live_rotation_z_mode != "RANDOM":

			live_rotation_z_mode = "FIXED"


		var live_rotation_z: float = clampf(
			float(
				action.get(
					"image_live_rotation_z",
					0.0
				)
			),
			-360.0,
			360.0
		)


		var live_rotation_z_min: float = clampf(
			float(
				action.get(
					"image_live_rotation_z_min",
					live_rotation_z
				)
			),
			-360.0,
			360.0
		)


		var live_rotation_z_max: float = clampf(
			float(
				action.get(
					"image_live_rotation_z_max",
					live_rotation_z
				)
			),
			-360.0,
			360.0
		)


		if live_rotation_z_min > live_rotation_z_max:

			var temporary_rotation_z: float = (
				live_rotation_z_min
			)

			live_rotation_z_min = live_rotation_z_max
			live_rotation_z_max = temporary_rotation_z


		# =====================================================
		# MIRROR
		# =====================================================

		var live_mirror_h: bool = bool(
			action.get(
				"image_live_mirror_h",
				false
			)
		)


		var live_mirror_v: bool = bool(
			action.get(
				"image_live_mirror_v",
				false
			)
		)


		# =====================================================
		# BUILD LIVE IMAGE REQUEST
		# =====================================================

		var live_image_request: Dictionary = {

			"action_type":
				"DISPLAY_IMAGE_LIVE",

			"image_live_target":
				live_target,

			"image_live_duration":
				live_duration,

			"image_live_scale_mode":
				live_scale_mode,

			"image_live_scale":
				live_scale,

			"image_live_scale_min":
				live_scale_min,

			"image_live_scale_max":
				live_scale_max,

			"image_live_offset_x_mode":
				live_offset_x_mode,

			"image_live_offset_x":
				live_offset_x,

			"image_live_offset_x_min":
				live_offset_x_min,

			"image_live_offset_x_max":
				live_offset_x_max,

			"image_live_offset_y_mode":
				live_offset_y_mode,

			"image_live_offset_y":
				live_offset_y,

			"image_live_offset_y_min":
				live_offset_y_min,

			"image_live_offset_y_max":
				live_offset_y_max,

			"image_live_offset_z_mode":
				live_offset_z_mode,

			"image_live_offset_z":
				live_offset_z,

			"image_live_offset_z_min":
				live_offset_z_min,

			"image_live_offset_z_max":
				live_offset_z_max,

			"image_live_rotation_x_mode":
				live_rotation_x_mode,

			"image_live_rotation_x":
				live_rotation_x,

			"image_live_rotation_x_min":
				live_rotation_x_min,

			"image_live_rotation_x_max":
				live_rotation_x_max,

			"image_live_rotation_y_mode":
				live_rotation_y_mode,

			"image_live_rotation_y":
				live_rotation_y,

			"image_live_rotation_y_min":
				live_rotation_y_min,

			"image_live_rotation_y_max":
				live_rotation_y_max,

			"image_live_rotation_z_mode":
				live_rotation_z_mode,

			"image_live_rotation_z":
				live_rotation_z,

			"image_live_rotation_z_min":
				live_rotation_z_min,

			"image_live_rotation_z_max":
				live_rotation_z_max,

			"image_live_mirror_h":
				live_mirror_h,

			"image_live_mirror_v":
				live_mirror_v
		}


		# =====================================================
		# EMIT LIVE IMAGE REQUEST
		# =====================================================

		interaction_burst_started.emit(
			[
				live_image_request
			]
		)


		print(
			"[CIGA INTERACTION] DISPLAY IMAGE LIVE REQUEST | ",
			"TARGET=",
			live_target,
			" | DURATION=",
			live_duration,
			" | SCALE_MODE=",
			live_scale_mode,
			" | SCALE=",
			live_scale,
			" | MIRROR_H=",
			live_mirror_h,
			" | MIRROR_V=",
			live_mirror_v
		)


		return true


	# =========================================================
	# NORMAL INTERACTION
	# =========================================================

	if object_manager == null:

		push_warning(
			"[CIGA INTERACTION] EVENT ACTION FAILED | OBJECT MANAGER"
		)

		return false


	var interaction := (
		CIGAInteraction.new()
	)


	# =========================================================
	# AMOUNT
	# =========================================================

	var resolved_amount: int = clampi(
		int(
			action.get(
				"resolved_amount",
				action.get(
					"amount",
					1
				)
			)
		),
		1,
		100
	)


	interaction.amount = (
		resolved_amount
	)


	# =========================================================
	# FORCE
	# =========================================================

	var force_mode: String = str(
		action.get(
			"force_mode",
			"INHERIT"
		)
	)


	if force_mode == "CUSTOM":

		interaction.force = float(
			action.get(
				"force",
				1.8
			)
		)

	else:

		var force_defaults: Dictionary = (
			_get_interaction_defaults_for_event()
		)


		interaction.force = float(
			force_defaults.get(
				"force",
				1.8
			)
		)


	# =========================================================
	# SPEED
	# =========================================================

	var speed_mode: String = str(
		action.get(
			"speed_mode",
			"INHERIT"
		)
	)


	if speed_mode == "CUSTOM":

		interaction.speed = float(
			action.get(
				"speed",
				6.2
			)
		)

	else:

		var speed_defaults: Dictionary = (
			_get_interaction_defaults_for_event()
		)


		interaction.speed = float(
			speed_defaults.get(
				"speed",
				6.2
			)
		)


	# =========================================================
	# TARGET MODE
	# =========================================================

	var target_mode: String = str(
		action.get(
			"target_mode",
			"RANDOM_FROM_ALL"
		)
	)


	if target_mode == "FIXED":

		interaction.random_target = false

	else:

		interaction.random_target = true


	# =========================================================
	# TARGET
	# =========================================================

	var event_target: String = str(
		action.get(
			"target",
			"CHEST"
		)
	)


	interaction.selected_target = (
		_normalize_hit_point_name(
			event_target
		)
	)


	# =========================================================
	# SELECTED TARGETS
	# =========================================================

	var selected_targets_value: Variant = (
		action.get(
			"selected_targets",
			[]
		)
	)


	if selected_targets_value is Array:

		var selected_targets_copy: Array = (
			(
				selected_targets_value
				as
				Array
			)
			.duplicate(true)
		)


		_set_property_if_exists(
			interaction,
			"selected_targets",
			selected_targets_copy
		)


	# =========================================================
	# SPAWN
	# =========================================================

	var spawn_name: String = str(
		action.get(
			"spawn",
			"RANDOM"
		)
	)


	if spawn_name.is_empty():

		spawn_name = "RANDOM"


	_set_property_if_exists(
		interaction,
		"selected_spawn",
		spawn_name
	)


	# =========================================================
	# OBJECT MODE
	# =========================================================

	var object_mode: String = str(
		action.get(
			"object_mode",
			"RANDOM_FROM_ALL"
		)
	)


	interaction.random_object = (
		object_mode != "FIXED"
	)


	# =========================================================
	# FIXED OBJECT
	# =========================================================

	if object_mode == "FIXED":

		var object_id: String = str(
			action.get(
				"object_id",
				""
			)
		)


		if object_id.is_empty():

			push_warning(
				"[CIGA INTERACTION] EVENT ACTION FAILED | FIXED OBJECT ID EMPTY"
			)

			return false


		var fixed_object: Dictionary = (
			_find_object_by_id(
				object_id
			)
		)


		if fixed_object.is_empty():

			push_warning(
				"[CIGA INTERACTION] EVENT ACTION FAILED | OBJECT NOT FOUND | "
				+
				object_id
			)

			return false


		_set_event_object(
			interaction,
			fixed_object
		)


	# =========================================================
	# RANDOM FROM SELECTED
	# =========================================================

	elif object_mode == "RANDOM_FROM_SELECTED":

		var selected_ids_value: Variant = (
			action.get(
				"selected_object_ids",
				[]
			)
		)


		if not selected_ids_value is Array:

			push_warning(
				"[CIGA INTERACTION] EVENT ACTION FAILED | INVALID OBJECT ARRAY"
			)

			return false


		var selected_ids: Array = (
			selected_ids_value
			as
			Array
		)


		if selected_ids.is_empty():

			push_warning(
				"[CIGA INTERACTION] EVENT ACTION FAILED | OBJECT ARRAY EMPTY"
			)

			return false


		var candidates: Array[Dictionary] = []


		for object_data: Dictionary in object_manager.objects:

			var current_id: String = str(
				object_data.get(
					"id",
					""
				)
			)


			if selected_ids.has(
				current_id
			):

				candidates.append(
					object_data
				)


		if candidates.is_empty():

			push_warning(
				"[CIGA INTERACTION] EVENT ACTION FAILED | NO OBJECT MATCH"
			)

			return false


		var selected_object: Dictionary = (
			candidates.pick_random()
		)


		_set_event_object(
			interaction,
			selected_object
		)


	# =========================================================
	# RANDOM FROM ALL
	# =========================================================

	else:

		interaction.random_object = true


	# =========================================================
	# SCALE
	# =========================================================

	var object_scale: float = float(
		action.get(
			"scale",
			1.0
		)
	)


	_set_property_if_exists(
		interaction,
		"object_scale",
		clampf(
			object_scale,
			0.01,
			100.0
		)
	)


	# =========================================================
	# EXECUTE
	# =========================================================

	return execute_configuration(
		interaction,
		true
	)


# =============================================================
# EVENT DEFAULTS
# =============================================================

func _get_interaction_defaults_for_event() -> Dictionary:

	if profile_manager == null:

		return {
			"force": 1.8,
			"speed": 6.2,
			"amount": 1
		}


	if not profile_manager.has_method(
		"get_active_interaction"
	):

		return {
			"force": 1.8,
			"speed": 6.2,
			"amount": 1
		}


	var value: Variant = (
		profile_manager
		.get_active_interaction()
	)


	if value is Dictionary:

		return (
			value
			as
			Dictionary
		)


	return {
		"force": 1.8,
		"speed": 6.2,
		"amount": 1
	}


# =============================================================
# FIND OBJECT
# =============================================================

func _find_object_by_id(
	object_id: String
) -> Dictionary:

	if object_manager == null:

		return {}


	if object_id.is_empty():

		return {}


	for object_data: Dictionary in (
		object_manager.objects
	):

		if str(
			object_data.get(
				"id",
				""
			)
		) == object_id:

			return (
				object_data
				.duplicate(true)
			)


	return {}


# =============================================================
# SET EVENT OBJECT
# =============================================================

func _set_event_object(
	interaction: CIGAInteraction,
	object_data: Dictionary
) -> void:

	if interaction == null:

		return


	if object_data.is_empty():

		return


	var object_id: String = str(
		object_data.get(
			"id",
			""
		)
	)


	if object_id.is_empty():

		return


	interaction.random_object = false


	_set_property_if_exists(
		interaction,
		"selected_object_id",
		object_id
	)


	_set_property_if_exists(
		interaction,
		"object_id",
		object_id
	)


	var object_scale: float = float(
		object_data.get(
			"scale",
			1.0
		)
	)


	_set_property_if_exists(
		interaction,
		"object_scale",
		object_scale
	)


# =============================================================
# SAFE PROPERTY SET
# =============================================================

func _set_property_if_exists(
	object: Object,
	property_name: String,
	value: Variant
) -> void:

	if object == null:

		return


	for property_data: Dictionary in (
		object.get_property_list()
	):

		if str(
			property_data.get(
				"name",
				""
			)
		) != property_name:

			continue


		object.set(
			property_name,
			value
		)

		return


# =============================================================
# SAFE PROPERTY GET
# =============================================================

func _get_property_if_exists(
	object: Object,
	property_name: String,
	default_value: Variant
) -> Variant:

	if object == null:

		return default_value


	for property_data: Dictionary in (
		object.get_property_list()
	):

		if str(
			property_data.get(
				"name",
				""
			)
		) != property_name:

			continue


		return (
			object.get(
				property_name
			)
		)


	return default_value
