class_name CIGAUI
extends Control


signal application_started


# =============================================================
# CIGA CORE
#
# Controla:
# - launcher
# - configuration
# - viewport
#
# Cada ecrã tem o seu tamanho inicial.
# A janela continua redimensionável.
# A UI não é escalada globalmente.
# =============================================================


enum Screen {
	LAUNCHER,
	CONFIGURATION,
	VIEWPORT
}


enum Page {
	CHARACTER,
	OBJECTS,
	INTERACTION,
	EVENTS,
	PROFILES,
	OUTPUT,
	SETTINGS
}


var current_screen: Screen = Screen.LAUNCHER

var current_page: Page = Page.CHARACTER


var profile_manager: CIGAProfiles

var character_manager: CIGACharacters

var object_manager: CIGAObjects


var character_runtime: Node = null

var interaction_manager: CIGAinteractionManager = null

var interaction_runtime: Node = null

var output_runtime: CIGAOutput = null

var vmc_runtime: CIGAVMCRuntime = null

var events_runtime: Node = null

var viewport_runtime: CIGAViewportRuntime = null

var settings_runtime: CIGASettings = null


var ciga_theme: CIGATheme

var launcher_ui: CIGALauncher

var character_ui: CIGACharacterUI

var objects_ui: CIGAObjectsUI

var interaction_ui: CIGAInteractionUI

var events_ui: CIGAEventsUI

var profiles_ui: CIGAProfilesUI

var output_ui: CIGAOutputUI

var settings_ui: CIGASettingsUI

var viewport_ui_module: CIGAViewport


var launcher_root: Control

var configuration_root: Control

var configuration_content: Control

var viewport_root: Control


var responsive_layout: CIGAResponsiveLayout

var page_container: Control


var profile_label: Label

var window_layout_request: int = 0

# Impede a criação acidental de mais do que uma CIGAUI.
static var instance: CIGAUI = null


const LAUNCHER_WINDOW_SIZE := Vector2i(
	640,
	520
)

const CONFIGURATION_WINDOW_SIZE := Vector2i(
	1280,
	720
)

const VIEWPORT_WINDOW_SIZE := Vector2i(
	1920,
	1080
)


const LAUNCHER_MIN_SIZE := Vector2i(
	600,
	480
)

const CONFIGURATION_MIN_SIZE := Vector2i(
	960,
	540
)

const VIEWPORT_MIN_SIZE := Vector2i(
	960,
	540
)


const CIGA_LOGO_PATH: String = (
	"res://assets/ciga_logo.png"
)


# A loading precisa de acompanhar o arranque real.
const LOADING_FADE_TIME: float = 0.25


const CHARACTER_RUNTIME_SCRIPT: String = (
	"res://scripts/runtime/character_runtime.gd"
)

const INTERACTION_RUNTIME_SCRIPT: String = (
	"res://scripts/runtime/interaction_runtime.gd"
)

const VMC_RUNTIME_SCRIPT: String = (
	"res://scripts/runtime/ciga_vmc_runtime.gd"
)

const OUTPUT_RUNTIME_SCRIPT: String = (
	"res://scripts/systems/ciga_output.gd"
)

const EVENTS_RUNTIME_SCRIPT: String = (
	"res://scripts/systems/ciga_events.gd"
)


var loading_root: Control = null

var loading_panel: PanelContainer = null

var loading_logo: TextureRect = null

var loading_status: Label = null

var loading_detail: Label = null

var loading_progress: ProgressBar = null

var loading_percent: Label = null

var loading_timer: Label = null

var loading_start_time: int = 0


var corner_loading_root: Control = null

var corner_loading_panel: PanelContainer = null

var corner_loading_logo: TextureRect = null

var corner_loading_label: Label = null


# =============================================================
# ARRANQUE
# =============================================================

func _ready() -> void:

	if (
		instance != null
		and
		instance != self
	):

		queue_free()

		return


	instance = self


	set_anchors_and_offsets_preset(
		PRESET_FULL_RECT
	)

	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0

	mouse_filter = (
		MOUSE_FILTER_IGNORE
	)


	var root_window: Window = get_window()

	if root_window != null:

		root_window.content_scale_mode = (
			Window.CONTENT_SCALE_MODE_DISABLED
		)

		root_window.content_scale_factor = 1.0


	create_loading_screen()

	create_corner_loading_indicator()


	await get_tree().process_frame
	await get_tree().process_frame


	set_application_window_size(
		LAUNCHER_WINDOW_SIZE,
		LAUNCHER_MIN_SIZE
	)


	await get_tree().process_frame


	await loading_step(
		"CIGA SYSTEMS",
		"INITIALIZING CORE...",
		0.03
	)


	ciga_theme = CIGATheme.new()


	await loading_step(
		"CIGA THEME",
		"Theme engine initialized.",
		0.10
	)


	profile_manager = CIGAProfiles.new()

	profile_manager.load_profiles()


	if not profile_manager.active_profile_changed.is_connected(
		_on_profile_changed
	):

		profile_manager.active_profile_changed.connect(
			_on_profile_changed
		)


	await loading_step(
		"PROFILE MANAGER",
		"Profiles loaded.",
		0.18
	)


	settings_runtime = CIGASettings.new()

	settings_runtime.load_from_active_profile(
		profile_manager
	)


	await loading_step(
		"SETTINGS RUNTIME",
		"Global settings loaded.",
		0.22
	)


	character_manager = CIGACharacters.new()

	character_manager.initialize()


	await loading_step(
		"CHARACTER MANAGER",
		"Character library ready.",
		0.28
	)


	object_manager = CIGAObjects.new()

	object_manager.initialize()


	await loading_step(
		"OBJECT MANAGER",
		"Object library ready.",
		0.34
	)


	_create_character_runtime()


	await loading_step(
		"CHARACTER RUNTIME",
		"Character runtime ready.",
		0.40
	)


	_create_interaction_manager()


	await loading_step(
		"INTERACTION MANAGER",
		"Interaction physics ready.",
		0.46
	)


	_create_interaction_runtime()


	await loading_step(
		"INTERACTION RUNTIME",
		"Interaction runtime ready.",
		0.53
	)


	_create_viewport_runtime()


	await loading_step(
		"VIEWPORT RUNTIME",
		"3D viewport runtime created.",
		0.60
	)


	_create_output_runtime()


	await loading_step(
		"OUTPUT RUNTIME",
		"Output manager initialized.",
		0.67
	)


	_create_events_runtime()


	await loading_step(
		"EVENTS RUNTIME",
		"Event engine initialized.",
		0.73
	)


	_create_vmc_runtime()


	await loading_step(
		"VMC RUNTIME",
		"VMC bridge ready.",
		0.79
	)


	create_launcher()


	await loading_step(
		"LAUNCHER",
		"Launcher interface created.",
		0.83
	)


	create_configuration()


	await loading_step(
		"CONFIGURATION",
		"Configuration interface created.",
		0.88
	)


	create_viewport()


	await loading_step(
		"VIEWPORT",
		"Viewport interface created.",
		0.92
	)


	setup_defaults()

	apply_dark_theme()

	update_profile_label()


	# =========================================================
	# GLOBAL OBJECT PRELOAD
	# =========================================================

	await _preload_application_assets()


	await loading_step(
		"CIGA SYSTEMS",
		"Synchronizing active profile...",
		0.96
	)


	show_screen(
		Screen.LAUNCHER
	)


	await loading_step(
		"CIGA SYSTEMS",
		"SYSTEM READY.",
		1.0
	)


	await wait_for_real_ui_ready()


	application_started.emit()


	await destroy_loading_screen()


	set_corner_loading_visible(
		false
	)


	call_deferred(
		"_initialize_character_ui"
	)


