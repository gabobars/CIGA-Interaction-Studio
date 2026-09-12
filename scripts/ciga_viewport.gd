class_name CIGAViewport
extends RefCounted


# =============================================================
# CIGA VIEWPORT
#
# Responsável por:
#
# - viewport 3D
# - camera
# - avatar
# - UI
# - display
# - notifications
# - calibração do avatar nativo
#
# IMPORTANTE:
#
# O teclado é tratado EXCLUSIVAMENTE pelo
# CIGAViewportRuntime.
#
# =============================================================


# =============================================================
# REFERENCES
# =============================================================

var root: Control = null
var viewport_ui: Control = null

var viewport_container: SubViewportContainer = null
var scene_viewport: SubViewport = null

var workspace: Node3D = null
var camera: Camera3D = null

var character_root: Node3D = null
var visual_character: Node3D = null

var runtime: CIGAViewportRuntime = null
var theme: CIGATheme = null

var background: ColorRect = null


# =============================================================
# UI
# =============================================================

var controls_scroll: ScrollContainer = null
var controls_panel: PanelContainer = null

var display_scroll: ScrollContainer = null
var display_panel: PanelContainer = null

var notification_label: Label = null


# =============================================================
# CAMERA UI
# =============================================================

var camera_preset: OptionButton = null

var camera_x: SpinBox = null
var camera_y: SpinBox = null
var camera_z: SpinBox = null
var camera_fov: SpinBox = null

var orientation_button: Button = null


# =============================================================
# NATIVE AVATAR CALIBRATION
# =============================================================

var calibration_section_label: Label = null

var avatar_body_scale: SpinBox = null
var avatar_body_width: SpinBox = null
var avatar_shoulder_width: SpinBox = null

var avatar_arm_length: SpinBox = null
var avatar_leg_length: SpinBox = null

var avatar_head_scale: SpinBox = null

var avatar_head_rot_x: SpinBox = null
var avatar_head_rot_y: SpinBox = null
var avatar_head_rot_z: SpinBox = null

var avatar_left_arm: SpinBox = null
var avatar_right_arm: SpinBox = null

var avatar_left_eye: SpinBox = null
var avatar_right_eye: SpinBox = null

var avatar_mouth: SpinBox = null

var avatar_tail_check: CheckBox = null
var avatar_tail_length: SpinBox = null

var avatar_reset_button: Button = null
var avatar_save_button: Button = null

var avatar_calibration_container: VBoxContainer = null

var native_avatar_controls_enabled: bool = false


# =============================================================
# SPAWNS
# =============================================================

var spawn_left_top_check: CheckBox = null
var spawn_left_bottom_check: CheckBox = null

var spawn_right_top_check: CheckBox = null
var spawn_right_bottom_check: CheckBox = null

var spawn_top_center_check: CheckBox = null
var spawn_bottom_center_check: CheckBox = null

var edge_spawn_status: Label = null
var runtime_status: Label = null


# =============================================================
# STREAMER
# =============================================================

var streamer_button: Button = null
var streamer_status: Label = null

var streamer_mode_enabled: bool = false


# =============================================================
# DISPLAY
# =============================================================

var display_mode_selector: OptionButton = null
var resolution_selector: OptionButton = null


# =============================================================
# HOTKEY HELP
# =============================================================

var hotkey_help_label: Label = null


# =============================================================
# CAMERA STATE
# =============================================================

var camera_flipped: bool = false


# =============================================================
# UI CALIBRATION
# =============================================================

var ui_camera_active: bool = false
var ui_test_object_active: bool = false

const UI_CALIBRATION_ALPHA: float = 0.28
const UI_NORMAL_ALPHA: float = 1.0

const UI_TEST_OBJECT_FEEDBACK_TIME: float = 0.35

var ui_test_object_serial: int = 0


# =============================================================
# CAMERA SPEED
# =============================================================

const CAMERA_MOVE_SPEED: float = 0.24
const CAMERA_ZOOM_SPEED: float = 0.90


# =============================================================
# NOTIFICATION
# =============================================================

const NOTIFICATION_SHOW_TIME: float = 1.20
const NOTIFICATION_ANIMATION_TIME: float = 0.28


# =============================================================
# DISPLAY
# =============================================================

const DISPLAY_WINDOWED: int = 0
const DISPLAY_BORDERLESS: int = 1
const DISPLAY_FULLSCREEN: int = 2


# =============================================================
# RESOLUTION
# =============================================================

const RESOLUTION_1280: int = 0
const RESOLUTION_1600: int = 1
const RESOLUTION_1920: int = 2


# =============================================================
# SIGNALS
# =============================================================

signal back_to_configuration
signal viewport_ready

signal streamer_mode_changed(
	enabled: bool
)


# =============================================================
# SETUP
# =============================================================

func setup(
	parent: Control,
	ui_theme: CIGATheme,
	viewport_runtime: CIGAViewportRuntime = null
) -> Control:

	theme = ui_theme

	runtime = viewport_runtime


	root = Control.new()

	root.name = "Viewport"

	root.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	root.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	root.visible = false

	parent.add_child(
		root
	)


	build()


	call_deferred(
		"_finish_setup"
	)


	return root


# =============================================================
# FINISH SETUP
# =============================================================

func _finish_setup() -> void:

	if root == null:

		return


	if camera != null:

		update_camera()


	update_runtime_status()

	refresh_edge_checkboxes()

	_reset_ui_interaction_state()

	refresh_native_avatar_controls()

	viewport_ready.emit()


# =============================================================
# BUILD
# =============================================================

func build() -> void:

	if root == null:

		return


	background = ColorRect.new()

	background.name = (
		"ViewportBackground"
	)

	background.color = Color(
		"#252A32"
	)

	background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	background.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	root.add_child(
		background
	)


	viewport_container = (
		SubViewportContainer.new()
	)

	viewport_container.name = (
		"MainViewport"
	)

	viewport_container.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	# =========================================================
	# IMPORTANT
	#
	# O SubViewport tem uma resolução interna própria
	# (1280x720 / 1600x900 / 1920x1080), mas o container
	# deve preencher toda a janela.
	#
	# Isto é particularmente importante em monitores 4K
	# e quando a janela entra em fullscreen.
	# =========================================================

	viewport_container.stretch = true

	viewport_container.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	root.add_child(
		viewport_container
	)


	scene_viewport = (
		SubViewport.new()
	)

	scene_viewport.name = (
		"SceneViewport"
	)

	scene_viewport.size = Vector2i(
		1920,
		1080
	)

	scene_viewport.render_target_update_mode = (
		SubViewport.UPDATE_ALWAYS
	)

	scene_viewport.transparent_bg = false

	viewport_container.add_child(
		scene_viewport
	)


	workspace = Node3D.new()

	workspace.name = (
		"Workspace"
	)

	scene_viewport.add_child(
		workspace
	)

	setup_workspace()


	viewport_ui = Control.new()

	viewport_ui.name = (
		"ViewportUI"
	)

	viewport_ui.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	viewport_ui.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	root.add_child(
		viewport_ui
	)


	build_controls()

	build_notification()


# =============================================================
# WORKSPACE
# =============================================================

func setup_workspace() -> void:

	if workspace == null:

		return


	var world_environment := (
		WorldEnvironment.new()
	)

	world_environment.name = (
		"WorldEnvironment"
	)


	var environment_resource := (
		Environment.new()
	)

	environment_resource.background_mode = (
		Environment.BG_COLOR
	)

	environment_resource.background_color = (
		Color("#252A32")
	)

	environment_resource.ambient_light_source = (
		Environment.AMBIENT_SOURCE_COLOR
	)

	environment_resource.ambient_light_color = (
		Color("#747474")
	)

	environment_resource.ambient_light_energy = 0.90

	world_environment.environment = (
		environment_resource
	)

	workspace.add_child(
		world_environment
	)


	camera = Camera3D.new()

	camera.name = (
		"Camera3D"
	)

	camera.position = Vector3(
		0.0,
		1.4,
		4.0
	)

	camera.rotation = Vector3.ZERO

	camera.fov = 40.0

	camera.near = 0.01

	camera.far = 1000.0

	camera.current = true

	workspace.add_child(
		camera
	)


	var key_light := (
		DirectionalLight3D.new()
	)

	key_light.name = (
		"KeyLight"
	)

	key_light.rotation_degrees = Vector3(
		-30.0,
		-25.0,
		0.0
	)

	key_light.light_energy = 1.4

	key_light.shadow_enabled = false

	workspace.add_child(
		key_light
	)


	var rim_light := (
		DirectionalLight3D.new()
	)

	rim_light.name = (
		"RimLight"
	)

	rim_light.rotation_degrees = Vector3(
		25.0,
		155.0,
		0.0
	)

	rim_light.light_energy = 0.65

	rim_light.shadow_enabled = false

	workspace.add_child(
		rim_light
	)


	character_root = Node3D.new()

	character_root.name = (
		"Character"
	)

	workspace.add_child(
		character_root
	)


	camera.rotation = Vector3.ZERO


# =============================================================
# CONTROLS
# =============================================================

func build_controls() -> void:

	build_camera_panel()

	build_display_panel()


