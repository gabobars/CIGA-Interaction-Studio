class_name CIGAEventsRuntime
extends Node


# =============================================================
# CIGA EVENTS RUNTIME
# =============================================================

signal event_started(
	event_name: String
)

signal event_finished(
	event_name: String
)

signal interaction_requested(
	interaction_data: Dictionary
)

signal worker_event_requested(
	event_data: Dictionary
)

# =============================================================
# REFERENCES
# =============================================================

var profile_manager: CIGAProfiles = null

var interaction_runtime: Node = null


# =============================================================
# STATE
# =============================================================

var ready_for_execution: bool = false

var executing: bool = false


# =============================================================
# AUDIO
# =============================================================

const MAX_AUDIO_PLAYERS: int = 16

const DEFAULT_SOUND_VOLUME: float = 0.70

var audio_players: Array[AudioStreamPlayer] = []


# =============================================================
# SETUP
# =============================================================

func setup(
	profiles: CIGAProfiles,
	interaction: Node
) -> void:

	profile_manager = profiles

	interaction_runtime = interaction

	ready_for_execution = (
		profile_manager != null
		and
		interaction_runtime != null
	)

	_ensure_audio_players()


func _ready() -> void:

	_ensure_audio_players()


# =============================================================
# AUDIO PLAYERS
# =============================================================

func _ensure_audio_players() -> void:

	if audio_players.size() >= MAX_AUDIO_PLAYERS:

		return


	for index: int in range(
		audio_players.size(),
		MAX_AUDIO_PLAYERS
	):

		var player := AudioStreamPlayer.new()


		player.name = (
			"CIGAEventAudioPlayer_"
			+
			str(
				index + 1
			)
		)


		add_child(
			player
		)


		audio_players.append(
			player
		)


func _get_free_audio_player() -> AudioStreamPlayer:

	_ensure_audio_players()


	for player: AudioStreamPlayer in audio_players:

		if not player.playing:

			return player


	if not audio_players.is_empty():

		return audio_players[0]


	return null


func _load_audio_stream(
	path: String
) -> AudioStream:

	if path.is_empty():

		return null


	if not FileAccess.file_exists(
		path
	):

		print(
			"[CIGA EVENTS] AUDIO FILE NOT FOUND | ",
			path
		)

		return null


	var extension := (
		path
		.get_extension()
		.to_lower()
	)


	match extension:

		"mp3":

			return AudioStreamMP3.load_from_file(
				path
			)

		"ogg":

			return AudioStreamOggVorbis.load_from_file(
				path
			)

		"wav":

			return AudioStreamWAV.load_from_file(
				path
			)

		_:

			print(
				"[CIGA EVENTS] UNSUPPORTED AUDIO FORMAT | ",
				extension
			)

			return null


func _play_sound_action(
	action: Dictionary
) -> void:

	var path := (
		str(
			action.get(
				"sound_path",
				""
			)
		)
		.strip_edges()
	)


	if path.is_empty():

		print(
			"[CIGA EVENTS] SOUND ACTION WITHOUT FILE"
		)

		return


	var stream := _load_audio_stream(
		path
	)


	if stream == null:

		print(
			"[CIGA EVENTS] SOUND LOAD FAILED | ",
			path
		)

		return


	var player := _get_free_audio_player()


	if player == null:

		return


	var volume := float(
		action.get(
			"volume",
			DEFAULT_SOUND_VOLUME
		)
	)


	if not is_finite(
		volume
	):

		volume = DEFAULT_SOUND_VOLUME


	volume = clampf(
		volume,
		0.0,
		1.0
	)


	player.stop()

	player.stream = stream


	if volume <= 0.0001:

		player.volume_db = -80.0

	else:

		player.volume_db = (
			linear_to_db(
				volume
			)
		)


	print(
		"[CIGA EVENTS] PLAY SOUND | ",
		str(
			action.get(
				"sound_name",
				path.get_file()
			)
		),
		" | VOLUME=",
		"%.0f" % (
			volume * 100.0
		),
		"%"
	)


	player.play()