# =============================================================
# LOADING
# =============================================================

func wait_for_real_ui_ready() -> void:

	if loading_root == null:

		return

	if not is_instance_valid(
		loading_root
	):

		return


	await get_tree().process_frame

	await get_tree().process_frame

	await get_tree().process_frame


func create_loading_screen() -> void:

	loading_start_time = (
		Time.get_ticks_msec()
	)


	loading_root = Control.new()

	loading_root.name = (
		"CIGALoadingScreen"
	)

	loading_root.set_anchors_and_offsets_preset(
		PRESET_FULL_RECT
	)

	loading_root.offset_left = 0.0
	loading_root.offset_top = 0.0
	loading_root.offset_right = 0.0
	loading_root.offset_bottom = 0.0

	# 4096 é o máximo válido para CanvasItem.
	loading_root.z_index = 4096

	loading_root.mouse_filter = (
		MOUSE_FILTER_STOP
	)

	add_child(
		loading_root
	)


	var background := ColorRect.new()

	background.name = "LoadingBackground"

	background.set_anchors_and_offsets_preset(
		PRESET_FULL_RECT
	)

	background.color = Color(
		0.008,
		0.008,
		0.010,
		1.0
	)

	background.mouse_filter = (
		MOUSE_FILTER_IGNORE
	)

	loading_root.add_child(
		background
	)


	var center := CenterContainer.new()

	center.set_anchors_and_offsets_preset(
		PRESET_FULL_RECT
	)

	center.mouse_filter = (
		MOUSE_FILTER_IGNORE
	)

	loading_root.add_child(
		center
	)


	var content := VBoxContainer.new()

	content.custom_minimum_size = Vector2(
		420.0,
		0.0
	)

	content.size_flags_horizontal = (
		Control.SIZE_SHRINK_CENTER
	)

	content.size_flags_vertical = (
		Control.SIZE_SHRINK_CENTER
	)

	content.add_theme_constant_override(
		"separation",
		5
	)

	content.alignment = (
		BoxContainer.ALIGNMENT_CENTER
	)

	center.add_child(
		content
	)


	loading_logo = TextureRect.new()

	loading_logo.name = "CIGALogo"

	loading_logo.custom_minimum_size = Vector2(
		220.0,
		220.0
	)

	loading_logo.size_flags_horizontal = (
		Control.SIZE_SHRINK_CENTER
	)

	loading_logo.expand_mode = (
		TextureRect.EXPAND_IGNORE_SIZE
	)

	loading_logo.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)

	loading_logo.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	var logo_texture: Texture2D = load(
		CIGA_LOGO_PATH
	)

	if logo_texture != null:

		loading_logo.texture = (
			logo_texture
		)

	content.add_child(
		loading_logo
	)


	var tagline_top := Label.new()

	tagline_top.text = (
		"ALWAYS THERE,"
	)

	tagline_top.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	tagline_top.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	tagline_top.add_theme_font_size_override(
		"font_size",
		19
	)

	tagline_top.add_theme_color_override(
		"font_color",
		Color(
			0.88,
			0.88,
			0.91,
			1.0
		)
	)

	content.add_child(
		tagline_top
	)


	var tagline_bottom := Label.new()

	tagline_bottom.text = (
		"ALWAYS WATCHING"
	)

	tagline_bottom.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	tagline_bottom.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	tagline_bottom.add_theme_font_size_override(
		"font_size",
		19
	)

	tagline_bottom.add_theme_color_override(
		"font_color",
		Color(
			0.55,
			0.55,
			0.60,
			1.0
		)
	)

	content.add_child(
		tagline_bottom
	)


	loading_status = Label.new()

	loading_status.text = (
		"INITIALIZING..."
	)

	loading_status.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	loading_status.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	loading_status.add_theme_font_size_override(
		"font_size",
		13
	)

	loading_status.add_theme_color_override(
		"font_color",
		Color(
			0.72,
			0.72,
			0.77,
			1.0
		)
	)

	content.add_child(
		loading_status
	)


	loading_detail = Label.new()

	loading_detail.text = (
		"PLEASE WAIT..."
	)

	loading_detail.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	loading_detail.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	loading_detail.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	loading_detail.add_theme_font_size_override(
		"font_size",
		11
	)

	loading_detail.add_theme_color_override(
		"font_color",
		Color(
			0.42,
			0.42,
			0.47,
			1.0
		)
	)

	content.add_child(
		loading_detail
	)


	loading_progress = ProgressBar.new()

	loading_progress.custom_minimum_size = Vector2(
		300.0,
		8.0
	)

	loading_progress.max_value = 1.0
	loading_progress.value = 0.0
	loading_progress.show_percentage = false

	loading_progress.size_flags_horizontal = (
		Control.SIZE_SHRINK_CENTER
	)

	content.add_child(
		loading_progress
	)


	loading_percent = Label.new()

	loading_percent.text = (
		"0%"
	)

	loading_percent.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	loading_percent.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	loading_percent.add_theme_font_size_override(
		"font_size",
		10
	)

	loading_percent.add_theme_color_override(
		"font_color",
		Color(
			0.35,
			0.35,
			0.40,
			1.0
		)
	)

	content.add_child(
		loading_percent
	)


	loading_timer = Label.new()

	loading_timer.text = (
		"CIGA CORE // BOOT"
	)

	loading_timer.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	loading_timer.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	loading_timer.add_theme_font_size_override(
		"font_size",
		9
	)

	loading_timer.add_theme_color_override(
		"font_color",
		Color(
			0.25,
			0.25,
			0.29,
			1.0
		)
	)

	content.add_child(
		loading_timer
	)


	loading_root.set_meta(
		"internal_note",
		"CIGA WATCHDOG // ACTIVE"
	)


func loading_step(
	status_text: String,
	detail_text: String,
	progress_value: float
) -> void:

	if loading_root == null:

		return

	if not is_instance_valid(
		loading_root
	):

		return


	loading_root.visible = true

	loading_root.z_index = 4096


	if loading_status != null:

		loading_status.text = (
			status_text
		)


	if loading_detail != null:

		loading_detail.text = (
			detail_text
		)


	var safe_progress := clampf(
		progress_value,
		0.0,
		1.0
	)


	if loading_progress != null:

		loading_progress.value = (
			safe_progress
		)


	if loading_percent != null:

		loading_percent.text = (
			str(
				int(
					round(
						safe_progress * 100.0
					)
				)
			)
			+
			"%"
		)


	if loading_timer != null:

		var elapsed := (
			float(
				Time.get_ticks_msec()
				-
				loading_start_time
			)
			/
			1000.0
		)

		loading_timer.text = (
			"CIGA CORE // BOOT // %.1fs"
			%
			elapsed
		)


	await get_tree().process_frame


func destroy_loading_screen() -> void:

	if loading_root == null:

		return

	if not is_instance_valid(
		loading_root
	):

		loading_root = null

		return


	var fade := (
		loading_root.create_tween()
	)

	fade.set_trans(
		Tween.TRANS_SINE
	)

	fade.set_ease(
		Tween.EASE_IN_OUT
	)

	fade.tween_property(
		loading_root,
		"modulate:a",
		0.0,
		LOADING_FADE_TIME
	)

	await fade.finished


	if is_instance_valid(
		loading_root
	):

		loading_root.queue_free()


	loading_root = null
	loading_panel = null
	loading_logo = null
	loading_status = null
	loading_detail = null
	loading_progress = null
	loading_percent = null
	loading_timer = null


