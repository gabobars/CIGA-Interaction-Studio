class_name CIGAEventsUI
extends RefCounted


# =============================================================
# CIGA EVENTS UI
#
# EVENT
#   -> nome visível
#   -> trigger interno
#   -> reward opcional
#   -> várias actions
#
# SUPPORTED ACTIONS
#   -> INTERACTION
#   -> PLAY_SOUND
#   -> DISPLAY_IMAGE
#
# SUPPORTED TRIGGERS
#   -> FOLLOW
#   -> SUBSCRIBE
#   -> BIT
#   -> RAID
#   -> CHANNEL EVENTS
#   -> STREAM EVENTS
#   -> CUSTOM
#
# IMPORTANTE
#
# O nome do evento e o trigger são coisas diferentes.
#
# Exemplo:
#
#   EVENT NAME:
#       ALL DINOSAURS FEAR THE T-REX
#
#   TRIGGER:
#       CHANNEL_POINTS_REDEEM
#
#   REWARD:
#       all dinosaurs fear the trex
#
# O Runtime deverá tratar a reward de forma
# case-insensitive.
#
# =============================================================


# =============================================================
# REFERENCES
# =============================================================

var root: PanelContainer = null

var theme: CIGATheme = null

var object_manager: CIGAObjects = null

var profile_manager: CIGAProfiles = null


# =============================================================
# MAIN PAGE
# =============================================================

var events_scroll: ScrollContainer = null

var events_margin: MarginContainer = null

var events_main: VBoxContainer = null

var events_flow: HFlowContainer = null

var empty_label: Label = null

var event_status: Label = null


# =============================================================
# EVENT EDITOR
# =============================================================

var editor_window: Window = null

var editor_event_id: String = ""

var editor_event_data: Dictionary = {}

var editor_actions: Array[Dictionary] = []

var editor_actions_container: VBoxContainer = null

var editor_trigger_selector: OptionButton = null

var editor_trigger_reward_input: LineEdit = null

var editor_event_name_input: LineEdit = null


# =============================================================
# IMAGE PREVIEW
# =============================================================

var image_preview_window: Window = null

var image_preview: CIGAImagePreview3D = null

var image_preview_panel: PanelContainer = null


# =============================================================
# CONSTANTS
# =============================================================

const BUILT_IN_EVENTS: Array[String] = [
	"FOLLOW",
	"SUBSCRIBE",
	"BIT",
	"RAID"
]


const EVENT_TRIGGERS: Array[String] = [

	"FOLLOW",
	"SUBSCRIBE",
	"BIT",
	"RAID",

	"CHANNEL_FOLLOW",
	"CHANNEL_SUBSCRIBE",
	"CHANNEL_CHEER",
	"CHANNEL_RAID",

	"CHANNEL_POINTS_REDEEM",

	"CHANNEL_SUBSCRIPTION_GIFT",
	"CHANNEL_SUBSCRIPTION_END",
	"CHANNEL_SUBSCRIPTION_MESSAGE",

	"CHANNEL_CHAT_MESSAGE",
	"CHANNEL_CHAT_MESSAGE_DELETE",
	"CHANNEL_CHAT_CLEAR",

	"CHANNEL_POLL_BEGIN",
	"CHANNEL_POLL_PROGRESS",
	"CHANNEL_POLL_END",

	"CHANNEL_PREDICTION_BEGIN",
	"CHANNEL_PREDICTION_PROGRESS",
	"CHANNEL_PREDICTION_LOCK",
	"CHANNEL_PREDICTION_END",

	"CHANNEL_HYPE_TRAIN_BEGIN",
	"CHANNEL_HYPE_TRAIN_PROGRESS",
	"CHANNEL_HYPE_TRAIN_END",

	"CHANNEL_GOAL_BEGIN",
	"CHANNEL_GOAL_PROGRESS",
	"CHANNEL_GOAL_END",

	"STREAM_ONLINE",
	"STREAM_OFFLINE",

	"CHANNEL_UPDATE",
	"CHANNEL_AD_BREAK_BEGIN",

	"CHANNEL_VIP_ADD",
	"CHANNEL_BAN",

	"CHANNEL_SHOUTOUT_CREATE",
	"CHANNEL_SHOUTOUT_RECEIVE",

	"CUSTOM"
]


const HITPOINTS: Array[String] = [
	"HEAD",
	"CHEST",
	"LEFT SHOULDER",
	"RIGHT SHOULDER",
	"LEFT ARM",
	"RIGHT ARM",
	"LEFT LEG",
	"RIGHT LEG"
]


const MAX_ACTIONS: int = 50

const MIN_AMOUNT: int = 1

const MAX_AMOUNT: int = 100

const MIN_FORCE: float = 0.0

const MAX_FORCE: float = 100.0

const MIN_SPEED: float = 0.1

const MAX_SPEED: float = 100.0


# =============================================================
# RESPONSIVE
# =============================================================

const PAGE_MARGIN_MIN: int = 12

const PAGE_MARGIN_MAX: int = 28

const EVENT_CARD_WIDTH: float = 240.0

const EVENT_CARD_HEIGHT: float = 190.0


# =============================================================
# EDITOR
# =============================================================

const EDITOR_MIN_WIDTH: int = 760

const EDITOR_MIN_HEIGHT: int = 620

const EDITOR_PREFERRED_WIDTH: int = 1250

const EDITOR_PREFERRED_HEIGHT: int = 900

const EDITOR_SCREEN_MARGIN_X: int = 60

const EDITOR_SCREEN_MARGIN_Y: int = 100


# =============================================================
# LIBRARIES
# =============================================================

const IMAGE_LIBRARY_DIR: String = (
	"user://ciga/assets/images"
)

const AUDIO_LIBRARY_DIR: String = (
	"user://ciga/assets/audio"
)


const DEFAULT_SOUND_VOLUME: float = 1.0

const DEFAULT_PREVIEW_VOLUME: float = 1.0


# =============================================================
# SETUP
# =============================================================

func setup(
	parent: Control,
	ui_theme: CIGATheme,
	objects: CIGAObjects = null,
	profiles: CIGAProfiles = null
) -> Control:

	theme = ui_theme

	object_manager = objects

	profile_manager = profiles


	root = PanelContainer.new()

	root.name = "EventsPage"


	root.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)


	root.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	root.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)


	root.visible = false


	theme.style_panel(
		root
	)


	parent.add_child(
		root
	)


	root.resized.connect(
		_update_responsive_layout
	)


	build()


	call_deferred(
		"refresh_events"
	)


	call_deferred(
		"_update_responsive_layout"
	)


	return root


# =============================================================
# BUILD MAIN PAGE
# =============================================================

func build() -> void:

	events_scroll = ScrollContainer.new()

	events_scroll.name = "EventsScroll"


	events_scroll.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)


	events_scroll.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	events_scroll.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)


	events_scroll.horizontal_scroll_mode = (
		ScrollContainer.SCROLL_MODE_DISABLED
	)

	events_scroll.vertical_scroll_mode = (
		ScrollContainer.SCROLL_MODE_AUTO
	)


	events_scroll.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)


	root.add_child(
		events_scroll
	)


	events_margin = MarginContainer.new()

	events_margin.name = "EventsMargin"


	events_margin.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	events_margin.size_flags_vertical = (
		Control.SIZE_SHRINK_BEGIN
	)


	events_scroll.add_child(
		events_margin
	)


	events_main = VBoxContainer.new()

	events_main.name = "EventsContent"


	events_main.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	events_main.size_flags_vertical = (
		Control.SIZE_SHRINK_BEGIN
	)


	events_main.add_theme_constant_override(
		"separation",
		14
	)


	events_margin.add_child(
		events_main
	)


	var title := theme.create_title(
		"EVENTS"
	)


	title.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	events_main.add_child(
		title
	)


	var description := theme.create_status_label(
		"Configure actions triggered by stream events."
	)


	description.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	description.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)


	events_main.add_child(
		description
	)


	event_status = theme.create_status_label(
		"SELECT AN EVENT TO CONFIGURE"
	)


	event_status.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	event_status.custom_minimum_size = Vector2(
		0.0,
		30.0
	)


	event_status.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)


	events_main.add_child(
		event_status
	)


	events_main.add_child(
		theme.create_section_label(
			"EVENTS"
		)
	)


	events_flow = HFlowContainer.new()

	events_flow.name = "EventsFlow"


	events_flow.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	events_flow.size_flags_vertical = (
		Control.SIZE_SHRINK_BEGIN
	)


	events_flow.add_theme_constant_override(
		"h_separation",
		14
	)

	events_flow.add_theme_constant_override(
		"v_separation",
		14
	)


	events_main.add_child(
		events_flow
	)


	var add_event := theme.create_button(
		"+ ADD CUSTOM EVENT"
	)


	add_event.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	add_event.custom_minimum_size = Vector2(
		0.0,
		46.0
	)


	events_main.add_child(
		add_event
	)


	add_event.pressed.connect(
		_add_custom_event
	)


	empty_label = theme.create_status_label(
		"NO EVENTS CONFIGURED"
	)


	empty_label.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	empty_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	events_main.add_child(
		empty_label
	)


# =============================================================
# RESPONSIVE
# =============================================================

func _update_responsive_layout() -> void:

	if root == null:

		return


	if events_margin == null:

		return


	var width: float = root.size.x


	if width <= 0.0:

		return


	var margin: int = clampi(
		int(
			round(
				width * 0.018
			)
		),
		PAGE_MARGIN_MIN,
		PAGE_MARGIN_MAX
	)


	theme.set_margins(
		events_margin,
		margin
	)


# =============================================================
# STORAGE
# =============================================================