# =============================================================
# CAMERA PANEL
# =============================================================

func build_camera_panel() -> void:

	controls_scroll = ScrollContainer.new()

	controls_scroll.name = (
		"CameraScroll"
	)

	controls_scroll.set_anchors_preset(
		Control.PRESET_TOP_LEFT
	)

	controls_scroll.offset_left = 20.0
	controls_scroll.offset_top = 20.0
	controls_scroll.offset_right = 380.0
	controls_scroll.offset_bottom = 700.0

	controls_scroll.horizontal_scroll_mode = (
		ScrollContainer.SCROLL_MODE_DISABLED
	)

	controls_scroll.vertical_scroll_mode = (
		ScrollContainer.SCROLL_MODE_AUTO
	)

	controls_scroll.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	viewport_ui.add_child(
		controls_scroll
	)


	controls_panel = PanelContainer.new()

	controls_panel.name = (
		"CameraPanel"
	)

	controls_panel.custom_minimum_size = Vector2(
		340.0,
		0.0
	)

	controls_panel.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	controls_panel.size_flags_vertical = (
		Control.SIZE_SHRINK_BEGIN
	)

	theme.style_panel(
		controls_panel
	)

	controls_scroll.add_child(
		controls_panel
	)


	var margin := MarginContainer.new()

	theme.set_margins(
		margin,
		16
	)

	margin.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	controls_panel.add_child(
		margin
	)


	var camera_box := VBoxContainer.new()

	camera_box.name = (
		"CameraBox"
	)

	camera_box.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	camera_box.size_flags_vertical = (
		Control.SIZE_SHRINK_BEGIN
	)

	camera_box.add_theme_constant_override(
		"separation",
		8
	)

	margin.add_child(
		camera_box
	)


	# =========================================================
	# CAMERA
	# =========================================================

	camera_box.add_child(
		theme.create_title(
			"CAMERA"
		)
	)


	camera_preset = OptionButton.new()

	camera_preset.add_item(
		"DEFAULT"
	)

	camera_preset.add_item(
		"CLOSE"
	)

	camera_preset.add_item(
		"MEDIUM"
	)

	camera_preset.add_item(
		"WIDE"
	)

	camera_preset.custom_minimum_size = Vector2(
		0.0,
		38.0
	)

	camera_preset.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	camera_preset.focus_mode = (
		Control.FOCUS_NONE
	)

	camera_box.add_child(
		camera_preset
	)

	camera_preset.item_selected.connect(
		_on_preset
	)


	camera_x = theme.create_spinbox(
		-20.0,
		20.0,
		0.05,
		0.0
	)

	camera_y = theme.create_spinbox(
		-20.0,
		20.0,
		0.05,
		1.4
	)

	camera_z = theme.create_spinbox(
		1.0,
		20.0,
		0.05,
		4.0
	)

	camera_fov = theme.create_spinbox(
		10.0,
		120.0,
		1.0,
		40.0
	)


	camera_box.add_child(
		theme.labeled_control(
			"X",
			camera_x
		)
	)

	camera_box.add_child(
		theme.labeled_control(
			"Y",
			camera_y
		)
	)

	camera_box.add_child(
		theme.labeled_control(
			"Z",
			camera_z
		)
	)

	camera_box.add_child(
		theme.labeled_control(
			"FOV",
			camera_fov
		)
	)


	camera_x.focus_mode = (
		Control.FOCUS_NONE
	)

	camera_y.focus_mode = (
		Control.FOCUS_NONE
	)

	camera_z.focus_mode = (
		Control.FOCUS_NONE
	)

	camera_fov.focus_mode = (
		Control.FOCUS_NONE
	)


	camera_x.value_changed.connect(
		update_camera
	)

	camera_y.value_changed.connect(
		update_camera
	)

	camera_z.value_changed.connect(
		update_camera
	)

	camera_fov.value_changed.connect(
		update_camera
	)


	orientation_button = (
		theme.create_button(
			"FRONT"
		)
	)

	orientation_button.focus_mode = (
		Control.FOCUS_NONE
	)

	orientation_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	camera_box.add_child(
		orientation_button
	)

	orientation_button.pressed.connect(
		toggle_orientation
	)


	var reset_button := (
		theme.create_button(
			"RESET CAMERA"
		)
	)

	reset_button.focus_mode = (
		Control.FOCUS_NONE
	)

	reset_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	camera_box.add_child(
		reset_button
	)

	reset_button.pressed.connect(
		reset_camera
	)


	var center_button := (
		theme.create_button(
			"CENTER POSITION"
		)
	)

	center_button.focus_mode = (
		Control.FOCUS_NONE
	)

	center_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	camera_box.add_child(
		center_button
	)

	center_button.pressed.connect(
		center_camera
	)


	camera_box.add_child(
		HSeparator.new()
	)


	# =========================================================
	# NATIVE AVATAR CALIBRATION
	# =========================================================

	calibration_section_label = (
		theme.create_section_label(
			"NATIVE AVATAR CALIBRATION"
		)
	)

	camera_box.add_child(
		calibration_section_label
	)


	avatar_calibration_container = VBoxContainer.new()

	avatar_calibration_container.name = (
		"AvatarCalibrationContainer"
	)

	avatar_calibration_container.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	avatar_calibration_container.add_theme_constant_override(
		"separation",
		6
	)

	camera_box.add_child(
		avatar_calibration_container
	)


	_build_native_calibration_controls()


	camera_box.add_child(
		HSeparator.new()
	)


	# =========================================================
	# OBJECT SPAWNS
	# =========================================================

	camera_box.add_child(
		theme.create_section_label(
			"OBJECT SPAWNS"
		)
	)


	spawn_left_top_check = create_spawn_checkbox(
		"LEFT TOP",
		"LEFT_TOP",
		camera_box
	)

	spawn_left_bottom_check = create_spawn_checkbox(
		"LEFT BOTTOM",
		"LEFT_BOTTOM",
		camera_box
	)

	spawn_right_top_check = create_spawn_checkbox(
		"RIGHT TOP",
		"RIGHT_TOP",
		camera_box
	)

	spawn_right_bottom_check = create_spawn_checkbox(
		"RIGHT BOTTOM",
		"RIGHT_BOTTOM",
		camera_box
	)

	spawn_top_center_check = create_spawn_checkbox(
		"TOP CENTER",
		"TOP_CENTER",
		camera_box
	)

	spawn_bottom_center_check = create_spawn_checkbox(
		"BOTTOM CENTER",
		"BOTTOM_CENTER",
		camera_box
	)


	edge_spawn_status = (
		theme.create_status_label(
			"6 SPAWN POINTS ENABLED"
		)
	)

	edge_spawn_status.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	edge_spawn_status.autowrap_mode = (
		TextServer.AUTOWRAP_OFF
	)

	camera_box.add_child(
		edge_spawn_status
	)


	var test_throw := (
		theme.create_button(
			"TEST OBJECT"
		)
	)

	test_throw.custom_minimum_size = Vector2(
		0.0,
		44.0
	)

	test_throw.focus_mode = (
		Control.FOCUS_NONE
	)

	test_throw.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	camera_box.add_child(
		test_throw
	)

	test_throw.pressed.connect(
		_on_test_throw
	)


	runtime_status = (
		theme.create_status_label(
			"VIEWPORT RUNTIME: INITIALIZING"
		)
	)

	runtime_status.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	runtime_status.autowrap_mode = (
		TextServer.AUTOWRAP_OFF
	)

	camera_box.add_child(
		runtime_status
	)


	camera_box.add_child(
		HSeparator.new()
	)


	var back_button := (
		theme.create_button(
			"BACK TO CONFIGURATION"
		)
	)

	back_button.custom_minimum_size = Vector2(
		0.0,
		44.0
	)

	back_button.focus_mode = (
		Control.FOCUS_NONE
	)

	back_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	camera_box.add_child(
		back_button
	)

	back_button.pressed.connect(
		_on_back_pressed
	)


	var bottom_spacer := Control.new()

	bottom_spacer.custom_minimum_size = Vector2(
		0.0,
		35.0
	)

	camera_box.add_child(
		bottom_spacer
	)


# =============================================================
# BUILD NATIVE CALIBRATION CONTROLS
# =============================================================