# =============================================================
# LOADING PEQUENO
# =============================================================

func create_corner_loading_indicator() -> void:

	corner_loading_root = Control.new()

	corner_loading_root.name = (
		"CIGACornerLoading"
	)

	corner_loading_root.set_anchors_and_offsets_preset(
		PRESET_FULL_RECT
	)

	corner_loading_root.offset_left = 0.0
	corner_loading_root.offset_top = 0.0
	corner_loading_root.offset_right = 0.0
	corner_loading_root.offset_bottom = 0.0

	corner_loading_root.mouse_filter = (
		MOUSE_FILTER_IGNORE
	)

	corner_loading_root.z_index = 4095

	add_child(
		corner_loading_root
	)


	corner_loading_panel = PanelContainer.new()

	corner_loading_panel.name = (
		"CornerLoadingPanel"
	)

	corner_loading_panel.custom_minimum_size = Vector2(
		190.0,
		46.0
	)

	corner_loading_panel.position = Vector2(
		16.0,
		16.0
	)

	corner_loading_panel.mouse_filter = (
		MOUSE_FILTER_IGNORE
	)

	corner_loading_root.add_child(
		corner_loading_panel
	)


	var box := HBoxContainer.new()

	box.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	box.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)

	box.alignment = (
		BoxContainer.ALIGNMENT_CENTER
	)

	box.add_theme_constant_override(
		"separation",
		9
	)

	corner_loading_panel.add_child(
		box
	)


	corner_loading_logo = TextureRect.new()

	corner_loading_logo.name = (
		"CornerLoadingLogo"
	)

	corner_loading_logo.custom_minimum_size = Vector2(
		28.0,
		28.0
	)

	corner_loading_logo.size_flags_horizontal = (
		Control.SIZE_SHRINK_CENTER
	)

	corner_loading_logo.size_flags_vertical = (
		Control.SIZE_SHRINK_CENTER
	)

	corner_loading_logo.expand_mode = (
		TextureRect.EXPAND_IGNORE_SIZE
	)

	corner_loading_logo.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)

	corner_loading_logo.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	var logo_texture: Texture2D = load(
		CIGA_LOGO_PATH
	)


	if logo_texture != null:

		corner_loading_logo.texture = (
			logo_texture
		)


	box.add_child(
		corner_loading_logo
	)


	corner_loading_label = Label.new()

	corner_loading_label.name = (
		"CornerLoadingLabel"
	)

	corner_loading_label.text = (
		"LOADING..."
	)

	corner_loading_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	corner_loading_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_LEFT
	)

	corner_loading_label.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	corner_loading_label.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)

	corner_loading_label.add_theme_font_size_override(
		"font_size",
		10
	)

	corner_loading_label.add_theme_color_override(
		"font_color",
		CIGATheme.TEXT_DIM
	)

	corner_loading_label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	box.add_child(
		corner_loading_label
	)


	corner_loading_root.visible = false

	corner_loading_root.modulate = Color(
		1.0,
		1.0,
		1.0,
		1.0
	)


func set_corner_loading_visible(
	visible_state: bool,
	status_text: String = "LOADING..."
) -> void:

	if corner_loading_root == null:

		return


	if not is_instance_valid(
		corner_loading_root
	):

		return


	if corner_loading_label != null:

		corner_loading_label.text = (
			status_text
		)


	corner_loading_root.visible = (
		visible_state
	)


	if visible_state:

		corner_loading_root.modulate.a = 1.0


func show_real_loading(
	status_text: String = "LOADING..."
) -> void:

	set_corner_loading_visible(
		true,
		status_text
	)


	await get_tree().process_frame


func _hide_corner_loading() -> void:

	if corner_loading_root == null:

		return


	if not is_instance_valid(
		corner_loading_root
	):

		return


	await get_tree().process_frame


	set_corner_loading_visible(
		false
	)


# =============================================================
# RUNTIMES
# =============================================================

func _create_character_runtime() -> void:

	if character_runtime != null:

		if is_instance_valid(
			character_runtime
		):

			return


	var runtime_script: Script = load(
		CHARACTER_RUNTIME_SCRIPT
	)


	if runtime_script == null:

		push_error(
			"CIGA CHARACTER RUNTIME SCRIPT NOT FOUND: "
			+
			CHARACTER_RUNTIME_SCRIPT
		)

		return


	character_runtime = (
		runtime_script.new()
	)


	if character_runtime == null:

		push_error(
			"CIGA CHARACTER RUNTIME CREATION FAILED"
		)

		return


	character_runtime.name = (
		"CIGACharacterRuntime"
	)


	add_child(
		character_runtime
	)


	if character_runtime.has_signal(
		"character_loaded"
	):

		if not character_runtime.character_loaded.is_connected(
			_on_runtime_character_loaded
		):

			character_runtime.character_loaded.connect(
				_on_runtime_character_loaded
			)


func _create_interaction_manager() -> void:

	if interaction_manager != null:

		if is_instance_valid(
			interaction_manager
		):

			return


	var runtime_script: Script = load(
		"res://scripts/runtime/interaction_manager.gd"
	)


	if runtime_script == null:

		push_error(
			"CIGA INTERACTION MANAGER SCRIPT NOT FOUND"
		)

		return


	var created: Variant = (
		runtime_script.new()
	)


	if not created is CIGAinteractionManager:

		push_error(
			"CIGA INTERACTION MANAGER CREATION FAILED"
		)

		return


	interaction_manager = (
		created
		as
		CIGAinteractionManager
	)


	interaction_manager.name = (
		"CIGAInteractionManager"
	)


	add_child(
		interaction_manager
	)


	# =========================================================
	# APPLY SETTINGS IMMEDIATELY
	# =========================================================

	if settings_runtime != null:

		interaction_manager.apply_settings(
			settings_runtime
		)


	# =========================================================
	# LISTEN FOR LIVE SETTING CHANGES
	# =========================================================

	if settings_runtime != null:

		var settings_callable := Callable(
			self,
			"_on_ciga_settings_changed"
		)


		if not settings_runtime.settings_changed.is_connected(
			settings_callable
		):

			settings_runtime.settings_changed.connect(
				settings_callable
			)


func _create_interaction_runtime() -> void:

	if interaction_runtime != null:

		if is_instance_valid(
			interaction_runtime
		):

			return


	var runtime_script: Script = load(
		INTERACTION_RUNTIME_SCRIPT
	)


	if runtime_script == null:

		push_error(
			"CIGA INTERACTION RUNTIME SCRIPT NOT FOUND: "
			+
			INTERACTION_RUNTIME_SCRIPT
		)

		return


	interaction_runtime = (
		runtime_script.new()
	)


	if interaction_runtime == null:

		push_error(
			"CIGA INTERACTION RUNTIME CREATION FAILED"
		)

		return


	interaction_runtime.name = (
		"CIGAInteractionRuntime"
	)


	add_child(
		interaction_runtime
	)


	if interaction_runtime.has_method(
		"setup"
	):

		interaction_runtime.call(
			"setup",
			object_manager,
			profile_manager
		)