# =============================================================
# NORMALIZE EVENT
#
# Everything becomes:
#
#   UPPERCASE
#   spaces      -> _
#   -           -> _
#   .           -> _
#   /           -> _
#
# Example:
#
#   channel-points-redeem
#   Channel Points Redeem
#   CHANNEL.POINTS.REDEEM
#
# all become:
#
#   CHANNEL_POINTS_REDEEM
# =============================================================

func normalize_event_name(
	event_name: String
) -> String:

	var normalized := (
		event_name
		.to_upper()
		.strip_edges()
	)


	if normalized.is_empty():

		return ""


	normalized = normalized.replace(
		".",
		"_"
	)

	normalized = normalized.replace(
		" ",
		"_"
	)

	normalized = normalized.replace(
		"-",
		"_"
	)

	normalized = normalized.replace(
		"/",
		"_"
	)


	while normalized.find(
		"__"
	) != -1:

		normalized = normalized.replace(
			"__",
			"_"
		)


	return normalized


# =============================================================
# ALIASES
# =============================================================

func get_event_aliases(
	event_name: String
) -> Array[String]:

	var normalized := normalize_event_name(
		event_name
	)

	var aliases: Array[String] = []


	if normalized.is_empty():

		return aliases


	aliases.append(
		normalized
	)


	# =========================================================
	# FOLLOW
	# =========================================================

	if (
		normalized == "FOLLOW"
		or
		normalized == "CHANNEL_FOLLOW"
	):

		if not aliases.has(
			"FOLLOW"
		):

			aliases.append(
				"FOLLOW"
			)


		if not aliases.has(
			"CHANNEL_FOLLOW"
		):

			aliases.append(
				"CHANNEL_FOLLOW"
			)


	# =========================================================
	# SUBSCRIPTION
	# =========================================================

	if (
		normalized == "SUB"
		or
		normalized == "SUBSCRIBE"
		or
		normalized == "SUBSCRIBER"
		or
		normalized == "CHANNEL_SUBSCRIBE"
	):

		for alias: String in [
			"SUB",
			"SUBSCRIBE",
			"SUBSCRIBER",
			"CHANNEL_SUBSCRIBE"
		]:

			if not aliases.has(
				alias
			):

				aliases.append(
					alias
				)


	# =========================================================
	# BITS / CHEER
	# =========================================================

	if (
		normalized == "BIT"
		or
		normalized == "BITS"
		or
		normalized == "CHEER"
		or
		normalized == "CHANNEL_CHEER"
	):

		for alias: String in [
			"BIT",
			"BITS",
			"CHEER",
			"CHANNEL_CHEER"
		]:

			if not aliases.has(
				alias
			):

				aliases.append(
					alias
				)


	# =========================================================
	# RAID
	# =========================================================

	if (
		normalized == "RAID"
		or
		normalized == "CHANNEL_RAID"
	):

		for alias: String in [
			"RAID",
			"CHANNEL_RAID"
		]:

			if not aliases.has(
				alias
			):

				aliases.append(
					alias
				)


	# =========================================================
	# CHANNEL POINTS
	# =========================================================

	if (
		normalized == "CHANNEL_POINTS_REDEEM"
		or
		normalized == "CHANNEL_POINT_REDEEM"
		or
		normalized == "CHANNEL_POINTS_REDEMPTION"
		or
		normalized == "CHANNEL_POINT_REDEMPTION"
		or
		normalized == "CHANNEL_POINTS_CUSTOM_REWARD_REDEMPTION"
		or
		normalized == "CHANNEL_POINTS_CUSTOM_REWARD_REDEMPTION_ADD"
		or
		normalized == "CHANNEL_CHANNEL_POINTS_CUSTOM_REWARD_REDEMPTION_ADD"
		or
		normalized == "CHANNELPOINTSREDEMPTION"
	):

		for alias: String in [
			"CHANNEL_POINTS_REDEEM",
			"CHANNEL_POINT_REDEEM",
			"CHANNEL_POINTS_REDEMPTION",
			"CHANNEL_POINT_REDEMPTION",
			"CHANNEL_POINTS_CUSTOM_REWARD_REDEMPTION",
			"CHANNEL_POINTS_CUSTOM_REWARD_REDEMPTION_ADD",
			"CHANNEL_CHANNEL_POINTS_CUSTOM_REWARD_REDEMPTION_ADD",
			"CHANNELPOINTSREDEMPTION"
		]:

			if not aliases.has(
				alias
			):

				aliases.append(
					alias
				)


	return aliases