func get_saved_events() -> Dictionary:

	if profile_manager == null:

		return {}


	var profile: Dictionary = (
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


func save_events(
	events: Dictionary
) -> void:

	if profile_manager == null:

		return


	var profile: Dictionary = (
		profile_manager.get_active_profile()
	)


	if profile.is_empty():

		return


	profile["events"] = (
		events.duplicate(true)
	)


	profile_manager.save_profiles()


# =============================================================
# CLEAN SAVED EVENTS
# =============================================================

func clean_saved_events(
	events: Dictionary
) -> Dictionary:

	var cleaned := (
		events.duplicate(true)
	)


	for event_id_value: Variant in (
		cleaned.keys()
	):

		var value: Variant = (
			cleaned[event_id_value]
		)


		if not value is Dictionary:

			cleaned.erase(
				event_id_value
			)

			continue


		var event_data: Dictionary = (
			value as Dictionary
		)


		if not event_data.has(
			"enabled"
		):

			event_data["enabled"] = true


		if not event_data.has(
			"trigger_event"
		):

			event_data["trigger_event"] = (
				normalize_trigger_id(
					str(
						event_id_value
					)
				)
			)


		if not event_data.has(
			"reward_name"
		):

			event_data["reward_name"] = ""


		if (
			not event_data.has(
				"actions"
			)
			or
			not event_data["actions"] is Array
		):

			event_data["actions"] = []


		var actions: Array = (
			event_data["actions"]
			as Array
		)


		for index: int in range(
			actions.size()
		):

			if not actions[index] is Dictionary:

				actions[index] = (
					create_default_action()
				)

				continue


			var action: Dictionary = (
				actions[index] as Dictionary
			)


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


			action["action_type"] = (
				action_type
			)


			if action_type == "DISPLAY_IMAGE":

				if not action.has(
					"image_path"
				):

					action["image_path"] = ""


				if not action.has(
					"image_name"
				):

					action["image_name"] = ""


				if not action.has(
					"image_target"
				):

					action["image_target"] = (
						"HeadHitPoint"
					)


				if not action.has(
					"image_duration"
				):

					action["image_duration"] = 5.0


				if not action.has(
					"image_scale"
				):

					action["image_scale"] = 1.0


				if not action.has(
					"image_offset_x"
				):

					action["image_offset_x"] = 0.0


				if not action.has(
					"image_offset_y"
				):

					action["image_offset_y"] = 0.0


				if not action.has(
					"image_offset_z"
				):

					action["image_offset_z"] = 0.0


				if not action.has(
					"image_rotation_x"
				):

					action["image_rotation_x"] = 0.0


				if not action.has(
					"image_rotation_y"
				):

					action["image_rotation_y"] = 0.0


				if not action.has(
					"image_rotation_z"
				):

					action["image_rotation_z"] = 0.0


				if not action.has(
					"image_mirror_h"
				):

					action["image_mirror_h"] = false


				if not action.has(
					"image_mirror_v"
				):

					action["image_mirror_v"] = false

			elif action_type == "DISPLAY_IMAGE_LIVE":

				if not action.has("image_live_target"):
					action["image_live_target"] = "HeadHitPoint"

				if not action.has("image_live_duration"):
					action["image_live_duration"] = 5.0

				if not action.has("image_live_scale_mode"):
					action["image_live_scale_mode"] = "FIXED"

				if not action.has("image_live_scale"):
					action["image_live_scale"] = 1.0

				if not action.has("image_live_scale_min"):
					action["image_live_scale_min"] = 0.8

				if not action.has("image_live_scale_max"):
					action["image_live_scale_max"] = 1.2

				if not action.has("image_live_offset_x_mode"):
					action["image_live_offset_x_mode"] = "FIXED"

				if not action.has("image_live_offset_x"):
					action["image_live_offset_x"] = 0.0

				if not action.has("image_live_offset_x_min"):
					action["image_live_offset_x_min"] = 0.0

				if not action.has("image_live_offset_x_max"):
					action["image_live_offset_x_max"] = 0.0

				if not action.has("image_live_offset_y_mode"):
					action["image_live_offset_y_mode"] = "FIXED"

				if not action.has("image_live_offset_y"):
					action["image_live_offset_y"] = 0.0

				if not action.has("image_live_offset_y_min"):
					action["image_live_offset_y_min"] = 0.0

				if not action.has("image_live_offset_y_max"):
					action["image_live_offset_y_max"] = 0.0

				if not action.has("image_live_offset_z_mode"):
					action["image_live_offset_z_mode"] = "FIXED"

				if not action.has("image_live_offset_z"):
					action["image_live_offset_z"] = 0.0

				if not action.has("image_live_offset_z_min"):
					action["image_live_offset_z_min"] = 0.0

				if not action.has("image_live_offset_z_max"):
					action["image_live_offset_z_max"] = 0.0

				if not action.has("image_live_rotation_x_mode"):
					action["image_live_rotation_x_mode"] = "FIXED"

				if not action.has("image_live_rotation_x"):
					action["image_live_rotation_x"] = 0.0

				if not action.has("image_live_rotation_x_min"):
					action["image_live_rotation_x_min"] = 0.0

				if not action.has("image_live_rotation_x_max"):
					action["image_live_rotation_x_max"] = 0.0

				if not action.has("image_live_rotation_y_mode"):
					action["image_live_rotation_y_mode"] = "FIXED"

				if not action.has("image_live_rotation_y"):
					action["image_live_rotation_y"] = 0.0

				if not action.has("image_live_rotation_y_min"):
					action["image_live_rotation_y_min"] = 0.0

				if not action.has("image_live_rotation_y_max"):
					action["image_live_rotation_y_max"] = 0.0

				if not action.has("image_live_rotation_z_mode"):
					action["image_live_rotation_z_mode"] = "FIXED"

				if not action.has("image_live_rotation_z"):
					action["image_live_rotation_z"] = 0.0

				if not action.has("image_live_rotation_z_min"):
					action["image_live_rotation_z_min"] = 0.0

				if not action.has("image_live_rotation_z_max"):
					action["image_live_rotation_z_max"] = 0.0

				if not action.has("image_live_mirror_h"):
					action["image_live_mirror_h"] = false

				if not action.has("image_live_mirror_v"):
					action["image_live_mirror_v"] = false
			elif action_type == "PLAY_SOUND":

				if not action.has(
					"sound_path"
				):

					action["sound_path"] = ""


				if not action.has(
					"sound_name"
				):

					action["sound_name"] = ""


				if not action.has(
					"volume"
				):

					action["volume"] = (
						DEFAULT_SOUND_VOLUME
					)


				if not action.has(
					"preview_volume"
				):

					action["preview_volume"] = (
						DEFAULT_PREVIEW_VOLUME
					)


	return cleaned


# =============================================================
# DEFAULT EVENT
# =============================================================

func create_default_event(
	trigger_event: String = "FOLLOW"
) -> Dictionary:

	return {

		"enabled":
			true,

		"trigger_event":
			normalize_trigger_id(
				trigger_event
			),

		"reward_name":
			"",

		"custom_event":
			true,

		"actions":
			[
				create_default_action()
			]
	}


# =============================================================
# DEFAULT ACTION
# =============================================================

func create_default_action() -> Dictionary:

	var defaults: Dictionary = (
		get_interaction_defaults()
	)


	return {

		"action_type":
			"INTERACTION",

		"object_mode":
			"RANDOM_FROM_ALL",

		"object_id":
			"",

		"selected_object_ids":
			[],

		"amount_mode":
			"FIXED",

		"amount":
			int(
				defaults.get(
					"amount",
					1
				)
			),

		"amount_min":
			1,

		"amount_max":
			1,

		"target_mode":
			"RANDOM_FROM_ALL",

		"target":
			"CHEST",

		"selected_targets":
			[],

		"force_mode":
			"INHERIT",

		"force":
			float(
				defaults.get(
					"force",
					1.8
				)
			),

		"speed_mode":
			"INHERIT",

		"speed":
			float(
				defaults.get(
					"speed",
					5.4
				)
			),

		"sound_path":
			"",

		"sound_name":
			"",

		"volume":
			DEFAULT_SOUND_VOLUME,

		"preview_volume":
			DEFAULT_PREVIEW_VOLUME,

		"image_path":
			"",

		"image_name":
			"",

		"image_target":
			"HeadHitPoint",

		"image_duration":
			5.0,

		"image_scale":
			1.0,

		"image_offset_x":
			0.0,

		"image_offset_y":
			0.0,

		"image_offset_z":
			0.0,

		"image_rotation_x":
			0.0,

		"image_rotation_y":
			0.0,

		"image_rotation_z":
			0.0,

		"image_mirror_h":
			false,

		"image_mirror_v":
			false,
	
		"image_live_target":
			"HeadHitPoint",

		"image_live_duration":
			5.0,

		"image_live_scale_mode":
			"FIXED",

		"image_live_scale":
			1.0,

		"image_live_scale_min":
			0.8,

		"image_live_scale_max":
			1.2,

		"image_live_offset_x_mode":
			"FIXED",

		"image_live_offset_x":
			0.0,

		"image_live_offset_x_min":
			0.0,

		"image_live_offset_x_max":
			0.0,

		"image_live_offset_y_mode":
			"FIXED",

		"image_live_offset_y":
			0.0,

		"image_live_offset_y_min":
			0.0,

		"image_live_offset_y_max":
			0.0,

		"image_live_offset_z_mode":
			"FIXED",

		"image_live_offset_z":
			0.0,

		"image_live_offset_z_min":
			0.0,

		"image_live_offset_z_max":
			0.0,

		"image_live_rotation_x_mode":
			"FIXED",

		"image_live_rotation_x":
			0.0,

		"image_live_rotation_x_min":
			0.0,

		"image_live_rotation_x_max":
			0.0,

		"image_live_rotation_y_mode":
			"FIXED",

		"image_live_rotation_y":
			0.0,

		"image_live_rotation_y_min":
			0.0,

		"image_live_rotation_y_max":
			0.0,

		"image_live_rotation_z_mode":
			"FIXED",

		"image_live_rotation_z":
			0.0,

		"image_live_rotation_z_min":
			0.0,

		"image_live_rotation_z_max":
			0.0,

		"image_live_mirror_h":
			false,

		"image_live_mirror_v":
			false
}
# =============================================================
# INTERACTION DEFAULTS
# =============================================================

func get_interaction_defaults() -> Dictionary:

	if profile_manager == null:

		return {
			"force": 1.8,
			"speed": 5.4,
			"amount": 1
		}


	if not profile_manager.has_method(
		"get_active_interaction"
	):

		return {
			"force": 1.8,
			"speed": 5.4,
			"amount": 1
		}


	var value: Variant = (
		profile_manager.get_active_interaction()
	)


	if not value is Dictionary:

		return {
			"force": 1.8,
			"speed": 5.4,
			"amount": 1
		}


	var data: Dictionary = (
		value as Dictionary
	)


	if data.is_empty():

		return {
			"force": 1.8,
			"speed": 5.4,
			"amount": 1
		}


	return data


# =============================================================
# REFRESH EVENTS
#
# NÃO cria eventos.
# NÃO recria defaults.
# NÃO remove duplicados.
#
# O que estiver guardado no profile é o que aparece.
# =============================================================

func refresh_events() -> void:

	if events_flow == null:

		return


	var events: Dictionary = (
		clean_saved_events(
			get_saved_events()
		)
	)


	for child: Node in (
		events_flow.get_children()
	):

		if is_instance_valid(child):

			child.queue_free()


	if empty_label != null:

		empty_label.visible = true


	for event_id_value: Variant in (
		events.keys()
	):

		var event_id: String = str(
			event_id_value
		)


		if event_id == "_ciga_defaults_initialized":

			continue


		var value: Variant = (
			events[event_id_value]
		)


		if not value is Dictionary:

			continue


		if empty_label != null:

			empty_label.visible = false


		create_event_card(
			event_id,
			value as Dictionary
		)


	call_deferred(
		"_update_responsive_layout"
	)


# =============================================================
# EVENT CARD
# =============================================================

func create_event_card(
	event_id: String,
	event_data: Dictionary
) -> void:

	if events_flow == null:

		return


	var card := PanelContainer.new()


	card.name = (
		"EventCard_"
		+
		sanitize_name(
			event_id
		)
	)


	card.custom_minimum_size = Vector2(
		EVENT_CARD_WIDTH,
		EVENT_CARD_HEIGHT
	)


	card.size_flags_horizontal = (
		Control.SIZE_SHRINK_BEGIN
	)

	card.size_flags_vertical = (
		Control.SIZE_SHRINK_BEGIN
	)


	theme.style_panel(
		card,
		CIGATheme.PANEL_LIGHT,
		CIGATheme.BORDER
	)


	events_flow.add_child(
		card
	)


	var margin := MarginContainer.new()


	margin.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	margin.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)


	theme.set_margins(
		margin,
		12
	)


	card.add_child(
		margin
	)


	var content := VBoxContainer.new()


	content.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	content.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)


	content.add_theme_constant_override(
		"separation",
		5
	)


	margin.add_child(
		content
	)


	var name_label := Label.new()


	name_label.text = (
		event_id
	)


	name_label.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	name_label.custom_minimum_size = Vector2(
		0.0,
		28.0
	)


	name_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	name_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)


	name_label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)


	name_label.add_theme_font_size_override(
		"font_size",
		18
	)


	name_label.add_theme_color_override(
		"font_color",
		CIGATheme.TEXT
	)


	content.add_child(
		name_label
	)


	var trigger_name: String = (
		normalize_trigger_id(
			str(
				event_data.get(
					"trigger_event",
					event_id
				)
			)
		)
	)


	var trigger_label := Label.new()


	trigger_label.text = (
		"TRIGGER: "
		+
		format_trigger_display_name(
			trigger_name
		)
	)


	trigger_label.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	trigger_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	trigger_label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)


	trigger_label.add_theme_font_size_override(
		"font_size",
		11
	)


	trigger_label.add_theme_color_override(
		"font_color",
		CIGATheme.ACCENT_BRIGHT
	)


	content.add_child(
		trigger_label
	)


	var reward_name: String = (
		str(
			event_data.get(
				"reward_name",
				""
			)
		)
		.strip_edges()
	)


	if not reward_name.is_empty():

		var reward_label := Label.new()


		reward_label.text = (
			"REWARD: "
			+
			reward_name
		)


		reward_label.size_flags_horizontal = (
			Control.SIZE_EXPAND_FILL
		)


		reward_label.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_CENTER
		)


		reward_label.autowrap_mode = (
			TextServer.AUTOWRAP_WORD_SMART
		)


		reward_label.add_theme_font_size_override(
			"font_size",
			10
		)


		reward_label.add_theme_color_override(
			"font_color",
			CIGATheme.TEXT_DIM
		)


		content.add_child(
			reward_label
		)


	var enabled := bool(
		event_data.get(
			"enabled",
			true
		)
	)


	var enabled_label := Label.new()


	enabled_label.text = (
		"ENABLED"
		if enabled
		else
		"DISABLED"
	)


	enabled_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	enabled_label.add_theme_font_size_override(
		"font_size",
		11
	)


	enabled_label.add_theme_color_override(
		"font_color",
		CIGATheme.TEXT_DIM
	)


	content.add_child(
		enabled_label
	)


	var action_count: int = (
		get_action_count(
			event_data
		)
	)


	var action_label := Label.new()


	action_label.text = (
		str(
			action_count
		)
		+
		" ACTION"
		+
		(
			"S"
			if action_count != 1
			else
			""
		)
	)


	action_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	action_label.add_theme_font_size_override(
		"font_size",
		11
	)


	action_label.add_theme_color_override(
		"font_color",
		CIGATheme.TEXT_DIM
	)


	content.add_child(
		action_label
	)


	var configure := theme.create_button(
		"CONFIGURE EVENT"
	)


	configure.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	configure.custom_minimum_size = Vector2(
		0.0,
		34.0
	)


	configure.focus_mode = (
		Control.FOCUS_NONE
	)


	content.add_child(
		configure
	)


	configure.pressed.connect(
		func() -> void:

			open_event_editor(
				event_id
			)
	)


	var remove := theme.create_button(
		"REMOVE EVENT"
	)


	remove.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	remove.custom_minimum_size = Vector2(
		0.0,
		30.0
	)


	remove.focus_mode = (
		Control.FOCUS_NONE
	)


	content.add_child(
		remove
	)


	remove.pressed.connect(
		func() -> void:

			remove_event(
				event_id
			)
	)