func _create_viewport_runtime() -> void:

	if viewport_runtime != null:

		if is_instance_valid(
			viewport_runtime
		):

			return


	var runtime_script: Script = load(
		"res://scripts/runtime/viewport_runtime.gd"
	)


	if runtime_script == null:

		push_error(
			"CIGA VIEWPORT RUNTIME SCRIPT NOT FOUND"
		)

		return


	var created: Variant = (
		runtime_script.new()
	)


	if not created is CIGAViewportRuntime:

		push_error(
			"CIGA VIEWPORT RUNTIME CREATION FAILED"
		)

		return


	viewport_runtime = (
		created
		as
		CIGAViewportRuntime
	)


	viewport_runtime.name = (
		"CIGAViewportRuntime"
	)


	add_child(
		viewport_runtime
	)


	if character_runtime != null:

		viewport_runtime.set_character_runtime(
			character_runtime
		)


	if interaction_manager != null:

		viewport_runtime.set_interaction_manager(
			interaction_manager
		)


	if object_manager != null:

		viewport_runtime.set_object_manager(
			object_manager
		)


	if profile_manager != null:

		viewport_runtime.set_profile_manager(
			profile_manager
		)


	if settings_runtime != null:

		viewport_runtime.set_settings_runtime(
			settings_runtime
		)


func _create_output_runtime() -> void:

	if output_runtime != null:

		if is_instance_valid(
			output_runtime
		):

			return


	var runtime_script: Script = load(
		OUTPUT_RUNTIME_SCRIPT
	)


	if runtime_script == null:

		push_error(
			"CIGA OUTPUT RUNTIME SCRIPT NOT FOUND: "
			+
			OUTPUT_RUNTIME_SCRIPT
		)

		return


	var created: Variant = (
		runtime_script.new()
	)


	if not created is CIGAOutput:

		push_error(
			"CIGA OUTPUT RUNTIME CREATION FAILED"
		)

		return


	output_runtime = (
		created
		as
		CIGAOutput
	)


	output_runtime.name = (
		"CIGAOutputRuntime"
	)


	add_child(
		output_runtime
	)


	output_runtime.setup(
		object_manager,
		profile_manager
	)


func _create_events_runtime() -> void:

	if events_runtime != null:

		if is_instance_valid(
			events_runtime
		):

			return


	var runtime_script: Script = load(
		EVENTS_RUNTIME_SCRIPT
	)


	if runtime_script == null:

		push_error(
			"CIGA EVENTS RUNTIME NOT FOUND: "
			+
			EVENTS_RUNTIME_SCRIPT
		)

		return


	events_runtime = (
		runtime_script.new()
	)


	if events_runtime == null:

		return


	events_runtime.name = (
		"CIGAEventsRuntime"
	)


	add_child(
		events_runtime
	)


	if events_runtime.has_method(
		"setup"
	):

		events_runtime.call(
			"setup",
			profile_manager,
			interaction_runtime
		)


	if (
		output_runtime != null
		and
		events_runtime != null
	):

		if output_runtime.has_method(
			"set_events_runtime"
		):

			output_runtime.call(
				"set_events_runtime",
				events_runtime
			)


func _create_vmc_runtime() -> void:

	if vmc_runtime != null:

		if is_instance_valid(
			vmc_runtime
		):

			return


	var runtime_script: Script = load(
		VMC_RUNTIME_SCRIPT
	)


	if runtime_script == null:

		push_error(
			"CIGA VMC RUNTIME SCRIPT NOT FOUND: "
			+
			VMC_RUNTIME_SCRIPT
		)

		return


	var created: Variant = (
		runtime_script.new()
	)


	if not created is CIGAVMCRuntime:

		push_error(
			"CIGA VMC RUNTIME CREATION FAILED"
		)

		return


	vmc_runtime = (
		created
		as
		CIGAVMCRuntime
	)


	vmc_runtime.name = (
		"CIGAVMCRuntime"
	)


	add_child(
		vmc_runtime
	)


	if vmc_runtime.has_method(
		"set_character_runtime"
	):

		vmc_runtime.call(
			"set_character_runtime",
			character_runtime
		)


	if interaction_manager != null:

		if vmc_runtime.has_method(
			"set_interaction_manager"
		):

			vmc_runtime.call(
				"set_interaction_manager",
				interaction_manager
			)


# =============================================================
# CHARACTER
# =============================================================

func _initialize_character_ui() -> void:

	if character_manager == null:

		return


	if character_ui == null:

		return


	sync_character_with_profile()

	character_ui.refresh()


	if profile_manager != null:

		if profile_manager.get_active_character_load_on_launch():

			character_ui.auto_load_if_enabled()


# =============================================================
# PROFILE
# =============================================================

func _on_profile_changed(
	_profile: Dictionary
) -> void:

	if profile_manager == null:

		return


	# =========================================================
	# SETTINGS
	# =========================================================

	if settings_runtime != null:

		settings_runtime.load_from_active_profile(
			profile_manager
		)


	if settings_ui != null:

		settings_ui.load_from_active_profile()

		settings_ui.refresh_controls()


	# =========================================================
	# CHARACTER
	# =========================================================

	sync_character_with_profile()


	var active_character := (
		character_manager.get_active_character()
	)


	if character_ui != null:

		character_ui.set_active_character_data(
			active_character
		)

		character_ui.refresh()


	if objects_ui != null:

		objects_ui.set_active_character_data(
			active_character
		)


	if interaction_ui != null:

		interaction_ui.set_active_character_data(
			active_character
		)


	# =========================================================
	# RE-APPLY SETTINGS TO INTERACTION MANAGER
	# =========================================================

	if (
		settings_runtime != null
		and
		interaction_manager != null
	):

		interaction_manager.apply_settings(
			settings_runtime
		)


	# =========================================================
	# MODULE REFRESH
	# =========================================================

	if objects_ui != null:

		objects_ui.refresh()


	if interaction_ui != null:

		interaction_ui.load_profile_configuration()

		interaction_ui.refresh()


	if profiles_ui != null:

		profiles_ui.refresh()


	if events_ui != null:

		events_ui.refresh_events()


	if output_ui != null:

		output_ui.refresh_output()


	update_profile_label()


	# =========================================================
	# PAGE
	# =========================================================

	var page_name := (
		profile_manager.get_active_last_page()
	)


	var new_page := (
		page_name_to_enum(
			page_name
		)
	)


	if current_screen == Screen.CONFIGURATION:

		open_page(
			new_page
		)

	else:

		current_page = new_page


	# =========================================================
	# CHARACTER AUTO LOAD
	# =========================================================

	if profile_manager.get_active_character_load_on_launch():

		call_deferred(
			"_try_auto_load_character"
		)


func _try_auto_load_character() -> void:

	if character_ui == null:

		return


	character_ui.auto_load_if_enabled()


# =============================================================
# PAGE CONVERSIONS
# =============================================================

func page_name_to_enum(
	page_name: String
) -> Page:

	match page_name:

		"CHARACTER":
			return Page.CHARACTER

		"OBJECTS":
			return Page.OBJECTS

		"INTERACTION":
			return Page.INTERACTION

		"EVENTS":
			return Page.EVENTS

		"PROFILES":
			return Page.PROFILES

		"OUTPUT":
			return Page.OUTPUT

		"SETTINGS":
			return Page.SETTINGS


	return Page.CHARACTER


func page_enum_to_name(
	page: Page
) -> String:

	match page:

		Page.CHARACTER:
			return "CHARACTER"

		Page.OBJECTS:
			return "OBJECTS"

		Page.INTERACTION:
			return "INTERACTION"

		Page.EVENTS:
			return "EVENTS"

		Page.PROFILES:
			return "PROFILES"

		Page.OUTPUT:
			return "OUTPUT"

		Page.SETTINGS:
			return "SETTINGS"


	return "CHARACTER"