# =============================================================
# REWARD
# =============================================================

func get_reward_name_from_payload(
	payload: Dictionary
) -> String:

	if payload.is_empty():

		return ""


	# =========================================================
	# TOP LEVEL
	# =========================================================

	for key: String in [
		"reward_name",
		"rewardName",
		"reward_title",
		"rewardTitle",
		"redemption"
	]:

		if not payload.has(
			key
		):

			continue


		var value: Variant = payload.get(
			key,
			""
		)


		if value == null:

			continue


		var result := (
			str(value)
			.strip_edges()
		)


		if not result.is_empty():

			return result


	# =========================================================
	# DATA
	# =========================================================

	var data_value: Variant = payload.get(
		"data",
		null
	)


	if data_value is Dictionary:

		var data := (
			data_value
			as Dictionary
		)


		for key: String in [
			"redemption",
			"reward_name",
			"rewardName",
			"reward_title",
			"rewardTitle"
		]:

			if not data.has(
				key
			):

				continue


			var value: Variant = data.get(
				key,
				""
			)


			if value == null:

				continue


			var result := (
				str(value)
				.strip_edges()
			)


			if not result.is_empty():

				return result


		# =====================================================
		# NESTED REWARD
		# =====================================================

		for key: String in [
			"reward",
			"redemption"
		]:

			var nested_value: Variant = (
				data.get(
					key,
					null
				)
			)


			if not nested_value is Dictionary:

				continue


			var reward_data := (
				nested_value
				as Dictionary
			)


			for nested_key: String in [
				"title",
				"name",
				"redemption"
			]:

				var value: Variant = (
					reward_data.get(
						nested_key,
						""
					)
				)


				if value == null:

					continue


				var result := (
					str(value)
					.strip_edges()
				)


				if not result.is_empty():

					return result


	# =========================================================
	# TOP LEVEL REWARD DICTIONARY
	# =========================================================

	var reward_value: Variant = (
		payload.get(
			"reward",
			null
		)
	)


	if reward_value is Dictionary:

		var reward := (
			reward_value
			as Dictionary
		)


		for key: String in [
			"title",
			"name",
			"redemption"
		]:

			var value: Variant = (
				reward.get(
					key,
					""
				)
			)


			if value == null:

				continue


			var result := (
				str(value)
				.strip_edges()
			)


			if not result.is_empty():

				return result


	return ""


# =============================================================
# REWARD MATCH
#
# CASE-INSENSITIVE
#
#   throw rock
#   THROW ROCK
#   Throw Rock
#   ThRoW RoCk
#
# all match the same reward.
#
# Empty configured reward means:
#
#   ANY REWARD
# =============================================================

func reward_matches(
	required_reward_name: String,
	payload: Dictionary
) -> bool:

	var required := (
		required_reward_name
		.strip_edges()
	)


	if required.is_empty():

		return true


	var actual := (
		get_reward_name_from_payload(
			payload
		)
		.strip_edges()
	)


	if actual.is_empty():

		return false


	return (
		required.to_lower()
		==
		actual.to_lower()
	)