func _build_native_calibration_controls() -> void:

	if avatar_calibration_container == null:

		return


	# =========================================================
	# BODY
	# =========================================================

	avatar_calibration_container.add_child(
		theme.create_section_label(
			"BODY"
		)
	)


	avatar_body_scale = _create_avatar_spin(
		0.70,
		1.50,
		0.01,
		1.00
	)

	avatar_calibration_container.add_child(
		theme.labeled_control(
			"HEIGHT / SCALE",
			avatar_body_scale
		)
	)


	avatar_body_width = _create_avatar_spin(
		0.75,
		1.35,
		0.01,
		1.00
	)

	avatar_calibration_container.add_child(
		theme.labeled_control(
			"BODY WIDTH",
			avatar_body_width
		)
	)


	avatar_shoulder_width = _create_avatar_spin(
		0.75,
		1.35,
		0.01,
		1.00
	)

	avatar_calibration_container.add_child(
		theme.labeled_control(
			"SHOULDER WIDTH",
			avatar_shoulder_width
		)
	)


	avatar_arm_length = _create_avatar_spin(
		0.75,
		1.30,
		0.01,
		1.00
	)

	avatar_calibration_container.add_child(
		theme.labeled_control(
			"ARM LENGTH",
			avatar_arm_length
		)
	)


	avatar_leg_length = _create_avatar_spin(
		0.75,
		1.30,
		0.01,
		1.00
	)

	avatar_calibration_container.add_child(
		theme.labeled_control(
			"LEG LENGTH",
			avatar_leg_length
		)
)

	# =========================================================
	# HEAD
	# =========================================================

	avatar_calibration_container.add_child(
		theme.create_section_label(
			"HEAD"
		)
	)


	avatar_head_scale = _create_avatar_spin(
		0.75,
		1.30,
		0.01,
		1.00
	)

	avatar_calibration_container.add_child(
		theme.labeled_control(
			"HEAD SIZE",
			avatar_head_scale
		)
	)


	avatar_head_rot_x = _create_avatar_spin(
		-90.0,
		90.0,
		1.0,
		0.0
	)

	avatar_calibration_container.add_child(
		theme.labeled_control(
			"HEAD ROT X",
			avatar_head_rot_x
		)
	)


	avatar_head_rot_y = _create_avatar_spin(
		-90.0,
		90.0,
		1.0,
		0.0
	)

	avatar_calibration_container.add_child(
		theme.labeled_control(
			"HEAD ROT Y",
			avatar_head_rot_y
		)
	)


	avatar_head_rot_z = _create_avatar_spin(
		-90.0,
		90.0,
		1.0,
		0.0
	)

	avatar_calibration_container.add_child(
		theme.labeled_control(
			"HEAD ROT Z",
			avatar_head_rot_z
		)
	)


	# =========================================================
	# ARMS
	# =========================================================

	avatar_calibration_container.add_child(
		theme.create_section_label(
			"POSE"
		)
	)


	avatar_left_arm = _create_avatar_spin(
		0.0,
		1.0,
		0.01,
		0.0
	)

	avatar_calibration_container.add_child(
		theme.labeled_control(
			"LEFT ARM",
			avatar_left_arm
		)
	)


	avatar_right_arm = _create_avatar_spin(
		0.0,
		1.0,
		0.01,
		0.0
	)

	avatar_calibration_container.add_child(
		theme.labeled_control(
			"RIGHT ARM",
			avatar_right_arm
		)
	)


	# =========================================================
	# FACE
	# =========================================================

	avatar_calibration_container.add_child(
		theme.create_section_label(
			"FACE"
		)
	)


	avatar_left_eye = _create_avatar_spin(
		0.0,
		1.0,
		0.01,
		1.0
	)

	avatar_calibration_container.add_child(
		theme.labeled_control(
			"LEFT EYE",
			avatar_left_eye
		)
	)


	avatar_right_eye = _create_avatar_spin(
		0.0,
		1.0,
		0.01,
		1.0
	)

	avatar_calibration_container.add_child(
		theme.labeled_control(
			"RIGHT EYE",
			avatar_right_eye
		)
	)


	avatar_mouth = _create_avatar_spin(
		0.0,
		1.0,
		0.01,
		0.0
	)

	avatar_calibration_container.add_child(
		theme.labeled_control(
			"MOUTH",
			avatar_mouth
		)
	)


	# =========================================================
	# TAIL
	# =========================================================

	avatar_calibration_container.add_child(
		theme.create_section_label(
			"TAIL"
		)
	)


	avatar_tail_check = CheckBox.new()

	avatar_tail_check.text = (
		"ENABLE TAIL"
	)

	avatar_tail_check.custom_minimum_size = Vector2(
		0.0,
		36.0
	)

	avatar_tail_check.focus_mode = (
		Control.FOCUS_NONE
	)

	avatar_calibration_container.add_child(
		avatar_tail_check
	)

	avatar_tail_check.toggled.connect(
		_on_native_tail_changed
	)


	avatar_tail_length = _create_avatar_spin(
		0.05,
		3.0,
		0.01,
		0.55
	)

	avatar_calibration_container.add_child(
		theme.labeled_control(
			"TAIL LENGTH",
			avatar_tail_length
		)
	)


	# =========================================================
	# ACTIONS
	# =========================================================

	avatar_reset_button = (
		theme.create_button(
			"RESET AVATAR"
		)
	)

	avatar_reset_button.custom_minimum_size = Vector2(
		0.0,
		40.0
	)

	avatar_reset_button.focus_mode = (
		Control.FOCUS_NONE
	)

	avatar_calibration_container.add_child(
		avatar_reset_button
	)

	avatar_reset_button.pressed.connect(
		_reset_native_avatar
	)


	avatar_save_button = (
		theme.create_button(
			"SAVE AVATAR"
		)
	)

	avatar_save_button.custom_minimum_size = Vector2(
		0.0,
		42.0
	)

	avatar_save_button.focus_mode = (
		Control.FOCUS_NONE
	)

	avatar_calibration_container.add_child(
		avatar_save_button
	)

	avatar_save_button.pressed.connect(
		_save_native_avatar
	)


	# =========================================================
	# CONNECTIONS
	# =========================================================

	avatar_body_scale.value_changed.connect(
		_on_avatar_body_scale_changed
	)

	avatar_body_width.value_changed.connect(
		_on_avatar_body_width_changed
	)

	avatar_shoulder_width.value_changed.connect(
		_on_avatar_shoulder_width_changed
	)

	avatar_arm_length.value_changed.connect(
		_on_avatar_arm_length_changed
	)

	avatar_leg_length.value_changed.connect(
		_on_avatar_leg_length_changed
	)

	avatar_head_scale.value_changed.connect(
		_on_avatar_head_scale_changed
	)

	avatar_head_rot_x.value_changed.connect(
		_on_avatar_head_rotation_changed
	)

	avatar_head_rot_y.value_changed.connect(
		_on_avatar_head_rotation_changed
	)

	avatar_head_rot_z.value_changed.connect(
		_on_avatar_head_rotation_changed
	)

	avatar_left_arm.value_changed.connect(
		_on_avatar_arm_pose_changed
	)

	avatar_right_arm.value_changed.connect(
		_on_avatar_arm_pose_changed
	)

	avatar_left_eye.value_changed.connect(
		_on_avatar_face_changed
	)

	avatar_right_eye.value_changed.connect(
		_on_avatar_face_changed
	)

	avatar_mouth.value_changed.connect(
		_on_avatar_face_changed
	)

	avatar_tail_length.value_changed.connect(
		_on_avatar_tail_length_changed
	)


	_set_native_calibration_controls_enabled(
		false
	)


# =============================================================
# CREATE AVATAR SPINBOX
# =============================================================

func _create_avatar_spin(
	minimum: float,
	maximum: float,
	step: float,
	default_value: float
) -> SpinBox:

	var spin := theme.create_spinbox(
		minimum,
		maximum,
		step,
		default_value
	)

	spin.focus_mode = (
		Control.FOCUS_NONE
	)

	spin.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	return spin


# =============================================================
# NATIVE AVATAR
# =============================================================

func _get_native_avatar() -> CIGACalibrationAvatar:

	if visual_character == null:

		return null


	if not visual_character is CIGACalibrationAvatar:

		return null


	return (
		visual_character
		as
		CIGACalibrationAvatar
	)


# =============================================================
# NATIVE CONTROLS ENABLED
# =============================================================

func _set_native_calibration_controls_enabled(
	enabled: bool
) -> void:

	native_avatar_controls_enabled = enabled


	var controls: Array[Control] = [

		avatar_body_scale,

		avatar_body_width,

		avatar_shoulder_width,

		avatar_arm_length,

		avatar_leg_length,

		avatar_head_scale,

		avatar_head_rot_x,

		avatar_head_rot_y,

		avatar_head_rot_z,

		avatar_left_arm,

		avatar_right_arm,

		avatar_left_eye,

		avatar_right_eye,

		avatar_mouth,

		avatar_tail_check,

		avatar_tail_length,

		avatar_reset_button,

		avatar_save_button
	]


	for control: Control in controls:

		if control == null:

			continue


		# -----------------------------------------------------
		# SpinBox
		# -----------------------------------------------------

		if control is SpinBox:

			var spin := (
				control
				as
				SpinBox
			)

			spin.editable = enabled


		# -----------------------------------------------------
		# Button / CheckBox
		# -----------------------------------------------------

		elif control is BaseButton:

			var button := (
				control
				as
				BaseButton
			)

			button.disabled = not enabled

# =============================================================
# REFRESH NATIVE AVATAR CONTROLS
# =============================================================