# =============================================================
# ACTION COUNT
# =============================================================

func get_action_count(
	event_data: Dictionary
) -> int:

	var value: Variant = (
		event_data.get(
			"actions",
			[]
		)
	)


	if not value is Array:

		return 0


	return (
		(value as Array).size()
	)


# =============================================================
# SANITIZE
# =============================================================

func sanitize_name(
	value: String
) -> String:

	return (
		value
		.replace(" ", "_")
		.replace("/", "_")
		.replace("\\", "_")
	)


# =============================================================
# EVENT EDITOR
# =============================================================

func open_event_editor(
	event_id: String
) -> void:

	var events: Dictionary = (
		get_saved_events()
	)


	if not events.has(
		event_id
	):

		return


	var value: Variant = (
		events[event_id]
	)


	if not value is Dictionary:

		return


	editor_event_id = (
		event_id
	)


	editor_event_data = (
		(value as Dictionary)
		.duplicate(true)
	)


	editor_actions.clear()


	var actions_value: Variant = (
		editor_event_data.get(
			"actions",
			[]
		)
	)


	if actions_value is Array:

		for action_value: Variant in (
			actions_value as Array
		):

			if action_value is Dictionary:

				editor_actions.append(
					(
						action_value as Dictionary
					).duplicate(true)
				)


	if editor_actions.is_empty():

		editor_actions.append(
			create_default_action()
		)


	create_event_editor_window()


# =============================================================
# EVENT EDITOR WINDOW
# =============================================================

func create_event_editor_window() -> void:

	close_event_editor()


	editor_window = Window.new()


	editor_window.name = (
		"CIGAEventEditor"
	)


	editor_window.title = (
		"CONFIGURE EVENT — "
		+
		editor_event_id
	)


	editor_window.unresizable = false
	editor_window.always_on_top = true

	var screen_index: int = (
		DisplayServer.window_get_current_screen()
	)


	var usable_rect: Rect2i = (
		DisplayServer.screen_get_usable_rect(
			screen_index
		)
	)


	var available_width: int = (
		maxi(
			usable_rect.size.x
			-
			EDITOR_SCREEN_MARGIN_X,
			1
		)
	)


	var available_height: int = (
		maxi(
			usable_rect.size.y
			-
			EDITOR_SCREEN_MARGIN_Y,
			1
		)
	)


	var final_width: int = mini(
		EDITOR_PREFERRED_WIDTH,
		available_width
	)


	var final_height: int = mini(
		EDITOR_PREFERRED_HEIGHT,
		available_height
	)


	var safe_min_width: int = mini(
		EDITOR_MIN_WIDTH,
		available_width
	)


	var safe_min_height: int = mini(
		EDITOR_MIN_HEIGHT,
		available_height
	)


	safe_min_width = maxi(
		safe_min_width,
		560
	)


	safe_min_height = maxi(
		safe_min_height,
		440
	)


	final_width = maxi(
		final_width,
		safe_min_width
	)


	final_height = maxi(
		final_height,
		safe_min_height
	)


	final_width = mini(
		final_width,
		available_width
	)


	final_height = mini(
		final_height,
		available_height
	)


	editor_window.size = Vector2i(
		final_width,
		final_height
	)


	editor_window.min_size = Vector2i(
		safe_min_width,
		safe_min_height
	)


	editor_window.close_requested.connect(
		_cancel_event_editor
	)


	root.add_child(
		editor_window
	)


	var background := PanelContainer.new()


	background.name = (
		"EditorBackground"
	)


	background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)


	theme.style_panel(
		background
	)


	editor_window.add_child(
		background
	)


	var margin := MarginContainer.new()


	margin.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)


	theme.set_margins(
		margin,
		10
	)


	background.add_child(
		margin
	)


	var main := VBoxContainer.new()


	main.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)


	main.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	main.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)


	main.add_theme_constant_override(
		"separation",
		6
	)


	margin.add_child(
		main
	)


	var title := theme.create_title(
		editor_event_id
	)


	title.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	title.custom_minimum_size = Vector2(
		0.0,
		32.0
	)


	title.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	title.clip_text = true


	main.add_child(
		title
	)


	var description := theme.create_status_label(
		"Configure the event name, trigger and actions."
	)


	description.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	description.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)


	main.add_child(
		description
	)


	# =========================================================
	# TRIGGER PANEL
	# =========================================================

	var trigger_panel := PanelContainer.new()


	trigger_panel.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	theme.style_panel(
		trigger_panel,
		CIGATheme.PANEL_LIGHT,
		CIGATheme.BORDER
	)


	main.add_child(
		trigger_panel
	)


	var trigger_margin := MarginContainer.new()


	theme.set_margins(
		trigger_margin,
		8
	)


	trigger_panel.add_child(
		trigger_margin
	)


	var trigger_box := VBoxContainer.new()


	trigger_box.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	trigger_box.add_theme_constant_override(
		"separation",
		5
	)


	trigger_margin.add_child(
		trigger_box
	)


	trigger_box.add_child(
		theme.create_section_label(
			"EVENT TRIGGER"
		)
	)


	# EVENT NAME

	editor_event_name_input = LineEdit.new()


	editor_event_name_input.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	editor_event_name_input.custom_minimum_size = Vector2(
		0.0,
		36.0
	)


	editor_event_name_input.placeholder_text = (
		"EVENT NAME"
	)


	editor_event_name_input.text = (
		editor_event_id
	)


	trigger_box.add_child(
		theme.labeled_control(
			"EVENT NAME",
			editor_event_name_input
		)
	)


	# TRIGGER

	editor_trigger_selector = OptionButton.new()


	editor_trigger_selector.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	editor_trigger_selector.custom_minimum_size = Vector2(
		0.0,
		36.0
	)


	for trigger_name: String in EVENT_TRIGGERS:

		editor_trigger_selector.add_item(
			format_trigger_display_name(
				trigger_name
			)
		)


	var saved_trigger: String = (
		normalize_trigger_id(
			str(
				editor_event_data.get(
					"trigger_event",
					"FOLLOW"
				)
			)
		)
	)


	var trigger_index: int = (
		EVENT_TRIGGERS.find(
			saved_trigger
		)
	)


	if trigger_index < 0:

		trigger_index = (
			EVENT_TRIGGERS.find(
				"CUSTOM"
			)
		)


	if trigger_index < 0:

		trigger_index = 0


	editor_trigger_selector.select(
		trigger_index
	)


	trigger_box.add_child(
		theme.labeled_control(
			"EVENT TYPE",
			editor_trigger_selector
		)
	)


	# REWARD

	editor_trigger_reward_input = LineEdit.new()


	editor_trigger_reward_input.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	editor_trigger_reward_input.custom_minimum_size = Vector2(
		0.0,
		36.0
	)


	editor_trigger_reward_input.placeholder_text = (
		"OPTIONAL — ANY REWARD IF EMPTY"
	)


	editor_trigger_reward_input.text = str(
		editor_event_data.get(
			"reward_name",
			""
		)
	)


	trigger_box.add_child(
		theme.labeled_control(
			"REWARD NAME",
			editor_trigger_reward_input
		)
	)


	trigger_box.add_child(
		theme.create_status_label(
			"Used for CHANNEL POINTS REDEEM. Empty = any reward. Matching is case-insensitive."
		)
	)


	# =========================================================
	# ACTION PANEL
	# =========================================================

	var actions_panel := PanelContainer.new()


	actions_panel.name = (
		"ActionsPanel"
	)


	actions_panel.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	actions_panel.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)


	theme.style_panel(
		actions_panel,
		CIGATheme.PANEL_LIGHT,
		CIGATheme.BORDER
	)


	main.add_child(
		actions_panel
	)


	var actions_margin := MarginContainer.new()


	actions_margin.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	actions_margin.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)


	theme.set_margins(
		actions_margin,
		8
	)


	actions_panel.add_child(
		actions_margin
	)


	var actions_scroll := ScrollContainer.new()


	actions_scroll.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	actions_scroll.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)


	actions_scroll.horizontal_scroll_mode = (
		ScrollContainer.SCROLL_MODE_DISABLED
	)


	actions_scroll.vertical_scroll_mode = (
		ScrollContainer.SCROLL_MODE_AUTO
	)


	actions_scroll.follow_focus = true


	actions_margin.add_child(
		actions_scroll
	)


	editor_actions_container = VBoxContainer.new()


	editor_actions_container.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	editor_actions_container.size_flags_vertical = (
		Control.SIZE_SHRINK_BEGIN
	)


	editor_actions_container.add_theme_constant_override(
		"separation",
		8
	)


	actions_scroll.add_child(
		editor_actions_container
	)


	rebuild_action_editors()


	var add_action := theme.create_button(
		"+ ADD ACTION"
	)


	add_action.custom_minimum_size = Vector2(
		0.0,
		36.0
	)


	add_action.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	main.add_child(
		add_action
	)


	add_action.pressed.connect(
		_add_editor_action
	)


	# FOOTER

	var footer := HBoxContainer.new()


	footer.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	footer.custom_minimum_size = Vector2(
		0.0,
		42.0
	)


	footer.add_theme_constant_override(
		"separation",
		8
	)


	main.add_child(
		footer
	)


	var cancel := theme.create_button(
		"CANCEL"
	)


	cancel.custom_minimum_size = Vector2(
		0.0,
		42.0
	)


	cancel.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	cancel.focus_mode = (
		Control.FOCUS_NONE
	)


	footer.add_child(
		cancel
	)


	cancel.pressed.connect(
		_cancel_event_editor
	)


	var save := theme.create_button(
		"SAVE EVENT"
	)


	save.custom_minimum_size = Vector2(
		0.0,
		42.0
	)


	save.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	save.focus_mode = (
		Control.FOCUS_NONE
	)


	footer.add_child(
		save
	)


	save.pressed.connect(
		_save_event_editor
	)


	editor_window.popup_centered_clamped(
		editor_window.size,
		0.90
	)
	editor_window.grab_focus()
	editor_window.move_to_foreground()

# =============================================================
# CLOSE EVENT EDITOR
# =============================================================

func close_event_editor() -> void:

	_close_image_preview_window()


	if (
		editor_window != null
		and
		is_instance_valid(
			editor_window
		)
	):

		editor_window.hide()
		editor_window.queue_free()


	editor_window = null

	editor_actions_container = null

	editor_trigger_selector = null

	editor_trigger_reward_input = null

	editor_event_name_input = null


	# =========================================================
	# RETURN FOCUS TO MAIN CIGA WINDOW
	# =========================================================

	if root != null and is_instance_valid(root):

		var main_window := root.get_window()

		if main_window != null:

			main_window.grab_focus()

			main_window.move_to_foreground()
# =============================================================
# ACTIONS
# =============================================================

func rebuild_action_editors() -> void:

	if editor_actions_container == null:

		return


	for child: Node in (
		editor_actions_container.get_children()
	):

		if is_instance_valid(child):

			child.queue_free()


	for index: int in range(
		editor_actions.size()
	):

		create_action_editor(
			index,
			editor_actions[
				index
			].duplicate(true)
		)


func _add_editor_action() -> void:

	if editor_actions.size() >= MAX_ACTIONS:

		return


	editor_actions.append(
		create_default_action()
	)


	rebuild_action_editors()


func remove_editor_action(
	index: int
) -> void:

	if index < 0:

		return


	if index >= editor_actions.size():

		return


	if editor_actions.size() <= 1:

		return


	editor_actions.remove_at(
		index
	)


	rebuild_action_editors()


# =============================================================
# CREATE ACTION EDITOR
# =============================================================

