class_name CIGAOutputUI
extends RefCounted


# =============================================================
# CIGA OUTPUT UI
# Godot 4.7.2
#
# OUTPUTS
#
#   - STREAM ELEMENTS
#   - VMC OUTPUT
#   - VTube Studio
#   - CIGAIS WORKER
#
# VMC:
#
#   - SENDER
#   - RECEIVER
#   - BOTH CONTROLLED BY ONE AUTO-CONNECT OPTION
#
# =============================================================


# =============================================================
# REFERENCES
# =============================================================

var root: PanelContainer

var theme: CIGATheme

var profile_manager: CIGAProfiles

var runtime: CIGAOutput

var vmc_runtime: CIGAVMCRuntime = null


# =============================================================
# MAIN
# =============================================================

var main_scroll: ScrollContainer

var main_margin: MarginContainer

var main_content: VBoxContainer

var source_grid: GridContainer

var global_logs: RichTextLabel

var global_status: Label

var connect_all_button: Button

var auto_connect_all_on_launch: CheckBox = null

var auto_connect_on_launch: CheckBox = null


# =============================================================
# SOURCE CARDS
# =============================================================

var source_cards: Dictionary = {}


# =============================================================
# SOURCE LOG HISTORY
# =============================================================

var source_log_history: Dictionary = {

	"STREAMELEMENTS":
		[],

	"VMC":
		[],

	"VTUBESTUDIO":
		[],

	"CIGAIS_WORKER":
		[]
}


# =============================================================
# SOURCES
# =============================================================

const SOURCE_STREAMELEMENTS: String = (
	"STREAMELEMENTS"
)

const SOURCE_VMC: String = (
	"VMC"
)

const SOURCE_VTUBESTUDIO: String = (
	"VTUBESTUDIO"
)

const SOURCE_CIGAIS_WORKER: String = (
	"CIGAIS_WORKER"
)


const SOURCES: Array[String] = [

	SOURCE_STREAMELEMENTS,

	SOURCE_VMC,

	SOURCE_VTUBESTUDIO,

	SOURCE_CIGAIS_WORKER
]


# =============================================================
# SOURCE WINDOW
# =============================================================

var source_window: Window = null

var source_window_source: String = ""


# =============================================================
# STREAM ELEMENTS CONTROLS
# =============================================================

var source_token: LineEdit = null

var source_token_type: OptionButton = null

var source_token_label: Label = null

var source_accept_mock: CheckBox = null

var source_connect_button: Button = null

var source_disconnect_button: Button = null

var source_window_status: Label = null

var source_logs: RichTextLabel = null


# =============================================================
# VMC CONTROLS
# =============================================================

# =========================================================
# SENDER
# =========================================================

var vmc_host: LineEdit = null

var vmc_port: LineEdit = null

var vmc_connect_button: Button = null

var vmc_disconnect_button: Button = null


# =========================================================
# RECEIVER
# =========================================================

var vmc_receiver_host: LineEdit = null

var vmc_receiver_port: LineEdit = null

var vmc_receiver_connect_button: Button = null

var vmc_receiver_disconnect_button: Button = null


# =========================================================
# STATUS
# =========================================================

var vmc_window_status: Label = null

var vmc_receiver_window_status: Label = null

var vmc_logs: RichTextLabel = null


# =============================================================
# VTUBE STUDIO CONTROLS
# =============================================================

var vtube_plugin_name: LineEdit = null

var vtube_plugin_developer: LineEdit = null

var vtube_token: LineEdit = null

var vtube_enabled: CheckBox = null

var vtube_connect_button: Button = null

var vtube_disconnect_button: Button = null

var vtube_clear_token_button: Button = null

var vtube_window_status: Label = null

var vtube_logs: RichTextLabel = null


# =============================================================
# CIGAIS WORKER CONTROLS
# =============================================================

var worker_guild_id: LineEdit = null

var worker_connect_button: Button = null

var worker_disconnect_button: Button = null

var worker_window_status: Label = null

var worker_logs: RichTextLabel = null


# =============================================================
# WINDOW
# =============================================================

const SOURCE_WINDOW_MIN_WIDTH: int = 700

const SOURCE_WINDOW_MIN_HEIGHT: int = 560

const SOURCE_WINDOW_PREFERRED_WIDTH: int = 1100

const SOURCE_WINDOW_PREFERRED_HEIGHT: int = 820


# =============================================================
# SETUP
# =============================================================

func setup(
	parent: Control,
	ui_theme: CIGATheme,
	profiles: CIGAProfiles = null,
	output_runtime: CIGAOutput = null,
	output_vmc_runtime: CIGAVMCRuntime = null
) -> Control:

	theme = ui_theme

	profile_manager = profiles

	runtime = output_runtime

	vmc_runtime = output_vmc_runtime


	if runtime != null:

		runtime.set_vmc_runtime(
			vmc_runtime
		)


	root = PanelContainer.new()

	root.name = "OutputPage"

	root.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	root.visible = false


	theme.style_panel(
		root
	)


	parent.add_child(
		root
	)


	build()

	connect_runtime_signals()


	call_deferred(
		"refresh_output"
	)


	call_deferred(
		"_auto_connect_sources_on_launch"
	)


	return root


# =============================================================
# PROCESS
# =============================================================

func _process(
	_delta: float
) -> void:

	if source_window != null:

		if not is_instance_valid(
			source_window
		):

			source_window = null

			source_window_source = ""


# =============================================================
# REFRESH
# =============================================================

func refresh_output() -> void:

	refresh_source_cards()

	update_global_status()

	_refresh_global_auto_connect_state()


	append_global_log(
		"CORE",
		"CIGA Output interface ready."
	)


# =============================================================
# BUILD
# =============================================================

func build() -> void:

	main_scroll = ScrollContainer.new()

	main_scroll.name = "OutputScroll"

	main_scroll.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	main_scroll.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	main_scroll.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)

	main_scroll.horizontal_scroll_mode = (
		ScrollContainer.SCROLL_MODE_DISABLED
	)

	main_scroll.vertical_scroll_mode = (
		ScrollContainer.SCROLL_MODE_AUTO
	)


	root.add_child(
		main_scroll
	)


	main_margin = _build_main_margin()

	main_margin.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	main_margin.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)


	main_scroll.add_child(
		main_margin
	)


func _build_main_margin() -> MarginContainer:

	main_margin = MarginContainer.new()

	main_margin.name = "MainMargin"

	main_margin.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	main_margin.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	main_margin.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)


	theme.set_margins(
		main_margin,
		16
	)


	main_content = VBoxContainer.new()

	main_content.name = "MainContent"

	main_content.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	main_content.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)


	main_content.add_theme_constant_override(
		"separation",
		14
	)


	main_margin.add_child(
		main_content
	)


	# =========================================================
	# TITLE
	# =========================================================

	var title := theme.create_title(
		"OUTPUT"
	)

	title.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	main_content.add_child(
		title
	)


	# =========================================================
	# DESCRIPTION
	# =========================================================

	var description := theme.create_status_label(
		"Manage CIGA external connections."
	)

	description.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	description.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)


	main_content.add_child(
		description
	)


	# =========================================================
	# STATUS
	# =========================================================

	global_status = theme.create_status_label(
		"CIGA OUTPUT READY"
	)

	global_status.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	main_content.add_child(
		global_status
	)


	# =========================================================
	# CONNECT ALL
	# =========================================================

	connect_all_button = theme.create_button(
		"CONNECT ALL AVAILABLE"
	)

	connect_all_button.custom_minimum_size = Vector2(
		0.0,
		44.0
	)

	connect_all_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	main_content.add_child(
		connect_all_button
	)


	connect_all_button.pressed.connect(
		_connect_all
	)


	# =========================================================
	# AUTO CONNECT ALL
	# =========================================================

	auto_connect_all_on_launch = CheckBox.new()

	auto_connect_all_on_launch.text = (
		"AUTO CONNECT ALL ON LAUNCH"
	)

	auto_connect_all_on_launch.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	auto_connect_all_on_launch.set_pressed_no_signal(
		_is_all_sources_auto_connect_enabled()
	)

	main_content.add_child(
		auto_connect_all_on_launch
	)


	auto_connect_all_on_launch.toggled.connect(
		_on_auto_connect_all_toggled
	)


	# =========================================================
	# CONNECTIONS LABEL
	# =========================================================

	main_content.add_child(
		theme.create_section_label(
			"CONNECTIONS"
		)
	)


	# =========================================================
	# CONNECTIONS PANEL
	# =========================================================

	var source_panel := PanelContainer.new()

	source_panel.name = "SourcePanel"

	source_panel.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	source_panel.size_flags_vertical = (
		Control.SIZE_SHRINK_BEGIN
	)

	source_panel.custom_minimum_size = Vector2(
		0.0,
		230.0
	)


	theme.style_panel(
		source_panel,
		CIGATheme.PANEL,
		CIGATheme.BORDER
	)


	main_content.add_child(
		source_panel
	)


	var source_margin := MarginContainer.new()

	source_margin.name = "SourceMargin"

	source_margin.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	source_margin.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)


	theme.set_margins(
		source_margin,
		12
	)


	source_panel.add_child(
		source_margin
	)


	# =========================================================
	# SOURCE GRID
	# =========================================================

	source_grid = GridContainer.new()

	source_grid.name = "SourceGrid"

	source_grid.columns = 3

	source_grid.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	source_grid.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)


	source_grid.add_theme_constant_override(
		"h_separation",
		14
	)

	source_grid.add_theme_constant_override(
		"v_separation",
		14
	)


	source_margin.add_child(
		source_grid
	)


	for source_id: String in SOURCES:

		create_source_card(
			source_id
		)


	# =========================================================
	# LOG
	# =========================================================

	main_content.add_child(
		theme.create_section_label(
			"CIGA OUTPUT LOG"
		)
	)


	global_logs = RichTextLabel.new()

	global_logs.custom_minimum_size = Vector2(
		0.0,
		220.0
	)

	global_logs.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	global_logs.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)

	global_logs.bbcode_enabled = false

	global_logs.scroll_following = true

	global_logs.text = (
		"CIGA OUTPUT INITIALIZING..."
	)


	main_content.add_child(
		global_logs
	)


	return main_margin