# =============================================================
# LAUNCHER
# =============================================================

func create_launcher() -> void:

	launcher_ui = CIGALauncher.new()


	launcher_root = (
		launcher_ui.setup(
			self,
			profile_manager,
			ciga_theme
		)
	)


	if not launcher_ui.profile_opened.is_connected(
		_on_launcher_profile_opened
	):

		launcher_ui.profile_opened.connect(
			_on_launcher_profile_opened
		)


func _on_launcher_profile_opened() -> void:

	sync_character_with_profile()

	refresh_all_modules()

	update_profile_label()

	show_screen(
		Screen.CONFIGURATION
	)


# =============================================================
# CONFIGURATION
# =============================================================

func create_configuration() -> void:

	configuration_root = Control.new()

	configuration_root.name = (
		"Configuration"
	)

	configuration_root.set_anchors_and_offsets_preset(
		PRESET_FULL_RECT
	)

	configuration_root.offset_left = 0.0
	configuration_root.offset_top = 0.0
	configuration_root.offset_right = 0.0
	configuration_root.offset_bottom = 0.0

	configuration_root.visible = false

	add_child(
		configuration_root
	)


	var background := ColorRect.new()

	background.color = (
		CIGATheme.BACKGROUND
	)

	background.set_anchors_and_offsets_preset(
		PRESET_FULL_RECT
	)

	background.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	configuration_root.add_child(
		background
	)


	create_navigation()

	create_header()


	configuration_content = Control.new()

	configuration_content.name = (
		"ResponsiveContent"
	)

	configuration_content.set_anchors_preset(
		PRESET_FULL_RECT
	)

	configuration_content.offset_left = 24.0
	configuration_content.offset_right = -24.0
	configuration_content.offset_top = 170.0
	configuration_content.offset_bottom = -24.0

	configuration_content.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	configuration_root.add_child(
		configuration_content
	)


	character_ui = CIGACharacterUI.new()


	var character_root := (
		character_ui.setup(
			configuration_content,
			character_manager,
			profile_manager,
			ciga_theme,
			character_runtime
		)
	)


	character_root.name = (
		"CharacterPage"
	)


	if not character_ui.character_loaded.is_connected(
		_on_character_loaded
	):

		character_ui.character_loaded.connect(
			_on_character_loaded
	)


	objects_ui = CIGAObjectsUI.new()


	var objects_root := (
		objects_ui.setup(
			configuration_content,
			object_manager,
			ciga_theme,
			character_runtime,
			profile_manager
		)
	)


	objects_root.name = (
		"ObjectsPage"
	)


	interaction_ui = CIGAInteractionUI.new()


	var interaction_root := (
		interaction_ui.setup(
			configuration_content,
			object_manager,
			ciga_theme,
			interaction_runtime,
			character_runtime,
			profile_manager
		)
	)


	interaction_root.name = (
		"InteractionPage"
	)


	events_ui = CIGAEventsUI.new()


	var events_root := (
		events_ui.setup(
			configuration_content,
			ciga_theme,
			object_manager,
			profile_manager
		)
	)


	events_root.name = (
		"EventsPage"
	)


	profiles_ui = CIGAProfilesUI.new()


	var profiles_root := (
		profiles_ui.setup(
			configuration_content,
			profile_manager,
			ciga_theme
		)
	)


	profiles_root.name = (
		"ProfilesPage"
	)


	output_ui = CIGAOutputUI.new()


	var output_root := (
		output_ui.setup(
			configuration_content,
			ciga_theme,
			profile_manager,
			output_runtime,
			vmc_runtime
		)
	)


	output_root.name = (
		"OutputPage"
	)


	settings_ui = CIGASettingsUI.new()


	var settings_root: Control = (
		settings_ui.setup(
			configuration_content,
			ciga_theme,
			settings_runtime,
			profile_manager
		)
	)


	settings_root.name = (
		"SettingsPage"
	)


	if not settings_ui.theme_changed.is_connected(
		_on_theme_changed
	):

		settings_ui.theme_changed.connect(
			_on_theme_changed
		)


	if not character_manager.character_changed.is_connected(
		_on_character_changed
	):

		character_manager.character_changed.connect(
			_on_character_changed
		)


	if not object_manager.object_imported.is_connected(
		_on_object_changed
	):

		object_manager.object_imported.connect(
			_on_object_changed
		)


	if not object_manager.object_removed.is_connected(
		_on_object_changed
	):

		object_manager.object_removed.connect(
			_on_object_changed
		)


	if not object_manager.active_object_changed.is_connected(
		_on_object_changed
	):

		object_manager.active_object_changed.connect(
			_on_object_changed
	)


	var pages: Dictionary = {

		"CHARACTER":
			character_root,

		"OBJECTS":
			objects_root,

		"INTERACTION":
			interaction_root,

		"EVENTS":
			events_root,

		"PROFILES":
			profiles_root,

		"OUTPUT":
			output_root,

		"SETTINGS":
			settings_root
	}


	responsive_layout = CIGAResponsiveLayout.new()


	page_container = (
		responsive_layout.setup(
			configuration_root,
			pages
		)
	)


	if interaction_ui != null:

		interaction_ui.register_responsive_layout(
			responsive_layout
		)


	call_deferred(
		"set_initial_responsive_page"
	)


func _on_character_loaded(
	character_data: Dictionary
) -> void:

	if interaction_ui != null:

		interaction_ui.set_active_character_data(
			character_data
		)


	if objects_ui != null:

		objects_ui.set_active_character_data(
			character_data
		)


func set_initial_responsive_page() -> void:

	if responsive_layout == null:

		return


	responsive_layout.show_page(
		"CHARACTER"
	)


# =============================================================
# NAVIGATION
# =============================================================

func create_navigation() -> void:

	var panel := PanelContainer.new()

	panel.name = (
		"TopNavigation"
	)

	panel.set_anchors_preset(
		PRESET_TOP_WIDE
	)

	panel.offset_left = 24.0
	panel.offset_right = -24.0
	panel.offset_top = 20.0
	panel.offset_bottom = 76.0

	panel.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	ciga_theme.style_panel(
		panel
	)

	configuration_root.add_child(
		panel
	)


	var box := HBoxContainer.new()

	box.set_anchors_and_offsets_preset(
		PRESET_FULL_RECT
	)

	box.add_theme_constant_override(
		"separation",
		2
	)

	panel.add_child(
		box
	)


	add_nav_button(
		box,
		"CHARACTER",
		Page.CHARACTER
	)


	add_nav_button(
		box,
		"OBJECTS",
		Page.OBJECTS
	)


	add_nav_button(
		box,
		"INTERACTION",
		Page.INTERACTION
	)


	add_nav_button(
		box,
		"EVENTS",
		Page.EVENTS
	)


	add_nav_button(
		box,
		"PROFILES",
		Page.PROFILES
	)


	add_nav_button(
		box,
		"OUTPUT",
		Page.OUTPUT
	)


	add_nav_button(
		box,
		"SETTINGS",
		Page.SETTINGS
	)


	var viewport_button := ciga_theme.create_button(
		"VIEWPORT"
	)


	viewport_button.custom_minimum_size = Vector2(
		115.0,
		42.0
	)


	viewport_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	box.add_child(
		viewport_button
	)


	viewport_button.pressed.connect(
		func() -> void:

			show_screen(
				Screen.VIEWPORT
			)
	)