func create_action_editor(
	index: int,
	data: Dictionary
) -> void:

	if editor_actions_container == null:

		return


	var panel := PanelContainer.new()


	panel.name = (
		"Action_"
		+
		str(
			index + 1
		)
	)


	panel.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	panel.size_flags_vertical = (
		Control.SIZE_SHRINK_BEGIN
	)


	theme.style_panel(
		panel,
		CIGATheme.PANEL_LIGHT,
		CIGATheme.BORDER
	)


	editor_actions_container.add_child(
		panel
	)


	var margin := MarginContainer.new()


	theme.set_margins(
		margin,
		12
	)


	panel.add_child(
		margin
	)


	var box := VBoxContainer.new()


	box.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	box.add_theme_constant_override(
		"separation",
		8
	)


	margin.add_child(
		box
	)


	# HEADER

	var header := HBoxContainer.new()


	header.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	header.add_theme_constant_override(
		"separation",
		8
	)


	box.add_child(
		header
	)


	var title := theme.create_title(
		"ACTION "
		+
		str(
			index + 1
		)
	)


	title.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	title.add_theme_font_size_override(
		"font_size",
		18
	)


	header.add_child(
		title
	)


	var remove := theme.create_button(
		"REMOVE"
	)


	remove.custom_minimum_size = Vector2(
		100.0,
		34.0
	)


	remove.focus_mode = (
		Control.FOCUS_NONE
	)


	remove.disabled = (
		editor_actions.size() <= 1
	)


	header.add_child(
		remove
	)


	remove.pressed.connect(
		func() -> void:

			remove_editor_action(
				index
			)
	)


	# =========================================================
	# ACTION TYPE
	# =========================================================

	var action_type := OptionButton.new()


	action_type.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	action_type.custom_minimum_size = Vector2(
		0.0,
		40.0
	)


	action_type.add_item(
		"INTERACTION"
	)

	action_type.add_item(
		"PLAY SOUND"
	)

	action_type.add_item(
		"DISPLAY IMAGE"
	)

	action_type.add_item(
		"DISPLAY IMAGE LIVE"
	)

	var type_name := (
		str(
			data.get(
				"action_type",
				"INTERACTION"
			)
		)
		.to_upper()
		.strip_edges()
	)


	match type_name:

		"PLAY_SOUND":

			action_type.select(1)

		"DISPLAY_IMAGE":

			action_type.select(2)

		"DISPLAY_IMAGE_LIVE":

			action_type.select(3)

		_:

			action_type.select(0)


	box.add_child(
		theme.labeled_control(
			"ACTION TYPE",
			action_type
		)
	)


	# =========================================================
	# SOUND
	# =========================================================

	var sound_container := (
		_create_sound_action_controls(
			panel,
			data
		)
	)


	box.add_child(
		sound_container
	)


	# =========================================================
	# IMAGE
	# =========================================================

	var image_container := (
		create_image_action_controls(
			panel,
			data
		)
	)


	box.add_child(
		image_container
	)

	var image_live_container := (
		create_live_image_action_controls(
			panel,
			data
		)
	)

	box.add_child(
		image_live_container
	)
	# =========================================================
	# INTERACTION
	# =========================================================

	var interaction_container := VBoxContainer.new()


	interaction_container.name = (
		"InteractionContainer"
	)


	interaction_container.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	interaction_container.add_theme_constant_override(
		"separation",
		8
	)


	box.add_child(
		interaction_container
	)


	_create_interaction_controls(
		panel,
		interaction_container,
		data
	)


	panel.set_meta(
		"controls",
		{
			"action_type":
				action_type,

			"sound_container":
				sound_container,

			"image_container":
				image_container,

			"image_live_container":
				image_live_container,

			"interaction_container":
				interaction_container
		}
	)


	action_type.item_selected.connect(
		func(_selected: int) -> void:

			update_action_editor_visibility(
				panel
			)
	)


	update_action_editor_visibility(
		panel
	)


# =============================================================
# ACTION VISIBILITY
# =============================================================

func update_action_editor_visibility(
	panel: PanelContainer
) -> void:

	if panel == null:

		return


	var controls_value: Variant = (
		panel.get_meta(
			"controls",
			null
		)
	)


	if not controls_value is Dictionary:

		return


	var controls: Dictionary = (
		controls_value as Dictionary
	)


	var action_type: OptionButton = (
		controls[
			"action_type"
		]
	)


	var sound_container: Control = (
		controls[
			"sound_container"
		]
	)


	var image_container: Control = (
		controls[
			"image_container"
		]
	)
	var image_live_container: Control = (
		controls[
			"image_live_container"
		]
	)
	


	var interaction_container: Control = (
		controls[
			"interaction_container"
		]
	)


	sound_container.visible = (
		action_type.selected == 1
	)

	image_container.visible = (
		action_type.selected == 2
	)

	image_live_container.visible = (
		action_type.selected == 3
	)

	interaction_container.visible = (
		action_type.selected == 0
	)

	var interaction_controls_value: Variant = (
		panel.get_meta(
			"interaction_controls",
			{}
		)
	)


	if interaction_controls_value is Dictionary:

		_update_interaction_visibility(
			interaction_controls_value as Dictionary
		)


# =============================================================
# INTERACTION CONTROLS
# =============================================================

func _create_interaction_controls(
	panel: PanelContainer,
	container: VBoxContainer,
	data: Dictionary
) -> void:

	container.add_child(
		theme.create_section_label(
			"OBJECT"
		)
	)


	var object_mode := OptionButton.new()


	object_mode.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	object_mode.custom_minimum_size = Vector2(
		0.0,
		40.0
	)


	object_mode.add_item(
		"FIXED OBJECT"
	)


	object_mode.add_item(
		"RANDOM FROM ALL OBJECTS"
	)


	object_mode.add_item(
		"RANDOM FROM SELECTED OBJECTS"
	)


	container.add_child(
		theme.labeled_control(
			"OBJECT MODE",
			object_mode
		)
	)


	var object_selector := OptionButton.new()


	object_selector.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	object_selector.custom_minimum_size = Vector2(
		0.0,
		40.0
	)


	container.add_child(
		theme.labeled_control(
			"OBJECT",
			object_selector
		)
	)


	build_object_selector(
		object_selector,
		data
	)


	var selected_objects_container := VBoxContainer.new()


	selected_objects_container.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	container.add_child(
		selected_objects_container
	)


	build_selected_objects(
		selected_objects_container,
		data
	)


	container.add_child(
		theme.create_section_label(
			"AMOUNT"
		)
	)


	var amount_mode := OptionButton.new()


	amount_mode.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	amount_mode.custom_minimum_size = Vector2(
		0.0,
		40.0
	)


	amount_mode.add_item(
		"FIXED AMOUNT"
	)


	amount_mode.add_item(
		"RANDOM RANGE"
	)


	container.add_child(
		theme.labeled_control(
			"AMOUNT MODE",
			amount_mode
		)
	)


	var amount := theme.create_spinbox(
		1.0,
		100.0,
		1.0,
		float(
			data.get(
				"amount",
				1
			)
		)
	)


	container.add_child(
		theme.labeled_control(
			"AMOUNT",
			amount
		)
	)


	var amount_range := HBoxContainer.new()


	amount_range.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	amount_range.add_theme_constant_override(
		"separation",
		8
	)


	var amount_min := theme.create_spinbox(
		1.0,
		100.0,
		1.0,
		float(
			data.get(
				"amount_min",
				1
			)
		)
	)


	var amount_max := theme.create_spinbox(
		1.0,
		100.0,
		1.0,
		float(
			data.get(
				"amount_max",
				1
			)
		)
	)


	amount_range.add_child(
		theme.labeled_control(
			"MIN",
			amount_min
		)
	)


	amount_range.add_child(
		theme.labeled_control(
			"MAX",
			amount_max
		)
	)


	container.add_child(
		amount_range
	)


	container.add_child(
		theme.create_section_label(
			"TARGET"
		)
	)


	var target_mode := OptionButton.new()


	target_mode.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	target_mode.custom_minimum_size = Vector2(
		0.0,
		40.0
	)


	target_mode.add_item(
		"FIXED HITPOINT"
	)


	target_mode.add_item(
		"RANDOM FROM ALL HITPOINTS"
	)


	target_mode.add_item(
		"RANDOM FROM SELECTED HITPOINTS"
	)


	container.add_child(
		theme.labeled_control(
			"TARGET MODE",
			target_mode
		)
	)


	var target_selector := OptionButton.new()


	target_selector.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	target_selector.custom_minimum_size = Vector2(
		0.0,
		40.0
	)


	container.add_child(
		theme.labeled_control(
			"HITPOINT",
			target_selector
		)
	)


	build_target_selector(
		target_selector,
		data
	)


	var selected_targets_container := VBoxContainer.new()


	selected_targets_container.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	container.add_child(
		selected_targets_container
	)


	build_selected_targets(
		selected_targets_container,
		data
	)


	container.add_child(
		theme.create_section_label(
			"PHYSICS"
		)
	)


	var force_mode := OptionButton.new()


	force_mode.add_item(
		"INHERIT INTERACTION DEFAULT"
	)


	force_mode.add_item(
		"CUSTOM FORCE"
	)


	force_mode.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	force_mode.custom_minimum_size = Vector2(
		0.0,
		40.0
	)


	container.add_child(
		theme.labeled_control(
			"FORCE MODE",
			force_mode
		)
	)


	var force := theme.create_spinbox(
		MIN_FORCE,
		MAX_FORCE,
		0.1,
		float(
			data.get(
				"force",
				1.8
			)
		)
	)


	container.add_child(
		theme.labeled_control(
			"FORCE",
			force
		)
	)


	var speed_mode := OptionButton.new()


	speed_mode.add_item(
		"INHERIT INTERACTION DEFAULT"
	)


	speed_mode.add_item(
		"CUSTOM SPEED"
	)


	speed_mode.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	speed_mode.custom_minimum_size = Vector2(
		0.0,
		40.0
	)


	container.add_child(
		theme.labeled_control(
			"SPEED MODE",
			speed_mode
		)
	)


	var speed := theme.create_spinbox(
		MIN_SPEED,
		MAX_SPEED,
		0.1,
		float(
			data.get(
				"speed",
				5.4
			)
		)
	)


	container.add_child(
		theme.labeled_control(
			"SPEED",
			speed
		)
	)


	# INITIAL STATE

	match str(
		data.get(
			"object_mode",
			"RANDOM_FROM_ALL"
		)
	):

		"FIXED":

			object_mode.select(0)

		"RANDOM_FROM_SELECTED":

			object_mode.select(2)

		_:

			object_mode.select(1)


	if str(
		data.get(
			"amount_mode",
			"FIXED"
		)
	) == "RANDOM_RANGE":

		amount_mode.select(1)

	else:

		amount_mode.select(0)


	match str(
		data.get(
			"target_mode",
			"RANDOM_FROM_ALL"
		)
	):

		"FIXED":

			target_mode.select(0)

		"RANDOM_FROM_SELECTED":

			target_mode.select(2)

		_:

			target_mode.select(1)


	if str(
		data.get(
			"force_mode",
			"INHERIT"
		)
	) == "CUSTOM":

		force_mode.select(1)

	else:

		force_mode.select(0)


	if str(
		data.get(
			"speed_mode",
			"INHERIT"
		)
	) == "CUSTOM":

		speed_mode.select(1)

	else:

		speed_mode.select(0)


	var controls: Dictionary = {

		"object_mode":
			object_mode,

		"object_selector":
			object_selector,

		"selected_objects_container":
			selected_objects_container,

		"amount_mode":
			amount_mode,

		"amount":
			amount,

		"amount_min":
			amount_min,

		"amount_max":
			amount_max,

		"amount_range":
			amount_range,

		"target_mode":
			target_mode,

		"target_selector":
			target_selector,

		"selected_targets_container":
			selected_targets_container,

		"force_mode":
			force_mode,

		"force":
			force,

		"speed_mode":
			speed_mode,

		"speed":
			speed
	}


	panel.set_meta(
		"interaction_controls",
		controls
	)


	object_mode.item_selected.connect(
		func(_value: int) -> void:

			update_action_editor_visibility(
				panel
			)
	)


	amount_mode.item_selected.connect(
		func(_value: int) -> void:

			update_action_editor_visibility(
				panel
			)
	)


	target_mode.item_selected.connect(
		func(_value: int) -> void:

			update_action_editor_visibility(
				panel
			)
	)


	force_mode.item_selected.connect(
		func(_value: int) -> void:

			update_action_editor_visibility(
				panel
			)
	)


	speed_mode.item_selected.connect(
		func(_value: int) -> void:

			update_action_editor_visibility(
				panel
			)
)

# =============================================================
# INTERACTION VISIBILITY
# =============================================================

func _update_interaction_visibility(
	controls: Dictionary
) -> void:

	var object_mode: OptionButton = (
		controls["object_mode"]
	)

	var object_selector: Control = (
		controls["object_selector"]
	)

	var selected_objects: Control = (
		controls["selected_objects_container"]
	)

	var amount_mode: OptionButton = (
		controls["amount_mode"]
	)

	var amount: Control = (
		controls["amount"]
	)

	var amount_min: Control = (
		controls["amount_min"]
	)

	var amount_max: Control = (
		controls["amount_max"]
	)

	var amount_range: Control = (
		controls["amount_range"]
	)

	var target_mode: OptionButton = (
		controls["target_mode"]
	)

	var target_selector: Control = (
		controls["target_selector"]
	)

	var selected_targets: Control = (
		controls["selected_targets_container"]
	)

	var force_mode: OptionButton = (
		controls["force_mode"]
	)

	var force: Control = (
		controls["force"]
	)

	var speed_mode: OptionButton = (
		controls["speed_mode"]
	)

	var speed: Control = (
		controls["speed"]
	)


	object_selector.visible = (
		object_mode.selected == 0
	)


	selected_objects.visible = (
		object_mode.selected == 2
	)


	amount.visible = (
		amount_mode.selected == 0
	)


	amount_range.visible = (
		amount_mode.selected == 1
	)


	amount_min.visible = (
		amount_mode.selected == 1
	)


	amount_max.visible = (
		amount_mode.selected == 1
	)


	target_selector.visible = (
		target_mode.selected == 0
	)


	selected_targets.visible = (
		target_mode.selected == 2
	)


	force.visible = (
		force_mode.selected == 1
	)


	speed.visible = (
		speed_mode.selected == 1
	)