# =============================================================
# SOURCE CARD
# =============================================================

func create_source_card(
	source_id: String
) -> void:

	var card := PanelContainer.new()

	card.name = (
		"SourceCard_"
		+
		source_id
	)

	card.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	card.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)

	card.custom_minimum_size = Vector2(
		0.0,
		190.0
	)


	theme.style_panel(
		card,
		CIGATheme.PANEL_LIGHT,
		CIGATheme.BORDER
	)


	source_grid.add_child(
		card
	)


	source_cards[source_id] = card


	# =========================================================
	# CARD CONTENT
	# =========================================================

	var margin := MarginContainer.new()

	margin.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	margin.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)


	theme.set_margins(
		margin,
		14
	)


	card.add_child(
		margin
	)


	var box := VBoxContainer.new()

	box.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	box.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)


	box.add_theme_constant_override(
		"separation",
		8
	)


	margin.add_child(
		box
	)


	# =========================================================
	# TITLE
	# =========================================================

	var title := Label.new()


	match source_id:

		SOURCE_STREAMELEMENTS:

			title.text = (
				"STREAM ELEMENTS"
			)


		SOURCE_VMC:

			title.text = (
				"VMC OUTPUT"
			)


		SOURCE_VTUBESTUDIO:

			title.text = (
				"VTUBE STUDIO"
			)


		SOURCE_CIGAIS_WORKER:

			title.text = (
				"CIGAIS WORKER"
			)


		_:

			title.text = (
				source_id
			)


	title.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	title.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	title.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	title.custom_minimum_size = Vector2(
		0.0,
		30.0
	)


	title.add_theme_font_size_override(
		"font_size",
		18
	)


	title.add_theme_color_override(
		"font_color",
		CIGATheme.TEXT
	)


	box.add_child(
		title
	)


	# =========================================================
	# STATUS
	# =========================================================

	var status := Label.new()

	status.name = "Status"

	status.text = (
		get_source_status(
			source_id
		)
	)

	status.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	status.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	status.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	status.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	status.custom_minimum_size = Vector2(
		0.0,
		34.0
	)


	status.add_theme_font_size_override(
		"font_size",
		12
	)


	status.add_theme_color_override(
		"font_color",
		CIGATheme.TEXT_DIM
	)


	box.add_child(
		status
	)


	# =========================================================
	# CONFIGURE
	# =========================================================

	var configure := theme.create_button(
		"CONFIGURE"
	)

	configure.custom_minimum_size = Vector2(
		0.0,
		36.0
	)

	configure.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	box.add_child(
		configure
	)


	configure.pressed.connect(
		func() -> void:

			open_source_window(
				source_id
			)
	)


	# =========================================================
	# CONNECT
	# =========================================================

	var connect_button := theme.create_button(
		"CONNECT"
	)

	connect_button.custom_minimum_size = Vector2(
		0.0,
		36.0
	)

	connect_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	box.add_child(
		connect_button
	)


	connect_button.pressed.connect(
		func() -> void:

			connect_source(
				source_id
			)
	)


# =============================================================
# STATUS
# =============================================================

func get_source_status(
	source_id: String
) -> String:

	if runtime == null:

		return "RUNTIME UNAVAILABLE"


	match source_id:

		SOURCE_STREAMELEMENTS:

			return runtime.get_connection_status(
				SOURCE_STREAMELEMENTS
			)


		SOURCE_VMC:

			if vmc_runtime == null:

				return "VMC UNAVAILABLE"


			return vmc_runtime.get_connection_status()


		SOURCE_VTUBESTUDIO:

			return runtime.get_connection_status(
				SOURCE_VTUBESTUDIO
			)


		SOURCE_CIGAIS_WORKER:

			return runtime.get_connection_status(
				SOURCE_CIGAIS_WORKER
			)


	return "UNKNOWN"


# =============================================================
# REFRESH CARDS
# =============================================================

func refresh_source_cards() -> void:

	for source_id: String in SOURCES:

		if not source_cards.has(
			source_id
		):

			continue


		var card_value: Variant = (
			source_cards.get(
				source_id,
				null
			)
		)


		if not card_value is PanelContainer:

			continue


		var card := (
			card_value
			as
			PanelContainer
		)


		var status_node := card.find_child(
			"Status",
			true,
			false
		)


		if status_node is Label:

			(status_node as Label).text = (
				get_source_status(
					source_id
				)
			)


# =============================================================
# RUNTIME SIGNALS
# =============================================================

func connect_runtime_signals() -> void:

	if runtime != null:

		if not runtime.connection_status_changed.is_connected(
			_on_connection_status_changed
		):

			runtime.connection_status_changed.connect(
				_on_connection_status_changed
			)


		if not runtime.log_message.is_connected(
			_on_runtime_log
		):

			runtime.log_message.connect(
				_on_runtime_log
			)


		if not runtime.stream_event_received.is_connected(
			_on_stream_event_received
		):

			runtime.stream_event_received.connect(
				_on_stream_event_received
			)


		if not runtime.event_forwarded.is_connected(
			_on_event_forwarded
		):

			runtime.event_forwarded.connect(
				_on_event_forwarded
			)


	if vmc_runtime != null:

		if not vmc_runtime.connection_status_changed.is_connected(
			_on_vmc_connection_status_changed
		):

			vmc_runtime.connection_status_changed.connect(
				_on_vmc_connection_status_changed
			)


		if not vmc_runtime.vmc_log.is_connected(
			_on_vmc_log
		):

			vmc_runtime.vmc_log.connect(
				_on_vmc_log
			)


# =============================================================
# CONNECTION STATUS
# =============================================================

func _on_connection_status_changed(
	source_id: String,
	status_value: String,
	message: String
) -> void:

	append_global_log(
		source_id,
		status_value
		+
		" | "
		+
		message
	)


	update_source_card(
		source_id
	)


	update_global_status()


# =============================================================
# RUNTIME LOG
# =============================================================

func _on_runtime_log(
	source_id: String,
	level: String,
	message: String
) -> void:

	append_global_log(
		source_id,
		"["
		+
		level
		+
		"] "
		+
		message
	)


# =============================================================
# RAW EVENT
# =============================================================

func _on_stream_event_received(
	source_id: String,
	event_name: String,
	payload: Dictionary
) -> void:

	var username: String = (
		extract_username(
			payload
		)
	)


	var text := (
		"EVENT RECEIVED | "
		+
		event_name
	)


	if not username.is_empty():

		text += (
			" | USER="
			+
			username
		)


	append_global_log(
		source_id,
		text
	)


# =============================================================
# FORWARDED
# =============================================================

func _on_event_forwarded(
	source_id: String,
	event_name: String,
	_payload: Dictionary
) -> void:

	append_global_log(
		source_id,
		"EVENT FORWARDED | "
		+
		event_name
	)


# =============================================================
# USERNAME
# =============================================================