func add_nav_button(
	parent: HBoxContainer,
	text_value: String,
	page: Page
) -> void:

	var button := ciga_theme.create_button(
		text_value
	)


	button.custom_minimum_size = Vector2(
		115.0,
		42.0
	)


	button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	parent.add_child(
		button
	)


	button.pressed.connect(
		func() -> void:

			open_page(
				page
			)
	)


# =============================================================
# HEADER
# =============================================================

func create_header() -> void:

	var panel := PanelContainer.new()

	panel.name = (
		"ConfigurationHeader"
	)

	panel.set_anchors_preset(
		PRESET_TOP_WIDE
	)

	panel.offset_left = 24.0
	panel.offset_right = -24.0
	panel.offset_top = 90.0
	panel.offset_bottom = 148.0

	panel.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	ciga_theme.style_panel(
		panel
	)

	configuration_root.add_child(
		panel
	)


	var box := HBoxContainer.new()

	box.set_anchors_and_offsets_preset(
		PRESET_FULL_RECT
	)

	box.add_theme_constant_override(
		"separation",
		10
	)

	panel.add_child(
		box
	)


	var title := ciga_theme.create_title(
		"CONFIGURATION"
	)


	title.custom_minimum_size = Vector2(
		210.0,
		40.0
	)


	title.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)


	box.add_child(
		title
	)


	var spacer := Control.new()

	spacer.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	box.add_child(
		spacer
	)


	profile_label = Label.new()


	profile_label.text = (
		"PROFILE: NONE"
	)


	profile_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)


	box.add_child(
		profile_label
	)


	var back_button := ciga_theme.create_button(
		"BACK"
	)


	back_button.custom_minimum_size = Vector2(
		100.0,
		40.0
	)


	box.add_child(
		back_button
	)


	back_button.pressed.connect(
		func() -> void:

			show_screen(
				Screen.LAUNCHER
			)
	)


	var leave_button := ciga_theme.create_button(
		"LEAVE APP"
	)


	leave_button.custom_minimum_size = Vector2(
		120.0,
		40.0
	)


	box.add_child(
		leave_button
	)


	leave_button.pressed.connect(
		_leave_application
	)


func _leave_application() -> void:

	get_tree().quit()


# =============================================================
# VIEWPORT
# =============================================================

func create_viewport() -> void:

	viewport_ui_module = (
		CIGAViewport.new()
	)


	viewport_root = (
		viewport_ui_module.setup(
			self,
			ciga_theme
		)
	)


	if viewport_runtime != null:

		viewport_ui_module.set_runtime(
			viewport_runtime
		)


	if not viewport_ui_module.back_to_configuration.is_connected(
		_on_viewport_back
	):

		viewport_ui_module.back_to_configuration.connect(
			_on_viewport_back
		)


# =============================================================
# SHOW SCREEN
# =============================================================

func show_screen(
	screen: Screen
) -> void:

	var previous_screen := (
		current_screen
	)


	current_screen = screen

	window_layout_request += 1

	var current_request: int = (
		window_layout_request
	)


	# =========================================================
	# LEAVING VIEWPORT
	#
	# O Viewport pode estar fullscreen.
	# Launcher e Configuration devem ser sempre windowed.
	# =========================================================

	if (
		screen == Screen.LAUNCHER
		or
		screen == Screen.CONFIGURATION
	):

		var current_mode := (
			DisplayServer.window_get_mode()
		)


		if current_mode != DisplayServer.WINDOW_MODE_WINDOWED:

			DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_WINDOWED
			)


		DisplayServer.window_set_flag(
			DisplayServer.WINDOW_FLAG_BORDERLESS,
			false
		)


	# =========================================================
	# LOADING INDICATOR
	# =========================================================

	if (
		loading_root == null
		or
		not is_instance_valid(
			loading_root
		)
	):

		set_corner_loading_visible(
			true,
			"SWITCHING..."
		)


	# =========================================================
	# VISIBILITY
	# =========================================================

	if launcher_root != null:

		launcher_root.visible = (
			screen == Screen.LAUNCHER
		)


	if configuration_root != null:

		configuration_root.visible = (
			screen == Screen.CONFIGURATION
		)


	if viewport_root != null:

		viewport_root.visible = (
			screen == Screen.VIEWPORT
		)


	# =========================================================
	# SCREEN SPECIFIC LOGIC
	# =========================================================

	match screen:

		Screen.CONFIGURATION:

			open_page(
				current_page
			)

			update_profile_label()


		Screen.VIEWPORT:

			if viewport_ui_module != null:

				viewport_ui_module.on_viewport_activated()

				viewport_ui_module.update_camera()


	# =========================================================
	# WINDOW LAYOUT
	#
	# Não fazemos resize/position imediatamente.
	# Damos tempo ao Godot/Windows para terminar qualquer
	# mudança de monitor ou fullscreen -> windowed.
	# =========================================================

	call_deferred(
		"_apply_screen_window_layout",
		screen,
		current_request
	)


	call_deferred(
		"_hide_corner_loading"
	)


# =============================================================
# PAGE
# =============================================================

func open_page(
	page: Page
) -> void:

	current_page = page


	if profile_manager != null:

		profile_manager.set_active_last_page(
			page_enum_to_name(
				page
			)
		)


	if responsive_layout != null:

		responsive_layout.show_page(
			page_enum_to_name(
				page
			)
		)


	if objects_ui != null:

		objects_ui.set_preview_active(
			page == Page.OBJECTS
		)


	if interaction_ui != null:

		interaction_ui.set_preview_active(
			page == Page.INTERACTION
		)


	if loading_root == null:

		set_corner_loading_visible(
			true,
			"LOADING "
			+
			page_enum_to_name(
				page
			)
		)


	match page:

		Page.CHARACTER:

			if character_ui != null:

				sync_character_with_profile()

				character_ui.refresh()


		Page.OBJECTS:

			if objects_ui != null:

				objects_ui.refresh()


		Page.INTERACTION:

			if interaction_ui != null:

				interaction_ui.load_profile_configuration()

				interaction_ui.refresh()

				interaction_ui.load_active_character_into_preview()


		Page.EVENTS:

			if events_ui != null:

				events_ui.refresh_events()


		Page.PROFILES:

			if profiles_ui != null:

				profiles_ui.refresh()


		Page.OUTPUT:

			if output_ui != null:

				output_ui.refresh_output()


		Page.SETTINGS:

			if settings_runtime != null:

				settings_runtime.load_from_active_profile(
					profile_manager
				)


			if settings_ui != null:

				settings_ui.load_from_active_profile()

				settings_ui.refresh_controls()


	call_deferred(
		"_hide_corner_loading"
	)


# =============================================================
# DEFAULTS
# =============================================================

func setup_defaults() -> void:

	if launcher_ui != null:

		launcher_ui.refresh_profiles()


	if profiles_ui != null:

		profiles_ui.refresh()


	if character_ui != null:

		character_ui.refresh()


	if objects_ui != null:

		objects_ui.refresh()


	if interaction_ui != null:

		interaction_ui.load_profile_configuration()

		interaction_ui.refresh()


	if events_ui != null:

		events_ui.refresh_events()


	if settings_runtime != null:

		settings_runtime.load_from_active_profile(
			profile_manager
		)


	if settings_ui != null:

		settings_ui.load_from_active_profile()

		settings_ui.refresh_controls()


	if viewport_ui_module != null:

		viewport_ui_module.reset_camera()