func refresh_native_avatar_controls() -> void:

	var avatar := _get_native_avatar()


	if avatar == null:

		_set_native_calibration_controls_enabled(
			false
		)

		return


	_set_native_calibration_controls_enabled(
		true
	)


	# =========================================================
	# BASIC PARAMETERS
	# =========================================================

	avatar_body_scale.set_value_no_signal(
		avatar.body_scale
	)

	avatar_body_width.set_value_no_signal(
		avatar.body_width_scale
	)

	avatar_shoulder_width.set_value_no_signal(
		avatar.shoulder_width_scale
	)

	avatar_arm_length.set_value_no_signal(
		avatar.arm_length_scale
	)

	avatar_leg_length.set_value_no_signal(
		avatar.leg_length_scale
	)

	avatar_head_scale.set_value_no_signal(
		avatar.head_scale
	)


	# =========================================================
	# HEAD ROTATION
	# =========================================================

	avatar_head_rot_x.set_value_no_signal(
		avatar.head_rotation.x
	)

	avatar_head_rot_y.set_value_no_signal(
		avatar.head_rotation.y
	)

	avatar_head_rot_z.set_value_no_signal(
		avatar.head_rotation.z
	)


	# =========================================================
	# POSE
	# =========================================================

	avatar_left_arm.set_value_no_signal(
		avatar.left_arm_pose
	)

	avatar_right_arm.set_value_no_signal(
		avatar.right_arm_pose
	)


	# =========================================================
	# FACE
	# =========================================================

	avatar_left_eye.set_value_no_signal(
		avatar.left_eye_open
	)

	avatar_right_eye.set_value_no_signal(
		avatar.right_eye_open
	)

	avatar_mouth.set_value_no_signal(
		avatar.mouth_open
	)


	# =========================================================
	# TAIL
	# =========================================================

	avatar_tail_check.set_pressed_no_signal(
		avatar.tail_enabled
	)

	avatar_tail_length.set_value_no_signal(
		avatar.tail_length
	)


# =============================================================
# NATIVE BODY SCALE
# =============================================================

func _on_avatar_body_scale_changed(
	value: float
) -> void:

	if not native_avatar_controls_enabled:

		return


	var avatar := _get_native_avatar()


	if avatar == null:

		return


	avatar.set_avatar_scale(
		value,
		avatar.head_scale
	)


	avatar_body_scale.set_value_no_signal(
		avatar.body_scale
	)


	_mark_avatar_interaction()


# =============================================================
# NATIVE BODY WIDTH
# =============================================================

func _on_avatar_body_width_changed(
	value: float
) -> void:

	if not native_avatar_controls_enabled:

		return


	var avatar := _get_native_avatar()


	if avatar == null:

		return


	avatar.set_body_width(
		value
	)


	_mark_avatar_interaction()


# =============================================================
# NATIVE SHOULDER WIDTH
# =============================================================

func _on_avatar_shoulder_width_changed(
	value: float
) -> void:

	if not native_avatar_controls_enabled:

		return


	var avatar := _get_native_avatar()


	if avatar == null:

		return


	avatar.set_shoulder_width(
		value
	)


	_mark_avatar_interaction()


# =============================================================
# NATIVE ARM LENGTH
# =============================================================

func _on_avatar_arm_length_changed(
	value: float
) -> void:

	if not native_avatar_controls_enabled:

		return


	var avatar := _get_native_avatar()


	if avatar == null:

		return


	avatar.set_arm_length(
		value
	)


	_mark_avatar_interaction()


# =============================================================
# NATIVE LEG LENGTH
# =============================================================

func _on_avatar_leg_length_changed(
	value: float
) -> void:

	if not native_avatar_controls_enabled:

		return


	var avatar := _get_native_avatar()


	if avatar == null:

		return


	avatar.set_leg_length(
		value
	)


	_mark_avatar_interaction()


# =============================================================
# NATIVE HEAD
# =============================================================

func _on_avatar_head_scale_changed(
	value: float
) -> void:

	if not native_avatar_controls_enabled:

		return


	var avatar := _get_native_avatar()


	if avatar == null:

		return


	avatar.set_avatar_scale(
		avatar.body_scale,
		value
	)


	_mark_avatar_interaction()


# =============================================================
# NATIVE HEAD ROTATION
# =============================================================

func _on_avatar_head_rotation_changed(
	_unused_value: float
) -> void:

	if not native_avatar_controls_enabled:

		return


	var avatar := _get_native_avatar()


	if avatar == null:

		return


	avatar.set_head_rotation(
		Vector3(
			float(
				avatar_head_rot_x.value
			),
			float(
				avatar_head_rot_y.value
			),
			float(
				avatar_head_rot_z.value
			)
		)
	)


	_mark_avatar_interaction()


# =============================================================
# NATIVE ARM POSE
# =============================================================

func _on_avatar_arm_pose_changed(
	_unused_value: float
) -> void:

	if not native_avatar_controls_enabled:

		return


	var avatar := _get_native_avatar()


	if avatar == null:

		return


	avatar.set_arm_pose(
		float(
			avatar_left_arm.value
		),
		float(
			avatar_right_arm.value
		)
	)


	_mark_avatar_interaction()


# =============================================================
# NATIVE FACE
# =============================================================

func _on_avatar_face_changed(
	_unused_value: float
) -> void:

	if not native_avatar_controls_enabled:

		return


	var avatar := _get_native_avatar()


	if avatar == null:

		return


	avatar.set_eye_open(
		float(
			avatar_left_eye.value
		),
		float(
			avatar_right_eye.value
		)
	)


	avatar.set_mouth_open(
		float(
			avatar_mouth.value
		)
	)


	_mark_avatar_interaction()


# =============================================================
# NATIVE TAIL
# =============================================================

func _on_native_tail_changed(
	enabled: bool
) -> void:

	if not native_avatar_controls_enabled:

		return


	var avatar := _get_native_avatar()


	if avatar == null:

		return


	avatar.set_tail_enabled(
		enabled
	)


	_mark_avatar_interaction()


# =============================================================
# NATIVE TAIL LENGTH
# =============================================================

func _on_avatar_tail_length_changed(
	value: float
) -> void:

	if not native_avatar_controls_enabled:

		return


	var avatar := _get_native_avatar()


	if avatar == null:

		return


	avatar.set_tail_length(
		value
	)


	_mark_avatar_interaction()


# =============================================================
# AVATAR INTERACTION
# =============================================================
func _mark_avatar_interaction() -> void:

	_clear_ui_interaction_state()


# =============================================================
# RESET NATIVE AVATAR
# =============================================================

func _reset_native_avatar() -> void:

	var avatar := _get_native_avatar()


	if avatar == null:

		return


	avatar.body_scale = 1.0
	avatar.head_scale = 1.0

	avatar.arm_length_scale = 1.0
	avatar.leg_length_scale = 1.0

	avatar.body_width_scale = 1.0
	avatar.shoulder_width_scale = 1.0

	avatar.head_rotation = Vector3.ZERO

	avatar.left_arm_pose = 0.0
	avatar.right_arm_pose = 0.0

	avatar.left_eye_open = 1.0
	avatar.right_eye_open = 1.0

	avatar.mouth_open = 0.0

	avatar.tail_enabled = false
	avatar.tail_length = (
		CIGACalibrationAvatar.DEFAULT_TAIL_LENGTH
	)


	avatar.rebuild_transform()

	avatar.set_eye_open(
		1.0,
		1.0
	)

	avatar.set_mouth_open(
		0.0
	)

	avatar.set_tail_length(
		avatar.tail_length
	)

	avatar.set_tail_enabled(
		false
	)


	refresh_native_avatar_controls()

	_mark_avatar_interaction()


	show_notification(
		"NATIVE AVATAR RESET"
	)


# =============================================================
# SAVE NATIVE AVATAR
# =============================================================

func _save_native_avatar() -> void:

	var avatar := _get_native_avatar()


	if avatar == null:

		return


	if runtime == null:

		return


	if runtime.character_manager == null:

		return


	var character_runtime := (
		runtime.character_runtime
	)


	if character_runtime == null:

		return


	var active_path := (
		character_runtime
		.get_active_character_path()
	)


	if active_path.is_empty():

		show_notification(
			"AVATAR SAVE FAILED"
		)

		return


	var definition := (
		avatar.get_definition()
	)


	var file := FileAccess.open(
		active_path,
		FileAccess.WRITE
	)


	if file == null:

		show_notification(
			"AVATAR SAVE FAILED"
		)

		return


	file.store_string(
		JSON.stringify(
			definition,
			"\t"
		)
	)

	file.close()


	var active_id := ""


	var characters_manager := (
		runtime.character_manager
	)


	for index in range(
		characters_manager.characters.size()
	):

		var character: Dictionary = (
			characters_manager.characters[
				index
			]
		)


		if str(
			character.get(
				"source_path",
				""
			)
		) == active_path:

			active_id = str(
				character.get(
					"id",
					""
				)
			)


			character["file_size"] = (
				FileAccess
				.get_file_as_bytes(
					active_path
				)
				.size()
			)

			characters_manager.characters[
				index
			] = character

			break


	if not active_id.is_empty():

		characters_manager.save_library()


	show_notification(
		"NATIVE AVATAR SAVED"
	)


	_clear_ui_interaction_state()


# =============================================================
# DISPLAY PANEL
# =============================================================