# =============================================================
# RECEIVE EVENT
# =============================================================

func receive_event(
	event_name: String,
	payload: Dictionary = {}
) -> void:

	var normalized_name := normalize_event_name(
		event_name
	)


	if normalized_name.is_empty():

		return


	var username := (
		_get_username_from_payload(
			payload
		)
	)


	var reward_name := (
		get_reward_name_from_payload(
			payload
		)
	)


	var user_input := (
		_get_user_input_from_payload(
			payload
		)
	)


	# =========================================================
	# LOG EXTERNAL EVENT
	# =========================================================

	_log_external_event(
		normalized_name,
		username,
		reward_name,
		user_input
	)


	# =========================================================
	# LOAD SAVED EVENTS
	# =========================================================

	var events := (
		get_saved_events()
	)


	if events.is_empty():

		return


	var aliases := (
		get_event_aliases(
			normalized_name
		)
	)


	if aliases.is_empty():

		return


	# =========================================================
	# FIND MATCHED EVENTS
	# =========================================================

	var matched_events: Array[Dictionary] = []


	for event_id_value: Variant in events.keys():

		var event_id := str(
			event_id_value
		)


		if event_id == "_ciga_defaults_initialized":

			continue


		var value: Variant = (
			events.get(
				event_id_value,
				{}
			)
		)


		if not value is Dictionary:

			continue


		var event_data := (
			value
			as
			Dictionary
		)


		# =====================================================
		# ENABLED
		# =====================================================

		if not bool(
			event_data.get(
				"enabled",
				true
			)
		):

			continue


		# =====================================================
		# TRIGGER
		# =====================================================

		var trigger_event := (
			normalize_event_name(
				str(
					event_data.get(
						"trigger_event",
						event_id
					)
				)
			)
		)


		if trigger_event.is_empty():

			continue


		if not aliases.has(
			trigger_event
		):

			continue


		# =====================================================
		# REWARD FILTER
		# =====================================================

		var required_reward := (
			str(
				event_data.get(
					"reward_name",
					""
				)
			)
			.strip_edges()
		)


		if (
			trigger_event == "CHANNEL_POINTS_REDEEM"
			and
			not reward_matches(
				required_reward,
				payload
			)
		):

			continue


		# =====================================================
		# MATCH
		# =====================================================

		var matched := (
			event_data
			.duplicate(true)
		)


		matched["_ciga_event_id"] = (
			event_id
		)


		matched_events.append(
			matched
		)


	# =========================================================
	# NO MATCH
	# =========================================================

	if matched_events.is_empty():

		return


	# =========================================================
	# CIGAIS WORKER / DISCORD
	#
	# Only send an external worker event when the matched
	# configuration actually contains a normal interaction.
	#
	# DISPLAY_IMAGE
	# DISPLAY_IMAGE_LIVE
	# PLAY_SOUND
	#
	# are local actions and do not generate a Discord message.
	# =========================================================

	if _matched_events_require_worker_notification(
		matched_events
	):

		var worker_event := _build_worker_event(
			normalized_name,
			payload,
			username,
			reward_name,
			user_input
		)


		if not worker_event.is_empty():

			worker_event_requested.emit(
				worker_event
			)


	# =========================================================
	# EXECUTE ALL MATCHED EVENTS
	# =========================================================

	executing = true


	for matched_value: Variant in matched_events:

		if not matched_value is Dictionary:

			continue


		var event_data := (
			matched_value
			as
			Dictionary
		)


		var event_id := str(
			event_data.get(
				"_ciga_event_id",
				""
			)
		)


		if event_id.is_empty():

			continue


		event_started.emit(
			event_id
		)


		var actions_value: Variant = (
			event_data.get(
				"actions",
				[]
			)
		)


		if actions_value is Array:

			var actions := (
				actions_value
				as
				Array
			)


			for action_value: Variant in actions:

				if not action_value is Dictionary:

					continue


				var action := (
					action_value
					as
					Dictionary
				)


				var resolved := (
					resolve_action(
						action,
						payload
					)
				)


				interaction_requested.emit(
					resolved
				)


				execute_action(
					resolved
				)


		event_finished.emit(
			event_id
		)


	executing = false


	_log_execution_result(
		normalized_name,
		matched_events.size()
	)
	