func extract_username(
	payload: Dictionary
) -> String:

	var username := str(
		payload.get(
			"username",
			""
		)
	)


	if not username.is_empty():

		return username


	var display_name := str(
		payload.get(
			"displayName",
			""
		)
	)


	if not display_name.is_empty():

		return display_name


	var data_value: Variant = (
		payload.get(
			"data",
			{}
		)
	)


	if data_value is Dictionary:

		var data := (
			data_value
			as
			Dictionary
		)


		username = str(
			data.get(
				"username",
				""
			)
		)


		if not username.is_empty():

			return username


		return str(
			data.get(
				"displayName",
				""
			)
		)


	return ""


# =============================================================
# GLOBAL LOG
# =============================================================

func append_global_log(
	source_id: String,
	message: String
) -> void:

	var timestamp := (
		Time.get_time_string_from_system()
	)


	if not source_log_history.has(
		source_id
	):

		source_log_history[source_id] = []


	var history_value: Variant = (
		source_log_history.get(
			source_id,
			[]
		)
	)


	if history_value is Array:

		var history := (
			history_value
			as
			Array
		)


		history.append(
			"["
			+
			timestamp
			+
			"] "
			+
			message
		)


		while history.size() > 200:

			history.pop_front()


		source_log_history[source_id] = history


	if global_logs == null:

		return


	if global_logs.text == (
		"CIGA OUTPUT INITIALIZING..."
	):

		global_logs.text = ""


	global_logs.append_text(
		"["
		+
		timestamp
		+
		"] ["
		+
		source_id
		+
		"] "
		+
		message
		+
		"\n"
	)


	if (
		source_window != null
		and
		is_instance_valid(
			source_window
		)
		and
		source_window_source == source_id
	):

		append_source_window_log(
			source_id,
			message
		)


# =============================================================
# GLOBAL STATUS
# =============================================================

func update_global_status() -> void:

	if global_status == null:

		return


	var connected_count := 0

	var connecting_count := 0


	for source_id: String in SOURCES:

		var status_value := (
			get_source_status(
				source_id
			)
		)


		if status_value == "CONNECTED":

			connected_count += 1


		elif (
			status_value == "CONNECTING"
			or
			status_value == "RECONNECTING"
		):

			connecting_count += 1


	global_status.text = (
		"CIGA OUTPUT | CONNECTED: "
		+
		str(
			connected_count
		)
		+
		" | CONNECTING: "
		+
		str(
			connecting_count
		)
	)


# =============================================================
# CARD
# =============================================================

func update_source_card(
	source_id: String
) -> void:

	if not source_cards.has(
		source_id
	):

		return


	var card_value: Variant = (
		source_cards.get(
			source_id,
			null
		)
	)


	if not card_value is PanelContainer:

		return


	var card := (
		card_value
		as
		PanelContainer
	)


	var status_node := card.find_child(
		"Status",
		true,
		false
	)


	if status_node is Label:

		(status_node as Label).text = (
			get_source_status(
				source_id
			)
		)


# =============================================================
# AUTO CONNECT CONFIG
# =============================================================

func _get_source_auto_connect_on_launch(
	source_id: String
) -> bool:

	if runtime == null:

		return false


	var config: Dictionary = (
		runtime.get_saved_source_config(
			source_id
		)
	)


	return bool(
		config.get(
			"auto_connect_on_launch",
			false
		)
	)


# =============================================================
# SET AUTO CONNECT CONFIG
# =============================================================

func _set_source_auto_connect_on_launch(
	source_id: String,
	enabled: bool
) -> void:

	if runtime == null:

		return


	var config: Dictionary = (
		runtime.get_saved_source_config(
			source_id
		)
	)


	config["auto_connect_on_launch"] = enabled


	runtime.save_source_config(
		source_id,
		config
	)


# =============================================================
# CHECK ALL AUTO CONNECT
# =============================================================

func _is_all_sources_auto_connect_enabled() -> bool:

	for source_id: String in SOURCES:

		if not _get_source_auto_connect_on_launch(
			source_id
		):

			return false


	return true


# =============================================================
# REFRESH GLOBAL AUTO CONNECT
# =============================================================

func _refresh_global_auto_connect_state() -> void:

	if auto_connect_all_on_launch == null:

		return


	auto_connect_all_on_launch.set_pressed_no_signal(
		_is_all_sources_auto_connect_enabled()
	)


# =============================================================
# REFRESH WINDOW AUTO CONNECT
# =============================================================

func _refresh_source_window_auto_connect_checkbox() -> void:

	if auto_connect_on_launch == null:

		return


	if source_window_source.is_empty():

		auto_connect_on_launch.set_pressed_no_signal(
			false
		)

		return


	auto_connect_on_launch.set_pressed_no_signal(
		_get_source_auto_connect_on_launch(
			source_window_source
		)
	)


# =============================================================
# CREATE WINDOW AUTO CONNECT CHECKBOX
# =============================================================

func _create_source_auto_connect_checkbox(
	parent: VBoxContainer,
	source_id: String
) -> void:

	auto_connect_on_launch = CheckBox.new()

	auto_connect_on_launch.text = (
		"AUTO CONNECT ON LAUNCH"
	)

	auto_connect_on_launch.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	auto_connect_on_launch.set_pressed_no_signal(
		_get_source_auto_connect_on_launch(
			source_id
		)
	)


	parent.add_child(
		auto_connect_on_launch
	)


	auto_connect_on_launch.toggled.connect(
		_on_auto_connect_on_launch_toggled
	)


# =============================================================
# INDIVIDUAL AUTO CONNECT TOGGLE
# =============================================================

func _on_auto_connect_on_launch_toggled(
	enabled: bool
) -> void:

	if source_window_source.is_empty():

		return


	_set_source_auto_connect_on_launch(
		source_window_source,
		enabled
	)


	append_global_log(
		source_window_source,
		"AUTO CONNECT ON LAUNCH = "
		+
		str(
			enabled
		)
	)


	_refresh_global_auto_connect_state()


# =============================================================
# GLOBAL AUTO CONNECT TOGGLE
# =============================================================

func _on_auto_connect_all_toggled(
	enabled: bool
) -> void:

	for source_id: String in SOURCES:

		_set_source_auto_connect_on_launch(
			source_id,
			enabled
		)


	_refresh_source_window_auto_connect_checkbox()


	_refresh_global_auto_connect_state()


	append_global_log(
		"CORE",
		"AUTO CONNECT ALL ON LAUNCH = "
		+
		str(
			enabled
		)
	)


	for source_id: String in SOURCES:

		append_global_log(
			source_id,
			"AUTO CONNECT ON LAUNCH = "
			+
			str(
				enabled
			)
		)


# =============================================================
# AUTO CONNECT ON LAUNCH
# =============================================================

func _auto_connect_sources_on_launch() -> void:

	append_global_log(
		"CORE",
		"Checking automatic connections."
	)


	# =========================================================
	# STREAM ELEMENTS
	# =========================================================

	if _get_source_auto_connect_on_launch(
		SOURCE_STREAMELEMENTS
	):

		if runtime != null:

			runtime.connect_source(
				SOURCE_STREAMELEMENTS,
				true
			)


	# =========================================================
	# VMC
	#
	# Sender + Receiver
	# =========================================================

	if _get_source_auto_connect_on_launch(
		SOURCE_VMC
	):

		connect_vmc_source()

		connect_vmc_receiver_source()


	# =========================================================
	# VTUBE STUDIO
	# =========================================================

	if _get_source_auto_connect_on_launch(
		SOURCE_VTUBESTUDIO
	):

		if runtime != null:

			runtime.connect_source(
				SOURCE_VTUBESTUDIO,
				true
			)


	# =========================================================
	# CIGAIS WORKER
	#
	# Failsafe:
	# sem Guild ID, não gera tentativa de conexão.
	# =========================================================

	if _get_source_auto_connect_on_launch(
		SOURCE_CIGAIS_WORKER
	):

		if runtime != null:

			var worker_config: Dictionary = (
				runtime.get_saved_source_config(
					SOURCE_CIGAIS_WORKER
				)
			)


			var guild_id: String = str(
				worker_config.get(
					"guild_id",
					""
				)
			).strip_edges()


			if guild_id.is_empty():

				append_global_log(
					SOURCE_CIGAIS_WORKER,
					"NO ID PROVIDED | Auto-connect skipped."
				)

			else:

				runtime.connect_source(
					SOURCE_CIGAIS_WORKER,
					false
				)


	refresh_source_cards()

	update_global_status()

	_refresh_global_auto_connect_state()


	append_global_log(
		"CORE",
		"Automatic connection check completed."
	)
# =============================================================
# CONNECT ALL
# =============================================================