func build_display_panel() -> void:

	display_scroll = ScrollContainer.new()

	display_scroll.name = (
		"DisplayScroll"
	)

	display_scroll.set_anchors_preset(
		Control.PRESET_TOP_RIGHT
	)

	display_scroll.offset_left = -380.0
	display_scroll.offset_right = -20.0
	display_scroll.offset_top = 20.0
	display_scroll.offset_bottom = 700.0

	display_scroll.horizontal_scroll_mode = (
		ScrollContainer.SCROLL_MODE_DISABLED
	)

	display_scroll.vertical_scroll_mode = (
		ScrollContainer.SCROLL_MODE_AUTO
	)

	display_scroll.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	viewport_ui.add_child(
		display_scroll
	)


	display_panel = PanelContainer.new()

	display_panel.name = (
		"DisplayPanel"
	)

	display_panel.custom_minimum_size = Vector2(
		360.0,
		0.0
	)

	display_panel.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	display_panel.size_flags_vertical = (
		Control.SIZE_SHRINK_BEGIN
	)

	theme.style_panel(
		display_panel
	)

	display_scroll.add_child(
		display_panel
	)


	var margin := MarginContainer.new()

	theme.set_margins(
		margin,
		16
	)

	margin.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	display_panel.add_child(
		margin
	)


	var display_box := VBoxContainer.new()

	display_box.name = (
		"DisplayBox"
	)

	display_box.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	display_box.size_flags_vertical = (
		Control.SIZE_SHRINK_BEGIN
	)

	display_box.add_theme_constant_override(
		"separation",
		8
	)

	margin.add_child(
		display_box
	)


	display_box.add_child(
		theme.create_title(
			"DISPLAY"
		)
	)


	display_mode_selector = OptionButton.new()

	display_mode_selector.add_item(
		"WINDOWED"
	)

	display_mode_selector.add_item(
		"BORDERLESS"
	)

	display_mode_selector.add_item(
		"FULLSCREEN"
	)

	display_mode_selector.select(
		DISPLAY_WINDOWED
	)

	display_mode_selector.custom_minimum_size = Vector2(
		0.0,
		38.0
	)

	display_mode_selector.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	display_mode_selector.focus_mode = (
		Control.FOCUS_NONE
	)

	display_box.add_child(
		display_mode_selector
	)

	display_mode_selector.item_selected.connect(
		_on_display_mode_changed
	)


	resolution_selector = OptionButton.new()

	resolution_selector.add_item(
		"1280 x 720"
	)

	resolution_selector.add_item(
		"1600 x 900"
	)

	resolution_selector.add_item(
		"1920 x 1080"
	)

	resolution_selector.select(
		RESOLUTION_1920
	)

	resolution_selector.custom_minimum_size = Vector2(
		0.0,
		38.0
	)

	resolution_selector.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	resolution_selector.focus_mode = (
		Control.FOCUS_NONE
	)

	display_box.add_child(
		resolution_selector
	)

	resolution_selector.item_selected.connect(
		_on_resolution_changed
	)


	streamer_button = (
		theme.create_button(
			"STREAMER MODE"
		)
	)

	streamer_button.custom_minimum_size = Vector2(
		0.0,
		44.0
	)

	streamer_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	streamer_button.focus_mode = (
		Control.FOCUS_NONE
	)

	display_box.add_child(
		streamer_button
	)

	streamer_button.pressed.connect(
		toggle_streamer_mode
	)


	streamer_status = (
		theme.create_status_label(
			"STREAMER MODE: DISABLED"
		)
	)

	streamer_status.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	streamer_status.autowrap_mode = (
		TextServer.AUTOWRAP_OFF
	)

	display_box.add_child(
		streamer_status
	)


	display_box.add_child(
		HSeparator.new()
	)


	display_box.add_child(
		theme.create_section_label(
			"KEYBOARD CONTROLS"
		)
	)


	var help_text := (
		"R — Rotate avatar\n"
		+ "T — Flip impact side\n"
		+ "TAB — Streamer mode\n"
		+ "SPACE — Test object / hold for random throws\n"
		+ "LEFT / RIGHT — Camera X\n"
		+ "UP / DOWN — Camera Y\n"
		+ "+ / - — Zoom\n"
		+ "PAGE UP / PAGE DOWN — Zoom"
	)


	hotkey_help_label = (
		theme.create_status_label(
			help_text
		)
	)

	hotkey_help_label.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	hotkey_help_label.size_flags_vertical = (
		Control.SIZE_SHRINK_BEGIN
	)

	hotkey_help_label.custom_minimum_size = Vector2(
		300.0,
		150.0
	)

	hotkey_help_label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	hotkey_help_label.clip_text = false

	display_box.add_child(
		hotkey_help_label
	)


	var display_bottom_spacer := Control.new()

	display_bottom_spacer.custom_minimum_size = Vector2(
		0.0,
		35.0
	)

	display_box.add_child(
		display_bottom_spacer
	)


# =============================================================
# SPAWN CHECKBOX
# =============================================================

func create_spawn_checkbox(
	text_value: String,
	edge_name: String,
	parent: VBoxContainer
) -> CheckBox:

	var check := CheckBox.new()

	check.text = (
		text_value
	)

	check.button_pressed = true

	check.custom_minimum_size = Vector2(
		0.0,
		30.0
	)

	check.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	check.focus_mode = (
		Control.FOCUS_NONE
	)

	parent.add_child(
		check
	)


	check.toggled.connect(
		func(enabled: bool) -> void:

			if runtime != null:

				runtime.set_edge_enabled(
					edge_name,
					enabled
				)

			update_edge_spawn_status()

			_clear_ui_interaction_state()
	)


	return check


# =============================================================
# REFRESH SPAWNS
# =============================================================

func refresh_edge_checkboxes() -> void:

	if runtime == null:

		return


	if spawn_left_top_check != null:

		spawn_left_top_check.set_pressed_no_signal(
			runtime.is_edge_enabled(
				"LEFT_TOP"
			)
		)


	if spawn_left_bottom_check != null:

		spawn_left_bottom_check.set_pressed_no_signal(
			runtime.is_edge_enabled(
				"LEFT_BOTTOM"
			)
		)


	if spawn_right_top_check != null:

		spawn_right_top_check.set_pressed_no_signal(
			runtime.is_edge_enabled(
				"RIGHT_TOP"
			)
		)


	if spawn_right_bottom_check != null:

		spawn_right_bottom_check.set_pressed_no_signal(
			runtime.is_edge_enabled(
				"RIGHT_BOTTOM"
			)
		)


	if spawn_top_center_check != null:

		spawn_top_center_check.set_pressed_no_signal(
			runtime.is_edge_enabled(
				"TOP_CENTER"
			)
		)


	if spawn_bottom_center_check != null:

		spawn_bottom_center_check.set_pressed_no_signal(
			runtime.is_edge_enabled(
				"BOTTOM_CENTER"
			)
		)


	update_edge_spawn_status()


# =============================================================
# EDGE STATUS
# =============================================================

func update_edge_spawn_status() -> void:

	if runtime == null:

		return


	if edge_spawn_status == null:

		return


	var count: int = (
		runtime.get_enabled_edge_count()
	)


	edge_spawn_status.text = (
		str(count)
		+ " SPAWN POINT"
		+
		(
			"S"
			if count != 1
			else
			""
		)
		+
		" ENABLED"
	)


# =============================================================
# CAMERA UPDATE
# =============================================================

func update_camera(
	_unused_value: float = 0.0
) -> void:

	update_camera_direct()


func update_camera_direct() -> void:

	if camera == null:

		return


	if camera_x == null:

		return


	if camera_y == null:

		return


	if camera_z == null:

		return


	if camera_fov == null:

		return


	camera.position = Vector3(
		camera_x.value,
		camera_y.value,
		camera_z.value
	)


	camera.fov = camera_fov.value

	camera.rotation = Vector3.ZERO


	if runtime != null:

		runtime.update_spawn_points()


# =============================================================
# CAMERA MOVE X
# =============================================================

func camera_move_x(
	direction: float,
	delta: float
) -> void:

	if camera_x == null:

		return


	var amount: float = (
		direction
		*
		CAMERA_MOVE_SPEED
		*
		delta
	)


	_change_camera_value(
		camera_x,
		amount
	)


	_mark_camera_interaction()


# =============================================================
# CAMERA MOVE Y
# =============================================================

func camera_move_y(
	direction: float,
	delta: float
) -> void:

	if camera_y == null:

		return


	var amount: float = (
		direction
		*
		CAMERA_MOVE_SPEED
		*
		delta
	)


	_change_camera_value(
		camera_y,
		amount
	)


	_mark_camera_interaction()


# =============================================================
# CAMERA ZOOM
# =============================================================

func camera_zoom(
	direction: float,
	delta: float
) -> void:

	if camera_z == null:

		return


	var amount: float = (
		direction
		*
		CAMERA_ZOOM_SPEED
		*
		delta
	)


	_change_camera_value(
		camera_z,
		amount
	)


	_mark_camera_interaction()


# =============================================================
# CHANGE CAMERA VALUE
# =============================================================