func _matched_events_require_worker_notification(
	matched_events: Array[Dictionary]
) -> bool:

	for event_data: Dictionary in matched_events:

		var actions_value: Variant = (
			event_data.get(
				"actions",
				[]
			)
		)


		if not actions_value is Array:

			continue


		var actions := (
			actions_value
			as
			Array
		)


		for action_value: Variant in actions:

			if not action_value is Dictionary:

				continue


			var action := (
				action_value
				as
				Dictionary
			)


			var action_type := (
				str(
					action.get(
						"action_type",
						""
					)
				)
				.to_upper()
				.strip_edges()
			)


			print(
				"[CIGA EVENTS] WORKER ACTION CHECK | TYPE=",
				action_type
			)


			# =================================================
			# DISPLAY IMAGE NORMAL
			# LOCAL ONLY
			# =================================================

			if action_type == "DISPLAY_IMAGE":

				continue


			# =================================================
			# PLAY SOUND
			# LOCAL ONLY
			# =================================================

			if action_type == "PLAY_SOUND":

				continue


			# =================================================
			# NORMAL INTERACTION
			# LOCAL CIGA ACTION
			#
			# NÃO envia Discord.
			# =================================================

			if action_type == "INTERACTION":

				continue


			# =================================================
			# DISPLAY IMAGE LIVE
			#
			# ÚNICA ACTION QUE REQUER WORKER
			# =================================================

			if action_type == "DISPLAY_IMAGE_LIVE":

				return true


			# =================================================
			# UNKNOWN
			#
			# Não enviamos automaticamente.
			# =================================================

			print(
				"[CIGA EVENTS] UNKNOWN WORKER ACTION TYPE | ",
				action_type
			)


	return false

# =============================================================
# RESOLVE ACTION
# =============================================================