func _connect_all() -> void:

	append_global_log(
		"CORE",
		"Starting CIGA external connections."
	)


	# =========================================================
	# STREAM ELEMENTS
	# =========================================================

	if runtime != null:

		runtime.connect_source(
			SOURCE_STREAMELEMENTS,
			true
		)


	# =========================================================
	# VMC SENDER
	# =========================================================

	connect_vmc_source()


	# =========================================================
	# VMC RECEIVER
	# =========================================================

	connect_vmc_receiver_source()


	# =========================================================
	# VTUBE STUDIO
	# =========================================================

	if runtime != null:

		runtime.connect_source(
			SOURCE_VTUBESTUDIO,
			true
		)


	# =========================================================
	# CIGAIS WORKER
	#
	# Failsafe:
	# Sem Guild ID, não tenta sequer iniciar a conexão.
	# =========================================================

	if runtime != null:

		var worker_config: Dictionary = (
			runtime.get_saved_source_config(
				SOURCE_CIGAIS_WORKER
			)
		)


		var guild_id: String = str(
			worker_config.get(
				"guild_id",
				""
			)
		).strip_edges()


		if guild_id.is_empty():

			append_global_log(
				SOURCE_CIGAIS_WORKER,
				"NO ID PROVIDED | Worker connection skipped."
			)

		else:

			runtime.connect_source(
				SOURCE_CIGAIS_WORKER,
				false
			)


	refresh_source_cards()

	update_global_status()


	append_global_log(
		"CORE",
		"CIGA external connection sequence completed."
	)


# =============================================================
# CONNECT SOURCE
# =============================================================

func connect_source(
	source_id: String
) -> void:

	match source_id:

		SOURCE_STREAMELEMENTS:

			if runtime != null:

				runtime.connect_source(
					SOURCE_STREAMELEMENTS,
					true
				)


		SOURCE_VMC:

			connect_vmc_source()

			connect_vmc_receiver_source()


		SOURCE_VTUBESTUDIO:

			if runtime != null:

				runtime.connect_source(
					SOURCE_VTUBESTUDIO,
					true
				)


		SOURCE_CIGAIS_WORKER:

			if runtime != null:

				runtime.connect_source(
					SOURCE_CIGAIS_WORKER,
					false
				)


# =============================================================
# CONNECT VMC RECEIVER
# =============================================================

func connect_vmc_receiver_source() -> void:

	if vmc_runtime == null:

		append_global_log(
			SOURCE_VMC,
			"VMC receiver unavailable."
		)

		return


	var host: String = (
		vmc_runtime.vmc_receiver_bind_host
	)


	var port: int = (
		vmc_runtime.get_vmc_receiver_port()
	)


	if host.is_empty():

		host = "127.0.0.1"


	if (
		port < 1
		or
		port > 65535
	):

		port = 39541


	vmc_runtime.set_vmc_receiver_bind_host(
		host
	)


	vmc_runtime.set_vmc_receiver_port(
		port
	)


	if vmc_runtime.vmc_receiver_connected:

		append_global_log(
			SOURCE_VMC,
			"VMC tracking receiver already connected | "
			+
			host
			+
			":"
			+
			str(
				port
			)
		)

		return


	if vmc_runtime.connect_vmc_receiver():

		append_global_log(
			SOURCE_VMC,
			"VMC tracking receiver active | "
			+
			host
			+
			":"
			+
			str(
				port
			)
		)

	else:

		append_global_log(
			SOURCE_VMC,
			"Failed to start VMC tracking receiver."
		)


# =============================================================
# CONNECT VMC SENDER
# =============================================================

func connect_vmc_source() -> void:

	if vmc_runtime == null:

		append_global_log(
			SOURCE_VMC,
			"VMC runtime unavailable."
		)

		return


	var host := (
		vmc_host.text.strip_edges()
		if vmc_host != null
		else
		vmc_runtime.get_vmc_host()
	)


	var port_text := (
		vmc_port.text.strip_edges()
		if vmc_port != null
		else
		str(
			vmc_runtime.get_vmc_port()
		)
	)


	if host.is_empty():

		update_source_window_status(
			"ERROR",
			"VMC host cannot be empty."
		)

		return


	if not port_text.is_valid_int():

		update_source_window_status(
			"ERROR",
			"VMC port must be a number."
		)

		return


	var port: int = int(
		port_text
	)


	if (
		port < 1
		or
		port > 65535
	):

		update_source_window_status(
			"ERROR",
			"VMC port must be between 1 and 65535."
		)

		return


	vmc_runtime.set_vmc_endpoint(
		host,
		port
	)


	if vmc_runtime.connect_vmc():

		append_global_log(
			SOURCE_VMC,
			"VMC output active | "
			+
			host
			+
			":"
			+
			str(
				port
			)
		)


		update_source_window_status(
			"CONNECTED",
			"VMC output started."
		)


	else:

		update_source_window_status(
			"ERROR",
			"Failed to start VMC output."
		)


	refresh_source_cards()

	update_global_status()


# =============================================================
# OPEN SOURCE WINDOW
# =============================================================

func open_source_window(
	source_id: String
) -> void:

	close_source_window()


	source_window_source = source_id


	source_window = Window.new()

	source_window.name = (
		"CIGAOutputSourceWindow_"
		+
		source_id
	)


	match source_id:

		SOURCE_STREAMELEMENTS:

			source_window.title = (
				"CIGA OUTPUT — STREAM ELEMENTS"
			)


		SOURCE_VMC:

			source_window.title = (
				"CIGA OUTPUT — VMC OUTPUT"
			)


		SOURCE_VTUBESTUDIO:

			source_window.title = (
				"CIGA OUTPUT — VTube Studio"
			)


		SOURCE_CIGAIS_WORKER:

			source_window.title = (
				"CIGA OUTPUT — CIGAIS Worker"
			)


		_:

			source_window.title = (
				"CIGA OUTPUT — "
				+
				source_id
			)


	source_window.size = Vector2i(
		SOURCE_WINDOW_PREFERRED_WIDTH,
		SOURCE_WINDOW_PREFERRED_HEIGHT
	)


	source_window.min_size = Vector2i(
		SOURCE_WINDOW_MIN_WIDTH,
		SOURCE_WINDOW_MIN_HEIGHT
	)


	source_window.close_requested.connect(
		close_source_window
	)


	root.add_child(
		source_window
	)


	match source_id:

		SOURCE_STREAMELEMENTS:

			build_streamelements_source_window()


		SOURCE_VMC:

			build_vmc_source_window()


		SOURCE_VTUBESTUDIO:

			build_vtube_studio_source_window()


		SOURCE_CIGAIS_WORKER:

			build_cigais_worker_source_window()


	source_window.popup_centered()


# =============================================================
# STREAM ELEMENTS WINDOW
# =============================================================

func build_streamelements_source_window() -> void:

	var margin := MarginContainer.new()

	margin.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)


	theme.set_margins(
		margin,
		16
	)


	source_window.add_child(
		margin
	)


	var main := VBoxContainer.new()

	main.add_theme_constant_override(
		"separation",
		10
	)


	margin.add_child(
		main
	)


	main.add_child(
		theme.create_title(
			"STREAM ELEMENTS"
		)
	)


	source_window_status = theme.create_status_label(
		"CIGA STATUS: "
		+
		get_source_status(
			SOURCE_STREAMELEMENTS
		)
	)


	main.add_child(
		source_window_status
	)


	main.add_child(
		theme.create_section_label(
			"CREDENTIALS"
		)
	)


	source_token_type = OptionButton.new()

	source_token_type.add_item(
		"API KEY"
	)

	source_token_type.add_item(
		"JWT TOKEN"
	)

	source_token_type.add_item(
		"OAUTH2 TOKEN"
	)


	main.add_child(
		theme.labeled_control(
			"CREDENTIAL TYPE",
			source_token_type
		)
	)


	source_token_label = Label.new()

	source_token_label.text = (
		"API KEY"
	)


	main.add_child(
		source_token_label
	)


	source_token = LineEdit.new()

	source_token.secret = true

	source_token.custom_minimum_size = Vector2(
		0.0,
		40.0
	)


	main.add_child(
		source_token
	)


	var security_warning := theme.create_status_label(
		"SECURITY NOTICE: CIGA stores this credential in the active profile. "
		+
		"Profile exports may contain the credential as well. "
		+
		"Only import or export CIGA profiles from trusted locations."
	)


	security_warning.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)


	main.add_child(
		security_warning
	)


	source_token_type.item_selected.connect(
		update_token_field
	)


	source_accept_mock = CheckBox.new()

	source_accept_mock.text = (
		"ACCEPT MOCK EVENTS"
	)


	main.add_child(
		source_accept_mock
	)


	# =========================================================
	# AUTO CONNECT
	# =========================================================

	_create_source_auto_connect_checkbox(
		main,
		SOURCE_STREAMELEMENTS
	)


	main.add_child(
		theme.create_section_label(
			"ACTIONS"
		)
	)


	source_connect_button = theme.create_button(
		"CONNECT"
	)


	source_connect_button.custom_minimum_size = Vector2(
		0.0,
		42.0
	)


	main.add_child(
		source_connect_button
	)


	source_connect_button.pressed.connect(
		_connect_window_source
	)


	source_disconnect_button = theme.create_button(
		"DISCONNECT"
	)


	source_disconnect_button.custom_minimum_size = Vector2(
		0.0,
		42.0
	)


	main.add_child(
		source_disconnect_button
	)


	source_disconnect_button.pressed.connect(
		_disconnect_window_source
	)


	var save := theme.create_button(
		"SAVE CONFIGURATION"
	)


	save.custom_minimum_size = Vector2(
		0.0,
		42.0
	)


	main.add_child(
		save
	)


	save.pressed.connect(
		_save_window_source
	)


	main.add_child(
		theme.create_section_label(
			"CIGA CONNECTION LOG"
		)
	)


	source_logs = RichTextLabel.new()

	source_logs.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)

	source_logs.bbcode_enabled = false

	source_logs.scroll_following = true


	source_logs.text = (
		"CIGA StreamElements monitor ready."
	)


	main.add_child(
		source_logs
	)


	refresh_source_window()


	load_source_window_history(
		SOURCE_STREAMELEMENTS
	)