# =============================================================
# REFRESH
# =============================================================

func refresh_all_modules() -> void:

	if launcher_ui != null:

		launcher_ui.refresh_profiles()


	if character_ui != null:

		character_ui.refresh()


	if objects_ui != null:

		objects_ui.refresh()


	if interaction_ui != null:

		interaction_ui.load_profile_configuration()

		interaction_ui.refresh()


	if events_ui != null:

		events_ui.refresh_events()


	if profiles_ui != null:

		profiles_ui.refresh()


	if settings_runtime != null:

		settings_runtime.load_from_active_profile(
			profile_manager
		)


	if settings_ui != null:

		settings_ui.load_from_active_profile()

		settings_ui.refresh_controls()


	var active_character := (
		character_manager.get_active_character()
	)


	if interaction_ui != null:

		interaction_ui.set_active_character_data(
			active_character
		)


	if objects_ui != null:

		objects_ui.set_active_character_data(
			active_character
		)


	if interaction_manager != null:

		interaction_manager.apply_settings(
			settings_runtime
		)


	update_profile_label()


# =============================================================
# CHARACTER SYNC
# =============================================================

func sync_character_with_profile() -> void:

	if profile_manager == null:

		return


	if character_manager == null:

		return


	var profile := (
		profile_manager.get_active_profile()
	)


	if profile.is_empty():

		character_manager.set_active_character(
			""
		)

		return


	var character_id := str(
		profile.get(
			"character_id",
			""
		)
	)


	if character_id.is_empty():

		if character_manager.characters.size() == 1:

			var character := (
				character_manager.characters[0]
			)


			var automatic_id := str(
				character.get(
					"id",
					""
				)
			)


			if not automatic_id.is_empty():

				character_manager.set_active_character(
					automatic_id
				)


				profile["character_id"] = (
					automatic_id
				)


				profile_manager.save_profiles()

				return


		character_manager.set_active_character(
			""
		)

		return


	for character: Dictionary in (
		character_manager.characters
	):

		if str(
			character.get(
				"id",
				""
			)
		) != character_id:

			continue


		character_manager.set_active_character(
			character_id
		)

		return


	profile["character_id"] = ""

	profile_manager.save_profiles()

	character_manager.set_active_character(
		""
	)


# =============================================================
# SIGNALS
# =============================================================

func _on_character_changed(
	character: Dictionary
) -> void:

	if character_ui != null:

		character_ui.refresh()


	if objects_ui != null:

		objects_ui.set_active_character_data(
			character
		)


	if interaction_ui != null:

		interaction_ui.set_active_character_data(
			character
		)


func _on_object_changed(
	_data: Dictionary = {}
) -> void:

	if objects_ui != null:

		objects_ui.refresh()


	if interaction_ui != null:

		interaction_ui.refresh()


# =============================================================
# PROFILE LABEL
# =============================================================

func update_profile_label() -> void:

	if profile_label == null:

		return


	if profile_manager == null:

		return


	var profile := (
		profile_manager.get_active_profile()
	)


	if profile.is_empty():

		profile_label.text = (
			"PROFILE: NONE"
		)

		return


	profile_label.text = (
		"PROFILE: "
		+
		str(
			profile.get(
				"name",
				"PROFILE"
			)
		)
	)

func _apply_screen_window_layout(
	screen: Screen,
	request_id: int
) -> void:

	# =========================================================
	# REQUEST VALIDATION
	#
	# Se entretanto outro ecrã foi aberto, esta operação ficou
	# obsoleta e não deve mexer na janela.
	# =========================================================

	if request_id != window_layout_request:

		return


	# =========================================================
	# WAIT FOR WINDOW STATE
	#
	# Especialmente importante para:
	#
	# - fullscreen -> windowed
	# - mudança de monitor
	# - launcher fullscreen -> configuration
	# =========================================================

	await get_tree().process_frame
	await get_tree().process_frame


	if request_id != window_layout_request:

		return


	var window := get_window()


	if window == null:

		return


	# =========================================================
	# VIEWPORT
	#
	# Se o Viewport já estiver fullscreen, não tentamos
	# redimensionar/reposicionar a janela.
	# =========================================================

	if screen == Screen.VIEWPORT:

		var current_mode := (
			DisplayServer.window_get_mode()
		)


		if (
			current_mode
			==
			DisplayServer.WINDOW_MODE_FULLSCREEN
		):

			return


	# =========================================================
	# TARGET SIZE
	# =========================================================

	match screen:

		Screen.LAUNCHER:

			set_application_window_size(
				LAUNCHER_WINDOW_SIZE,
				LAUNCHER_MIN_SIZE
			)


		Screen.CONFIGURATION:

			set_application_window_size(
				CONFIGURATION_WINDOW_SIZE,
				CONFIGURATION_MIN_SIZE
			)


		Screen.VIEWPORT:

			set_application_window_size(
				VIEWPORT_WINDOW_SIZE,
				VIEWPORT_MIN_SIZE
			)
func set_application_window_size(
	window_size: Vector2i,
	window_min_size: Vector2i
) -> void:

	var window := get_window()


	if window == null:

		return


	# =========================================================
	# CURRENT MONITOR
	#
	# Só obtemos isto depois da transição de janela ter sido
	# processada pelos frames anteriores.
	# =========================================================

	var screen := (
		DisplayServer.window_get_current_screen()
	)


	var usable_rect := (
		DisplayServer.screen_get_usable_rect(
			screen
		)
	)


	if usable_rect.size.x <= 0:

		return


	if usable_rect.size.y <= 0:

		return


	# =========================================================
	# SAFE SIZE
	# =========================================================

	var safe_width: int = maxi(
		usable_rect.size.x - 24,
		1
	)


	var safe_height: int = maxi(
		usable_rect.size.y - 24,
		1
	)


	var final_width: int = mini(
		window_size.x,
		safe_width
	)


	var final_height: int = mini(
		window_size.y,
		safe_height
	)


	var minimum_width: int = mini(
		window_min_size.x,
		safe_width
	)


	var minimum_height: int = mini(
		window_min_size.y,
		safe_height
	)


	final_width = maxi(
		final_width,
		minimum_width
	)


	final_height = maxi(
		final_height,
		minimum_height
	)


	final_width = mini(
		final_width,
		safe_width
	)


	final_height = mini(
		final_height,
		safe_height
	)


	var final_size := Vector2i(
		final_width,
		final_height
	)


	# =========================================================
	# MINIMUM SIZE
	# =========================================================

	window.min_size = Vector2i(
		minimum_width,
		minimum_height
	)


	# =========================================================
	# RESIZE FIRST
	#
	# NÃO fazemos position imediatamente a seguir.
	# O Windows/Godot pode precisar de um frame para aplicar
	# o novo tamanho.
	# =========================================================

	window.size = final_size


	await get_tree().process_frame


	# =========================================================
	# RECALCULATE MONITOR
	#
	# O monitor pode ter mudado entretanto.
	# Isto é particularmente importante depois de:
	#
	# - mover Viewport para outro monitor
	# - sair de fullscreen
	# =========================================================

	var final_screen := (
		DisplayServer.window_get_current_screen()
	)


	var final_usable_rect := (
		DisplayServer.screen_get_usable_rect(
			final_screen
		)
	)


	var final_position := Vector2i(
		final_usable_rect.position.x
		+
		(
			final_usable_rect.size.x
			-
			final_size.x
		)
		/
		2.0,

		final_usable_rect.position.y
		+
		(
			final_usable_rect.size.y
			-
			final_size.y
		)
		/
		2.0
	)


	# =========================================================
	# POSITION LAST
	# =========================================================

	window.position = final_position


	await get_tree().process_frame


	# =========================================================
	# FINAL RESPONSIVE REFRESH
	# =========================================================

	if responsive_layout != null:

		responsive_layout.force_refresh()


	if events_ui != null:

		events_ui.call_deferred(
			"_update_responsive_layout"
		)


	if profiles_ui != null:

		if profiles_ui.root != null:

			profiles_ui.root.queue_redraw()