func resolve_action(
	action: Dictionary,
	payload: Dictionary
) -> Dictionary:

	var result := (
		action
		.duplicate(true)
	)


	if result.is_empty():

		return result


	var action_type := (
		str(
			result.get(
				"action_type",
				"INTERACTION"
			)
		)
		.to_upper()
		.strip_edges()
	)


	result["action_type"] = (
		action_type
	)


	# =========================================================
	# SOUND
	# =========================================================

	if action_type == "PLAY_SOUND":

		var sound_path := str(
			result.get(
				"sound_path",
				""
			)
		)


		var volume := float(
			result.get(
				"volume",
				DEFAULT_SOUND_VOLUME
			)
		)


		if not is_finite(
			volume
		):

			volume = DEFAULT_SOUND_VOLUME


		result["sound_path"] = (
			sound_path
		)


		result["sound_name"] = str(
			result.get(
				"sound_name",
				""
			)
		)


		result["volume"] = clampf(
			volume,
			0.0,
			1.0
		)


	# =========================================================
	# DISPLAY IMAGE
	# =========================================================

	elif action_type == "DISPLAY_IMAGE":

		var duration := float(
			result.get(
				"image_duration",
				300.0
			)
		)


		var image_scale := float(
			result.get(
				"image_scale",
				1.0
			)
		)


		if not is_finite(
			duration
		):

			duration = 300.0


		if not is_finite(
			image_scale
		):

			image_scale = 1.0


		result["image_path"] = str(
			result.get(
				"image_path",
				""
			)
		)


		result["image_name"] = str(
			result.get(
				"image_name",
				""
			)
		)


		result["image_target"] = (
			str(
				result.get(
					"image_target",
					"HEAD"
				)
			)
			.strip_edges()
		)


		result["image_duration"] = clampf(
			duration,
			0.1,
			3600.0
		)


		result["image_scale"] = clampf(
			image_scale,
			0.01,
			10.0
		)


		# -----------------------------------------------------
		# OFFSET
		# -----------------------------------------------------

		for key: String in [
			"image_offset_x",
			"image_offset_y",
			"image_offset_z"
		]:

			var offset := float(
				result.get(
					key,
					0.0
				)
			)


			if not is_finite(
				offset
			):

				offset = 0.0


			result[key] = clampf(
				offset,
				-10.0,
				10.0
			)


		# -----------------------------------------------------
		# ROTATION
		# -----------------------------------------------------

		for key: String in [
			"image_rotation_x",
			"image_rotation_y",
			"image_rotation_z"
		]:

			var rotation := float(
				result.get(
					key,
					0.0
				)
			)


			if not is_finite(
				rotation
			):

				rotation = 0.0


			result[key] = rotation


		result["image_mirror_h"] = bool(
			result.get(
				"image_mirror_h",
				false
			)
		)


		result["image_mirror_v"] = bool(
			result.get(
				"image_mirror_v",
				false
			)
		)


	# =========================================================
	# INTERACTION
	# =========================================================

	else:

		result["action_type"] = (
			"INTERACTION"
			if action_type.is_empty()
			else
			action_type
		)


	# =========================================================
	# AMOUNT
	#
	# Só interessa para INTERACTION,
	# mas manter isto aqui continua compatível com
	# a estrutura que já tinhas.
	# =========================================================

	var amount_mode := (
		str(
			result.get(
				"amount_mode",
				"FIXED"
			)
		)
		.to_upper()
		.strip_edges()
	)


	if amount_mode == "RANDOM_RANGE":

		var minimum := clampi(
			int(
				result.get(
					"amount_min",
					1
				)
			),
			1,
			100
		)


		var maximum := clampi(
			int(
				result.get(
					"amount_max",
					minimum
				)
			),
			1,
			100
		)


		if minimum > maximum:

			var temp := minimum

			minimum = maximum

			maximum = temp


		result["resolved_amount"] = (
			randi_range(
				minimum,
				maximum
			)
		)

	else:

		result["resolved_amount"] = clampi(
			int(
				result.get(
					"amount",
					1
				)
			),
			1,
			100
		)


	# =========================================================
	# PAYLOAD
	# =========================================================

	result["event_payload"] = (
		payload
		.duplicate(true)
	)


	result["reward_name"] = (
		get_reward_name_from_payload(
			payload
		)
	)


	return result


# =============================================================
# EXECUTE ACTION
# =============================================================