# =============================================================
# OBJECT SELECTOR
# =============================================================

func build_object_selector(
	selector: OptionButton,
	data: Dictionary
) -> void:

	selector.clear()

	selector.add_item(
		"SELECT OBJECT"
	)


	if object_manager == null:

		return


	var selected_id := str(
		data.get(
			"object_id",
			""
		)
	)


	for object_data: Dictionary in (
		object_manager.objects
	):

		var object_id := str(
			object_data.get(
				"id",
				""
			)
		)


		var object_name := str(
			object_data.get(
				"name",
				"OBJECT"
			)
		)


		selector.add_item(
			object_name
		)


		if object_id == selected_id:

			selector.select(
				selector.item_count - 1
			)


# =============================================================
# SELECTED OBJECTS
# =============================================================

func build_selected_objects(
	container: VBoxContainer,
	data: Dictionary
) -> void:

	for child: Node in (
		container.get_children()
	):

		child.queue_free()


	if object_manager == null:

		return


	container.add_child(
		create_small_label(
			"SELECT WHICH OBJECTS MAY BE RANDOMLY CHOSEN:"
		)
	)


	var value: Variant = (
		data.get(
			"selected_object_ids",
			[]
		)
	)


	var selected_ids: Array = []


	if value is Array:

		selected_ids = (
			value as Array
		)


	for object_data: Dictionary in (
		object_manager.objects
	):

		var object_id := str(
			object_data.get(
				"id",
				""
			)
		)


		var object_name := str(
			object_data.get(
				"name",
				"OBJECT"
			)
		)


		var check := CheckBox.new()


		check.text = object_name


		check.custom_minimum_size = Vector2(
			0.0,
			32.0
		)


		check.size_flags_horizontal = (
			Control.SIZE_EXPAND_FILL
		)


		check.button_pressed = (
			selected_ids.has(
				object_id
			)
		)


		container.add_child(
			check
		)


# =============================================================
# TARGET SELECTOR
# =============================================================

func build_target_selector(
	selector: OptionButton,
	data: Dictionary
) -> void:

	selector.clear()


	var selected_target := (
		str(
			data.get(
				"target",
				"CHEST"
			)
		)
		.to_upper()
	)


	for target_name: String in HITPOINTS:

		selector.add_item(
			target_name
		)


		if target_name == selected_target:

			selector.select(
				selector.item_count - 1
			)


# =============================================================
# SELECTED TARGETS
# =============================================================

func build_selected_targets(
	container: VBoxContainer,
	data: Dictionary
) -> void:

	for child: Node in (
		container.get_children()
	):

		child.queue_free()


	container.add_child(
		create_small_label(
			"SELECT WHICH HITPOINTS MAY BE RANDOMLY CHOSEN:"
		)
	)


	var value: Variant = (
		data.get(
			"selected_targets",
			[]
		)
	)


	var selected_targets: Array = []


	if value is Array:

		selected_targets = (
			value as Array
		)


	for target_name: String in HITPOINTS:

		var check := CheckBox.new()


		check.text = target_name


		check.custom_minimum_size = Vector2(
			0.0,
			32.0
		)


		check.size_flags_horizontal = (
			Control.SIZE_EXPAND_FILL
		)


		check.button_pressed = (
			selected_targets.has(
				target_name
			)
		)


		container.add_child(
			check
		)


# =============================================================
# SMALL LABEL
# =============================================================

func create_small_label(
	text_value: String
) -> Label:

	var label := Label.new()


	label.text = text_value


	label.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)


	label.add_theme_font_size_override(
		"font_size",
		12
	)


	label.add_theme_color_override(
		"font_color",
		CIGATheme.TEXT_DIM
	)


	return label


# =============================================================
# SOUND
# =============================================================

func _create_sound_action_controls(
	panel: PanelContainer,
	data: Dictionary
) -> VBoxContainer:

	var container := VBoxContainer.new()


	container.name = "SoundContainer"


	container.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	container.add_theme_constant_override(
		"separation",
		8
	)


	container.add_child(
		theme.create_section_label(
			"SOUND"
		)
	)


	var file_row := HBoxContainer.new()


	file_row.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	var file_label := Label.new()


	file_label.text = str(
		data.get(
			"sound_name",
			"NO AUDIO SELECTED"
		)
	)


	file_label.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	file_row.add_child(
		file_label
	)


	var browse := theme.create_button(
		"BROWSE"
	)


	browse.custom_minimum_size = Vector2(
		120.0,
		40.0
	)


	file_row.add_child(
		browse
	)


	container.add_child(
		file_row
	)


	var volume := theme.create_spinbox(
		0.0,
		100.0,
		1.0,
		_volume_to_percent(
			float(
				data.get(
					"volume",
					DEFAULT_SOUND_VOLUME
				)
			)
		)
	)


	container.add_child(
		theme.labeled_control(
			"VOLUME (%)",
			volume
		)
	)


	var preview_volume := theme.create_spinbox(
		0.0,
		100.0,
		1.0,
		_volume_to_percent(
			float(
				data.get(
					"preview_volume",
					DEFAULT_PREVIEW_VOLUME
				)
			)
		)
	)


	var preview_row := HBoxContainer.new()


	preview_row.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	preview_row.add_child(
		theme.labeled_control(
			"PREVIEW VOLUME (%)",
			preview_volume
		)
	)


	var play_preview := theme.create_button(
		"PLAY PREVIEW"
	)


	play_preview.custom_minimum_size = Vector2(
		150.0,
		40.0
	)


	preview_row.add_child(
		play_preview
	)


	container.add_child(
		preview_row
	)


	container.add_child(
		theme.create_status_label(
			"Audio is copied into the CIGA user library. Volume uses 0–100%."
		)
	)


	var file_dialog := FileDialog.new()


	file_dialog.file_mode = (
		FileDialog.FILE_MODE_OPEN_FILE
	)


	file_dialog.access = (
		FileDialog.ACCESS_FILESYSTEM
	)


	file_dialog.add_filter(
		"*.wav ; WAV"
	)

	file_dialog.add_filter(
		"*.ogg ; OGG"
	)

	file_dialog.add_filter(
		"*.mp3 ; MP3"
	)


	panel.add_child(
		file_dialog
	)


	browse.pressed.connect(
		func() -> void:

			file_dialog.popup_centered_ratio(
				0.75
			)
	)


	file_dialog.file_selected.connect(
		func(path: String) -> void:

			var copied_path := (
				_copy_audio_to_ciga_library(
					path
				)
			)


			if copied_path.is_empty():

				return


			data["sound_path"] = copied_path

			data["sound_name"] = (
				copied_path.get_file()
			)


			file_label.text = (
				copied_path.get_file()
			)


			var controls: Dictionary = (
				panel.get_meta(
					"sound_controls",
					{}
				)
			)


			controls["sound_path"] = (
				copied_path
			)

			controls["sound_name"] = (
				copied_path.get_file()
			)


			panel.set_meta(
				"sound_controls",
				controls
			)


			_load_audio_for_preview(
				panel,
				copied_path
			)
	)


	play_preview.pressed.connect(
		func() -> void:

			_preview_audio_file(
				panel
			)
	)


	panel.set_meta(
		"sound_controls",
		{

			"sound_container":
				container,

			"sound_file_label":
				file_label,

			"sound_path":
				str(
					data.get(
						"sound_path",
						""
					)
				),

			"sound_name":
				str(
					data.get(
						"sound_name",
						""
					)
				),

			"volume":
				volume,

			"preview_volume":
				preview_volume,

			"play_preview":
				play_preview,

			"file_dialog":
				file_dialog
		}
	)


	return container


func _volume_to_percent(
	value: float
) -> float:

	if not is_finite(value):

		return 100.0


	if value >= 0.0 and value <= 1.0:

		return clampf(
			value * 100.0,
			0.0,
			100.0
		)


	return clampf(
		value,
		0.0,
		100.0
	)


func _copy_audio_to_ciga_library(
	source_path: String
) -> String:

	if (
		source_path.is_empty()
		or
		not FileAccess.file_exists(
			source_path
		)
	):

		return ""


	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(
			AUDIO_LIBRARY_DIR
		)
	)


	var destination := (
		AUDIO_LIBRARY_DIR
		+
		"/"
		+
		source_path.get_file()
	)


	var bytes := FileAccess.get_file_as_bytes(
		source_path
	)


	if bytes.is_empty():

		return ""


	var file := FileAccess.open(
		destination,
		FileAccess.WRITE
	)


	if file == null:

		return ""


	file.store_buffer(
		bytes
	)

	file.close()


	return destination


func _load_audio_for_preview(
	panel: PanelContainer,
	path: String
) -> void:

	if panel == null:

		return


	var player := (
		panel.get_node_or_null(
			"PreviewAudioPlayer"
		)
		as AudioStreamPlayer
	)


	if player == null:

		player = AudioStreamPlayer.new()

		player.name = (
			"PreviewAudioPlayer"
		)

		panel.add_child(
			player
		)


	var extension := (
		path
		.get_extension()
		.to_lower()
	)


	var stream: AudioStream = null


	match extension:

		"wav":

			stream = AudioStreamWAV.load_from_file(
				path
			)

		"ogg":

			stream = AudioStreamOggVorbis.load_from_file(
				path
			)

		"mp3":

			stream = AudioStreamMP3.load_from_file(
				path
			)


	if stream != null:

		player.stream = stream


func _preview_audio_file(
	panel: PanelContainer
) -> void:

	if panel == null:

		return


	var controls: Dictionary = (
		panel.get_meta(
			"sound_controls",
			{}
		)
	)


	var path := str(
		controls.get(
			"sound_path",
			""
		)
	)


	if path.is_empty():

		return


	_load_audio_for_preview(
		panel,
		path
	)


	var player := (
		panel.get_node_or_null(
			"PreviewAudioPlayer"
		)
		as AudioStreamPlayer
	)


	if player == null:

		return


	var preview_control := (
		controls.get(
			"preview_volume"
		)
		as SpinBox
	)


	if preview_control == null:

		return


	var percent := clampf(
		preview_control.value,
		0.0,
		100.0
	)


	var linear_volume := (
		percent / 100.0
	)


	if linear_volume <= 0.0001:

		player.volume_db = -80.0

	else:

		player.volume_db = (
			linear_to_db(
				linear_volume
			)
		)


	player.stop()

	player.play()