func _change_camera_value(
	spin: SpinBox,
	amount: float
) -> void:

	if spin == null:

		return


	var old_value: float = float(
		spin.value
	)


	var new_value: float = clampf(
		old_value + amount,
		float(
			spin.min_value
		),
		float(
			spin.max_value
		)
	)


	if is_equal_approx(
		old_value,
		new_value
	):

		return


	spin.set_value_no_signal(
		new_value
	)


	update_camera_direct()


# =============================================================
# CENTER CAMERA
# =============================================================

func center_camera() -> void:

	set_camera(
		0.0,
		1.4,
		4.0,
		40.0
	)

	_clear_ui_interaction_state()


# =============================================================
# CAMERA PRESETS
# =============================================================

func _on_preset(
	index: int
) -> void:

	match index:

		0:

			set_camera(
				0.0,
				1.4,
				4.0,
				40.0
			)


		1:

			set_camera(
				0.0,
				1.5,
				2.2,
				38.0
			)


		2:

			set_camera(
				0.0,
				1.5,
				4.0,
				42.0
			)


		3:

			set_camera(
				0.0,
				1.7,
				6.5,
				48.0
			)


	_clear_ui_interaction_state()


# =============================================================
# SET CAMERA
# =============================================================

func set_camera(
	x: float,
	y: float,
	z: float,
	fov: float
) -> void:

	if camera_x != null:

		camera_x.set_value_no_signal(
			x
		)


	if camera_y != null:

		camera_y.set_value_no_signal(
			y
		)


	if camera_z != null:

		camera_z.set_value_no_signal(
			z
		)


	if camera_fov != null:

		camera_fov.set_value_no_signal(
			fov
		)


	update_camera_direct()


# =============================================================
# RESET CAMERA
# =============================================================

func reset_camera() -> void:

	camera_flipped = false


	if orientation_button != null:

		orientation_button.text = (
			"FRONT"
		)


	set_camera(
		0.0,
		1.4,
		4.0,
		40.0
	)


	_clear_ui_interaction_state()


# =============================================================
# ORIENTATION
# =============================================================

func toggle_orientation() -> void:

	camera_flipped = (
		not camera_flipped
	)


	if orientation_button != null:

		orientation_button.text = (
			"FLIPPED"
			if camera_flipped
			else
			"FRONT"
		)


	if runtime != null:

		runtime.impact_orientation_flipped = (
			camera_flipped
		)

		runtime.save_profile_settings()


	show_notification(
		"IMPACT SIDE FLIPPED"
		if camera_flipped
		else
		"IMPACT SIDE FRONT"
	)


	_clear_ui_interaction_state()


# =============================================================
# TEST OBJECT
# =============================================================

func _on_test_throw() -> void:

	if runtime == null:

		if runtime_status != null:

			runtime_status.text = (
				"VIEWPORT RUNTIME: UNAVAILABLE"
			)

		_clear_ui_interaction_state()

		return


	_mark_test_object_interaction()


	var success: bool = (
		runtime.launch_test_object()
	)


	if runtime_status != null:

		if success:

			runtime_status.text = (
				"VIEWPORT RUNTIME: OBJECT LAUNCHED"
			)

		else:

			runtime_status.text = (
				"VIEWPORT RUNTIME: LAUNCH FAILED"
			)


	_update_test_object_ui_state()


# =============================================================
# RUNTIME STATUS
# =============================================================

func update_runtime_status() -> void:

	if runtime_status == null:

		return


	if runtime == null:

		runtime_status.text = (
			"VIEWPORT RUNTIME: UNAVAILABLE"
		)

		return


	runtime_status.text = (
		"VIEWPORT RUNTIME: "
		+
		runtime.get_status()
	)


# =============================================================
# STREAMER MODE
# =============================================================

func toggle_streamer_mode() -> void:

	var state: bool = false


	if runtime != null:

		state = (
			runtime.toggle_streamer_mode()
		)

	else:

		streamer_mode_enabled = (
			not streamer_mode_enabled
		)

		state = streamer_mode_enabled

		_apply_local_streamer_mode(
			state
		)


	apply_streamer_mode_ui(
		state
	)

	_clear_ui_interaction_state()


# =============================================================
# LOCAL STREAMER MODE
# =============================================================

func _apply_local_streamer_mode(
	enabled: bool
) -> void:

	if scene_viewport != null:

		scene_viewport.transparent_bg = (
			enabled
		)


# =============================================================
# STREAMER UI
# =============================================================

func apply_streamer_mode_ui(
	enabled: bool
) -> void:

	streamer_mode_enabled = (
		enabled
	)


	if background != null:

		background.visible = (
			not enabled
		)


	if scene_viewport != null:

		scene_viewport.transparent_bg = (
			enabled
		)


	if controls_scroll != null:

		controls_scroll.visible = (
			not enabled
		)


	if display_scroll != null:

		display_scroll.visible = (
			not enabled
		)


	if streamer_button != null:

		streamer_button.text = (
			"EXIT STREAMER MODE"
			if enabled
			else
			"STREAMER MODE"
		)


	if streamer_status != null:

		streamer_status.text = (
			"STREAMER MODE: ENABLED"
			if enabled
			else
			"STREAMER MODE: DISABLED"
		)


	streamer_mode_changed.emit(
		enabled
	)


# =============================================================
# DISPLAY MODE
# =============================================================

func _on_display_mode_changed(
	index: int
) -> void:

	index = clampi(
		index,
		DISPLAY_WINDOWED,
		DISPLAY_FULLSCREEN
	)


	_apply_display_mode(
		index
	)


	save_display_settings()

	_clear_ui_interaction_state()


# =============================================================
# APPLY DISPLAY MODE
# =============================================================

func _apply_display_mode(
	index: int
) -> void:

	var window: Window = null


	if root != null:

		window = (
			root.get_window()
		)


	if window == null:

		return


	match index:

		DISPLAY_WINDOWED:

			window.borderless = false

			window.mode = (
				Window.MODE_WINDOWED
			)


		DISPLAY_BORDERLESS:

			window.mode = (
				Window.MODE_WINDOWED
			)

			window.borderless = true


		DISPLAY_FULLSCREEN:

			window.borderless = false

			window.mode = (
				Window.MODE_FULLSCREEN
			)


# =============================================================
# RESOLUTION
# =============================================================

func _on_resolution_changed(
	index: int
) -> void:

	index = clampi(
		index,
		RESOLUTION_1280,
		RESOLUTION_1920
	)


	_apply_resolution(
		index
	)


	save_display_settings()

	_clear_ui_interaction_state()


func _apply_resolution(
	index: int
) -> void:

	if scene_viewport == null:

		return


	match index:

		RESOLUTION_1280:

			scene_viewport.size = Vector2i(
				1280,
				720
			)


		RESOLUTION_1600:

			scene_viewport.size = Vector2i(
				1600,
				900
			)


		RESOLUTION_1920:

			scene_viewport.size = Vector2i(
				1920,
				1080
			)


	# =========================================================
	# O SubViewport mantém a resolução interna escolhida.
	#
	# O SubViewportContainer trata do escalamento para a janela.
	# Assim não precisamos transformar um monitor 4K numa
	# resolução interna de 3840x2160.
	# =========================================================

	if viewport_container != null:

		viewport_container.stretch = true


	if runtime != null:

		runtime.update_spawn_points()

# =============================================================
# SAVE DISPLAY SETTINGS
# =============================================================

func save_display_settings() -> void:

	if runtime == null:

		return


	if runtime.profile_manager == null:

		return


	var profile: Dictionary = (
		runtime.profile_manager.get_active_profile()
	)


	if profile.is_empty():

		return


	var display_data: Dictionary = {}


	var previous_value: Variant = (
		profile.get(
			"display",
			{}
		)
	)


	if previous_value is Dictionary:

		display_data = (
			previous_value
			as Dictionary
		)


	var window: Window = null


	if root != null:

		window = root.get_window()


	if window != null:

		var mode_index: int = (
			DISPLAY_WINDOWED
		)


		var current_mode := (
			DisplayServer.window_get_mode()
		)


		if current_mode == (
			DisplayServer.WINDOW_MODE_FULLSCREEN
		):

			mode_index = (
				DISPLAY_FULLSCREEN
			)


		elif current_mode == (
			DisplayServer.WINDOW_MODE_WINDOWED
		):

			if DisplayServer.window_get_flag(
				DisplayServer.WINDOW_FLAG_BORDERLESS
			):

				mode_index = (
					DISPLAY_BORDERLESS
				)

			else:

				mode_index = (
					DISPLAY_WINDOWED
				)


		display_data["mode"] = (
			mode_index
		)


	if resolution_selector != null:

		display_data["resolution"] = (
			resolution_selector.selected
		)


	if scene_viewport != null:

		display_data["width"] = (
			scene_viewport.size.x
		)

		display_data["height"] = (
			scene_viewport.size.y
		)


	profile["display"] = (
		display_data
	)


	runtime.profile_manager.save_profiles()


# =============================================================
# LOAD DISPLAY SETTINGS
# =============================================================