func execute_action(
	action: Dictionary
) -> void:

	if action.is_empty():

		return


	var action_type := (
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
	# SOUND
	# =========================================================

	if action_type == "PLAY_SOUND":

		_play_sound_action(
			action
		)

		return


	# =========================================================
	# INTERACTION + IMAGE
	#
	# Both are forwarded to CIGAInteractionRuntime.
	# The Interaction Runtime decides how to handle them.
	# =========================================================

	if interaction_runtime == null:

		print(
			"[CIGA EVENTS] INTERACTION RUNTIME NOT AVAILABLE"
		)

		return


	if not interaction_runtime.has_method(
		"execute_event_action"
	):

		print(
			"[CIGA EVENTS] execute_event_action() NOT FOUND"
		)

		return


	var result_value: Variant = (
		interaction_runtime.call(
			"execute_event_action",
			action
		)
	)


	if not bool(
		result_value
	):

		print(
			"[CIGA EVENTS] ACTION FAILED | TYPE=",
			action_type
		)


# =============================================================
# USERNAME
# =============================================================

func _get_username_from_payload(
	payload: Dictionary
) -> String:

	if payload.is_empty():

		return ""


	# =========================================================
	# TOP LEVEL
	# =========================================================

	for key: String in [
		"username",
		"displayName",
		"display_name",
		"user_name",
		"user_login",
		"userLogin",
		"name"
	]:

		if not payload.has(
			key
		):

			continue


		var value: Variant = (
			payload.get(
				key,
				""
			)
		)


		if value == null:

			continue


		var result := (
			str(value)
			.strip_edges()
		)


		if not result.is_empty():

			return result


	# =========================================================
	# NESTED DATA
	# =========================================================

	var data_value: Variant = (
		payload.get(
			"data",
			null
		)
	)


	if data_value is Dictionary:

		var data: Dictionary = (
			data_value as Dictionary
		)


		for key: String in [
			"username",
			"displayName",
			"display_name",
			"user_name",
			"user_login",
			"userLogin",
			"name"
		]:

			if not data.has(
				key
			):

				continue


			var value: Variant = (
				data.get(
					key,
					""
				)
			)


			if value == null:

				continue


			var result := (
				str(value)
				.strip_edges()
			)


			if not result.is_empty():

				return result


	return ""

# =============================================================
# USER INPUT
# =============================================================

func _get_user_input_from_payload(
	payload: Dictionary
) -> String:

	for key: String in [
		"user_input",
		"userInput",
		"input",
		"message"
	]:

		if not payload.has(
			key
		):

			continue


		var value: Variant = payload.get(
			key,
			""
		)


		if value == null:

			continue


		var result := (
			str(value)
			.strip_edges()
		)


		if not result.is_empty():

			return result


	return ""

## =============================================================
# BUILD WORKER EVENT
# =============================================================

func _build_worker_event(
	event_name: String,
	payload: Dictionary,
	username: String,
	reward_name: String,
	user_input: String
) -> Dictionary:

	# =========================================================
	# WORKER CONFIG
	#
	# O Guild ID usado pelo CIGAIS Worker pertence ao source:
	#
	#   output
	#     -> sources
	#         -> CIGAIS_WORKER
	#             -> guild_id
	#
	# Mantemos exatamente a mesma estrutura usada
	# pelo CIGAOutput.
	# =========================================================

	var guild_id := ""


	if profile_manager != null:

		var profile := (
			profile_manager.get_active_profile()
		)


		if not profile.is_empty():

			var output_value: Variant = (
				profile.get(
					"output",
					{}
				)
			)


			if output_value is Dictionary:

				var output: Dictionary = (
					output_value as Dictionary
				)


				var sources_value: Variant = (
					output.get(
						"sources",
						{}
					)
				)


				if sources_value is Dictionary:

					var sources: Dictionary = (
						sources_value as Dictionary
					)


					var worker_value: Variant = (
						sources.get(
							"CIGAIS_WORKER",
							{}
						)
					)


					if worker_value is Dictionary:

						var worker_config: Dictionary = (
							worker_value as Dictionary
						)


						guild_id = str(
							worker_config.get(
								"guild_id",
								""
							)
						).strip_edges()


	# =========================================================
	# GUILD ID REQUIRED
	# =========================================================

	if guild_id.is_empty():

		print(
			"[CIGA EVENTS] WORKER EVENT SKIPPED | "
			+ "DISCORD GUILD ID NOT CONFIGURED"
		)

		return {}


	# =========================================================
	# REQUEST ID
	# =========================================================

	var request_id := (
		"ciga-event-"
		+
		str(
			Time.get_ticks_usec()
		)
		+
		"-"
		+
		str(
			randi()
		)
	)


	# =========================================================
	# EVENT
	# =========================================================

	var event_data: Dictionary = {

		"type":
			"cigais_event",

		"guild_id":
			guild_id,

		"event":
			event_name,

		"request_id":
			request_id,

		"twitch_user_id":
			_get_twitch_user_id_from_payload(
				payload
			),

		"twitch_username":
			username,

		"reward":
			reward_name,

		"user_input":
			user_input,

		"timestamp":
			Time.get_datetime_string_from_system(
				true
			)
	}


	return event_data

# =============================================================
# TWITCH USER ID
# =============================================================

func _get_twitch_user_id_from_payload(
	payload: Dictionary
) -> String:

	if payload.is_empty():

		return ""


	# =========================================================
	# TOP LEVEL
	# =========================================================

	for key: String in [
		"twitch_user_id",
		"twitchUserId",
		"user_id",
		"userId",
		"providerId",
		"provider_id"
	]:

		if not payload.has(
			key
		):

			continue


		var value: Variant = (
			payload.get(
				key,
				""
			)
		)


		if value == null:

			continue


		var result := (
			str(value)
			.strip_edges()
		)


		if not result.is_empty():

			return result


	# =========================================================
	# DATA
	# =========================================================

	var data_value: Variant = (
		payload.get(
			"data",
			null
		)
	)


	if data_value is Dictionary:

		var data: Dictionary = (
			data_value as Dictionary
		)


		for key: String in [
			"twitch_user_id",
			"twitchUserId",
			"user_id",
			"userId",
			"providerId",
			"provider_id"
		]:

			if not data.has(
				key
			):

				continue


			var value: Variant = (
				data.get(
					key,
					""
				)
			)


			if value == null:

				continue


			var result := (
				str(value)
				.strip_edges()
			)


			if not result.is_empty():

				return result


	return ""

# =============================================================
# LOGGING
# =============================================================

func _log_external_event(
	event_name: String,
	username: String,
	reward_name: String,
	user_input: String
) -> void:

	var message := (
		"[CIGA EVENTS] EVENT RECEIVED | "
		+
		event_name
	)


	if not username.is_empty():

		message += (
			" | USER="
			+
			username
		)


	if not reward_name.is_empty():

		message += (
			" | REWARD="
			+
			reward_name
		)


	if not user_input.is_empty():

		message += (
			" | INPUT="
			+
			user_input
		)


	print(
		message
	)


func _log_execution_result(
	event_name: String,
	matched_count: int
) -> void:

	print(
		"[CIGA EVENTS] EVENT EXECUTED | ",
		event_name,
		" | MATCHED=",
		matched_count
	)


# =============================================================
# EVENTS
# =============================================================

func get_saved_events() -> Dictionary:

	if profile_manager == null:

		return {}


	var profile := (
		profile_manager.get_active_profile()
	)


	if profile.is_empty():

		return {}


	var value: Variant = (
		profile.get(
			"events",
			{}
		)
	)


	if not value is Dictionary:

		return {}


	return (
		(value as Dictionary)
		.duplicate(true)
	)


# =============================================================
# DEBUG EVENT
# =============================================================

func debug_receive_event(
	event_name: String,
	username: String = "debug_user",
	reward_name: String = "",
	user_input: String = ""
) -> void:

	var payload: Dictionary = {

		"username":
			username,

		"displayName":
			username,

		"user_login":
			username,

		"user_name":
			username,

		"_ciga_debug":
			true
	}


	if not reward_name.strip_edges().is_empty():

		payload["reward"] = {

			"id":
				"debug_reward",

			"title":
				reward_name,

			"cost":
				0
		}


		payload["reward_name"] = (
			reward_name
		)


		payload["redemption"] = (
			reward_name
		)


	if not user_input.strip_edges().is_empty():

		payload["user_input"] = (
			user_input
		)


	receive_event(
		event_name,
		payload
	)


# =============================================================
# STATUS
# =============================================================

func is_ready() -> bool:

	return ready_for_execution


func is_executing() -> bool:

	return executing


# =============================================================
# EXIT
# =============================================================

func _exit_tree() -> void:

	for player: AudioStreamPlayer in audio_players:

		if is_instance_valid(
			player
		):

			player.stop()

			player.queue_free()


	audio_players.clear()