# =============================================================
# VMC WINDOW
# =============================================================

func build_vmc_source_window() -> void:

	var scroll := ScrollContainer.new()

	scroll.name = "VMCScroll"

	scroll.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	scroll.horizontal_scroll_mode = (
		ScrollContainer.SCROLL_MODE_DISABLED
	)

	scroll.vertical_scroll_mode = (
		ScrollContainer.SCROLL_MODE_AUTO
	)

	scroll.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	scroll.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)


	source_window.add_child(
		scroll
	)


	var content := VBoxContainer.new()

	content.name = "VMCContent"

	content.custom_minimum_size = Vector2(
		0.0,
		0.0
	)

	content.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	content.add_theme_constant_override(
		"separation",
		10
	)


	scroll.add_child(
		content
	)


	var margin := MarginContainer.new()

	margin.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	margin.size_flags_vertical = (
		Control.SIZE_SHRINK_BEGIN
	)


	theme.set_margins(
		margin,
		16
	)


	content.add_child(
		margin
	)


	var main := VBoxContainer.new()

	main.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	main.add_theme_constant_override(
		"separation",
		10
	)


	margin.add_child(
		main
	)


	# =========================================================
	# TITLE
	# =========================================================

	main.add_child(
		theme.create_title(
			"VMC OUTPUT"
		)
	)


	# =========================================================
	# STATUS
	# =========================================================

	vmc_window_status = theme.create_status_label(
		"CIGA STATUS: "
		+
		get_source_status(
			SOURCE_VMC
		)
	)

	vmc_window_status.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	main.add_child(
		vmc_window_status
	)


	# =========================================================
	# SENDER
	# =========================================================

	main.add_child(
		theme.create_section_label(
			"VMC OUTPUT / SENDER"
		)
	)


	main.add_child(
		theme.create_status_label(
			"Sends VMC / OSC tracking data to external software such as VSeeFace or Warudo."
		)
	)


	vmc_host = LineEdit.new()

	vmc_host.placeholder_text = (
		"127.0.0.1"
	)


	if vmc_runtime != null:

		vmc_host.text = (
			vmc_runtime.get_vmc_host()
		)

	else:

		vmc_host.text = (
			"127.0.0.1"
		)


	vmc_host.custom_minimum_size = Vector2(
		0.0,
		40.0
	)

	vmc_host.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	main.add_child(
		theme.labeled_control(
			"DESTINATION HOST",
			vmc_host
		)
	)


	vmc_port = LineEdit.new()

	vmc_port.placeholder_text = (
		"39539"
	)


	if vmc_runtime != null:

		vmc_port.text = str(
			vmc_runtime.get_vmc_port()
		)

	else:

		vmc_port.text = (
			"39539"
		)


	vmc_port.custom_minimum_size = Vector2(
		0.0,
		40.0
	)

	vmc_port.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	main.add_child(
		theme.labeled_control(
			"DESTINATION PORT",
			vmc_port
		)
	)


	vmc_connect_button = theme.create_button(
		"CONNECT VMC OUTPUT"
	)

	vmc_connect_button.custom_minimum_size = Vector2(
		0.0,
		44.0
	)

	vmc_connect_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	main.add_child(
		vmc_connect_button
	)


	vmc_connect_button.pressed.connect(
		_connect_vmc_from_window
	)


	vmc_disconnect_button = theme.create_button(
		"DISCONNECT VMC OUTPUT"
	)

	vmc_disconnect_button.custom_minimum_size = Vector2(
		0.0,
		44.0
	)

	vmc_disconnect_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	main.add_child(
		vmc_disconnect_button
	)


	vmc_disconnect_button.pressed.connect(
		_disconnect_vmc_from_window
	)


	# =========================================================
	# SEPARATOR
	# =========================================================

	main.add_child(
		HSeparator.new()
	)


	# =========================================================
	# RECEIVER
	# =========================================================

	main.add_child(
		theme.create_section_label(
			"VMC TRACKING RECEIVER"
		)
	)


	main.add_child(
		theme.create_status_label(
			"Receives VMC / OSC tracking data from external software without sending anything back."
		)
	)


	vmc_receiver_window_status = theme.create_status_label(
		"RECEIVER: "
		+
		_get_vmc_receiver_status()
	)

	vmc_receiver_window_status.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	main.add_child(
		vmc_receiver_window_status
	)


	vmc_receiver_host = LineEdit.new()

	vmc_receiver_host.placeholder_text = (
		"127.0.0.1"
	)


	if vmc_runtime != null:

		vmc_receiver_host.text = (
			vmc_runtime.vmc_receiver_bind_host
		)

	else:

		vmc_receiver_host.text = (
			"127.0.0.1"
		)


	vmc_receiver_host.custom_minimum_size = Vector2(
		0.0,
		40.0
	)

	vmc_receiver_host.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	main.add_child(
		theme.labeled_control(
			"BIND HOST",
			vmc_receiver_host
		)
	)


	vmc_receiver_port = LineEdit.new()

	vmc_receiver_port.placeholder_text = (
		"39541"
	)


	if vmc_runtime != null:

		vmc_receiver_port.text = str(
			vmc_runtime.get_vmc_receiver_port()
		)

	else:

		vmc_receiver_port.text = (
			"39541"
		)


	vmc_receiver_port.custom_minimum_size = Vector2(
		0.0,
		40.0
	)

	vmc_receiver_port.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	main.add_child(
		theme.labeled_control(
			"RECEIVER PORT",
			vmc_receiver_port
		)
	)


	vmc_receiver_connect_button = theme.create_button(
		"CONNECT TRACKING RECEIVER"
	)

	vmc_receiver_connect_button.custom_minimum_size = Vector2(
		0.0,
		44.0
	)

	vmc_receiver_connect_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	main.add_child(
		vmc_receiver_connect_button
	)


	vmc_receiver_connect_button.pressed.connect(
		_connect_vmc_receiver_from_window
	)


	vmc_receiver_disconnect_button = theme.create_button(
		"DISCONNECT TRACKING RECEIVER"
	)

	vmc_receiver_disconnect_button.custom_minimum_size = Vector2(
		0.0,
		44.0
	)

	vmc_receiver_disconnect_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	main.add_child(
		vmc_receiver_disconnect_button
	)


	vmc_receiver_disconnect_button.pressed.connect(
		_disconnect_vmc_receiver_from_window
	)


	# =========================================================
	# VMC AUTO CONNECT
	# =========================================================

	_create_source_auto_connect_checkbox(
		main,
		SOURCE_VMC
	)


	# =========================================================
	# ENDPOINTS
	# =========================================================

	main.add_child(
		HSeparator.new()
	)


	main.add_child(
		theme.create_section_label(
			"CURRENT ENDPOINTS"
		)
	)


	var endpoint_info := theme.create_status_label(
		_get_vmc_endpoints_text()
	)

	endpoint_info.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	main.add_child(
		endpoint_info
	)


	# =========================================================
	# LOG
	# =========================================================

	main.add_child(
		theme.create_section_label(
			"VMC LOG"
		)
	)


	vmc_logs = RichTextLabel.new()

	vmc_logs.custom_minimum_size = Vector2(
		0.0,
		220.0
	)

	vmc_logs.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	vmc_logs.size_flags_vertical = (
		Control.SIZE_SHRINK_BEGIN
	)

	vmc_logs.bbcode_enabled = false

	vmc_logs.scroll_following = true

	vmc_logs.scroll_active = true


	vmc_logs.text = (
		"CIGA VMC monitor ready."
	)


	main.add_child(
		vmc_logs
	)


	load_source_window_history(
		SOURCE_VMC
	)


	update_source_window_status(
		get_source_status(
			SOURCE_VMC
		),
		"VMC window ready."
	)