func load_saved_display_mode() -> void:

	var mode_index: int = (
		DISPLAY_WINDOWED
	)


	var resolution_index: int = (
		RESOLUTION_1920
	)


	if runtime != null:

		if runtime.profile_manager != null:

			var profile: Dictionary = (
				runtime.profile_manager.get_active_profile()
			)


			if not profile.is_empty():

				var display_value: Variant = (
					profile.get(
						"display",
						{}
					)
				)


				if display_value is Dictionary:

					var display_data: Dictionary = (
						display_value
						as
						Dictionary
					)


					mode_index = clampi(
						int(
							display_data.get(
								"mode",
								DISPLAY_WINDOWED
							)
						),
						DISPLAY_WINDOWED,
						DISPLAY_FULLSCREEN
					)


					var width: int = int(
						display_data.get(
							"width",
							1920
						)
					)


					var height: int = int(
						display_data.get(
							"height",
							1080
						)
					)


					if (
						width == 1280
						and
						height == 720
					):

						resolution_index = (
							RESOLUTION_1280
						)


					elif (
						width == 1600
						and
						height == 900
					):

						resolution_index = (
							RESOLUTION_1600
						)


					else:

						resolution_index = (
							RESOLUTION_1920
						)


	if display_mode_selector != null:

		display_mode_selector.select(
			mode_index
		)


	if resolution_selector != null:

		resolution_selector.select(
			resolution_index
		)


	_apply_resolution(
		resolution_index
	)


	_apply_display_mode(
		mode_index
	)


	_clear_ui_interaction_state()


# =============================================================
# SET RUNTIME
# =============================================================

func set_runtime(
	new_runtime: CIGAViewportRuntime
) -> void:

	runtime = new_runtime


	if runtime != null:

		runtime.set_viewport(
			self
		)


	update_runtime_status()

	refresh_edge_checkboxes()

	refresh_native_avatar_controls()

	_clear_ui_interaction_state()


func on_viewport_activated() -> void:

	if root == null:

		return


	root.visible = true

	_reset_ui_interaction_state()


	# =========================================================
	# GARANTIR VIEWPORT CONTAINER
	# =========================================================

	if viewport_container != null:

		viewport_container.stretch = true


	# =========================================================
	# ESPERAR UM FRAME
	#
	# Importante quando acabámos de:
	#
	# - mudar de monitor
	# - sair da Configuration
	# - entrar em fullscreen
	# - alterar o tamanho da janela
	# =========================================================

	await root.get_tree().process_frame


	if viewport_container != null:

		viewport_container.set_anchors_and_offsets_preset(
			Control.PRESET_FULL_RECT
		)


	if viewport_ui != null:

		viewport_ui.set_anchors_and_offsets_preset(
			Control.PRESET_FULL_RECT
		)


	load_saved_display_mode()

	update_camera_direct()

	update_runtime_status()

	refresh_edge_checkboxes()

	refresh_native_avatar_controls()
# =============================================================
# BACK
# =============================================================

func _on_back_pressed() -> void:

	save_display_settings()

	_reset_ui_interaction_state()

	back_to_configuration.emit()


# =============================================================
# CHARACTER
# =============================================================

func set_character(
	new_character: Node3D
) -> void:

	if character_root == null:

		return


	if new_character == null:

		clear_character()

		return


	if visual_character == new_character:

		set_visual_character_visible(
			not streamer_mode_enabled
		)

		refresh_native_avatar_controls()

		return


	clear_character()

	visual_character = (
		new_character
	)


	if visual_character.get_parent() == null:

		character_root.add_child(
			visual_character
		)


	visual_character.position = Vector3.ZERO

	visual_character.rotation = Vector3.ZERO


	_apply_runtime_native_definition()

	set_visual_character_visible(
		not streamer_mode_enabled
	)

	center_visual_character()

	refresh_native_avatar_controls()



# =============================================================
# APPLY RUNTIME NATIVE DEFINITION
# =============================================================

func _apply_runtime_native_definition() -> void:

	var avatar := _get_native_avatar()


	if avatar == null:

		return


	if runtime == null:

		return


	if runtime.character_runtime == null:

		return


	var definition: Dictionary = (
		runtime.character_runtime.active_native_definition
	)


	if definition.is_empty():

		return


	# =========================================================
	# AVATAR
	# =========================================================

	var avatar_value: Variant = (
		definition.get(
			"avatar",
			{}
		)
	)


	if avatar_value is Dictionary:

		var avatar_data := (
			avatar_value
			as
			Dictionary
		)


		avatar.body_scale = clampf(
			float(
				avatar_data.get(
					"body_scale",
					1.0
				)
			),
			0.70,
			1.50
		)


		avatar.head_scale = clampf(
			float(
				avatar_data.get(
					"head_scale",
					1.0
				)
			),
			0.75,
			1.30
		)


		avatar.arm_length_scale = clampf(
			float(
				avatar_data.get(
					"arm_length",
					1.0
				)
			),
			0.75,
			1.30
		)


		avatar.leg_length_scale = clampf(
			float(
				avatar_data.get(
					"leg_length",
					1.0
				)
			),
			0.75,
			1.30
		)


		avatar.body_width_scale = clampf(
			float(
				avatar_data.get(
					"body_width",
					1.0
				)
			),
			0.75,
			1.35
		)


		avatar.shoulder_width_scale = clampf(
			float(
				avatar_data.get(
					"shoulder_width",
					1.0
				)
			),
			0.75,
			1.35
		)


	# =========================================================
	# POSE
	# =========================================================

	var pose_value: Variant = (
		definition.get(
			"pose",
			{}
		)
	)


	if pose_value is Dictionary:

		var pose := (
			pose_value
			as
			Dictionary
		)


		var rotation_value: Variant = (
			pose.get(
				"head_rotation",
				{}
			)
		)


		if rotation_value is Dictionary:

			var rotation_data := (
				rotation_value
				as
				Dictionary
			)


			avatar.head_rotation = Vector3(
				float(
					rotation_data.get(
						"x",
						0.0
					)
				),
				float(
					rotation_data.get(
						"y",
						0.0
					)
				),
				float(
					rotation_data.get(
						"z",
						0.0
					)
				)
			)


		avatar.left_arm_pose = clampf(
			float(
				pose.get(
					"left_arm",
					0.0
				)
			),
			0.0,
			1.0
		)


		avatar.right_arm_pose = clampf(
			float(
				pose.get(
					"right_arm",
					0.0
				)
			),
			0.0,
			1.0
		)


		avatar.left_eye_open = clampf(
			float(
				pose.get(
					"left_eye",
					1.0
				)
			),
			0.0,
			1.0
		)


		avatar.right_eye_open = clampf(
			float(
				pose.get(
					"right_eye",
					1.0
				)
			),
			0.0,
			1.0
		)


		avatar.mouth_open = clampf(
			float(
				pose.get(
					"mouth",
					0.0
				)
			),
			0.0,
			1.0
		)


	# =========================================================
	# TAIL
	# =========================================================

	var tail_value: Variant = (
		definition.get(
			"tail",
			{}
		)
	)


	if tail_value is Dictionary:

		var tail_data := (
			tail_value
			as
			Dictionary
		)


		avatar.tail_enabled = bool(
			tail_data.get(
				"enabled",
				false
			)
		)


		avatar.tail_length = clampf(
			float(
				tail_data.get(
					"length",
					CIGACalibrationAvatar.DEFAULT_TAIL_LENGTH
				)
			),
			0.05,
			3.0
		)


	# =========================================================
	# APPLY
	# =========================================================

	avatar.rebuild_transform()

	avatar.set_eye_open(
		avatar.left_eye_open,
		avatar.right_eye_open
	)

	avatar.set_mouth_open(
		avatar.mouth_open
	)

	avatar.set_tail_length(
		avatar.tail_length
	)

	avatar.set_tail_enabled(
		avatar.tail_enabled
	)


# =============================================================
# CENTER VISUAL CHARACTER
# =============================================================

func center_visual_character() -> void:

	if visual_character == null:

		return


	var bounds := (
		calculate_visual_bounds(
			visual_character
		)
	)


	if bounds.size == Vector3.ZERO:

		return


	visual_character.position.x -= (
		bounds.position.x
		+
		bounds.size.x * 0.5
	)


	visual_character.position.z -= (
		bounds.position.z
		+
		bounds.size.z * 0.5
	)


	var corrected_bounds := (
		calculate_visual_bounds(
			visual_character
		)
	)


	if corrected_bounds.size != Vector3.ZERO:

		visual_character.position.y -= (
			corrected_bounds.position.y
		)


# =============================================================
# VISUAL BOUNDS
# =============================================================

func calculate_visual_bounds(
	root_node: Node3D
) -> AABB:

	if root_node == null:

		return AABB()


	var result := AABB()

	var found: bool = false


	var mesh_nodes: Array[Node] = (
		root_node.find_children(
			"*",
			"MeshInstance3D",
			true,
			false
		)
	)


	for node: Node in mesh_nodes:

		if not node is MeshInstance3D:

			continue


		var mesh_instance := (
			node
			as
			MeshInstance3D
		)


		if mesh_instance.mesh == null:

			continue


		var local_bounds := (
			mesh_instance.mesh.get_aabb()
		)


		var world_bounds := (
			transform_aabb(
				local_bounds,
				mesh_instance.global_transform
			)
		)


		if not found:

			result = world_bounds

			found = true

		else:

			result = result.merge(
				world_bounds
			)


	return result