func create_live_image_action_controls(
	panel: PanelContainer,
	data: Dictionary
) -> VBoxContainer:

	var container := VBoxContainer.new()

	container.name = "ImageLiveContainer"

	container.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	container.add_theme_constant_override(
		"separation",
		8
	)


	container.add_child(
		theme.create_section_label(
			"DISPLAY IMAGE LIVE"
		)
	)


	container.add_child(
		theme.create_status_label(
			"The image is provided live through CIGAIS. "
			+
			"The preview uses a placeholder only for positioning."
		)
	)


	# =========================================================
	# DURATION
	# =========================================================

	var duration := theme.create_spinbox(
		0.1,
		3600.0,
		0.1,
		float(
			data.get(
				"image_live_duration",
				5.0
			)
		)
	)


	container.add_child(
		theme.labeled_control(
			"DURATION (SECONDS)",
			duration
		)
	)


	# =========================================================
	# TARGET
	# =========================================================

	var target_label := Label.new()

	target_label.text = (
		"TARGET: "
		+
		str(
			data.get(
				"image_live_target",
				"HeadHitPoint"
			)
		)
	)

	container.add_child(
		target_label
	)


	# =========================================================
	# PREVIEW BUTTON
	# =========================================================

	var preview_button := theme.create_button(
		"OPEN 3D LIVE IMAGE PREVIEW"
	)

	preview_button.custom_minimum_size = Vector2(
		0.0,
		46.0
	)

	container.add_child(
		preview_button
	)


	container.add_child(
		theme.create_status_label(
			"Configure where the live image appears. "
			+
			"The Discord image will use these settings when the event executes."
		)
	)


	# =========================================================
	# CONTROLS
	# =========================================================

	var live_controls: Dictionary = {

		"image_live_container":
			container,

		"image_live_duration":
			duration,

		"image_live_target":
			str(
				data.get(
					"image_live_target",
					"HeadHitPoint"
				)
			),

		"image_live_scale_mode":
			str(
				data.get(
					"image_live_scale_mode",
					"FIXED"
				)
			),

		"image_live_scale":
			float(
				data.get(
					"image_live_scale",
					1.0
				)
			),

		"image_live_scale_min":
			float(
				data.get(
					"image_live_scale_min",
					0.8
				)
			),

		"image_live_scale_max":
			float(
				data.get(
					"image_live_scale_max",
					1.2
				)
			),

		"image_live_offset_x_mode":
			str(
				data.get(
					"image_live_offset_x_mode",
					"FIXED"
				)
			),

		"image_live_offset_x":
			float(
				data.get(
					"image_live_offset_x",
					0.0
				)
			),

		"image_live_offset_x_min":
			float(
				data.get(
					"image_live_offset_x_min",
					0.0
				)
			),

		"image_live_offset_x_max":
			float(
				data.get(
					"image_live_offset_x_max",
					0.0
				)
			),

		"image_live_offset_y_mode":
			str(
				data.get(
					"image_live_offset_y_mode",
					"FIXED"
				)
			),

		"image_live_offset_y":
			float(
				data.get(
					"image_live_offset_y",
					0.0
				)
			),

		"image_live_offset_y_min":
			float(
				data.get(
					"image_live_offset_y_min",
					0.0
				)
			),

		"image_live_offset_y_max":
			float(
				data.get(
					"image_live_offset_y_max",
					0.0
				)
			),

		"image_live_offset_z_mode":
			str(
				data.get(
					"image_live_offset_z_mode",
					"FIXED"
				)
			),

		"image_live_offset_z":
			float(
				data.get(
					"image_live_offset_z",
					0.0
				)
			),

		"image_live_offset_z_min":
			float(
				data.get(
					"image_live_offset_z_min",
					0.0
				)
			),

		"image_live_offset_z_max":
			float(
				data.get(
					"image_live_offset_z_max",
					0.0
				)
			),

		"image_live_rotation_x_mode":
			str(
				data.get(
					"image_live_rotation_x_mode",
					"FIXED"
				)
			),

		"image_live_rotation_x":
			float(
				data.get(
					"image_live_rotation_x",
					0.0
				)
			),

		"image_live_rotation_x_min":
			float(
				data.get(
					"image_live_rotation_x_min",
					0.0
				)
			),

		"image_live_rotation_x_max":
			float(
				data.get(
					"image_live_rotation_x_max",
					0.0
				)
			),

		"image_live_rotation_y_mode":
			str(
				data.get(
					"image_live_rotation_y_mode",
					"FIXED"
				)
			),

		"image_live_rotation_y":
			float(
				data.get(
					"image_live_rotation_y",
					0.0
				)
			),

		"image_live_rotation_y_min":
			float(
				data.get(
					"image_live_rotation_y_min",
					0.0
				)
			),

		"image_live_rotation_y_max":
			float(
				data.get(
					"image_live_rotation_y_max",
					0.0
				)
			),

		"image_live_rotation_z_mode":
			str(
				data.get(
					"image_live_rotation_z_mode",
					"FIXED"
				)
			),

		"image_live_rotation_z":
			float(
				data.get(
					"image_live_rotation_z",
					0.0
				)
			),

		"image_live_rotation_z_min":
			float(
				data.get(
					"image_live_rotation_z_min",
					0.0
				)
			),

		"image_live_rotation_z_max":
			float(
				data.get(
					"image_live_rotation_z_max",
					0.0
				)
			),

		"image_live_mirror_h":
			bool(
				data.get(
					"image_live_mirror_h",
					false
				)
			),

		"image_live_mirror_v":
			bool(
				data.get(
					"image_live_mirror_v",
					false
				)
			),

		"image_live_target_label":
			target_label,

		"preview_button":
			preview_button
	}


	panel.set_meta(
		"image_live_controls",
		live_controls
	)


	preview_button.pressed.connect(
		func() -> void:

			_open_live_image_preview(
				panel
			)
	)


	return container

# =============================================================
# IMAGE
# =============================================================

func create_image_action_controls(
	panel: PanelContainer,
	data: Dictionary
) -> VBoxContainer:

	var container := VBoxContainer.new()


	container.name = "ImageContainer"


	container.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	container.add_theme_constant_override(
		"separation",
		8
	)


	container.add_child(
		theme.create_section_label(
			"DISPLAY IMAGE"
		)
	)


	var file_row := HBoxContainer.new()


	var image_file_label := Label.new()


	image_file_label.text = str(
		data.get(
			"image_name",
			"NO IMAGE SELECTED"
		)
	)


	image_file_label.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	file_row.add_child(
		image_file_label
	)


	var browse := theme.create_button(
		"BROWSE"
	)


	browse.custom_minimum_size = Vector2(
		120.0,
		40.0
	)


	file_row.add_child(
		browse
	)


	container.add_child(
		file_row
	)


	var duration := theme.create_spinbox(
		0.1,
		3600.0,
		0.1,
		float(
			data.get(
				"image_duration",
				5.0
			)
		)
	)


	container.add_child(
		theme.labeled_control(
			"DURATION (SECONDS)",
			duration
		)
	)


	container.add_child(
		theme.create_status_label(
			"Use the 3D preview to move, scale, rotate, change target and mirror the image."
		)
	)


	var target_label := Label.new()


	target_label.text = (
		"TARGET: "
		+
		str(
			data.get(
				"image_target",
				"HeadHitPoint"
			)
		)
	)


	container.add_child(
		target_label
	)


	var preview_button := theme.create_button(
		"OPEN 3D IMAGE PREVIEW"
	)


	preview_button.custom_minimum_size = Vector2(
		0.0,
		46.0
	)


	container.add_child(
		preview_button
	)


	var file_dialog := FileDialog.new()


	file_dialog.file_mode = (
		FileDialog.FILE_MODE_OPEN_FILE
	)


	file_dialog.access = (
		FileDialog.ACCESS_FILESYSTEM
	)


	file_dialog.add_filter(
		"*.png ; PNG"
	)

	file_dialog.add_filter(
		"*.jpg ; JPG"
	)

	file_dialog.add_filter(
		"*.jpeg ; JPEG"
	)

	file_dialog.add_filter(
		"*.webp ; WEBP"
	)


	panel.add_child(
		file_dialog
	)


	var image_controls: Dictionary = {

		"image_container":
			container,

		"image_file_label":
			image_file_label,

		"image_path":
			str(
				data.get(
					"image_path",
					""
				)
			),

		"image_name":
			str(
				data.get(
					"image_name",
					""
				)
			),

		"image_target":
			str(
				data.get(
					"image_target",
					"HeadHitPoint"
				)
			),

		"image_duration":
			duration,

		"preview_button":
			preview_button,

		"file_dialog":
			file_dialog,

		"image_scale":
			float(
				data.get(
					"image_scale",
					1.0
				)
			),

		"image_offset":
			Vector3(
				float(
					data.get(
						"image_offset_x",
						0.0
					)
				),
				float(
					data.get(
						"image_offset_y",
						0.0
					)
				),
				float(
					data.get(
						"image_offset_z",
						0.0
					)
				)
			),

		"image_rotation":
			Vector3(
				float(
					data.get(
						"image_rotation_x",
						0.0
					)
				),
				float(
					data.get(
						"image_rotation_y",
						0.0
					)
				),
				float(
					data.get(
						"image_rotation_z",
						0.0
					)
				)
			),

		"image_mirror_h":
			bool(
				data.get(
					"image_mirror_h",
					false
				)
			),

		"image_mirror_v":
			bool(
				data.get(
					"image_mirror_v",
					false
				)
			),

		"image_target_label":
			target_label
	}


	panel.set_meta(
		"image_controls",
		image_controls
	)


	browse.pressed.connect(
		func() -> void:

			file_dialog.popup_centered_ratio(
				0.75
			)
	)


	file_dialog.file_selected.connect(
		func(path: String) -> void:

			var copied_path := (
				_copy_image_to_ciga_library(
					path
				)
			)


			if copied_path.is_empty():

				return


			image_controls["image_path"] = (
				copied_path
			)

			image_controls["image_name"] = (
				copied_path.get_file()
			)


			image_file_label.text = (
				copied_path.get_file()
			)


			panel.set_meta(
				"image_controls",
				image_controls
			)
	)


	preview_button.pressed.connect(
		func() -> void:

			_open_image_preview(
				panel
			)
	)


	return container


func _copy_image_to_ciga_library(
	source_path: String
) -> String:

	if (
		source_path.is_empty()
		or
		not FileAccess.file_exists(
			source_path
		)
	):

		return ""


	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(
			IMAGE_LIBRARY_DIR
		)
	)


	var destination := (
		IMAGE_LIBRARY_DIR
		+
		"/"
		+
		source_path.get_file()
	)


	var bytes := FileAccess.get_file_as_bytes(
		source_path
	)


	if bytes.is_empty():

		return ""


	var file := FileAccess.open(
		destination,
		FileAccess.WRITE
	)


	if file == null:

		return ""


	file.store_buffer(
		bytes
	)

	file.close()


	return destination


# =============================================================
# IMAGE PREVIEW
# =============================================================

func _open_image_preview(
	panel: PanelContainer
) -> void:

	if panel == null:

		return


	_close_image_preview_window()


	image_preview_panel = panel


	image_preview_window = Window.new()


	image_preview_window.name = (
		"CIGAImagePreviewWindow"
	)


	image_preview_window.title = (
		"CIGA — IMAGE PREVIEW"
	)


	image_preview_window.always_on_top = true


	image_preview_window.size = Vector2i(
		1450,
		900
	)


	image_preview_window.min_size = Vector2i(
		1100,
		700
	)


	image_preview_window.close_requested.connect(
		_close_image_preview_window
	)


	root.add_child(
		image_preview_window
	)


	image_preview = (
		CIGAImagePreview3D.new()
	)


	image_preview.name = (
		"CIGAImagePreview3D"
	)


	image_preview.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)


	image_preview_window.add_child(
		image_preview
	)


	image_preview.image_settings_changed.connect(
		_on_image_preview_settings_changed
	)


	var controls: Dictionary = (
		panel.get_meta(
			"image_controls",
			{}
		)
	)


	var image_path := str(
		controls.get(
			"image_path",
			""
		)
	)


	var texture: Texture2D = null


	if not image_path.is_empty():

		var loaded: Resource = (
			ResourceLoader.load(
				image_path
			)
		)


		if loaded is Texture2D:

			texture = (
				loaded as Texture2D
			)

	var target_name := str(
		controls.get(
			"image_target",
			"HeadHitPoint"
		)
	)


	var image_scale := float(
		controls.get(
			"image_scale",
			1.0
		)
	)


	var offset: Vector3 = (
		controls.get(
			"image_offset",
			Vector3.ZERO
		)
	)


	var rotation: Vector3 = (
		controls.get(
			"image_rotation",
			Vector3.ZERO
		)
	)


	var mirror_h := bool(
		controls.get(
			"image_mirror_h",
			false
		)
	)


	var mirror_v := bool(
		controls.get(
			"image_mirror_v",
			false
		)
	)


	image_preview.set_image_texture(
		image_path,
		texture,
		target_name,
		image_scale,
		offset,
		rotation,
		mirror_h,
		mirror_v
	)


	image_preview_window.popup_centered_clamped(
		Vector2i(
			1450,
			900
		),
		0.90
	)