# =============================================================
# VMC ENDPOINT TEXT
# =============================================================

func _get_vmc_endpoint_text() -> String:

	if vmc_runtime == null:

		return (
			"VMC ENDPOINT: UNAVAILABLE"
		)


	return (
		"VMC ENDPOINT: "
		+
		vmc_runtime.get_vmc_host()
		+
		":"
		+
		str(
			vmc_runtime.get_vmc_port()
		)
	)


# =============================================================
# VMC RECEIVER STATUS
# =============================================================

func _get_vmc_receiver_status() -> String:

	if vmc_runtime == null:

		return "UNAVAILABLE"


	if vmc_runtime.vmc_receiver_connected:

		return "CONNECTED"


	return "DISCONNECTED"


# =============================================================
# VMC ENDPOINTS TEXT
# =============================================================

func _get_vmc_endpoints_text() -> String:

	if vmc_runtime == null:

		return (
			"SENDER: UNAVAILABLE\n"
			+
			"RECEIVER: UNAVAILABLE"
		)


	return (
		"SENDER: "
		+
		vmc_runtime.get_vmc_host()
		+
		":"
		+
		str(
			vmc_runtime.get_vmc_port()
		)
		+
		"\n"
		+
		"RECEIVER: "
		+
		vmc_runtime.vmc_receiver_bind_host
		+
		":"
		+
		str(
			vmc_runtime.get_vmc_receiver_port()
		)
	)


# =============================================================
# CONNECT VMC RECEIVER FROM WINDOW
# =============================================================

func _connect_vmc_receiver_from_window() -> void:

	if vmc_runtime == null:

		return


	var host := (
		vmc_receiver_host.text.strip_edges()
		if vmc_receiver_host != null
		else
		vmc_runtime.vmc_receiver_bind_host
	)


	var port_text := (
		vmc_receiver_port.text.strip_edges()
		if vmc_receiver_port != null
		else
		str(
			vmc_runtime.get_vmc_receiver_port()
		)
	)


	if host.is_empty():

		update_source_window_status(
			"ERROR",
			"Tracking receiver host cannot be empty."
		)

		return


	if not port_text.is_valid_int():

		update_source_window_status(
			"ERROR",
			"Tracking receiver port must be a number."
		)

		return


	var port: int = int(
		port_text
	)


	if (
		port < 1
		or
		port > 65535
	):

		update_source_window_status(
			"ERROR",
			"Tracking receiver port must be between 1 and 65535."
		)

		return


	vmc_runtime.set_vmc_receiver_bind_host(
		host
	)


	vmc_runtime.set_vmc_receiver_port(
		port
	)


	if vmc_runtime.connect_vmc_receiver():

		append_global_log(
			SOURCE_VMC,
			"VMC tracking receiver active | "
			+
			host
			+
			":"
			+
			str(
				port
			)
		)


		if vmc_receiver_window_status != null:

			vmc_receiver_window_status.text = (
				"RECEIVER: CONNECTED | "
				+
				host
				+
				":"
				+
				str(
					port
				)
			)


		update_source_window_status(
			"CONNECTED",
			"VMC tracking receiver started."
		)


	else:

		if vmc_receiver_window_status != null:

			vmc_receiver_window_status.text = (
				"RECEIVER: ERROR"
			)


		update_source_window_status(
			"ERROR",
			"Failed to start VMC tracking receiver."
		)


	refresh_source_cards()

	update_global_status()


# =============================================================
# DISCONNECT VMC RECEIVER FROM WINDOW
# =============================================================

func _disconnect_vmc_receiver_from_window() -> void:

	if vmc_runtime == null:

		return


	vmc_runtime.disconnect_vmc_receiver()


	append_global_log(
		SOURCE_VMC,
		"VMC tracking receiver disconnected."
	)


	if vmc_receiver_window_status != null:

		vmc_receiver_window_status.text = (
			"RECEIVER: DISCONNECTED"
		)


	update_source_window_status(
		"DISCONNECTED",
		"VMC tracking receiver stopped."
	)


	refresh_source_cards()

	update_global_status()


# =============================================================
# CONNECT VMC FROM WINDOW
# =============================================================

func _connect_vmc_from_window() -> void:

	connect_vmc_source()


# =============================================================
# DISCONNECT VMC FROM WINDOW
# =============================================================

func _disconnect_vmc_from_window() -> void:

	if vmc_runtime == null:

		return


	vmc_runtime.disconnect_vmc()


	append_global_log(
		SOURCE_VMC,
		"VMC output disconnected."
	)


	update_source_window_status(
		"DISCONNECTED",
		"VMC output stopped."
	)


	refresh_source_cards()

	update_global_status()


# =============================================================
# VTUBE STUDIO WINDOW
# =============================================================

func build_vtube_studio_source_window() -> void:

	var margin := MarginContainer.new()

	margin.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)


	theme.set_margins(
		margin,
		16
	)


	source_window.add_child(
		margin
	)


	var main := VBoxContainer.new()

	main.add_theme_constant_override(
		"separation",
		10
	)


	margin.add_child(
		main
	)


	main.add_child(
		theme.create_title(
			"VTUBE STUDIO"
		)
	)


	vtube_window_status = theme.create_status_label(
		"CIGA STATUS: "
		+
		get_source_status(
			SOURCE_VTUBESTUDIO
		)
	)


	main.add_child(
		vtube_window_status
	)


	main.add_child(
		theme.create_status_label(
			"2D OUTPUT | VTube Studio Public API"
		)
	)


	main.add_child(
		theme.create_section_label(
			"PLUGIN IDENTITY"
		)
	)


	vtube_plugin_name = LineEdit.new()

	vtube_plugin_name.placeholder_text = (
		"CIGA Systems"
	)

	vtube_plugin_name.custom_minimum_size = Vector2(
		0.0,
		40.0
	)


	main.add_child(
		theme.labeled_control(
			"PLUGIN NAME",
			vtube_plugin_name
		)
	)


	vtube_plugin_developer = LineEdit.new()

	vtube_plugin_developer.placeholder_text = (
		"CIGA Systems"
	)

	vtube_plugin_developer.custom_minimum_size = Vector2(
		0.0,
		40.0
	)


	main.add_child(
		theme.labeled_control(
			"DEVELOPER",
			vtube_plugin_developer
		)
	)


	main.add_child(
		theme.create_section_label(
			"AUTHENTICATION"
		)
	)


	vtube_token = LineEdit.new()

	vtube_token.secret = true

	vtube_token.placeholder_text = (
		"Authentication token generated by VTube Studio"
	)

	vtube_token.custom_minimum_size = Vector2(
		0.0,
		40.0
	)


	main.add_child(
		theme.labeled_control(
			"AUTHENTICATION TOKEN",
			vtube_token
		)
	)


	vtube_enabled = CheckBox.new()

	vtube_enabled.text = (
		"ENABLE VTube Studio OUTPUT"
	)


	main.add_child(
		vtube_enabled
	)


	main.add_child(
		theme.create_status_label(
			"First connection will request authorization from VTube Studio."
		)
	)


	# =========================================================
	# AUTO CONNECT
	# =========================================================

	_create_source_auto_connect_checkbox(
		main,
		SOURCE_VTUBESTUDIO
	)


	main.add_child(
		theme.create_section_label(
			"ACTIONS"
		)
	)


	vtube_connect_button = theme.create_button(
		"CONNECT TO VTUBE STUDIO"
	)

	vtube_connect_button.custom_minimum_size = Vector2(
		0.0,
		44.0
	)


	main.add_child(
		vtube_connect_button
	)


	vtube_connect_button.pressed.connect(
		_connect_vtube_studio_from_window
	)


	vtube_disconnect_button = theme.create_button(
		"DISCONNECT"
	)

	vtube_disconnect_button.custom_minimum_size = Vector2(
		0.0,
		44.0
	)


	main.add_child(
		vtube_disconnect_button
	)


	vtube_disconnect_button.pressed.connect(
		_disconnect_vtube_studio_from_window
	)


	vtube_clear_token_button = theme.create_button(
		"CLEAR AUTHENTICATION TOKEN"
	)


	vtube_clear_token_button.custom_minimum_size = Vector2(
		0.0,
		44.0
	)


	main.add_child(
		vtube_clear_token_button
	)


	vtube_clear_token_button.pressed.connect(
		_clear_vtube_studio_token
	)


	var save := theme.create_button(
		"SAVE VTube Studio CONFIGURATION"
	)


	save.custom_minimum_size = Vector2(
		0.0,
		44.0
	)


	main.add_child(
		save
	)


	save.pressed.connect(
		_save_vtube_studio_configuration
	)


	main.add_child(
		theme.create_section_label(
			"CIGA VTUBE STUDIO LOG"
		)
	)


	vtube_logs = RichTextLabel.new()

	vtube_logs.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)

	vtube_logs.bbcode_enabled = false

	vtube_logs.scroll_following = true


	vtube_logs.text = (
		"CIGA VTube Studio monitor ready."
	)


	main.add_child(
		vtube_logs
	)


	refresh_vtube_studio_window()


	load_source_window_history(
		SOURCE_VTUBESTUDIO
	)