func _refresh_window_layout() -> void:

	if not is_inside_tree():

		return


	await get_tree().process_frame


	if responsive_layout != null:

		responsive_layout.force_refresh()


	if events_ui != null:

		events_ui.call_deferred(
			"_update_responsive_layout"
		)


	if profiles_ui != null:

		if profiles_ui.root != null:

			profiles_ui.root.queue_redraw()


# =============================================================
# THEME
# =============================================================

func _on_theme_changed() -> void:

	if ciga_theme == null:

		return


	ciga_theme.apply_dark(
		self
	)


func apply_dark_theme() -> void:

	if ciga_theme == null:

		return


	ciga_theme.apply_dark(
		self
	)


# =============================================================
# EVENT BRIDGE
# =============================================================

func _on_output_event_received(
	_source_id: String,
	event_name: String,
	payload: Dictionary
) -> void:

	if events_runtime == null:

		return


	if events_runtime.has_method(
		"receive_event"
	):

		events_runtime.call(
			"receive_event",
			event_name,
			payload
		)


# =============================================================
# CHARACTER RUNTIME
# =============================================================

func _on_runtime_character_loaded(
	character: Node3D
) -> void:

	if interaction_manager == null:

		return


	interaction_manager.set_character(
		character
	)


# =============================================================
# VIEWPORT BACK
# =============================================================

func _on_viewport_back() -> void:

	show_screen(
		Screen.CONFIGURATION
	)


	call_deferred(
		"_refresh_window_layout"
	)


# =============================================================
# CIGA SETTINGS -> INTERACTION MANAGER
#
# Aqui é feita a ponte em tempo real:
#
# CIGASettings
#     ↓
# settings_changed
#     ↓
# CIGAUI
#     ↓
# CIGAinteractionManager
# =============================================================

func _on_ciga_settings_changed(
	key: String,
	value: Variant
) -> void:

	if interaction_manager == null:

		return


	match key:

		# =====================================================
		# DEFAULT FORCE
		# =====================================================

		CIGASettings.KEY_DEFAULT_FORCE:

			interaction_manager.set_object_force(
				float(value)
			)


		# =====================================================
		# DEFAULT SPEED
		# =====================================================

		CIGASettings.KEY_DEFAULT_SPEED:

			interaction_manager.set_object_speed(
				float(value)
			)


		# =====================================================
		# IMPACT MOVEMENT
		# =====================================================

		CIGASettings.KEY_IMPACT_MOVEMENT:

			interaction_manager.set_impact_movement(
				float(value)
			)


		# =====================================================
		# REALISTIC MODE
		# =====================================================

		CIGASettings.KEY_REALISTIC_MODE:

			interaction_manager.set_realistic_mode(
				bool(value)
			)


# =============================================================
# APPLICATION BOOT PRELOAD
# =============================================================

func _preload_application_assets() -> void:

	if object_manager == null:

		return


	var total_objects: int = (
		object_manager.objects.size()
	)


	if viewport_runtime != null:

		await loading_step(
			"VIEWPORT RUNTIME",
			"Initializing 3D viewport...",
			0.12
		)


		viewport_runtime.initialize_runtime()


	await get_tree().process_frame


	# =========================================================
	# PHASE 1
	# PREPARAR CACHE OPTIMIZADO
	# =========================================================

	await loading_step(
		"OBJECT CACHE",
		"Preparing optimized object cache...",
		0.20
	)


	if total_objects > 0:

		for index in range(
			total_objects
		):

			var object_data: Dictionary = (
				object_manager.objects[index]
			)


			var object_id: String = str(
				object_data.get(
					"id",
					""
				)
			)


			var object_name: String = str(
				object_data.get(
					"name",
					object_id
				)
			)


			if object_id.is_empty():

				continue


			var progress: float = (
				0.20
				+
				(
					float(index)
					/
					float(total_objects)
				)
				*
				0.25
			)


			await loading_step(
				"OBJECT CACHE",
				"Preparing "
				+
				object_name
				+
				"...",
				progress
			)


			var prepare_result: Dictionary = (
				object_manager.prepare_object_for_startup(
					object_id
				)
			)


			await get_tree().process_frame


	# =========================================================
	# PHASE 2
	# CARREGAR PACKEDSCENES PARA RAM
	# =========================================================

	await loading_step(
		"OBJECT RESOURCE CACHE",
		"Loading object resources into memory...",
		0.48
	)


	if total_objects > 0:

		for index in range(
			total_objects
		):

			var object_data: Dictionary = (
				object_manager.objects[index]
			)


			var object_id: String = str(
				object_data.get(
					"id",
					""
				)
			)


			var object_name: String = str(
				object_data.get(
					"name",
					object_id
				)
			)


			if object_id.is_empty():

				continue


			var progress: float = (
				0.48
				+
				(
					float(index)
					/
					float(total_objects)
				)
				*
				0.20
			)


			await loading_step(
				"OBJECT RESOURCE CACHE",
				"Loading "
				+
				object_name
				+
				"...",
				progress
			)


			var packed_scene: PackedScene = (
				object_manager.get_cached_packed_scene(
					object_id
				)
			)


			await get_tree().process_frame


	# =========================================================
	# PHASE 3
	# OBJECTS PREVIEW
	# =========================================================

	await loading_step(
		"OBJECT PREVIEW",
		"Preparing object preview system...",
		0.70
	)


	if objects_ui != null:

		if objects_ui.preview != null:

			if objects_ui.preview.has_method(
				"set_object_manager"
			):

				objects_ui.preview.set_object_manager(
					object_manager
				)


			if objects_ui.preview.has_method(
				"set_active"
			):

				objects_ui.preview.set_active(
					false
				)


	await get_tree().process_frame


	# =========================================================
	# PHASE 4
	# INTERACTION PREVIEW
	# =========================================================

	await loading_step(
		"INTERACTION PREVIEW",
		"Preparing interaction preview system...",
		0.78
	)


	if interaction_ui != null:

		if interaction_ui.preview != null:

			if interaction_ui.preview.has_method(
				"set_object_manager"
			):

				interaction_ui.preview.set_object_manager(
					object_manager
				)


			if interaction_ui.preview.has_method(
				"set_active"
			):

				interaction_ui.preview.set_active(
					false
				)


	await get_tree().process_frame


	# =========================================================
	# PHASE 5
	# VIEWPORT RUNTIME
	# =========================================================

	await loading_step(
		"VIEWPORT RUNTIME",
		"Connecting viewport to object resource cache...",
		0.84
	)


	if viewport_runtime != null:

		if viewport_runtime.has_method(
			"preload_object_library"
		):

			viewport_runtime.preload_object_library()


	await get_tree().process_frame


	# =========================================================
	# COMPLETE
	# =========================================================

	await loading_step(
		"CIGA SYSTEMS",
		"Object resources and previews ready.",
		0.94
	)


	await get_tree().process_frame