func _open_live_image_preview(
	panel: PanelContainer
) -> void:

	if panel == null:

		return


	_close_image_preview_window()


	image_preview_panel = panel


	image_preview_window = Window.new()

	image_preview_window.name = (
		"CIGALiveImagePreviewWindow"
	)

	image_preview_window.title = (
		"CIGA — LIVE IMAGE PREVIEW"
	)

	image_preview_window.always_on_top = true

	image_preview_window.size = Vector2i(
		1200,
		860
	)

	image_preview_window.min_size = Vector2i(
		900,
		650
	)

	image_preview_window.close_requested.connect(
		_close_image_preview_window
	)

	root.add_child(
		image_preview_window
	)


	image_preview = (
		CIGAImagePreview3D.new()
	)

	image_preview.name = (
		"CIGAImagePreview3D"
	)

	image_preview.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	image_preview_window.add_child(
		image_preview
	)


	image_preview.live_image_settings_changed.connect(
		_on_live_image_preview_settings_changed
	)


	var controls: Dictionary = (
		panel.get_meta(
			"image_live_controls",
			{}
		)
	)


	var settings := {
		"target":
			str(
				controls.get(
					"image_live_target",
					"HeadHitPoint"
				)
			),

		"scale_mode":
			str(
				controls.get(
					"image_live_scale_mode",
					"FIXED"
				)
			),

		"scale":
			float(
				controls.get(
					"image_live_scale",
					1.0
				)
			),

		"scale_min":
			float(
				controls.get(
					"image_live_scale_min",
					0.8
				)
			),

		"scale_max":
			float(
				controls.get(
					"image_live_scale_max",
					1.2
				)
			),

		"offset_x_mode":
			str(
				controls.get(
					"image_live_offset_x_mode",
					"FIXED"
				)
			),

		"offset_x":
			float(
				controls.get(
					"image_live_offset_x",
					0.0
				)
			),

		"offset_x_min":
			float(
				controls.get(
					"image_live_offset_x_min",
					0.0
				)
			),

		"offset_x_max":
			float(
				controls.get(
					"image_live_offset_x_max",
					0.0
				)
			),

		"offset_y_mode":
			str(
				controls.get(
					"image_live_offset_y_mode",
					"FIXED"
				)
			),

		"offset_y":
			float(
				controls.get(
					"image_live_offset_y",
					0.0
				)
			),

		"offset_y_min":
			float(
				controls.get(
					"image_live_offset_y_min",
					0.0
				)
			),

		"offset_y_max":
			float(
				controls.get(
					"image_live_offset_y_max",
					0.0
				)
			),

		"offset_z_mode":
			str(
				controls.get(
					"image_live_offset_z_mode",
					"FIXED"
				)
			),

		"offset_z":
			float(
				controls.get(
					"image_live_offset_z",
					0.0
				)
			),

		"offset_z_min":
			float(
				controls.get(
					"image_live_offset_z_min",
					0.0
				)
			),

		"offset_z_max":
			float(
				controls.get(
					"image_live_offset_z_max",
					0.0
				)
			),

		"rotation_x_mode":
			str(
				controls.get(
					"image_live_rotation_x_mode",
					"FIXED"
				)
			),

		"rotation_x":
			float(
				controls.get(
					"image_live_rotation_x",
					0.0
				)
			),

		"rotation_x_min":
			float(
				controls.get(
					"image_live_rotation_x_min",
					0.0
				)
			),

		"rotation_x_max":
			float(
				controls.get(
					"image_live_rotation_x_max",
					0.0
				)
			),

		"rotation_y_mode":
			str(
				controls.get(
					"image_live_rotation_y_mode",
					"FIXED"
				)
			),

		"rotation_y":
			float(
				controls.get(
					"image_live_rotation_y",
					0.0
				)
			),

		"rotation_y_min":
			float(
				controls.get(
					"image_live_rotation_y_min",
					0.0
				)
			),

		"rotation_y_max":
			float(
				controls.get(
					"image_live_rotation_y_max",
					0.0
				)
			),

		"rotation_z_mode":
			str(
				controls.get(
					"image_live_rotation_z_mode",
					"FIXED"
				)
			),

		"rotation_z":
			float(
				controls.get(
					"image_live_rotation_z",
					0.0
				)
			),

		"rotation_z_min":
			float(
				controls.get(
					"image_live_rotation_z_min",
					0.0
				)
			),

		"rotation_z_max":
			float(
				controls.get(
					"image_live_rotation_z_max",
					0.0
				)
			),

		"mirror_h":
			bool(
				controls.get(
					"image_live_mirror_h",
					false
				)
			),

		"mirror_v":
			bool(
				controls.get(
					"image_live_mirror_v",
					false
				)
			)
	}


	var placeholder := _create_live_placeholder_texture()


	image_preview.set_live_placeholder(
		placeholder,
		str(
			settings.get(
				"target",
				"HeadHitPoint"
			)
		),
		settings
	)


	image_preview_window.popup_centered_clamped(
		Vector2i(
			1200,
			860
		),
		0.90
	)

	image_preview_window.grab_focus()

	image_preview_window.move_to_foreground()

func _create_live_placeholder_texture() -> Texture2D:

	var image := Image.create(
		256,
		256,
		false,
		Image.FORMAT_RGBA8
	)


	for y: int in range(256):

		for x: int in range(256):

			var block_x: int = (
				x / 32
			)

			var block_y: int = (
				y / 32
			)


			var even: bool = (
				(block_x + block_y) % 2 == 0
			)


			var value: float = (
				0.14
				if even
				else
				0.08
			)


			image.set_pixel(
				x,
				y,
				Color(
					value,
					value,
					value,
					1.0
				)
			)


	# Borda
	for x: int in range(256):

		image.set_pixel(
			x,
			0,
			Color(
				0.55,
				0.55,
				0.55,
				1.0
			)
		)

		image.set_pixel(
			x,
			255,
			Color(
				0.55,
				0.55,
				0.55,
				1.0
			)
		)


	for y: int in range(256):

		image.set_pixel(
			0,
			y,
			Color(
				0.55,
				0.55,
				0.55,
				1.0
			)
		)

		image.set_pixel(
			255,
			y,
			Color(
				0.55,
				0.55,
				0.55,
				1.0
			)
		)


	return ImageTexture.create_from_image(
		image
	)
func _on_live_image_preview_settings_changed(
	settings: Dictionary
) -> void:

	if (
		image_preview_panel == null
		or
		not is_instance_valid(
			image_preview_panel
		)
	):

		return


	var controls: Dictionary = (
		image_preview_panel.get_meta(
			"image_live_controls",
			{}
		)
	)


	for key: String in settings.keys():

		controls[
			"image_live_"
			+
			key
		] = settings[key]


	# target
	var target_value := str(
		settings.get(
			"target",
			"HeadHitPoint"
		)
	)

	controls["image_live_target"] = (
		target_value
	)


	# mirror
	controls["image_live_mirror_h"] = bool(
		settings.get(
			"mirror_h",
			false
		)
	)

	controls["image_live_mirror_v"] = bool(
		settings.get(
			"mirror_v",
			false
		)
	)


	image_preview_panel.set_meta(
		"image_live_controls",
		controls
	)


	var label := (
		controls.get(
			"image_live_target_label"
		)
		as
		Label
	)


	if label != null:

		label.text = (
			"TARGET: "
			+
			target_value
		)

func _on_image_preview_settings_changed(
	target_name: String,
	image_scale: float,
	offset: Vector3,
	rotation: Vector3,
	mirror_h: bool,
	mirror_v: bool
) -> void:

	if (
		image_preview_panel == null
		or
		not is_instance_valid(
			image_preview_panel
		)
	):

		return


	var controls: Dictionary = (
		image_preview_panel.get_meta(
			"image_controls",
			{}
		)
	)


	controls["image_target"] = (
		target_name
	)

	controls["image_scale"] = (
		image_scale
	)

	controls["image_offset"] = (
		offset
	)

	controls["image_rotation"] = (
		rotation
	)

	controls["image_mirror_h"] = (
		mirror_h
	)

	controls["image_mirror_v"] = (
		mirror_v
	)


	image_preview_panel.set_meta(
		"image_controls",
		controls
	)


	var label := (
		controls.get(
			"image_target_label"
		)
		as Label
	)


	if label != null:

		label.text = (
			"TARGET: "
			+
			target_name
		)


func _close_image_preview_window() -> void:

	if (
		image_preview_window != null
		and
		is_instance_valid(
			image_preview_window
		)
	):

		image_preview_window.hide()

		image_preview_window.queue_free()


	image_preview_window = null

	image_preview = null

	image_preview_panel = null

# =============================================================
# CAPTURE ACTION
# =============================================================

func capture_action_from_panel(
	panel: PanelContainer
) -> Dictionary:

	var result := (
		create_default_action()
	)


	if panel == null:

		return result


	var controls_value: Variant = (
		panel.get_meta(
			"controls",
			null
		)
	)


	if not controls_value is Dictionary:

		return result


	var controls: Dictionary = (
		controls_value as Dictionary
	)


	var action_type: OptionButton = (
		controls["action_type"]
	)


	match action_type.selected:

		1:

			result["action_type"] = (
				"PLAY_SOUND"
			)

		2:

			result["action_type"] = (
				"DISPLAY_IMAGE"
			)

		3:

			result["action_type"] = (
				"DISPLAY_IMAGE_LIVE"
			)

		_:

			result["action_type"] = (
				"INTERACTION"
			)

	# =========================================================
	# SOUND
	# =========================================================

	if action_type.selected == 1:

		var sound_controls: Dictionary = (
			panel.get_meta(
				"sound_controls",
				{}
			)
		)


		result["sound_path"] = str(
			sound_controls.get(
				"sound_path",
				""
			)
		)


		result["sound_name"] = str(
			sound_controls.get(
				"sound_name",
				""
			)
		)


		var volume_control := (
			sound_controls["volume"]
			as SpinBox
		)


		var preview_volume_control := (
			sound_controls["preview_volume"]
			as SpinBox
		)


		if volume_control != null:

			result["volume"] = (
				clampf(
					volume_control.value,
					0.0,
					100.0
				)
				/
				100.0
			)


		if preview_volume_control != null:

			result["preview_volume"] = (
				clampf(
					preview_volume_control.value,
					0.0,
					100.0
				)
				/
				100.0
			)


		return result


	# =========================================================
	# IMAGE
	# =========================================================

	if action_type.selected == 2:

		var image_controls: Dictionary = (
			panel.get_meta(
				"image_controls",
				{}
			)
		)


		result["image_path"] = str(
			image_controls.get(
				"image_path",
				""
			)
		)


		result["image_name"] = str(
			image_controls.get(
				"image_name",
				""
			)
		)


		result["image_target"] = (
			str(
				image_controls.get(
					"image_target",
					"HeadHitPoint"
				)
			)
		)


		var duration_control := (
			image_controls.get(
				"image_duration"
			)
			as SpinBox
		)


		if duration_control != null:

			result["image_duration"] = (
				duration_control.value
			)


		result["image_scale"] = float(
			image_controls.get(
				"image_scale",
				1.0
			)
		)


		var offset: Vector3 = (
			image_controls.get(
				"image_offset",
				Vector3.ZERO
			)
		)


		var rotation: Vector3 = (
			image_controls.get(
				"image_rotation",
				Vector3.ZERO
			)
		)


		result["image_offset_x"] = (
			offset.x
		)

		result["image_offset_y"] = (
			offset.y
		)

		result["image_offset_z"] = (
			offset.z
		)


		result["image_rotation_x"] = (
			rotation.x
		)

		result["image_rotation_y"] = (
			rotation.y
		)

		result["image_rotation_z"] = (
			rotation.z
		)


		result["image_mirror_h"] = bool(
			image_controls.get(
				"image_mirror_h",
				false
			)
		)


		result["image_mirror_v"] = bool(
			image_controls.get(
				"image_mirror_v",
				false
			)
		)


		return result

	# =========================================================
	# LIVE IMAGE
	# =========================================================

	if action_type.selected == 3:

		var live_controls: Dictionary = (
			panel.get_meta(
				"image_live_controls",
				{}
			)
		)


		var duration_control := (
			live_controls.get(
				"image_live_duration"
			)
			as
			SpinBox
		)


		if duration_control != null:

			result["image_live_duration"] = (
				clampf(
					duration_control.value,
					0.1,
					3600.0
				)
			)


		result["image_live_target"] = str(
			live_controls.get(
				"image_live_target",
				"HeadHitPoint"
			)
		)


		result["image_live_scale_mode"] = str(
			live_controls.get(
				"image_live_scale_mode",
				"FIXED"
			)
		)


		result["image_live_scale"] = clampf(
			float(
				live_controls.get(
					"image_live_scale",
					1.0
				)
			),
			0.01,
			10.0
		)


		result["image_live_scale_min"] = clampf(
			float(
				live_controls.get(
					"image_live_scale_min",
					0.8
				)
			),
			0.01,
			10.0
		)


		result["image_live_scale_max"] = clampf(
			float(
				live_controls.get(
					"image_live_scale_max",
					1.2
				)
			),
			0.01,
			10.0
		)


		var live_keys := [
			"offset_x_mode",
			"offset_x",
			"offset_x_min",
			"offset_x_max",
			"offset_y_mode",
			"offset_y",
			"offset_y_min",
			"offset_y_max",
			"offset_z_mode",
			"offset_z",
			"offset_z_min",
			"offset_z_max",
			"rotation_x_mode",
			"rotation_x",
			"rotation_x_min",
			"rotation_x_max",
			"rotation_y_mode",
			"rotation_y",
			"rotation_y_min",
			"rotation_y_max",
			"rotation_z_mode",
			"rotation_z",
			"rotation_z_min",
			"rotation_z_max"
		]


		for key: String in live_keys:

			result[
				"image_live_"
				+
				key
			] = live_controls.get(
				"image_live_"
				+
				key,
				(
					"FIXED"
					if key.ends_with("_mode")
					else
					0.0
				)
			)


		result["image_live_mirror_h"] = bool(
			live_controls.get(
				"image_live_mirror_h",
				false
			)
		)


		result["image_live_mirror_v"] = bool(
			live_controls.get(
				"image_live_mirror_v",
				false
			)
		)


		return result
	# =========================================================
	# INTERACTION
	# =========================================================

	var interaction: Dictionary = (
		panel.get_meta(
			"interaction_controls",
			{}
		)
	)


	var object_mode: OptionButton = (
		interaction["object_mode"]
	)


	match object_mode.selected:

		0:

			result["object_mode"] = (
				"FIXED"
			)

		2:

			result["object_mode"] = (
				"RANDOM_FROM_SELECTED"
			)

		_:

			result["object_mode"] = (
				"RANDOM_FROM_ALL"
			)


	var object_selector: OptionButton = (
		interaction["object_selector"]
	)


	if (
		object_selector.selected > 0
		and
		object_manager != null
	):

		var object_index := (
			object_selector.selected - 1
		)


		if (
			object_index >= 0
			and
			object_index < object_manager.objects.size()
		):

			var object_data: Dictionary = (
				object_manager.objects[
					object_index
				]
			)


			result["object_id"] = str(
				object_data.get(
					"id",
					""
				)
			)


	var selected_object_ids: Array[String] = []


	var selected_container: VBoxContainer = (
		interaction[
			"selected_objects_container"
		]
	)


	for child: Node in (
		selected_container.get_children()
	):

		if not child is CheckBox:

			continue


		var check := (
			child
			as
			CheckBox
		)


		if not check.button_pressed:

			continue


		for object_data: Dictionary in (
			object_manager.objects
		):

			if str(
				object_data.get(
					"name",
					""
				)
			) != check.text:

				continue


			var object_id := str(
				object_data.get(
					"id",
					""
				)
			)


			if not object_id.is_empty():

				selected_object_ids.append(
					object_id
				)


			break


	result["selected_object_ids"] = (
		selected_object_ids
	)


	var amount_mode: OptionButton = (
		interaction[
			"amount_mode"
		]
	)


	result["amount_mode"] = (
		"RANDOM_RANGE"
		if amount_mode.selected == 1
		else
		"FIXED"
	)


	var amount: SpinBox = (
		interaction["amount"]
	)


	var amount_min: SpinBox = (
		interaction["amount_min"]
	)


	var amount_max: SpinBox = (
		interaction["amount_max"]
	)


	result["amount"] = clampi(
		int(round(amount.value)),
		MIN_AMOUNT,
		MAX_AMOUNT
	)


	result["amount_min"] = clampi(
		int(round(amount_min.value)),
		MIN_AMOUNT,
		MAX_AMOUNT
	)


	result["amount_max"] = clampi(
		int(round(amount_max.value)),
		MIN_AMOUNT,
		MAX_AMOUNT
	)


	if result["amount_min"] > result["amount_max"]:

		var temp: int = (
			result["amount_min"]
		)

		result["amount_min"] = (
			result["amount_max"]
		)

		result["amount_max"] = temp


	var target_mode: OptionButton = (
		interaction["target_mode"]
	)


	match target_mode.selected:

		0:

			result["target_mode"] = (
				"FIXED"
			)

		2:

			result["target_mode"] = (
				"RANDOM_FROM_SELECTED"
			)

		_:

			result["target_mode"] = (
				"RANDOM_FROM_ALL"
			)


	var target_selector: OptionButton = (
		interaction["target_selector"]
	)


	if (
		target_selector.selected >= 0
		and
		target_selector.selected < HITPOINTS.size()
	):

		result["target"] = (
			HITPOINTS[
				target_selector.selected
			]
		)


	var selected_targets: Array[String] = []


	var target_container: VBoxContainer = (
		interaction[
			"selected_targets_container"
		]
	)


	for child: Node in (
		target_container.get_children()
	):

		if not child is CheckBox:

			continue


		var check := (
			child
			as
			CheckBox
		)


		if check.button_pressed:

			selected_targets.append(
				check.text
			)


	result["selected_targets"] = (
		selected_targets
	)


	var force_mode: OptionButton = (
		interaction["force_mode"]
	)


	var force: SpinBox = (
		interaction["force"]
	)


	if force_mode.selected == 1:

		result["force_mode"] = (
			"CUSTOM"
		)

		result["force"] = clampf(
			force.value,
			MIN_FORCE,
			MAX_FORCE
		)

	else:

		result["force_mode"] = (
			"INHERIT"
		)


	var speed_mode: OptionButton = (
		interaction["speed_mode"]
	)


	var speed: SpinBox = (
		interaction["speed"]
	)


	if speed_mode.selected == 1:

		result["speed_mode"] = (
			"CUSTOM"
		)

		result["speed"] = clampf(
			speed.value,
			MIN_SPEED,
			MAX_SPEED
		)

	else:

		result["speed_mode"] = (
			"INHERIT"
		)


	return result