# =============================================================
# CIGAIS WORKER WINDOW
# =============================================================

func build_cigais_worker_source_window() -> void:

	var margin := MarginContainer.new()

	margin.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)


	theme.set_margins(
		margin,
		16
	)


	source_window.add_child(
		margin
	)


	var main := VBoxContainer.new()

	main.add_theme_constant_override(
		"separation",
		10
	)


	margin.add_child(
		main
	)


	main.add_child(
		theme.create_title(
			"CIGAIS WORKER"
		)
	)


	worker_window_status = theme.create_status_label(
		"CIGA STATUS: "
		+
		get_source_status(
			SOURCE_CIGAIS_WORKER
		)
	)


	main.add_child(
		worker_window_status
	)


	main.add_child(
		theme.create_status_label(
			"CIGAIS Worker connects CIGA Interaction Studio "
			+
			"to the CIGA Discord bot through the CIGAIS Worker."
		)
	)


	main.add_child(
		theme.create_section_label(
			"DISCORD"
		)
	)


	worker_guild_id = LineEdit.new()

	worker_guild_id.placeholder_text = (
		"Discord Guild ID"
	)

	worker_guild_id.custom_minimum_size = Vector2(
		0.0,
		40.0
	)

	worker_guild_id.clear_button_enabled = true


	main.add_child(
		theme.labeled_control(
			"DISCORD GUILD ID",
			worker_guild_id
		)
	)


	main.add_child(
		theme.create_status_label(
			"Example: 1537362988623855646"
		)
	)


	# =========================================================
	# AUTO CONNECT
	# =========================================================

	_create_source_auto_connect_checkbox(
		main,
		SOURCE_CIGAIS_WORKER
	)


	main.add_child(
		theme.create_section_label(
			"CONNECTION"
		)
	)


	worker_connect_button = theme.create_button(
		"CONNECT TO CIGAIS WORKER"
	)


	worker_connect_button.custom_minimum_size = Vector2(
		0.0,
		44.0
	)


	main.add_child(
		worker_connect_button
	)


	worker_connect_button.pressed.connect(
		_connect_cigais_worker_from_window
	)


	worker_disconnect_button = theme.create_button(
		"DISCONNECT"
	)


	worker_disconnect_button.custom_minimum_size = Vector2(
		0.0,
		44.0
	)


	main.add_child(
		worker_disconnect_button
	)


	worker_disconnect_button.pressed.connect(
		_disconnect_cigais_worker_from_window
	)


	var save := theme.create_button(
		"SAVE CONFIGURATION"
	)


	save.custom_minimum_size = Vector2(
		0.0,
		44.0
	)


	main.add_child(
		save
	)


	save.pressed.connect(
		_save_cigais_worker_configuration
	)


	main.add_child(
		theme.create_section_label(
			"CIGAIS WORKER LOG"
		)
	)


	worker_logs = RichTextLabel.new()

	worker_logs.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)

	worker_logs.bbcode_enabled = false

	worker_logs.scroll_following = true


	worker_logs.text = (
		"CIGAIS Worker monitor ready."
	)


	main.add_child(
		worker_logs
	)


	refresh_cigais_worker_window()


	load_source_window_history(
		SOURCE_CIGAIS_WORKER
	)


# =============================================================
# REFRESH CIGAIS WORKER WINDOW
# =============================================================

func refresh_cigais_worker_window() -> void:

	if source_window_source != SOURCE_CIGAIS_WORKER:

		return


	if runtime == null:

		return


	var config: Dictionary = (
		runtime.get_saved_source_config(
			SOURCE_CIGAIS_WORKER
		)
	)


	if worker_guild_id != null:

		worker_guild_id.text = str(
			config.get(
				"guild_id",
				""
			)
		)


# =============================================================
# CONNECT CIGAIS WORKER
# =============================================================

func _connect_cigais_worker_from_window() -> void:

	_save_cigais_worker_configuration()


	if runtime == null:

		return


	var config: Dictionary = (
		runtime.get_saved_source_config(
			SOURCE_CIGAIS_WORKER
		)
	)


	var guild_id: String = str(
		config.get(
			"guild_id",
			""
		)
	).strip_edges()


	if guild_id.is_empty():

		append_global_log(
			SOURCE_CIGAIS_WORKER,
			"NO ID PROVIDED | CIGAIS Worker connection skipped."
		)

		update_source_window_status(
			"DISCONNECTED",
			"NO ID PROVIDED | Configure the Discord Guild ID first."
		)

		return


	runtime.connect_source(
		SOURCE_CIGAIS_WORKER,
		false
	)

# =============================================================
# SAVE CIGAIS WORKER CONFIG
# =============================================================

func _save_cigais_worker_configuration() -> void:

	if runtime == null:

		return


	if source_window_source != SOURCE_CIGAIS_WORKER:

		return


	var config: Dictionary = (
		runtime.get_saved_source_config(
			SOURCE_CIGAIS_WORKER
		)
	)


	if worker_guild_id != null:

		config["guild_id"] = (
			worker_guild_id.text.strip_edges()
		)


	runtime.save_source_config(
		SOURCE_CIGAIS_WORKER,
		config
	)


	append_global_log(
		SOURCE_CIGAIS_WORKER,
		"Configuration saved."
	)


	update_source_window_status(
		get_source_status(
			SOURCE_CIGAIS_WORKER
		),
		"Configuration saved."
	)


# =============================================================
# DISCONNECT CIGAIS WORKER
# =============================================================

func _disconnect_cigais_worker_from_window() -> void:

	if runtime == null:

		return


	runtime.disconnect_source(
		SOURCE_CIGAIS_WORKER
	)


# =============================================================
# TOKEN
# =============================================================

func update_token_field(
	index: int
) -> void:

	if source_token == null:

		return


	match index:

		0:

			source_token_label.text = (
				"API KEY"
			)

			source_token.placeholder_text = (
				"Enter API key"
			)


		1:

			source_token_label.text = (
				"JWT TOKEN"
			)

			source_token.placeholder_text = (
				"Enter JWT token"
			)


		2:

			source_token_label.text = (
				"OAUTH2 TOKEN"
			)

			source_token.placeholder_text = (
				"Enter OAuth2 token"
			)


# =============================================================
# REFRESH STREAM ELEMENTS WINDOW
# =============================================================

func refresh_source_window() -> void:

	if source_window_source != SOURCE_STREAMELEMENTS:

		return


	var config := (
		get_source_config(
			SOURCE_STREAMELEMENTS
		)
	)


	if source_token != null:

		source_token.text = str(
			config.get(
				"token",
				""
			)
		)


	if source_token_type != null:

		var token_type := str(
			config.get(
				"token_type",
				"apikey"
			)
		)


		var index := 0


		match token_type:

			"jwt":

				index = 1


			"oauth2":

				index = 2


		source_token_type.select(
			index
		)


		update_token_field(
			index
		)


	if source_accept_mock != null:

		source_accept_mock.set_pressed_no_signal(
			bool(
				config.get(
					"accept_mock_events",
					false
				)
			)
)

# =============================================================
# REFRESH VTUBE STUDIO WINDOW
# =============================================================

func refresh_vtube_studio_window() -> void:

	if source_window_source != SOURCE_VTUBESTUDIO:

		return


	if runtime == null:

		return


	var config: Dictionary = (
		runtime.get_saved_source_config(
			SOURCE_VTUBESTUDIO
		)
	)


	if vtube_plugin_name != null:

		vtube_plugin_name.text = str(
			config.get(
				"plugin_name",
				"CIGA Systems"
			)
		)


	if vtube_plugin_developer != null:

		vtube_plugin_developer.text = str(
			config.get(
				"plugin_developer",
				"CIGA Systems"
			)
		)


	if vtube_token != null:

		vtube_token.text = str(
			config.get(
				"authentication_token",
				""
			)
		)


	if vtube_enabled != null:

		vtube_enabled.set_pressed_no_signal(
			bool(
				config.get(
					"enabled",
					false
				)
			)
		)