# =============================================================
# TRANSFORM AABB
# =============================================================

func transform_aabb(
	aabb: AABB,
	transform: Transform3D
) -> AABB:

	var points: Array[Vector3] = [

		Vector3(
			aabb.position.x,
			aabb.position.y,
			aabb.position.z
		),

		Vector3(
			aabb.end.x,
			aabb.position.y,
			aabb.position.z
		),

		Vector3(
			aabb.position.x,
			aabb.end.y,
			aabb.position.z
		),

		Vector3(
			aabb.end.x,
			aabb.end.y,
			aabb.position.z
		),

		Vector3(
			aabb.position.x,
			aabb.position.y,
			aabb.end.z
		),

		Vector3(
			aabb.end.x,
			aabb.position.y,
			aabb.end.z
		),

		Vector3(
			aabb.position.x,
			aabb.end.y,
			aabb.end.z
		),

		Vector3(
			aabb.end.x,
			aabb.end.y,
			aabb.end.z
		)
	]


	var result := AABB()

	var initialized: bool = false


	for point: Vector3 in points:

		var transformed := (
			transform
			*
			point
		)


		if not initialized:

			result = AABB(
				transformed,
				Vector3.ZERO
			)

			initialized = true

		else:

			result = result.merge(
				AABB(
					transformed,
					Vector3.ZERO
				)
			)


	return result


# =============================================================
# VISUAL CHARACTER VISIBILITY
# =============================================================

func set_visual_character_visible(
	visible_state: bool
) -> void:

	if visual_character == null:

		return


	_set_mesh_visibility(
		visual_character,
		visible_state
	)


func _set_mesh_visibility(
	node: Node,
	visible_state: bool
) -> void:

	if node == null:

		return


	if node is MeshInstance3D:

		var mesh := (
			node
			as
			MeshInstance3D
		)

		mesh.visible = (
			visible_state
		)


	elif node is CSGShape3D:

		var csg := (
			node
			as
			CSGShape3D
		)

		csg.visible = (
			visible_state
		)


	for child: Node in node.get_children():

		_set_mesh_visibility(
			child,
			visible_state
		)


# =============================================================
# CLEAR CHARACTER
# =============================================================

func clear_character() -> void:

	if character_root == null:

		return


	visual_character = null

	_set_native_calibration_controls_enabled(
		false
	)


	for child: Node in character_root.get_children():

		if is_instance_valid(
			child
		):

			child.queue_free()


# =============================================================
# LOCAL ROTATION
# =============================================================

func rotate_local_character() -> void:

	if visual_character == null:

		return


	visual_character.rotation.y += PI


# =============================================================
# NOTIFICATION
# =============================================================

func build_notification() -> void:

	if viewport_ui == null:

		return


	notification_label = Label.new()

	notification_label.name = (
		"ViewportNotification"
	)

	notification_label.text = ""

	notification_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	notification_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	notification_label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	notification_label.visible = false

	notification_label.modulate = Color(
		1.0,
		1.0,
		1.0,
		0.0
	)

	notification_label.add_theme_font_size_override(
		"font_size",
		16
	)

	notification_label.add_theme_color_override(
		"font_color",
		Color(
			0.90,
			0.90,
			0.93,
			1.0
		)
	)

	notification_label.set_anchors_preset(
		Control.PRESET_CENTER_BOTTOM
	)

	notification_label.position = Vector2(
		-180.0,
		-50.0
	)

	notification_label.size = Vector2(
		360.0,
		36.0
	)

	viewport_ui.add_child(
		notification_label
	)


# =============================================================
# SHOW NOTIFICATION
# =============================================================

func show_notification(
	text_value: String
) -> void:

	if notification_label == null:

		return


	if not is_instance_valid(
		notification_label
	):

		return


	var previous_value: Variant = null

	if notification_label.has_meta(
	"notification_tween"
):
		previous_value = notification_label.get_meta(
		"notification_tween"
	)


	if previous_value is Tween:

		var previous_tween := (
			previous_value
			as
			Tween
		)


		if previous_tween.is_valid():

			previous_tween.kill()


	notification_label.text = (
		text_value
	)

	notification_label.visible = true

	notification_label.modulate = Color(
		1.0,
		1.0,
		1.0,
		0.0
	)

	notification_label.position = Vector2(
		-180.0,
		-50.0
	)


	var enter_tween := (
		notification_label.create_tween()
	)


	notification_label.set_meta(
		"notification_tween",
		enter_tween
	)


	enter_tween.set_trans(
		Tween.TRANS_SINE
	)

	enter_tween.set_ease(
		Tween.EASE_OUT
	)


	enter_tween.parallel().tween_property(
		notification_label,
		"modulate:a",
		1.0,
		NOTIFICATION_ANIMATION_TIME
	)


	enter_tween.parallel().tween_property(
		notification_label,
		"position:y",
		-70.0,
		NOTIFICATION_ANIMATION_TIME
	)


	await enter_tween.finished


	if notification_label == null:

		return


	if not is_instance_valid(
		notification_label
	):

		return


	var main_loop := (
		Engine.get_main_loop()
	)


	if main_loop == null:

		return


	if not main_loop is SceneTree:

		return


	var tree := (
		main_loop
		as
		SceneTree
	)


	await tree.create_timer(
		NOTIFICATION_SHOW_TIME
	).timeout


	if notification_label == null:

		return


	if not is_instance_valid(
		notification_label
	):

		return


	var exit_tween := (
		notification_label.create_tween()
	)


	notification_label.set_meta(
		"notification_tween",
		exit_tween
	)


	exit_tween.set_trans(
		Tween.TRANS_SINE
	)

	exit_tween.set_ease(
		Tween.EASE_IN
	)


	exit_tween.parallel().tween_property(
		notification_label,
		"modulate:a",
		0.0,
		NOTIFICATION_ANIMATION_TIME
	)


	exit_tween.parallel().tween_property(
		notification_label,
		"position:y",
		-90.0,
		NOTIFICATION_ANIMATION_TIME
	)


	await exit_tween.finished


	if notification_label != null:

		if is_instance_valid(
			notification_label
		):

			notification_label.visible = false


# =============================================================
# CAMERA UI INTERACTION
# =============================================================

func _mark_camera_interaction() -> void:

	ui_camera_active = true

	_set_ui_calibration_alpha(
		UI_CALIBRATION_ALPHA
	)


# =============================================================
# TEST OBJECT INTERACTION
# =============================================================

func _mark_test_object_interaction() -> void:

	ui_test_object_serial += 1

	var current_serial: int = (
		ui_test_object_serial
	)

	ui_test_object_active = true

	_set_ui_calibration_alpha(
		UI_CALIBRATION_ALPHA
	)


	if root == null:

		return


	var tree := (
		root.get_tree()
	)


	if tree == null:

		return


	tree.create_timer(
		UI_TEST_OBJECT_FEEDBACK_TIME
	).timeout.connect(
		func() -> void:

			if current_serial != ui_test_object_serial:

				return


			ui_test_object_active = false

			_update_ui_visibility_state()
	)


# =============================================================
# TEST OBJECT STATE
# =============================================================

func _update_test_object_ui_state() -> void:

	_update_ui_visibility_state()


# =============================================================
# RESET UI INTERACTION
# =============================================================

func _reset_ui_interaction_state() -> void:

	ui_camera_active = false

	ui_test_object_active = false

	ui_test_object_serial += 1

	_set_ui_calibration_alpha(
		UI_NORMAL_ALPHA
	)


# =============================================================
# CLEAR CURRENT UI INTERACTION
# =============================================================

func _clear_ui_interaction_state() -> void:

	ui_camera_active = false

	ui_test_object_active = false

	ui_test_object_serial += 1

	_update_ui_visibility_state()


# =============================================================
# UI VISIBILITY
# =============================================================

func _update_ui_visibility_state() -> void:

	var calibration_active: bool = (
		ui_camera_active
		or
		ui_test_object_active
	)


	if calibration_active:

		_set_ui_calibration_alpha(
			UI_CALIBRATION_ALPHA
		)

	else:

		_set_ui_calibration_alpha(
			UI_NORMAL_ALPHA
		)


# =============================================================
# SET UI ALPHA
# =============================================================

func _set_ui_calibration_alpha(
	alpha_value: float
) -> void:

	var safe_alpha := clampf(
		alpha_value,
		0.0,
		1.0
	)


	if controls_scroll != null:

		controls_scroll.modulate.a = (
			safe_alpha
		)


	if display_scroll != null:

		display_scroll.modulate.a = (
			safe_alpha
		)


# =============================================================
# EXTERNAL CAMERA UI STATE
# =============================================================

func set_ui_camera_active(
	active_state: bool
) -> void:

	ui_camera_active = active_state

	_update_ui_visibility_state()


# =============================================================
# EXTERNAL TEST OBJECT UI STATE
# =============================================================

func set_ui_test_object_active(
	active_state: bool
) -> void:

	ui_test_object_active = active_state

	_update_ui_visibility_state()