# =============================================================
# COLLECT ACTIONS
# =============================================================

func collect_editor_actions() -> Array[Dictionary]:

	var result: Array[Dictionary] = []


	if editor_actions_container == null:

		return result


	for child: Node in (
		editor_actions_container.get_children()
	):

		if not child is PanelContainer:

			continue


		result.append(
			capture_action_from_panel(
				child as PanelContainer
			)
		)


	return result


# =============================================================
# SAVE EVENT
# =============================================================

func _save_event_editor() -> void:

	if editor_event_id.is_empty():

		return


	if (
		editor_event_name_input != null
		and
		editor_event_name_input.text
		.strip_edges()
		== "_ciga_defaults_initialized"
	):

		if event_status != null:

			event_status.text = (
				"INVALID EVENT NAME"
			)

		return


	var actions := (
		collect_editor_actions()
	)


	if actions.is_empty():

		actions.append(
			create_default_action()
		)


	var events := (
		get_saved_events()
	)


	# =========================================================
	# EVENT NAME
	# =========================================================

	var new_event_id := (
		editor_event_id
	)


	if editor_event_name_input != null:

		var entered_name := (
			editor_event_name_input.text
			.strip_edges()
		)


		if not entered_name.is_empty():

			new_event_id = (
				entered_name
			)


	if new_event_id != editor_event_id:

		if events.has(
			new_event_id
		):

			if event_status != null:

				event_status.text = (
					"EVENT NAME ALREADY EXISTS: "
					+
					new_event_id
				)

			return


	# =========================================================
	# TRIGGER
	# =========================================================

	var trigger_event := (
		"FOLLOW"
	)


	if editor_trigger_selector != null:

		var selected_index := (
			editor_trigger_selector.selected
		)


		if (
			selected_index >= 0
			and
			selected_index < EVENT_TRIGGERS.size()
		):

			trigger_event = (
				EVENT_TRIGGERS[
					selected_index
				]
			)


	trigger_event = (
		normalize_trigger_id(
			trigger_event
		)
	)


	# CUSTOM PRESERVATION

	if trigger_event == "CUSTOM":

		var old_trigger := str(
			editor_event_data.get(
				"trigger_event",
				""
			)
		).strip_edges()


		if not old_trigger.is_empty():

			trigger_event = (
				normalize_trigger_id(
					old_trigger
				)
			)


	# =========================================================
	# REWARD
	# =========================================================

	var reward_name := ""


	if editor_trigger_reward_input != null:

		reward_name = (
			editor_trigger_reward_input.text
			.strip_edges()
		)


	# =========================================================
	# SAVE DATA
	# =========================================================

	editor_event_data["trigger_event"] = (
		trigger_event
	)


	editor_event_data["reward_name"] = (
		reward_name
	)


	editor_event_data["actions"] = (
		actions
	)


	editor_event_data["enabled"] = true


	if (
		new_event_id != editor_event_id
		and
		events.has(
			editor_event_id
		)
	):

		events.erase(
			editor_event_id
		)


	events[new_event_id] = (
		editor_event_data.duplicate(
			true
		)
	)


	save_events(
		events
	)


	print(
		"[CIGA EVENTS UI] EVENT SAVED | ",
		editor_event_id,
		" -> ",
		new_event_id,
		" | TRIGGER=",
		trigger_event,
		" | REWARD=",
		reward_name
	)


	editor_event_id = (
		new_event_id
	)


	close_event_editor()


	if event_status != null:

		var status_text := (
			"EVENT SAVED: "
			+
			new_event_id
			+
			" → "
			+
			format_trigger_display_name(
				trigger_event
			)
		)


		if not reward_name.is_empty():

			status_text += (
				" ["
				+
				reward_name
				+
				"]"
			)


		event_status.text = (
			status_text
		)


	refresh_events()


# =============================================================
# CANCEL
# =============================================================

func _cancel_event_editor() -> void:

	close_event_editor()


	if event_status != null:

		event_status.text = (
			"CHANGES CANCELLED"
		)


# =============================================================
# FLOAT FORMAT
# =============================================================

func format_float(
	value: float
) -> String:

	return (
		"%.2f"
		%
		value
	)


# =============================================================
# TRIGGER DISPLAY
# =============================================================

func format_trigger_display_name(
	trigger_id: String
) -> String:

	var normalized := (
		normalize_trigger_id(
			trigger_id
		)
	)


	match normalized:

		"FOLLOW":

			return "FOLLOW"

		"SUBSCRIBE":

			return "SUBSCRIBE"

		"BIT":

			return "BITS / CHEER"

		"RAID":

			return "RAID"

		"CHANNEL_FOLLOW":

			return "CHANNEL FOLLOW"

		"CHANNEL_SUBSCRIBE":

			return "CHANNEL SUBSCRIBE"

		"CHANNEL_CHEER":

			return "CHANNEL CHEER"

		"CHANNEL_RAID":

			return "CHANNEL RAID"

		"CHANNEL_POINTS_REDEEM":

			return "CHANNEL POINTS REDEEM"

		"CHANNEL_SUBSCRIPTION_GIFT":

			return "SUBSCRIPTION GIFT"

		"CHANNEL_SUBSCRIPTION_END":

			return "SUBSCRIPTION END"

		"CHANNEL_SUBSCRIPTION_MESSAGE":

			return "SUBSCRIPTION MESSAGE"

		"CHANNEL_CHAT_MESSAGE":

			return "CHAT MESSAGE"

		"CHANNEL_CHAT_MESSAGE_DELETE":

			return "CHAT MESSAGE DELETE"

		"CHANNEL_CHAT_CLEAR":

			return "CHAT CLEAR"

		"CHANNEL_POLL_BEGIN":

			return "POLL BEGIN"

		"CHANNEL_POLL_PROGRESS":

			return "POLL PROGRESS"

		"CHANNEL_POLL_END":

			return "POLL END"

		"CHANNEL_PREDICTION_BEGIN":

			return "PREDICTION BEGIN"

		"CHANNEL_PREDICTION_PROGRESS":

			return "PREDICTION PROGRESS"

		"CHANNEL_PREDICTION_LOCK":

			return "PREDICTION LOCK"

		"CHANNEL_PREDICTION_END":

			return "PREDICTION END"

		"CHANNEL_HYPE_TRAIN_BEGIN":

			return "HYPE TRAIN BEGIN"

		"CHANNEL_HYPE_TRAIN_PROGRESS":

			return "HYPE TRAIN PROGRESS"

		"CHANNEL_HYPE_TRAIN_END":

			return "HYPE TRAIN END"

		"CHANNEL_GOAL_BEGIN":

			return "GOAL BEGIN"

		"CHANNEL_GOAL_PROGRESS":

			return "GOAL PROGRESS"

		"CHANNEL_GOAL_END":

			return "GOAL END"

		"STREAM_ONLINE":

			return "STREAM ONLINE"

		"STREAM_OFFLINE":

			return "STREAM OFFLINE"

		"CHANNEL_UPDATE":

			return "CHANNEL UPDATE"

		"CHANNEL_AD_BREAK_BEGIN":

			return "AD BREAK BEGIN"

		"CHANNEL_VIP_ADD":

			return "VIP ADD"

		"CHANNEL_BAN":

			return "CHANNEL BAN"

		"CHANNEL_SHOUTOUT_CREATE":

			return "SHOUTOUT CREATE"

		"CHANNEL_SHOUTOUT_RECEIVE":

			return "SHOUTOUT RECEIVE"

		"CUSTOM":

			return "CUSTOM / EXTERNAL"


		_:

			return normalized


# =============================================================
# NORMALIZE TRIGGER
# =============================================================

func normalize_trigger_id(
	trigger_id: String
) -> String:

	var normalized := (
		trigger_id
		.to_upper()
		.strip_edges()
		.replace(
			".",
			"_"
		)
		.replace(
			" ",
			"_"
		)
		.replace(
			"-",
			"_"
		)
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
# REMOVE EVENT
# =============================================================

func remove_event(
	event_id: String
) -> void:

	if event_id.is_empty():

		return


	if event_id == "_ciga_defaults_initialized":

		return


	var events := (
		get_saved_events()
	)


	if not events.has(
		event_id
	):

		return


	events.erase(
		event_id
	)


	save_events(
		events
	)


	if editor_event_id == event_id:

		close_event_editor()


	if event_status != null:

		event_status.text = (
			"EVENT REMOVED: "
			+
			event_id
		)


	refresh_events()


# =============================================================
# ADD CUSTOM EVENT
# =============================================================

func _add_custom_event() -> void:

	var events := (
		get_saved_events()
	)


	var number: int = 1


	while true:

		var event_id := (
			"CUSTOM %02d"
			%
			number
		)


		if not events.has(
			event_id
		):

			var custom_event := (
				create_default_event(
					"FOLLOW"
				)
			)


			custom_event["custom_event"] = true


			events[event_id] = (
				custom_event
			)


			save_events(
				events
			)


			refresh_events()


			open_event_editor(
				event_id
			)


			return


		number += 1