# =============================================================
# GET SOURCE CONFIG
# =============================================================

func get_source_config(
	source_id: String
) -> Dictionary:

	if runtime == null:

		return {}


	return runtime.get_saved_source_config(
		source_id
	)


# =============================================================
# CONNECT WINDOW SOURCE
# =============================================================

func _connect_window_source() -> void:

	_save_window_source()


	connect_source(
		source_window_source
	)


# =============================================================
# CONNECT VTUBE STUDIO
# =============================================================

func _connect_vtube_studio_from_window() -> void:

	_save_vtube_studio_configuration()


	if runtime == null:

		return


	runtime.connect_source(
		SOURCE_VTUBESTUDIO,
		true
	)


# =============================================================
# DISCONNECT WINDOW SOURCE
# =============================================================

func _disconnect_window_source() -> void:

	if source_window_source == SOURCE_STREAMELEMENTS:

		if runtime != null:

			runtime.disconnect_source(
				SOURCE_STREAMELEMENTS
			)


	elif source_window_source == SOURCE_VMC:

		_disconnect_vmc_from_window()

		_disconnect_vmc_receiver_from_window()


	elif source_window_source == SOURCE_VTUBESTUDIO:

		_disconnect_vtube_studio_from_window()


	elif source_window_source == SOURCE_CIGAIS_WORKER:

		_disconnect_cigais_worker_from_window()


# =============================================================
# DISCONNECT VTUBE STUDIO
# =============================================================

func _disconnect_vtube_studio_from_window() -> void:

	if runtime == null:

		return


	runtime.disconnect_source(
		SOURCE_VTUBESTUDIO
	)


# =============================================================
# SAVE STREAM ELEMENTS
# =============================================================

func _save_window_source() -> void:

	if (
		runtime == null
		or
		source_window_source != SOURCE_STREAMELEMENTS
		or
		source_token == null
		or
		source_token_type == null
	):

		return


	var config := (
		get_source_config(
			SOURCE_STREAMELEMENTS
		)
	)


	config["token"] = (
		source_token.text.strip_edges()
	)


	match source_token_type.selected:

		1:

			config["token_type"] = "jwt"


		2:

			config["token_type"] = "oauth2"


		_:

			config["token_type"] = "apikey"


	if source_accept_mock != null:

		config["accept_mock_events"] = (
			source_accept_mock.button_pressed
		)


	runtime.save_source_config(
		SOURCE_STREAMELEMENTS,
		config
	)


	append_global_log(
		SOURCE_STREAMELEMENTS,
		"Configuration saved."
	)


	update_source_window_status(
		get_source_status(
			SOURCE_STREAMELEMENTS
		),
		"Configuration saved."
	)


# =============================================================
# SAVE VTUBE STUDIO CONFIG
# =============================================================

func _save_vtube_studio_configuration() -> void:

	if runtime == null:

		return


	if source_window_source != SOURCE_VTUBESTUDIO:

		return


	var config: Dictionary = (
		runtime.get_saved_source_config(
			SOURCE_VTUBESTUDIO
		)
	)


	if vtube_plugin_name != null:

		config["plugin_name"] = (
			vtube_plugin_name.text.strip_edges()
		)


	if vtube_plugin_developer != null:

		config["plugin_developer"] = (
			vtube_plugin_developer.text.strip_edges()
		)


	if vtube_token != null:

		config["authentication_token"] = (
			vtube_token.text.strip_edges()
		)


	if vtube_enabled != null:

		config["enabled"] = (
			vtube_enabled.button_pressed
		)


	runtime.save_source_config(
		SOURCE_VTUBESTUDIO,
		config
	)


	append_global_log(
		SOURCE_VTUBESTUDIO,
		"Configuration saved."
	)


	update_source_window_status(
		get_source_status(
			SOURCE_VTUBESTUDIO
		),
		"Configuration saved."
	)


# =============================================================
# CLEAR VTUBE STUDIO TOKEN
# =============================================================

func _clear_vtube_studio_token() -> void:

	if runtime == null:

		return


	if runtime.has_method(
		"clear_vtube_studio_token"
	):

		runtime.clear_vtube_studio_token()


	if vtube_token != null:

		vtube_token.text = ""


	append_global_log(
		SOURCE_VTUBESTUDIO,
		"Authentication token cleared."
	)


	update_source_window_status(
		"DISCONNECTED",
		"Authentication token cleared."
	)


# =============================================================
# WINDOW STATUS
# =============================================================

func update_source_window_status(
	status_value: String,
	message: String
) -> void:

	if source_window_status != null:

		source_window_status.text = (
			"CIGA STATUS: "
			+
			status_value
			+
			" | "
			+
			message
		)


	if vmc_window_status != null:

		vmc_window_status.text = (
			"CIGA STATUS: "
			+
			status_value
			+
			" | "
			+
			message
		)


	if vtube_window_status != null:

		vtube_window_status.text = (
			"CIGA STATUS: "
			+
			status_value
			+
			" | "
			+
			message
		)


	if worker_window_status != null:

		worker_window_status.text = (
			"CIGA STATUS: "
			+
			status_value
			+
			" | "
			+
			message
		)


# =============================================================
# VMC STATUS
# =============================================================

func _on_vmc_connection_status_changed(
	status_value: String,
	message: String
) -> void:

	append_global_log(
		SOURCE_VMC,
		status_value
		+
		" | "
		+
		message
	)


	update_source_card(
		SOURCE_VMC
	)


	update_global_status()


	if (
		source_window != null
		and
		source_window_source == SOURCE_VMC
	):

		update_source_window_status(
			status_value,
			message
		)


# =============================================================
# VMC LOG
# =============================================================

func _on_vmc_log(
	level: String,
	message: String
) -> void:

	append_global_log(
		SOURCE_VMC,
		"["
		+
		level
		+
		"] "
		+
		message
	)


# =============================================================
# APPEND SOURCE WINDOW LOG
# =============================================================

func append_source_window_log(
	source_id: String,
	message: String
) -> void:

	var target: RichTextLabel = null


	if source_id == SOURCE_VTUBESTUDIO:

		target = vtube_logs


	elif source_id == SOURCE_CIGAIS_WORKER:

		target = worker_logs


	elif source_id == SOURCE_VMC:

		target = vmc_logs


	else:

		target = source_logs


	if target == null:

		return


	target.append_text(
		"["
		+
		Time.get_time_string_from_system()
		+
		"] "
		+
		message
		+
		"\n"
	)


# =============================================================
# CLOSE SOURCE WINDOW
# =============================================================

func close_source_window() -> void:

	if source_window != null:

		if is_instance_valid(
			source_window
		):

			source_window.queue_free()


	source_window = null

	source_window_source = ""


	source_token = null

	source_token_type = null

	source_token_label = null

	source_accept_mock = null

	source_connect_button = null

	source_disconnect_button = null

	source_window_status = null

	source_logs = null


	vmc_host = null

	vmc_port = null

	vmc_connect_button = null

	vmc_disconnect_button = null

	vmc_window_status = null

	vmc_logs = null


	vmc_receiver_host = null

	vmc_receiver_port = null

	vmc_receiver_connect_button = null

	vmc_receiver_disconnect_button = null

	vmc_receiver_window_status = null


	vtube_plugin_name = null

	vtube_plugin_developer = null

	vtube_token = null

	vtube_enabled = null

	vtube_connect_button = null

	vtube_disconnect_button = null

	vtube_clear_token_button = null

	vtube_window_status = null

	vtube_logs = null


	worker_guild_id = null

	worker_connect_button = null

	worker_disconnect_button = null

	worker_window_status = null

	worker_logs = null


	auto_connect_on_launch = null


# =============================================================
# LOAD SOURCE HISTORY
# =============================================================

func load_source_window_history(
	source_id: String
) -> void:

	var target: RichTextLabel = null


	if source_id == SOURCE_VTUBESTUDIO:

		target = vtube_logs


	elif source_id == SOURCE_CIGAIS_WORKER:

		target = worker_logs


	elif source_id == SOURCE_VMC:

		target = vmc_logs


	else:

		target = source_logs


	if target == null:

		return


	target.clear()


	var history_value: Variant = (
		source_log_history.get(
			source_id,
			[]
		)
	)


	if not history_value is Array:

		target.text = (
			"CIGA "
			+
			source_id
			+
			" monitor ready."
		)

		return


	var history := (
		history_value
		as
		Array
	)


	if history.is_empty():

		target.text = (
			"CIGA "
			+
			source_id
			+
			" monitor ready."
		)

		return


	for entry: Variant in history:

		target.append_text(
			str(
				entry
			)
			+
			"\n"
		)
