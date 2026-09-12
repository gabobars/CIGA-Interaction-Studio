class_name CIGAImagePreview3D
extends Control


# =============================================================
# GIZMO OVERLAY
# =============================================================

class GizmoOverlay extends Control:

	var gizmo_center: Vector2 = Vector2.ZERO

	var x_direction: Vector2 = Vector2.RIGHT
	var y_direction: Vector2 = Vector2.UP
	var z_direction: Vector2 = Vector2.RIGHT

	var hover_axis: int = 0
	var drag_axis: int = 0


	func refresh(
		center: Vector2,
		x_axis: Vector2,
		y_axis: Vector2,
		z_axis: Vector2,
		hovered: int,
		dragged: int
	) -> void:

		gizmo_center = center
		x_direction = x_axis
		y_direction = y_axis
		z_direction = z_axis
		hover_axis = hovered
		drag_axis = dragged

		queue_redraw()


	func _draw() -> void:

		_draw_axis(
			x_direction,
			1,
			Color(0.90, 0.24, 0.24, 1.0)
		)

		_draw_axis(
			y_direction,
			2,
			Color(0.35, 0.90, 0.40, 1.0)
		)

		_draw_axis(
			z_direction,
			3,
			Color(0.30, 0.55, 1.00, 1.0)
		)

		draw_circle(
			gizmo_center,
			5.0,
			Color(0.95, 0.95, 0.95, 0.95)
		)

		draw_circle(
			gizmo_center,
			9.0,
			Color(0.05, 0.05, 0.06, 0.95),
			false,
			2.0
		)


	func _draw_axis(
		direction: Vector2,
		axis: int,
		color: Color
	) -> void:

		if direction.length() < 0.001:
			return


		var active: bool = (
			axis == hover_axis
			or
			axis == drag_axis
		)


		var width: float = (
			4.5
			if active
			else
			2.5
		)


		var end: Vector2 = (
			gizmo_center
			+
			direction
		)


		draw_line(
			gizmo_center,
			end,
			color,
			width,
			true
		)


		var unit: Vector2 = (
			direction.normalized()
		)


		var side: Vector2 = Vector2(
			-unit.y,
			unit.x
		)


		var arrow_size: float = (
			11.0
			if active
			else
			9.0
		)


		var base: Vector2 = (
			end
			-
			unit * arrow_size
		)


		draw_colored_polygon(
			PackedVector2Array([
				end,
				base + side * (arrow_size * 0.58),
				base - side * (arrow_size * 0.58)
			]),
			color
		)


# =============================================================
# SIGNALS
# =============================================================

signal image_settings_changed(
	target_name: String,
	image_scale: float,
	offset: Vector3,
	rotation: Vector3,
	mirror_h: bool,
	mirror_v: bool
)

signal live_image_settings_changed(
	settings: Dictionary
)


# =============================================================
# REFERENCES
# =============================================================

var character_runtime: CIGACharacterRuntime = null

var viewport_container: SubViewportContainer = null

var sub_viewport: SubViewport = null

var world: World3D = null

var camera: Camera3D = null

var stage_root: Node3D = null

var character_holder: Node3D = null

var image_holder: Node3D = null

var character_model: Node3D = null

var image_model: Sprite3D = null


# =============================================================
# MAIN UI
# =============================================================

var main_layout: VBoxContainer = null

var normal_toolbar: HBoxContainer = null

var live_toolbar: VBoxContainer = null

var live_toolbar_row_1: HBoxContainer = null

var live_toolbar_row_2: HBoxContainer = null

var status_label: Label = null

var preview_content_root: Control = null


# =============================================================
# LIVE SIDE PANEL
# =============================================================

var live_side_panel: PanelContainer = null

var live_controls_scroll: ScrollContainer = null

var live_controls_root: VBoxContainer = null


# =============================================================
# VIEWPORT OVERLAY
# =============================================================

var viewport_overlay: Control = null


var gizmo_overlay: Control = null


# =============================================================
# NORMAL TOOLBAR
# =============================================================

var target_selector: OptionButton = null

var mirror_h_button: CheckButton = null

var mirror_v_button: CheckButton = null

var scale_label: Label = null


# =============================================================
# LIVE TOP CONTROLS
# =============================================================

var live_title_label: Label = null

var live_target_selector: OptionButton = null

var live_mirror_h_button: CheckButton = null

var live_mirror_v_button: CheckButton = null


# =============================================================
# LIVE SIDE CONTROLS
# =============================================================

var scale_mode_selector: OptionButton = null

var scale_fixed_spin: SpinBox = null

var scale_min_spin: SpinBox = null

var scale_max_spin: SpinBox = null


var offset_x_mode_selector: OptionButton = null

var offset_x_fixed_spin: SpinBox = null

var offset_x_min_spin: SpinBox = null

var offset_x_max_spin: SpinBox = null


var offset_y_mode_selector: OptionButton = null

var offset_y_fixed_spin: SpinBox = null

var offset_y_min_spin: SpinBox = null

var offset_y_max_spin: SpinBox = null


var offset_z_mode_selector: OptionButton = null

var offset_z_fixed_spin: SpinBox = null

var offset_z_min_spin: SpinBox = null

var offset_z_max_spin: SpinBox = null


var rotation_x_mode_selector: OptionButton = null

var rotation_x_fixed_spin: SpinBox = null

var rotation_x_min_spin: SpinBox = null

var rotation_x_max_spin: SpinBox = null


var rotation_y_mode_selector: OptionButton = null

var rotation_y_fixed_spin: SpinBox = null

var rotation_y_min_spin: SpinBox = null

var rotation_y_max_spin: SpinBox = null


var rotation_z_mode_selector: OptionButton = null

var rotation_z_fixed_spin: SpinBox = null

var rotation_z_min_spin: SpinBox = null

var rotation_z_max_spin: SpinBox = null


# =============================================================
# IMAGE STATE
# =============================================================

var current_image_path: String = ""

var current_texture: Texture2D = null

var current_target: String = "HeadHitPoint"

var current_scale: float = 1.0

var current_offset: Vector3 = Vector3.ZERO

var current_rotation: Vector3 = Vector3.ZERO

var current_mirror_h: bool = false

var current_mirror_v: bool = false


# =============================================================
# LIVE STATE
# =============================================================

var live_mode_enabled: bool = false


var live_scale_mode: String = "FIXED"

var live_scale_fixed: float = 1.0

var live_scale_min: float = 0.8

var live_scale_max: float = 1.2


var live_offset_x_mode: String = "FIXED"

var live_offset_x_fixed: float = 0.0

var live_offset_x_min: float = 0.0

var live_offset_x_max: float = 0.0


var live_offset_y_mode: String = "FIXED"

var live_offset_y_fixed: float = 0.0

var live_offset_y_min: float = 0.0

var live_offset_y_max: float = 0.0


var live_offset_z_mode: String = "FIXED"

var live_offset_z_fixed: float = 0.0

var live_offset_z_min: float = 0.0

var live_offset_z_max: float = 0.0


var live_rotation_x_mode: String = "FIXED"

var live_rotation_x_fixed: float = 0.0

var live_rotation_x_min: float = 0.0

var live_rotation_x_max: float = 0.0


var live_rotation_y_mode: String = "FIXED"

var live_rotation_y_fixed: float = 0.0

var live_rotation_y_min: float = 0.0

var live_rotation_y_max: float = 0.0


var live_rotation_z_mode: String = "FIXED"

var live_rotation_z_fixed: float = 0.0

var live_rotation_z_min: float = 0.0

var live_rotation_z_max: float = 0.0


# =============================================================
# LIVE PREVIEW SAMPLE
# =============================================================

var live_preview_scale: float = 1.0

var live_preview_offset: Vector3 = Vector3.ZERO

var live_preview_rotation: Vector3 = Vector3.ZERO


# =============================================================
# IMAGE DRAG
# =============================================================

var image_dragging: bool = false

var image_drag_mode: int = 0

var image_drag_start_mouse: Vector2 = Vector2.ZERO

var image_drag_start_offset: Vector3 = Vector3.ZERO

var image_drag_start_scale: float = 1.0

var image_drag_start_rotation: Vector3 = Vector3.ZERO

var image_drag_start_local_point: Vector3 = Vector3.ZERO

var image_drag_parent: Node3D = null


const IMAGE_DRAG_MOVE: int = 1

const IMAGE_DRAG_SCALE: int = 2

const IMAGE_DRAG_ROTATE: int = 3


# =============================================================
# GIZMO
# =============================================================

const GIZMO_AXIS_NONE: int = 0

const GIZMO_AXIS_X: int = 1

const GIZMO_AXIS_Y: int = 2

const GIZMO_AXIS_Z: int = 3


var gizmo_hover_axis: int = GIZMO_AXIS_NONE

var gizmo_drag_axis: int = GIZMO_AXIS_NONE

var gizmo_dragging: bool = false

var gizmo_drag_start_mouse: Vector2 = Vector2.ZERO

var gizmo_drag_start_offset: Vector3 = Vector3.ZERO


const GIZMO_LENGTH: float = 72.0

const GIZMO_HIT_RADIUS: float = 13.0


# =============================================================
# CAMERA
# =============================================================

var camera_target: Vector3 = Vector3(
	0.0,
	1.0,
	0.0
)

var manual_camera_position: Vector3 = Vector3(
	0.0,
	1.5,
	4.0
)

var manual_camera_fov: float = 42.0

var camera_dragging: bool = false

var camera_drag_mode: int = 0


const CAMERA_ORBIT: int = 1

const CAMERA_PAN: int = 2

const CAMERA_ROTATE_SENSITIVITY: float = 0.003

const CAMERA_PAN_SENSITIVITY: float = 0.0015

const CAMERA_ZOOM_STEP: float = 0.12

const CAMERA_MIN_DISTANCE: float = 0.20

const CAMERA_MAX_DISTANCE: float = 100.0


# =============================================================
# CONSTANTS
# =============================================================

const IMAGE_BASE_WIDTH: float = 0.35

const GROUND_Y: float = 0.0


# =============================================================
# READY
# =============================================================

func _ready() -> void:

	mouse_filter = Control.MOUSE_FILTER_STOP

	_build_preview()

	_refresh_runtime_reference()

	set_process(true)

	call_deferred(
		"_update_preview_layout"
	)


# =============================================================
# RUNTIME REFERENCE
# =============================================================

func _refresh_runtime_reference() -> void:

	var found: Node = get_node_or_null(
		"/root/CIGACharacterRuntime"
	)


	if found != null and found is CIGACharacterRuntime:

		character_runtime = (
			found
			as
			CIGACharacterRuntime
		)

		return


	var tree_root: Window = get_tree().root

	var candidate_nodes: Array[Node] = (
		tree_root.find_children(
			"*",
			"CIGACharacterRuntime",
			true,
			false
		)
	)


	for candidate: Node in candidate_nodes:

		if candidate is CIGACharacterRuntime:

			character_runtime = (
				candidate
				as
				CIGACharacterRuntime
			)

			return


# =============================================================
# BUILD
# =============================================================

func _build_preview() -> void:

	main_layout = VBoxContainer.new()

	main_layout.name = (
		"PreviewMainLayout"
	)

	main_layout.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	main_layout.add_theme_constant_override(
		"separation",
		6
	)

	add_child(
		main_layout
	)


	# =========================================================
	# NORMAL TOOLBAR
	# =========================================================

	normal_toolbar = HBoxContainer.new()

	normal_toolbar.name = (
		"NormalToolbar"
	)

	normal_toolbar.custom_minimum_size.y = 42.0

	normal_toolbar.add_theme_constant_override(
		"separation",
		8
	)

	main_layout.add_child(
		normal_toolbar
	)


	_build_normal_toolbar()


	# =========================================================
	# LIVE TOOLBAR
	# =========================================================

	live_toolbar = VBoxContainer.new()

	live_toolbar.name = (
		"LiveToolbar"
	)

	live_toolbar.custom_minimum_size.y = 78.0

	live_toolbar.add_theme_constant_override(
		"separation",
		4
	)

	live_toolbar.visible = false

	main_layout.add_child(
		live_toolbar
	)


	_build_live_toolbar()


	# =========================================================
	# STATUS
	# =========================================================

	status_label = Label.new()

	status_label.name = (
		"StatusLabel"
	)

	status_label.text = (
		"LMB = MOVE     "
		+
		"CTRL + LMB = SCALE     "
		+
		"SHIFT + LMB = ROTATE     "
		+
		"RMB = ORBIT     "
		+
		"CTRL + RMB = PAN     "
		+
		"WHEEL = ZOOM"
	)

	status_label.custom_minimum_size.y = 28.0

	status_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	status_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	status_label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	main_layout.add_child(
		status_label
	)


	# =========================================================
	# CONTENT ROOT
	# =========================================================

	preview_content_root = Control.new()

	preview_content_root.name = (
		"PreviewContentRoot"
	)

	preview_content_root.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	preview_content_root.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)

	main_layout.add_child(
		preview_content_root
	)


	# =========================================================
	# VIEWPORT
	# =========================================================

	viewport_container = SubViewportContainer.new()

	viewport_container.name = (
		"ViewportContainer"
	)

	viewport_container.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	viewport_container.stretch = true

	viewport_container.gui_input.connect(
		_on_viewport_gui_input
	)

	preview_content_root.add_child(
		viewport_container
	)


	# =========================================================
	# LIVE SIDE PANEL
	# =========================================================

	live_side_panel = PanelContainer.new()

	live_side_panel.name = (
		"LiveSidePanel"
	)

	live_side_panel.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	live_side_panel.visible = false

	preview_content_root.add_child(
		live_side_panel
	)


	live_controls_scroll = ScrollContainer.new()

	live_controls_scroll.name = (
		"LiveControlsScroll"
	)

	live_controls_scroll.horizontal_scroll_mode = (
		ScrollContainer.SCROLL_MODE_DISABLED
	)

	live_controls_scroll.vertical_scroll_mode = (
		ScrollContainer.SCROLL_MODE_AUTO
	)

	live_controls_scroll.follow_focus = true

	live_side_panel.add_child(
		live_controls_scroll
	)


	live_controls_root = VBoxContainer.new()

	live_controls_root.name = (
		"LiveControlsRoot"
	)

	live_controls_root.custom_minimum_size = Vector2(
		400.0,
		0.0
	)

	live_controls_root.add_theme_constant_override(
		"separation",
		7
	)

	live_controls_scroll.add_child(
		live_controls_root
	)


	_build_live_side_controls()


	# =========================================================
	# SUBVIEWPORT
	# =========================================================

	sub_viewport = SubViewport.new()

	sub_viewport.name = (
		"ImagePreviewViewport"
	)

	sub_viewport.size = Vector2i(
		1200,
		760
	)

	sub_viewport.render_target_update_mode = (
		SubViewport.UPDATE_ALWAYS
	)

	sub_viewport.transparent_bg = false

	sub_viewport.handle_input_locally = true

	viewport_container.add_child(
		sub_viewport
	)


	world = World3D.new()

	sub_viewport.world_3d = (
		world
	)


	# =========================================================
	# STAGE
	# =========================================================

	stage_root = Node3D.new()

	stage_root.name = (
		"StageRoot"
	)

	sub_viewport.add_child(
		stage_root
	)


	# =========================================================
	# ENVIRONMENT
	# =========================================================

	var environment_node := WorldEnvironment.new()

	environment_node.name = (
		"WorldEnvironment"
	)


	var environment := Environment.new()

	environment.background_mode = (
		Environment.BG_COLOR
	)

	environment.background_color = Color(
		0.025,
		0.025,
		0.035,
		1.0
	)

	environment.ambient_light_source = (
		Environment.AMBIENT_SOURCE_COLOR
	)

	environment.ambient_light_color = Color(
		0.65,
		0.65,
		0.70,
		1.0
	)

	environment.ambient_light_energy = 0.65

	environment_node.environment = (
		environment
	)

	stage_root.add_child(
		environment_node
	)


	# =========================================================
	# LIGHT
	# =========================================================

	var light := DirectionalLight3D.new()

	light.name = (
		"KeyLight"
	)

	light.rotation_degrees = Vector3(
		-35.0,
		-25.0,
		0.0
	)

	light.light_energy = 1.2

	stage_root.add_child(
		light
	)


	# =========================================================
	# GROUND
	# =========================================================

	var ground_mesh := MeshInstance3D.new()

	ground_mesh.name = (
		"Ground"
	)

	var plane := PlaneMesh.new()

	plane.size = Vector2(
		10.0,
		10.0
	)

	ground_mesh.mesh = plane

	ground_mesh.position.y = (
		GROUND_Y
	)


	var ground_material := StandardMaterial3D.new()

	ground_material.albedo_color = Color(
		0.05,
		0.05,
		0.06,
		1.0
	)

	ground_material.roughness = 0.95

	ground_mesh.material_override = (
		ground_material
	)

	stage_root.add_child(
		ground_mesh
	)


	# =========================================================
	# CHARACTER
	# =========================================================

	character_holder = Node3D.new()

	character_holder.name = (
		"CharacterHolder"
	)

	stage_root.add_child(
		character_holder
	)


	# =========================================================
	# IMAGE
	# =========================================================

	image_holder = Node3D.new()

	image_holder.name = (
		"ImageHolder"
	)

	stage_root.add_child(
		image_holder
	)


	# =========================================================
	# CAMERA
	# =========================================================

	camera = Camera3D.new()

	camera.name = (
		"PreviewCamera"
	)

	camera.current = true

	camera.fov = manual_camera_fov

	stage_root.add_child(
		camera
	)


	# =========================================================
	# VIEWPORT OVERLAY
	# =========================================================

	viewport_overlay = Control.new()

	viewport_overlay.name = (
		"ViewportOverlay"
	)

	viewport_overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	viewport_overlay.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	preview_content_root.add_child(
		viewport_overlay
	)



	# =========================================================
	# GIZMO OVERLAY
	# =========================================================

	gizmo_overlay = GizmoOverlay.new()

	gizmo_overlay.name = (
		"TransformGizmoOverlay"
	)

	gizmo_overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	gizmo_overlay.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	viewport_overlay.add_child(
		gizmo_overlay
	)


# =============================================================
# LAYOUT
# =============================================================

func _notification(
	what: int
) -> void:

	if what != NOTIFICATION_RESIZED:
		return

	call_deferred(
		"_update_preview_layout"
	)


func _update_preview_layout() -> void:

	if (
		preview_content_root == null
		or
		viewport_container == null
	):

		return


	var content_size := (
		preview_content_root.size
	)


	var side_width: float = 0.0


	if live_mode_enabled:

		side_width = 430.0


	# ---------------------------------------------------------
	# LIVE PANEL
	# ---------------------------------------------------------

	if live_side_panel != null:

		live_side_panel.visible = (
			live_mode_enabled
		)

		live_side_panel.position = Vector2(
			0.0,
			0.0
		)

		live_side_panel.size = Vector2(
			side_width,
			content_size.y
		)


	# ---------------------------------------------------------
	# VIEWPORT
	# ---------------------------------------------------------

	viewport_container.position = Vector2(
		side_width + (
			8.0
			if live_mode_enabled
			else
			0.0
		),
		0.0
	)

	viewport_container.size = Vector2(
		maxf(
			1.0,
			content_size.x
			-
			side_width
			-
			(
				8.0
				if live_mode_enabled
				else
				0.0
			)
		),
		maxf(
			1.0,
			content_size.y
		)
	)


	# ---------------------------------------------------------
	# OVERLAY
	# ---------------------------------------------------------

	if viewport_overlay != null:

		viewport_overlay.position = Vector2(
			0.0,
			0.0
		)

		viewport_overlay.size = (
			content_size
		)


# =============================================================
# NORMAL TOOLBAR
# =============================================================

func _build_normal_toolbar() -> void:

	var target_label := Label.new()

	target_label.text = (
		"TARGET"
	)

	target_label.custom_minimum_size = Vector2(
		60.0,
		36.0
	)

	target_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	normal_toolbar.add_child(
		target_label
	)


	target_selector = OptionButton.new()

	target_selector.name = (
		"TargetSelector"
	)

	target_selector.custom_minimum_size = Vector2(
		190.0,
		36.0
	)


	for target: String in [
		"HeadHitPoint",
		"ChestHitPoint",
		"LeftShoulderHitPoint",
		"RightShoulderHitPoint",
		"LeftArmHitPoint",
		"RightArmHitPoint",
		"LeftLegHitPoint",
		"RightLegHitPoint"
	]:

		target_selector.add_item(
			target
		)


	target_selector.item_selected.connect(
		_on_target_selected
	)

	normal_toolbar.add_child(
		target_selector
	)


	mirror_h_button = CheckButton.new()

	mirror_h_button.text = (
		"MIRROR H"
	)

	mirror_h_button.custom_minimum_size = Vector2(
		105.0,
		36.0
	)

	mirror_h_button.toggled.connect(
		_on_mirror_h_toggled
	)

	normal_toolbar.add_child(
		mirror_h_button
	)


	mirror_v_button = CheckButton.new()

	mirror_v_button.text = (
		"MIRROR V"
	)

	mirror_v_button.custom_minimum_size = Vector2(
		105.0,
		36.0
	)

	mirror_v_button.toggled.connect(
		_on_mirror_v_toggled
	)

	normal_toolbar.add_child(
		mirror_v_button
	)


	scale_label = Label.new()

	scale_label.text = (
		"SCALE 1.00x"
	)

	scale_label.custom_minimum_size = Vector2(
		120.0,
		36.0
	)

	scale_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	normal_toolbar.add_child(
		scale_label
	)


# =============================================================
# LIVE TOP TOOLBAR
# =============================================================

func _build_live_toolbar() -> void:

	live_toolbar_row_1 = HBoxContainer.new()

	live_toolbar_row_1.add_theme_constant_override(
		"separation",
		8
	)

	live_toolbar.add_child(
		live_toolbar_row_1
	)


	live_toolbar_row_2 = HBoxContainer.new()

	live_toolbar_row_2.add_theme_constant_override(
		"separation",
		8
	)

	live_toolbar.add_child(
		live_toolbar_row_2
	)


	live_title_label = Label.new()

	live_title_label.text = (
		"DISPLAY IMAGE LIVE"
	)

	live_title_label.custom_minimum_size = Vector2(
		190.0,
		30.0
	)

	live_title_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	live_title_label.add_theme_font_size_override(
		"font_size",
		17
	)

	live_toolbar_row_1.add_child(
		live_title_label
	)


	var target_label := Label.new()

	target_label.text = (
		"TARGET"
	)

	target_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	live_toolbar_row_1.add_child(
		target_label
	)


	live_target_selector = OptionButton.new()

	live_target_selector.custom_minimum_size = Vector2(
		180.0,
		30.0
	)


	for target: String in [
		"HeadHitPoint",
		"ChestHitPoint",
		"LeftShoulderHitPoint",
		"RightShoulderHitPoint",
		"LeftArmHitPoint",
		"RightArmHitPoint",
		"LeftLegHitPoint",
		"RightLegHitPoint"
	]:

		live_target_selector.add_item(
			target
		)


	live_target_selector.item_selected.connect(
		_on_live_target_selected
	)

	live_toolbar_row_1.add_child(
		live_target_selector
	)


	live_mirror_h_button = CheckButton.new()

	live_mirror_h_button.text = (
		"MIRROR H"
	)

	live_mirror_h_button.toggled.connect(
		_on_live_mirror_h_toggled
	)

	live_toolbar_row_1.add_child(
		live_mirror_h_button
	)


	live_mirror_v_button = CheckButton.new()

	live_mirror_v_button.text = (
		"MIRROR V"
	)

	live_mirror_v_button.toggled.connect(
		_on_live_mirror_v_toggled
	)

	live_toolbar_row_1.add_child(
		live_mirror_v_button
	)


	var live_help := Label.new()

	live_help.text = (
		"Configure the live transform in the panel"
	)

	live_help.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	live_help.add_theme_color_override(
		"font_color",
		Color(
			0.65,
			0.65,
			0.65,
			1.0
		)
	)

	live_toolbar_row_2.add_child(
		live_help
	)


# =============================================================
# LIVE SIDE CONTROLS
# =============================================================

func _build_live_side_controls() -> void:

	var title := Label.new()

	title.text = (
		"LIVE TRANSFORM"
	)

	title.custom_minimum_size.y = (
		32.0
	)

	title.add_theme_font_size_override(
		"font_size",
		17
	)

	live_controls_root.add_child(
		title
	)


	


	_create_live_parameter_side(
		"SCALE",
		"scale",
		0.01,
		10.0,
		0.01
	)

	_create_live_parameter_side(
		"OFFSET X",
		"offset_x",
		-10.0,
		10.0,
		0.01
	)

	_create_live_parameter_side(
		"OFFSET Y",
		"offset_y",
		-10.0,
		10.0,
		0.01
	)

	_create_live_parameter_side(
		"OFFSET Z",
		"offset_z",
		-10.0,
		10.0,
		0.01
	)

	_create_live_parameter_side(
		"ROTATION X",
		"rotation_x",
		-180.0,
		180.0,
		0.1
	)

	_create_live_parameter_side(
		"ROTATION Y",
		"rotation_y",
		-180.0,
		180.0,
		0.1
	)

	_create_live_parameter_side(
		"ROTATION Z",
		"rotation_z",
		-180.0,
		180.0,
		0.1
	)


# =============================================================
# LIVE SIDE PARAMETER
# =============================================================

func _create_live_parameter_side(
	label_text: String,
	parameter_name: String,
	minimum: float,
	maximum: float,
	step: float
) -> void:

	var panel := PanelContainer.new()

	panel.custom_minimum_size = Vector2(
		0.0,
		74.0
	)

	live_controls_root.add_child(
		panel
	)


	var root := VBoxContainer.new()

	root.add_theme_constant_override(
		"separation",
		3
	)

	panel.add_child(
		root
	)


	var label := Label.new()

	label.text = (
		label_text
	)

	label.custom_minimum_size.y = (
		24.0
	)

	label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	root.add_child(
		label
	)


	var row := HBoxContainer.new()

	row.add_theme_constant_override(
		"separation",
		5
	)

	root.add_child(
		row
	)


	var selector := _create_mode_selector()

	row.add_child(
		selector
	)


	var fixed_spin := _create_spinbox(
		minimum,
		maximum,
		step,
		0.0
	)

	row.add_child(
		fixed_spin
	)


	var min_spin := _create_spinbox(
		minimum,
		maximum,
		step,
		0.0
	)

	row.add_child(
		min_spin
	)


	var max_spin := _create_spinbox(
		minimum,
		maximum,
		step,
		0.0
	)

	row.add_child(
		max_spin
	)


	match parameter_name:

		"scale":

			scale_mode_selector = selector

			scale_fixed_spin = fixed_spin

			scale_min_spin = min_spin

			scale_max_spin = max_spin


			selector.item_selected.connect(
				_on_scale_mode_selected
			)

			fixed_spin.value_changed.connect(
				_on_scale_fixed_changed
			)

			min_spin.value_changed.connect(
				_on_scale_min_changed
			)

			max_spin.value_changed.connect(
				_on_scale_max_changed
			)


		"offset_x":

			offset_x_mode_selector = selector

			offset_x_fixed_spin = fixed_spin

			offset_x_min_spin = min_spin

			offset_x_max_spin = max_spin


			selector.item_selected.connect(
				_on_offset_x_mode_selected
			)

			fixed_spin.value_changed.connect(
				_on_offset_x_value_changed
			)

			min_spin.value_changed.connect(
				_on_offset_x_value_changed
			)

			max_spin.value_changed.connect(
				_on_offset_x_value_changed
			)


		"offset_y":

			offset_y_mode_selector = selector

			offset_y_fixed_spin = fixed_spin

			offset_y_min_spin = min_spin

			offset_y_max_spin = max_spin


			selector.item_selected.connect(
				_on_offset_y_mode_selected
			)

			fixed_spin.value_changed.connect(
				_on_offset_y_value_changed
			)

			min_spin.value_changed.connect(
				_on_offset_y_value_changed
			)

			max_spin.value_changed.connect(
				_on_offset_y_value_changed
			)


		"offset_z":

			offset_z_mode_selector = selector

			offset_z_fixed_spin = fixed_spin

			offset_z_min_spin = min_spin

			offset_z_max_spin = max_spin


			selector.item_selected.connect(
				_on_offset_z_mode_selected
			)

			fixed_spin.value_changed.connect(
				_on_offset_z_value_changed
			)

			min_spin.value_changed.connect(
				_on_offset_z_value_changed
			)

			max_spin.value_changed.connect(
				_on_offset_z_value_changed
			)


		"rotation_x":

			rotation_x_mode_selector = selector

			rotation_x_fixed_spin = fixed_spin

			rotation_x_min_spin = min_spin

			rotation_x_max_spin = max_spin


			selector.item_selected.connect(
				_on_rotation_x_mode_selected
			)

			fixed_spin.value_changed.connect(
				_on_rotation_x_value_changed
			)

			min_spin.value_changed.connect(
				_on_rotation_x_value_changed
			)

			max_spin.value_changed.connect(
				_on_rotation_x_value_changed
			)


		"rotation_y":

			rotation_y_mode_selector = selector

			rotation_y_fixed_spin = fixed_spin

			rotation_y_min_spin = min_spin

			rotation_y_max_spin = max_spin


			selector.item_selected.connect(
				_on_rotation_y_mode_selected
			)

			fixed_spin.value_changed.connect(
				_on_rotation_y_value_changed
			)

			min_spin.value_changed.connect(
				_on_rotation_y_value_changed
			)

			max_spin.value_changed.connect(
				_on_rotation_y_value_changed
			)


		"rotation_z":

			rotation_z_mode_selector = selector

			rotation_z_fixed_spin = fixed_spin

			rotation_z_min_spin = min_spin

			rotation_z_max_spin = max_spin


			selector.item_selected.connect(
				_on_rotation_z_mode_selected
			)

			fixed_spin.value_changed.connect(
				_on_rotation_z_value_changed
			)

			min_spin.value_changed.connect(
				_on_rotation_z_value_changed
			)

			max_spin.value_changed.connect(
				_on_rotation_z_value_changed
			)


	_update_live_axis_control_visibility(
		selector,
		fixed_spin,
		min_spin,
		max_spin
	)


# =============================================================
# MODE SELECTOR
# =============================================================

func _create_mode_selector() -> OptionButton:

	var selector := OptionButton.new()

	selector.custom_minimum_size = Vector2(
		84.0,
		30.0
	)

	selector.add_item(
		"FIXED"
	)

	selector.add_item(
		"RANDOM"
	)

	return selector


# =============================================================
# SPINBOX
# =============================================================

func _create_spinbox(
	minimum: float,
	maximum: float,
	step: float,
	value: float
) -> SpinBox:

	var spin := SpinBox.new()

	spin.min_value = minimum

	spin.max_value = maximum

	spin.step = step

	spin.value = value

	spin.allow_greater = false

	spin.allow_lesser = false

	spin.custom_minimum_size = Vector2(
		85.0,
		30.0
	)

	return spin


# =============================================================
# NORMAL IMAGE
# =============================================================

func set_image_texture(
	image_path: String,
	texture: Texture2D,
	target_name: String = "HeadHitPoint",
	scale_value: float = 1.0,
	offset: Vector3 = Vector3.ZERO,
	rotation: Vector3 = Vector3.ZERO,
	mirror_x: bool = false,
	mirror_y: bool = false
) -> void:

	var resolved_texture: Texture2D = texture

	# =========================================================
	# USER IMAGE FALLBACK
	# =========================================================

	if (
		resolved_texture == null
		and
		not image_path.is_empty()
	):

		var image := Image.new()

		var error := image.load(
			image_path
		)

		if error == OK and not image.is_empty():

			resolved_texture = (
				ImageTexture.create_from_image(
					image
				)
			)

			print(
				"[CIGA IMAGE PREVIEW] USER IMAGE LOADED | ",
				image.get_width(),
				"x",
				image.get_height()
			)

		else:

			push_warning(
				"[CIGA IMAGE PREVIEW] USER IMAGE LOAD FAILED | "
				+
				image_path
				+
				" | ERROR="
				+
				error_string(
					error
				)
			)


	current_image_path = image_path
	current_texture = resolved_texture

	current_target = _normalize_hitpoint(
		target_name
	)

	current_scale = clampf(
		scale_value,
		0.01,
		10.0
	)

	current_offset = offset
	current_rotation = rotation

	current_mirror_h = mirror_x
	current_mirror_v = mirror_y


	_ensure_character()
	_ensure_image()

	_update_image_transform()
	_frame_camera_to_character()
	_update_preview_layout()
# =============================================================
# LIVE MODE
# =============================================================

func set_live_mode(
	enabled: bool,
	settings: Dictionary = {}
) -> void:

	live_mode_enabled = enabled

	normal_toolbar.visible = (
		not enabled
	)

	live_toolbar.visible = enabled

	live_side_panel.visible = enabled


	if not enabled:

		_update_preview_layout()

		return


	_apply_live_settings_dictionary(
		settings
	)

	_update_live_controls_from_state()

	_update_live_preview_from_live_settings(
		true
	)

	_update_preview_layout()


# =============================================================
# LIVE PLACEHOLDER
# =============================================================

func set_live_placeholder(
	texture: Texture2D,
	target_name: String = "HeadHitPoint",
	settings: Dictionary = {}
) -> void:

	live_mode_enabled = true

	normal_toolbar.visible = false

	live_toolbar.visible = true

	live_side_panel.visible = true

	current_image_path = ""

	current_texture = texture

	current_target = _normalize_hitpoint(
		target_name
	)


	_apply_live_settings_dictionary(
		settings
	)


	_ensure_character()

	_ensure_image()

	_update_live_controls_from_state()

	_update_live_target_selector()

	_update_live_mirror_buttons()

	_update_live_preview_from_live_settings(
		true
	)

	_update_image_transform()

	_frame_camera_to_character()

	_update_preview_layout()


# =============================================================
# NORMAL SETTINGS
# =============================================================

func update_image_settings(
	target_name: String,
	image_scale: float,
	offset: Vector3,
	rotation: Vector3,
	mirror_h: bool,
	mirror_v: bool
) -> void:

	current_target = _normalize_hitpoint(
		target_name
	)

	current_scale = clampf(
		image_scale,
		0.01,
		10.0
	)

	current_offset = offset

	current_rotation = rotation

	current_mirror_h = mirror_h

	current_mirror_v = mirror_v


	_update_target_selector()

	_update_mirror_buttons()

	_update_image_transform()


func get_image_settings() -> Dictionary:

	return {
		"target":
			current_target,

		"scale":
			current_scale,

		"offset":
			current_offset,

		"rotation":
			current_rotation,

		"mirror_h":
			current_mirror_h,

		"mirror_v":
			current_mirror_v
	}


# =============================================================
# GET LIVE SETTINGS
# =============================================================

func get_live_settings() -> Dictionary:

	_update_live_modes_from_ui()

	_update_live_values_from_ui()

	_normalize_live_ranges()


	return {
		"target":
			current_target,

		"scale_mode":
			live_scale_mode,

		"scale":
			live_scale_fixed,

		"scale_min":
			live_scale_min,

		"scale_max":
			live_scale_max,


		"offset_x_mode":
			live_offset_x_mode,

		"offset_x":
			live_offset_x_fixed,

		"offset_x_min":
			live_offset_x_min,

		"offset_x_max":
			live_offset_x_max,


		"offset_y_mode":
			live_offset_y_mode,

		"offset_y":
			live_offset_y_fixed,

		"offset_y_min":
			live_offset_y_min,

		"offset_y_max":
			live_offset_y_max,


		"offset_z_mode":
			live_offset_z_mode,

		"offset_z":
			live_offset_z_fixed,

		"offset_z_min":
			live_offset_z_min,

		"offset_z_max":
			live_offset_z_max,


		"rotation_x_mode":
			live_rotation_x_mode,

		"rotation_x":
			live_rotation_x_fixed,

		"rotation_x_min":
			live_rotation_x_min,

		"rotation_x_max":
			live_rotation_x_max,


		"rotation_y_mode":
			live_rotation_y_mode,

		"rotation_y":
			live_rotation_y_fixed,

		"rotation_y_min":
			live_rotation_y_min,

		"rotation_y_max":
			live_rotation_y_max,


		"rotation_z_mode":
			live_rotation_z_mode,

		"rotation_z":
			live_rotation_z_fixed,

		"rotation_z_min":
			live_rotation_z_min,

		"rotation_z_max":
			live_rotation_z_max,


		"mirror_h":
			current_mirror_h,

		"mirror_v":
			current_mirror_v
	}


# =============================================================
# UPDATE LIVE UI
# =============================================================

func _update_live_controls_from_state() -> void:

	if scale_mode_selector == null:

		return


	scale_mode_selector.select(
		1
		if live_scale_mode == "RANDOM"
		else
		0
	)

	scale_fixed_spin.set_value_no_signal(
		live_scale_fixed
	)

	scale_min_spin.set_value_no_signal(
		live_scale_min
	)

	scale_max_spin.set_value_no_signal(
		live_scale_max
	)


	_set_axis_controls_from_state(
		offset_x_mode_selector,
		offset_x_fixed_spin,
		offset_x_min_spin,
		offset_x_max_spin,
		live_offset_x_mode,
		live_offset_x_fixed,
		live_offset_x_min,
		live_offset_x_max
	)


	_set_axis_controls_from_state(
		offset_y_mode_selector,
		offset_y_fixed_spin,
		offset_y_min_spin,
		offset_y_max_spin,
		live_offset_y_mode,
		live_offset_y_fixed,
		live_offset_y_min,
		live_offset_y_max
	)


	_set_axis_controls_from_state(
		offset_z_mode_selector,
		offset_z_fixed_spin,
		offset_z_min_spin,
		offset_z_max_spin,
		live_offset_z_mode,
		live_offset_z_fixed,
		live_offset_z_min,
		live_offset_z_max
	)


	_set_axis_controls_from_state(
		rotation_x_mode_selector,
		rotation_x_fixed_spin,
		rotation_x_min_spin,
		rotation_x_max_spin,
		live_rotation_x_mode,
		live_rotation_x_fixed,
		live_rotation_x_min,
		live_rotation_x_max
	)


	_set_axis_controls_from_state(
		rotation_y_mode_selector,
		rotation_y_fixed_spin,
		rotation_y_min_spin,
		rotation_y_max_spin,
		live_rotation_y_mode,
		live_rotation_y_fixed,
		live_rotation_y_min,
		live_rotation_y_max
	)


	_set_axis_controls_from_state(
		rotation_z_mode_selector,
		rotation_z_fixed_spin,
		rotation_z_min_spin,
		rotation_z_max_spin,
		live_rotation_z_mode,
		live_rotation_z_fixed,
		live_rotation_z_min,
		live_rotation_z_max
	)


	_update_live_scale_ui()

	_update_live_axis_control_visibility(
		offset_x_mode_selector,
		offset_x_fixed_spin,
		offset_x_min_spin,
		offset_x_max_spin
	)

	_update_live_axis_control_visibility(
		offset_y_mode_selector,
		offset_y_fixed_spin,
		offset_y_min_spin,
		offset_y_max_spin
	)

	_update_live_axis_control_visibility(
		offset_z_mode_selector,
		offset_z_fixed_spin,
		offset_z_min_spin,
		offset_z_max_spin
	)

	_update_live_axis_control_visibility(
		rotation_x_mode_selector,
		rotation_x_fixed_spin,
		rotation_x_min_spin,
		rotation_x_max_spin
	)

	_update_live_axis_control_visibility(
		rotation_y_mode_selector,
		rotation_y_fixed_spin,
		rotation_y_min_spin,
		rotation_y_max_spin
	)

	_update_live_axis_control_visibility(
		rotation_z_mode_selector,
		rotation_z_fixed_spin,
		rotation_z_min_spin,
		rotation_z_max_spin
	)

	_update_live_target_selector()

	_update_live_mirror_buttons()


func _set_axis_controls_from_state(
	selector: OptionButton,
	fixed_spin: SpinBox,
	min_spin: SpinBox,
	max_spin: SpinBox,
	mode: String,
	fixed_value: float,
	min_value: float,
	max_value: float
) -> void:

	if selector != null:

		selector.select(
			1
			if mode == "RANDOM"
			else
			0
		)


	if fixed_spin != null:

		fixed_spin.set_value_no_signal(
			fixed_value
		)


	if min_spin != null:

		min_spin.set_value_no_signal(
			min_value
		)


	if max_spin != null:

		max_spin.set_value_no_signal(
			max_value
		)


# =============================================================
# APPLY LIVE SETTINGS DICTIONARY
# =============================================================

func _apply_live_settings_dictionary(
	settings: Dictionary
) -> void:

	if settings.is_empty():

		return


	current_target = _normalize_hitpoint(
		str(
			settings.get(
				"target",
				current_target
			)
		)
	)


	live_scale_mode = str(
		settings.get(
			"scale_mode",
			"FIXED"
		)
	).to_upper().strip_edges()


	if live_scale_mode != "RANDOM":

		live_scale_mode = "FIXED"


	live_scale_fixed = float(
		settings.get(
			"scale",
			1.0
		)
	)

	live_scale_min = float(
		settings.get(
			"scale_min",
			0.8
		)
	)

	live_scale_max = float(
		settings.get(
			"scale_max",
			1.2
		)
)

	live_offset_x_mode = str(
		settings.get(
			"offset_x_mode",
			"FIXED"
		)
	).to_upper().strip_edges()


	if live_offset_x_mode != "RANDOM":

		live_offset_x_mode = "FIXED"


	live_offset_x_fixed = float(
		settings.get(
			"offset_x",
			0.0
		)
	)

	live_offset_x_min = float(
		settings.get(
			"offset_x_min",
			0.0
		)
	)

	live_offset_x_max = float(
		settings.get(
			"offset_x_max",
			0.0
		)
	)


	live_offset_y_mode = str(
		settings.get(
			"offset_y_mode",
			"FIXED"
		)
	).to_upper().strip_edges()


	if live_offset_y_mode != "RANDOM":

		live_offset_y_mode = "FIXED"


	live_offset_y_fixed = float(
		settings.get(
			"offset_y",
			0.0
		)
	)

	live_offset_y_min = float(
		settings.get(
			"offset_y_min",
			0.0
		)
	)

	live_offset_y_max = float(
		settings.get(
			"offset_y_max",
			0.0
		)
	)


	live_offset_z_mode = str(
		settings.get(
			"offset_z_mode",
			"FIXED"
		)
	).to_upper().strip_edges()


	if live_offset_z_mode != "RANDOM":

		live_offset_z_mode = "FIXED"


	live_offset_z_fixed = float(
		settings.get(
			"offset_z",
			0.0
		)
	)

	live_offset_z_min = float(
		settings.get(
			"offset_z_min",
			0.0
		)
	)

	live_offset_z_max = float(
		settings.get(
			"offset_z_max",
			0.0
		)
	)


	live_rotation_x_mode = str(
		settings.get(
			"rotation_x_mode",
			"FIXED"
		)
	).to_upper().strip_edges()


	if live_rotation_x_mode != "RANDOM":

		live_rotation_x_mode = "FIXED"


	live_rotation_x_fixed = float(
		settings.get(
			"rotation_x",
			0.0
		)
	)

	live_rotation_x_min = float(
		settings.get(
			"rotation_x_min",
			0.0
		)
	)

	live_rotation_x_max = float(
		settings.get(
			"rotation_x_max",
			0.0
		)
	)


	live_rotation_y_mode = str(
		settings.get(
			"rotation_y_mode",
			"FIXED"
		)
	).to_upper().strip_edges()


	if live_rotation_y_mode != "RANDOM":

		live_rotation_y_mode = "FIXED"


	live_rotation_y_fixed = float(
		settings.get(
			"rotation_y",
			0.0
		)
	)

	live_rotation_y_min = float(
		settings.get(
			"rotation_y_min",
			0.0
		)
	)

	live_rotation_y_max = float(
		settings.get(
			"rotation_y_max",
			0.0
		)
	)


	live_rotation_z_mode = str(
		settings.get(
			"rotation_z_mode",
			"FIXED"
		)
	).to_upper().strip_edges()


	if live_rotation_z_mode != "RANDOM":

		live_rotation_z_mode = "FIXED"


	live_rotation_z_fixed = float(
		settings.get(
			"rotation_z",
			0.0
		)
	)

	live_rotation_z_min = float(
		settings.get(
			"rotation_z_min",
			0.0
		)
	)

	live_rotation_z_max = float(
		settings.get(
			"rotation_z_max",
			0.0
		)
	)


	current_mirror_h = bool(
		settings.get(
			"mirror_h",
			current_mirror_h
		)
	)

	current_mirror_v = bool(
		settings.get(
			"mirror_v",
			current_mirror_v
		)
	)


	_normalize_live_ranges()


# =============================================================
# NORMALIZE
# =============================================================

func _normalize_live_ranges() -> void:

	live_scale_fixed = clampf(
		live_scale_fixed,
		0.01,
		10.0
	)

	live_scale_min = clampf(
		live_scale_min,
		0.01,
		10.0
	)

	live_scale_max = clampf(
		live_scale_max,
		0.01,
		10.0
	)


	if live_scale_min > live_scale_max:

		var scale_temp := live_scale_min

		live_scale_min = live_scale_max

		live_scale_max = scale_temp


	live_offset_x_fixed = clampf(
		live_offset_x_fixed,
		-10.0,
		10.0
	)

	live_offset_x_min = clampf(
		live_offset_x_min,
		-10.0,
		10.0
	)

	live_offset_x_max = clampf(
		live_offset_x_max,
		-10.0,
		10.0
	)


	if live_offset_x_min > live_offset_x_max:

		var temp_x := live_offset_x_min

		live_offset_x_min = live_offset_x_max

		live_offset_x_max = temp_x


	live_offset_y_fixed = clampf(
		live_offset_y_fixed,
		-10.0,
		10.0
	)

	live_offset_y_min = clampf(
		live_offset_y_min,
		-10.0,
		10.0
	)

	live_offset_y_max = clampf(
		live_offset_y_max,
		-10.0,
		10.0
	)


	if live_offset_y_min > live_offset_y_max:

		var temp_y := live_offset_y_min

		live_offset_y_min = live_offset_y_max

		live_offset_y_max = temp_y


	live_offset_z_fixed = clampf(
		live_offset_z_fixed,
		-10.0,
		10.0
	)

	live_offset_z_min = clampf(
		live_offset_z_min,
		-10.0,
		10.0
	)

	live_offset_z_max = clampf(
		live_offset_z_max,
		-10.0,
		10.0
	)


	if live_offset_z_min > live_offset_z_max:

		var temp_z := live_offset_z_min

		live_offset_z_min = live_offset_z_max

		live_offset_z_max = temp_z


	live_rotation_x_fixed = clampf(
		live_rotation_x_fixed,
		-180.0,
		180.0
	)

	live_rotation_x_min = clampf(
		live_rotation_x_min,
		-180.0,
		180.0
	)

	live_rotation_x_max = clampf(
		live_rotation_x_max,
		-180.0,
		180.0
	)


	if live_rotation_x_min > live_rotation_x_max:

		var temp_rx := live_rotation_x_min

		live_rotation_x_min = live_rotation_x_max

		live_rotation_x_max = temp_rx


	live_rotation_y_fixed = clampf(
		live_rotation_y_fixed,
		-180.0,
		180.0
	)

	live_rotation_y_min = clampf(
		live_rotation_y_min,
		-180.0,
		180.0
	)

	live_rotation_y_max = clampf(
		live_rotation_y_max,
		-180.0,
		180.0
	)


	if live_rotation_y_min > live_rotation_y_max:

		var temp_ry := live_rotation_y_min

		live_rotation_y_min = live_rotation_y_max

		live_rotation_y_max = temp_ry


	live_rotation_z_fixed = clampf(
		live_rotation_z_fixed,
		-180.0,
		180.0
	)

	live_rotation_z_min = clampf(
		live_rotation_z_min,
		-180.0,
		180.0
	)

	live_rotation_z_max = clampf(
		live_rotation_z_max,
		-180.0,
		180.0
	)


	if live_rotation_z_min > live_rotation_z_max:

		var temp_rz := live_rotation_z_min

		live_rotation_z_min = live_rotation_z_max

		live_rotation_z_max = temp_rz


# =============================================================
# LIVE PREVIEW SAMPLING
# =============================================================

func _update_live_preview_from_live_settings(
	regenerate_random: bool = false
) -> void:

	_normalize_live_ranges()


	if live_scale_mode == "RANDOM":

		if regenerate_random:

			live_preview_scale = randf_range(
				live_scale_min,
				live_scale_max
			)

		else:

			live_preview_scale = clampf(
				live_preview_scale,
				live_scale_min,
				live_scale_max
			)

	else:

		live_preview_scale = (
			live_scale_fixed
		)


	if live_offset_x_mode == "RANDOM":

		if regenerate_random:

			live_preview_offset.x = randf_range(
				live_offset_x_min,
				live_offset_x_max
			)

		else:

			live_preview_offset.x = clampf(
				live_preview_offset.x,
				live_offset_x_min,
				live_offset_x_max
			)

	else:

		live_preview_offset.x = (
			live_offset_x_fixed
		)


	if live_offset_y_mode == "RANDOM":

		if regenerate_random:

			live_preview_offset.y = randf_range(
				live_offset_y_min,
				live_offset_y_max
			)

		else:

			live_preview_offset.y = clampf(
				live_preview_offset.y,
				live_offset_y_min,
				live_offset_y_max
			)

	else:

		live_preview_offset.y = (
			live_offset_y_fixed
		)


	if live_offset_z_mode == "RANDOM":

		if regenerate_random:

			live_preview_offset.z = randf_range(
				live_offset_z_min,
				live_offset_z_max
			)

		else:

			live_preview_offset.z = clampf(
				live_preview_offset.z,
				live_offset_z_min,
				live_offset_z_max
			)

	else:

		live_preview_offset.z = (
			live_offset_z_fixed
		)


	if live_rotation_x_mode == "RANDOM":

		if regenerate_random:

			live_preview_rotation.x = randf_range(
				live_rotation_x_min,
				live_rotation_x_max
			)

		else:

			live_preview_rotation.x = clampf(
				live_preview_rotation.x,
				live_rotation_x_min,
				live_rotation_x_max
			)

	else:

		live_preview_rotation.x = (
			live_rotation_x_fixed
		)


	if live_rotation_y_mode == "RANDOM":

		if regenerate_random:

			live_preview_rotation.y = randf_range(
				live_rotation_y_min,
				live_rotation_y_max
			)

		else:

			live_preview_rotation.y = clampf(
				live_preview_rotation.y,
				live_rotation_y_min,
				live_rotation_y_max
			)

	else:

		live_preview_rotation.y = (
			live_rotation_y_fixed
		)


	if live_rotation_z_mode == "RANDOM":

		if regenerate_random:

			live_preview_rotation.z = randf_range(
				live_rotation_z_min,
				live_rotation_z_max
			)

		else:

			live_preview_rotation.z = clampf(
				live_preview_rotation.z,
				live_rotation_z_min,
				live_rotation_z_max
			)

	else:

		live_preview_rotation.z = (
			live_rotation_z_fixed
		)


	current_scale = (
		live_preview_scale
	)

	current_offset = (
		live_preview_offset
	)

	current_rotation = (
		live_preview_rotation
	)


	_update_image_transform()


# =============================================================
# CHARACTER
# =============================================================

func _ensure_character() -> void:

	if (
		character_model != null
		and
		is_instance_valid(
			character_model
		)
	):

		return


	_refresh_runtime_reference()


	if character_runtime == null:

		return


	var active_character: Node3D = null


	if character_runtime.has_method(
		"get_active_character"
	):

		var value: Variant = (
			character_runtime.get_active_character()
		)


		if value is Node3D:

			active_character = (
				value
				as
				Node3D
			)


	if active_character == null:

		return


	character_model = (
		active_character.duplicate(true)
		as
		Node3D
	)


	if character_model == null:

		return


	character_model.name = (
		"PreviewCharacter"
	)

	character_model.position = Vector3.ZERO

	character_model.rotation = Vector3.ZERO

	character_model.scale = Vector3.ONE


	character_holder.add_child(
		character_model
	)


	_restore_preview_hitpoints()

	_center_character_on_ground()


func _restore_preview_hitpoints() -> void:

	if character_model == null:

		return


	var existing_head: Node3D = (
		character_model.get_node_or_null(
			"HeadHitPoint"
		)
		as
		Node3D
	)


	if existing_head != null:

		return


	if character_runtime == null:

		return


	if not character_runtime.has_method(
		"find_skeleton"
	):

		return


	if not character_runtime.has_method(
		"create_hit_point"
	):

		return


	var skeleton_value: Variant = (
		character_runtime.find_skeleton(
			character_model
		)
	)


	if not skeleton_value is Skeleton3D:

		return


	var skeleton: Skeleton3D = (
		skeleton_value
		as
		Skeleton3D
	)


	var bone_map: Dictionary = {}


	if character_runtime.has_method(
		"get_active_bone_map"
	):

		var map_value: Variant = (
			character_runtime.get_active_bone_map()
		)


		if map_value is Dictionary:

			bone_map = (
				map_value
				as
				Dictionary
			)


	for hitpoint_value: Variant in bone_map.keys():

		var hitpoint_name := str(
			hitpoint_value
		)

		var bone_name := str(
			bone_map[hitpoint_value]
		)


		var created_value: Variant = (
			character_runtime.create_hit_point(
				character_model,
				skeleton,
				hitpoint_name,
				bone_name
			)
		)


		if created_value is Node3D:

			var created := (
				created_value
				as
				Node3D
			)

			created.name = (
				hitpoint_name
			)


# =============================================================
# CENTER CHARACTER
# =============================================================

func _center_character_on_ground() -> void:

	if character_model == null:

		return


	var bounds := _calculate_bounds(
		character_model
	)


	if bounds.size.length() <= 0.0001:

		return


	var center := (
		bounds.position
		+
		bounds.size * 0.5
	)


	character_model.global_position.x -= (
		center.x
	)

	character_model.global_position.z -= (
		center.z
	)


	bounds = _calculate_bounds(
		character_model
	)


	character_model.global_position.y += (
		GROUND_Y
		-
		bounds.position.y
	)


# =============================================================
# BOUNDS
# =============================================================

func _calculate_bounds(
	node: Node3D
) -> AABB:

	var found := false

	var result := AABB()

	var meshes: Array[MeshInstance3D] = []

	_collect_meshes(
		node,
		meshes
	)


	for mesh_instance: MeshInstance3D in meshes:

		if mesh_instance.mesh == null:

			continue


		var local_box: AABB = (
			mesh_instance.mesh.get_aabb()
		)


		var transform: Transform3D = (
			mesh_instance.global_transform
		)


		var corners: Array[Vector3] = [

			local_box.position,

			local_box.position
			+
			Vector3(
				local_box.size.x,
				0.0,
				0.0
			),

			local_box.position
			+
			Vector3(
				0.0,
				local_box.size.y,
				0.0
			),

			local_box.position
			+
			Vector3(
				0.0,
				0.0,
				local_box.size.z
			),

			local_box.position
			+
			Vector3(
				local_box.size.x,
				local_box.size.y,
				0.0
			),

			local_box.position
			+
			Vector3(
				local_box.size.x,
				0.0,
				local_box.size.z
			),

			local_box.position
			+
			Vector3(
				0.0,
				local_box.size.y,
				local_box.size.z
			),

			local_box.position
			+
			local_box.size
		]


		for corner: Vector3 in corners:

			var world_corner := (
				transform
				*
				corner
			)


			if not found:

				result = AABB(
					world_corner,
					Vector3.ZERO
				)

				found = true

			else:

				result = result.expand(
					world_corner
				)


	return result


func _collect_meshes(
	node: Node,
	result: Array[MeshInstance3D]
) -> void:

	if node is MeshInstance3D:

		result.append(
			node as MeshInstance3D
		)


	for child: Node in node.get_children():

		_collect_meshes(
			child,
			result
		)


# =============================================================
# IMAGE
# =============================================================

func _ensure_image() -> void:
	if image_model != null and is_instance_valid(image_model):
		_update_image_texture()
		return

	image_model = Sprite3D.new()
	image_model.name = "EventImage"
	image_model.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	image_model.no_depth_test = false
	image_model.render_priority = 20

	if image_holder != null:
		image_holder.add_child(image_model)

	_update_image_texture()

func _update_image_texture() -> void:
	if image_model == null:
		return

	image_model.texture = current_texture

	if current_texture != null:
		var width := maxi(current_texture.get_width(), 1)
		image_model.pixel_size = IMAGE_BASE_WIDTH / float(width)

	_update_image_transform()

# =============================================================
# HITPOINT
# =============================================================

func _find_hitpoint(
	target_name: String
) -> Node3D:

	if character_model == null:

		return null


	return (
		character_model.find_child(
			_normalize_hitpoint(
				target_name
			),
			true,
			false
		)
		as
		Node3D
	)


# =============================================================
# IMAGE TRANSFORM
# =============================================================

func _update_image_transform() -> void:

	if image_model == null:

		return


	var target := _find_hitpoint(
		current_target
	)


	if target != null:

		if image_model.get_parent() != target:

			image_model.reparent(
				target,
				true
			)

	else:

		if image_model.get_parent() != image_holder:

			image_model.reparent(
				image_holder,
				true
			)


	image_model.position = (
		current_offset
	)

	image_model.rotation_degrees = (
		current_rotation
	)

	image_model.scale = Vector3(
		current_scale,
		current_scale,
		1.0
	)

	image_model.flip_h = (
		current_mirror_h
	)

	image_model.flip_v = (
		current_mirror_v
	)


	if scale_label != null:

		scale_label.text = (
			"SCALE %.2fx"
			%
			current_scale
		)


	_refresh_gizmo_overlay()


# =============================================================
# HITPOINT NORMALIZE
# =============================================================

func _normalize_hitpoint(
	value: String
) -> String:

	var normalized: String = (
		value
		.strip_edges()
		.to_upper()
	)


	if (
		normalized == "HEAD"
		or
		normalized == "HEADHITPOINT"
	):

		return "HeadHitPoint"


	if (
		normalized == "CHEST"
		or
		normalized == "CHESTHITPOINT"
	):

		return "ChestHitPoint"


	if (
		normalized == "LEFT SHOULDER"
		or
		normalized == "LEFTSHOULDER"
		or
		normalized == "LEFTSHOULDERHITPOINT"
	):

		return "LeftShoulderHitPoint"


	if (
		normalized == "RIGHT SHOULDER"
		or
		normalized == "RIGHTSHOULDER"
		or
		normalized == "RIGHTSHOULDERHITPOINT"
	):

		return "RightShoulderHitPoint"


	if (
		normalized == "LEFT ARM"
		or
		normalized == "LEFTARM"
		or
		normalized == "LEFTARMHITPOINT"
	):

		return "LeftArmHitPoint"


	if (
		normalized == "RIGHT ARM"
		or
		normalized == "RIGHTARM"
		or
		normalized == "RIGHTARMHITPOINT"
	):

		return "RightArmHitPoint"


	if (
		normalized == "LEFT LEG"
		or
		normalized == "LEFTLEG"
		or
		normalized == "LEFTLEGHITPOINT"
	):

		return "LeftLegHitPoint"


	if (
		normalized == "RIGHT LEG"
		or
		normalized == "RIGHTLEG"
		or
		normalized == "RIGHTLEGHITPOINT"
	):

		return "RightLegHitPoint"


	return "HeadHitPoint"


# =============================================================
# TARGET UI
# =============================================================

func _find_option_index(
	button: OptionButton,
	value: String
) -> int:

	if button == null:

		return -1


	for i in range(
		button.item_count
	):

		if button.get_item_text(
			i
		) == value:

			return i


	return -1


func _update_target_selector() -> void:

	if target_selector == null:

		return


	var index := _find_option_index(
		target_selector,
		current_target
	)


	if index >= 0:

		target_selector.select(
			index
		)


func _update_live_target_selector() -> void:

	if live_target_selector == null:

		return


	var index := _find_option_index(
		live_target_selector,
		current_target
	)


	if index >= 0:

		live_target_selector.select(
			index
		)


func _update_mirror_buttons() -> void:

	if mirror_h_button != null:

		mirror_h_button.set_pressed_no_signal(
			current_mirror_h
		)

	if mirror_v_button != null:

		mirror_v_button.set_pressed_no_signal(
			current_mirror_v
		)


func _update_live_mirror_buttons() -> void:

	if live_mirror_h_button != null:

		live_mirror_h_button.set_pressed_no_signal(
			current_mirror_h
		)

	if live_mirror_v_button != null:

		live_mirror_v_button.set_pressed_no_signal(
			current_mirror_v
		)


# =============================================================
# TARGET CALLBACKS
# =============================================================

func _on_target_selected(
	index: int
) -> void:

	if target_selector == null:

		return


	if (
		index < 0
		or
		index >= target_selector.item_count
	):

		return


	current_target = (
		target_selector.get_item_text(
			index
		)
	)


	_update_image_transform()

	_emit_settings_changed()


func _on_live_target_selected(
	index: int
) -> void:

	if live_target_selector == null:

		return


	if (
		index < 0
		or
		index >= live_target_selector.item_count
	):

		return


	current_target = (
		live_target_selector.get_item_text(
			index
		)
	)


	_update_image_transform()

	_emit_live_settings()


# =============================================================
# MIRROR CALLBACKS
# =============================================================

func _on_mirror_h_toggled(
	value: bool
) -> void:

	current_mirror_h = value

	_update_image_transform()

	_emit_settings_changed()


func _on_mirror_v_toggled(
	value: bool
) -> void:

	current_mirror_v = value

	_update_image_transform()

	_emit_settings_changed()


func _on_live_mirror_h_toggled(
	value: bool
) -> void:

	current_mirror_h = value

	_update_image_transform()

	_emit_live_settings()


func _on_live_mirror_v_toggled(
	value: bool
) -> void:

	current_mirror_v = value

	_update_image_transform()

	_emit_live_settings()


# =============================================================
# EMIT NORMAL
# =============================================================

func _emit_settings_changed() -> void:

	if live_mode_enabled:

		return


	image_settings_changed.emit(
		current_target,
		current_scale,
		current_offset,
		current_rotation,
		current_mirror_h,
		current_mirror_v
	)


# =============================================================
# SCALE CALLBACKS
# =============================================================

func _on_scale_mode_selected(
	_index: int
) -> void:

	_update_live_modes_from_ui()

	_update_live_scale_ui()

	_update_live_preview_from_live_settings(
		true
	)

	_emit_live_settings()


func _on_scale_fixed_changed(
	value: float
) -> void:

	live_scale_fixed = value

	_update_live_preview_from_live_settings(
		false
	)

	_emit_live_settings()


func _on_scale_min_changed(
	value: float
) -> void:

	live_scale_min = value

	_normalize_live_ranges()

	_update_live_preview_from_live_settings(
		false
	)

	_emit_live_settings()


func _on_scale_max_changed(
	value: float
) -> void:

	live_scale_max = value

	_normalize_live_ranges()

	_update_live_preview_from_live_settings(
		false
	)

	_emit_live_settings()


# =============================================================
# OFFSET X CALLBACKS
# =============================================================

func _on_offset_x_mode_selected(
	_index: int
) -> void:

	_update_live_modes_from_ui()

	_update_live_axis_control_visibility(
		offset_x_mode_selector,
		offset_x_fixed_spin,
		offset_x_min_spin,
		offset_x_max_spin
	)

	_update_live_preview_from_live_settings(
		true
	)

	_emit_live_settings()


func _on_offset_x_value_changed(
	_value: float
) -> void:

	_update_live_values_from_ui()

	_normalize_live_ranges()

	_update_live_preview_from_live_settings(
		false
	)

	_emit_live_settings()


# =============================================================
# OFFSET Y CALLBACKS
# =============================================================

func _on_offset_y_mode_selected(
	_index: int
) -> void:

	_update_live_modes_from_ui()

	_update_live_axis_control_visibility(
		offset_y_mode_selector,
		offset_y_fixed_spin,
		offset_y_min_spin,
		offset_y_max_spin
	)

	_update_live_preview_from_live_settings(
		true
	)

	_emit_live_settings()


func _on_offset_y_value_changed(
	_value: float
) -> void:

	_update_live_values_from_ui()

	_normalize_live_ranges()

	_update_live_preview_from_live_settings(
		false
	)

	_emit_live_settings()


# =============================================================
# OFFSET Z CALLBACKS
# =============================================================

func _on_offset_z_mode_selected(
	_index: int
) -> void:

	_update_live_modes_from_ui()

	_update_live_axis_control_visibility(
		offset_z_mode_selector,
		offset_z_fixed_spin,
		offset_z_min_spin,
		offset_z_max_spin
	)

	_update_live_preview_from_live_settings(
		true
	)

	_emit_live_settings()


func _on_offset_z_value_changed(
	_value: float
) -> void:

	_update_live_values_from_ui()

	_normalize_live_ranges()

	_update_live_preview_from_live_settings(
		false
	)

	_emit_live_settings()


# =============================================================
# ROTATION X CALLBACKS
# =============================================================

func _on_rotation_x_mode_selected(
	_index: int
) -> void:

	_update_live_modes_from_ui()

	_update_live_axis_control_visibility(
		rotation_x_mode_selector,
		rotation_x_fixed_spin,
		rotation_x_min_spin,
		rotation_x_max_spin
	)

	_update_live_preview_from_live_settings(
		true
	)

	_emit_live_settings()


func _on_rotation_x_value_changed(
	_value: float
) -> void:

	_update_live_values_from_ui()

	_normalize_live_ranges()

	_update_live_preview_from_live_settings(
		false
	)

	_emit_live_settings()


# =============================================================
# ROTATION Y CALLBACKS
# =============================================================

func _on_rotation_y_mode_selected(
	_index: int
) -> void:

	_update_live_modes_from_ui()

	_update_live_axis_control_visibility(
		rotation_y_mode_selector,
		rotation_y_fixed_spin,
		rotation_y_min_spin,
		rotation_y_max_spin
	)

	_update_live_preview_from_live_settings(
		true
	)

	_emit_live_settings()


func _on_rotation_y_value_changed(
	_value: float
) -> void:

	_update_live_values_from_ui()

	_normalize_live_ranges()

	_update_live_preview_from_live_settings(
		false
	)

	_emit_live_settings()


# =============================================================
# ROTATION Z CALLBACKS
# =============================================================

func _on_rotation_z_mode_selected(
	_index: int
) -> void:

	_update_live_modes_from_ui()

	_update_live_axis_control_visibility(
		rotation_z_mode_selector,
		rotation_z_fixed_spin,
		rotation_z_min_spin,
		rotation_z_max_spin
	)

	_update_live_preview_from_live_settings(
		true
	)

	_emit_live_settings()


func _on_rotation_z_value_changed(
	_value: float
) -> void:

	_update_live_values_from_ui()

	_normalize_live_ranges()

	_update_live_preview_from_live_settings(
		false
	)

	_emit_live_settings()


# =============================================================
# LIVE MODES / VALUES FROM UI
# =============================================================

func _update_live_modes_from_ui() -> void:

	if scale_mode_selector != null:

		live_scale_mode = (
			"RANDOM"
			if scale_mode_selector.selected == 1
			else
			"FIXED"
		)


	if offset_x_mode_selector != null:

		live_offset_x_mode = (
			"RANDOM"
			if offset_x_mode_selector.selected == 1
			else
			"FIXED"
		)


	if offset_y_mode_selector != null:

		live_offset_y_mode = (
			"RANDOM"
			if offset_y_mode_selector.selected == 1
			else
			"FIXED"
		)


	if offset_z_mode_selector != null:

		live_offset_z_mode = (
			"RANDOM"
			if offset_z_mode_selector.selected == 1
			else
			"FIXED"
		)


	if rotation_x_mode_selector != null:

		live_rotation_x_mode = (
			"RANDOM"
			if rotation_x_mode_selector.selected == 1
			else
			"FIXED"
		)


	if rotation_y_mode_selector != null:

		live_rotation_y_mode = (
			"RANDOM"
			if rotation_y_mode_selector.selected == 1
			else
			"FIXED"
		)


	if rotation_z_mode_selector != null:

		live_rotation_z_mode = (
			"RANDOM"
			if rotation_z_mode_selector.selected == 1
			else
			"FIXED"
		)


func _update_live_values_from_ui() -> void:

	if scale_fixed_spin != null:

		live_scale_fixed = (
			scale_fixed_spin.value
		)

	if scale_min_spin != null:

		live_scale_min = (
			scale_min_spin.value
		)

	if scale_max_spin != null:

		live_scale_max = (
			scale_max_spin.value
		)


	if offset_x_fixed_spin != null:

		live_offset_x_fixed = (
			offset_x_fixed_spin.value
		)

	if offset_x_min_spin != null:

		live_offset_x_min = (
			offset_x_min_spin.value
		)

	if offset_x_max_spin != null:

		live_offset_x_max = (
			offset_x_max_spin.value
		)


	if offset_y_fixed_spin != null:

		live_offset_y_fixed = (
			offset_y_fixed_spin.value
		)

	if offset_y_min_spin != null:

		live_offset_y_min = (
			offset_y_min_spin.value
		)

	if offset_y_max_spin != null:

		live_offset_y_max = (
			offset_y_max_spin.value
		)


	if offset_z_fixed_spin != null:

		live_offset_z_fixed = (
			offset_z_fixed_spin.value
		)

	if offset_z_min_spin != null:

		live_offset_z_min = (
			offset_z_min_spin.value
		)

	if offset_z_max_spin != null:

		live_offset_z_max = (
			offset_z_max_spin.value
		)


	if rotation_x_fixed_spin != null:

		live_rotation_x_fixed = (
			rotation_x_fixed_spin.value
		)

	if rotation_x_min_spin != null:

		live_rotation_x_min = (
			rotation_x_min_spin.value
		)

	if rotation_x_max_spin != null:

		live_rotation_x_max = (
			rotation_x_max_spin.value
		)


	if rotation_y_fixed_spin != null:

		live_rotation_y_fixed = (
			rotation_y_fixed_spin.value
		)

	if rotation_y_min_spin != null:

		live_rotation_y_min = (
			rotation_y_min_spin.value
		)

	if rotation_y_max_spin != null:

		live_rotation_y_max = (
			rotation_y_max_spin.value
		)


	if rotation_z_fixed_spin != null:

		live_rotation_z_fixed = (
			rotation_z_fixed_spin.value
		)

	if rotation_z_min_spin != null:

		live_rotation_z_min = (
			rotation_z_min_spin.value
		)

	if rotation_z_max_spin != null:

		live_rotation_z_max = (
			rotation_z_max_spin.value
		)


# =============================================================
# LIVE VISIBILITY
# =============================================================

func _update_live_scale_ui() -> void:

	if scale_mode_selector == null:

		return


	var random_mode := (
		live_scale_mode == "RANDOM"
	)


	scale_fixed_spin.visible = (
		not random_mode
	)

	scale_min_spin.visible = (
		random_mode
	)

	scale_max_spin.visible = (
		random_mode
	)


func _update_live_axis_control_visibility(
	selector: OptionButton,
	fixed_spin: SpinBox,
	min_spin: SpinBox,
	max_spin: SpinBox
) -> void:

	if selector == null:

		return


	var random_mode := (
		selector.selected == 1
	)


	fixed_spin.visible = (
		not random_mode
	)

	min_spin.visible = (
		random_mode
	)

	max_spin.visible = (
		random_mode
	)


# =============================================================
# SYNC CURRENT TRANSFORM INTO LIVE STATE
# =============================================================

func _sync_current_transform_to_live_state() -> void:

	if not live_mode_enabled:

		return


	if live_scale_mode == "FIXED":

		live_scale_fixed = (
			current_scale
		)


	if live_offset_x_mode == "FIXED":

		live_offset_x_fixed = (
			current_offset.x
		)


	if live_offset_y_mode == "FIXED":

		live_offset_y_fixed = (
			current_offset.y
		)


	if live_offset_z_mode == "FIXED":

		live_offset_z_fixed = (
			current_offset.z
		)


	if live_rotation_x_mode == "FIXED":

		live_rotation_x_fixed = (
			current_rotation.x
		)


	if live_rotation_y_mode == "FIXED":

		live_rotation_y_fixed = (
			current_rotation.y
		)


	if live_rotation_z_mode == "FIXED":

		live_rotation_z_fixed = (
			current_rotation.z
		)


	live_preview_scale = (
		current_scale
	)

	live_preview_offset = (
		current_offset
	)

	live_preview_rotation = (
		current_rotation
	)


	_update_live_controls_from_state()

	_normalize_live_ranges()


# =============================================================
# EMIT LIVE
# =============================================================

func _emit_live_settings() -> void:

	if not live_mode_enabled:

		return


	live_image_settings_changed.emit(
		get_live_settings()
	)

# =============================================================
# FRAME CAMERA TO CHARACTER
# =============================================================

func _frame_camera_to_character() -> void:

	if (
		camera == null
		or
		character_model == null
	):

		return


	var bounds: AABB = (
		_calculate_bounds(
			character_model
		)
	)


	if bounds.size.length() <= 0.0001:

		return


	var width: float = (
		maxf(
			bounds.size.x,
			0.001
		)
	)


	var height: float = (
		maxf(
			bounds.size.y,
			0.001
		)
	)


	var depth: float = (
		maxf(
			bounds.size.z,
			0.001
		)
	)


	camera_target = (
		bounds.position
		+
		bounds.size * 0.5
	)


	var vertical_fov: float = (
		deg_to_rad(
			camera.fov
		)
	)


	var distance: float = (
		height
		*
		0.5
		/
		tan(
			vertical_fov * 0.5
		)
	)


	distance = maxf(
		distance,
		width * 0.75
	)


	distance = maxf(
		distance,
		depth * 1.2
	)


	distance *= 1.35


	camera.global_position = Vector3(
		camera_target.x,
		camera_target.y,
		camera_target.z + distance
	)


	camera.look_at(
		camera_target,
		Vector3.UP
	)


	manual_camera_position = (
		camera.global_position
	)


	manual_camera_fov = (
		camera.fov
	)


# =============================================================
# CAMERA ZOOM
# =============================================================

func _zoom_camera(
	amount: float
) -> void:

	if camera == null:

		return


	var offset: Vector3 = (
		camera.global_position
		-
		camera_target
	)


	var distance: float = (
		offset.length()
	)


	if distance <= 0.001:

		offset = Vector3(
			0.0,
			0.0,
			1.0
		)

		distance = 1.0


	var next_distance: float = (
		distance
		+
		amount
		*
		distance
		*
		CAMERA_ZOOM_STEP
	)


	next_distance = clampf(
		next_distance,
		CAMERA_MIN_DISTANCE,
		CAMERA_MAX_DISTANCE
	)


	camera.global_position = (
		camera_target
		+
		offset.normalized()
		*
		next_distance
	)


	camera.look_at(
		camera_target,
		Vector3.UP
	)


	manual_camera_position = (
		camera.global_position
	)


	manual_camera_fov = (
		camera.fov
	)


# =============================================================
# CAMERA ORBIT
# =============================================================

func _orbit_camera(
	mouse_delta: Vector2
) -> void:

	if camera == null:

		return


	var offset: Vector3 = (
		camera.global_position
		-
		camera_target
	)


	var distance: float = maxf(
		offset.length(),
		CAMERA_MIN_DISTANCE
	)


	# ---------------------------------------------------------
	# HORIZONTAL ORBIT
	# ---------------------------------------------------------

	offset = offset.rotated(
		Vector3.UP,
		-mouse_delta.x
		*
		CAMERA_ROTATE_SENSITIVITY
	)


	# ---------------------------------------------------------
	# VERTICAL ORBIT
	# ---------------------------------------------------------

	var right: Vector3 = (
		camera.global_transform.basis.x
		.normalized()
	)


	offset = offset.rotated(
		right,
		-mouse_delta.y
		*
		CAMERA_ROTATE_SENSITIVITY
	)


	camera.global_position = (
		camera_target
		+
		offset.normalized()
		*
		distance
	)


	camera.look_at(
		camera_target,
		Vector3.UP
	)


	manual_camera_position = (
		camera.global_position
	)


	manual_camera_fov = (
		camera.fov
	)


# =============================================================
# CAMERA PAN
# =============================================================

func _pan_camera(
	mouse_delta: Vector2
) -> void:

	if camera == null:

		return


	var distance: float = maxf(
		camera.global_position.distance_to(
			camera_target
		),
		CAMERA_MIN_DISTANCE
	)


	var amount: float = (
		distance
		*
		CAMERA_PAN_SENSITIVITY
	)


	var right: Vector3 = (
		camera.global_transform.basis.x
		.normalized()
	)


	var up: Vector3 = (
		camera.global_transform.basis.y
		.normalized()
	)


	var movement: Vector3 = (
		-right
		*
		mouse_delta.x
		*
		amount
		+
		up
		*
		mouse_delta.y
		*
		amount
	)


	camera.global_position += (
		movement
	)


	camera_target += (
		movement
	)


	camera.look_at(
		camera_target,
		Vector3.UP
	)


	manual_camera_position = (
		camera.global_position
	)


	manual_camera_fov = (
		camera.fov
	)

# =============================================================
# COORDINATE CONVERSION
# =============================================================

func _viewport_event_to_preview_screen(
	viewport_position: Vector2
) -> Vector2:

	if viewport_container == null:

		return viewport_position


	return (
		viewport_container.position
		+
		viewport_position
	)


func _viewport_to_preview_screen(
	viewport_position: Vector2
) -> Vector2:

	if (
		viewport_container == null
		or
		sub_viewport == null
	):

		return viewport_position


	var viewport_size := Vector2(
		maxf(
			float(sub_viewport.size.x),
			1.0
		),
		maxf(
			float(sub_viewport.size.y),
			1.0
		)
	)


	var container_size := Vector2(
		maxf(
			viewport_container.size.x,
			1.0
		),
		maxf(
			viewport_container.size.y,
			1.0
		)
	)


	var scale_factor := Vector2(
		container_size.x
		/
		viewport_size.x,

		container_size.y
		/
		viewport_size.y
	)


	return (
		viewport_container.position
		+
		viewport_position
		*
		scale_factor
	)


func _preview_screen_to_viewport(
	screen_position: Vector2
) -> Vector2:

	if (
		viewport_container == null
		or
		sub_viewport == null
	):

		return screen_position


	var local_position := (
		screen_position
		-
		viewport_container.position
	)


	var viewport_size := Vector2(
		maxf(
			float(sub_viewport.size.x),
			1.0
		),
		maxf(
			float(sub_viewport.size.y),
			1.0
		)
	)


	var container_size := Vector2(
		maxf(
			viewport_container.size.x,
			1.0
		),
		maxf(
			viewport_container.size.y,
			1.0
		)
	)


	local_position.x *= (
		viewport_size.x
		/
		container_size.x
	)


	local_position.y *= (
		viewport_size.y
		/
		container_size.y
	)


	return local_position


# =============================================================
# WORLD -> PREVIEW SCREEN
# =============================================================

func _project_world_to_preview(
	world_position: Vector3
) -> Vector2:

	if (
		camera == null
		or
		not camera.is_inside_tree()
	):

		return Vector2.ZERO


	var camera_forward := (
		-camera.global_transform.basis.z
	)


	var to_point := (
		world_position
		-
		camera.global_position
	)


	if to_point.length_squared() <= 0.000001:

		return Vector2.ZERO


	var depth := (
		to_point.dot(
			camera_forward
		)
	)


	if depth <= 0.01:

		return Vector2.ZERO


	return _viewport_to_preview_screen(
		camera.unproject_position(
			world_position
		)
	)


# =============================================================
# GIZMO PROJECTION
# =============================================================

func _project_gizmo_axis(
	local_axis: Vector3
) -> Vector2:

	if (
		camera == null
		or
		image_model == null
	):

		return Vector2.ZERO


	if (
		not camera.is_inside_tree()
		or
		not image_model.is_inside_tree()
	):

		return Vector2.ZERO


	var image_position := (
		image_model.global_position
	)


	var center := _project_world_to_preview(
		image_position
	)


	if center == Vector2.ZERO:

		return Vector2.ZERO


	var world_axis := local_axis


	if world_axis.length() < 0.001:

		return Vector2.ZERO


	var end_world := (
		image_position
		+
		world_axis.normalized()
		*
		GIZMO_LENGTH
		*
		0.01
	)


	var end := _project_world_to_preview(
		end_world
	)


	var direction := (
		end
		-
		center
	)


	if direction.length() < 0.001:

		return Vector2.ZERO


	return (
		direction.normalized()
		*
		GIZMO_LENGTH
	)


# =============================================================
# GIZMO REFRESH
# =============================================================

func _refresh_gizmo_overlay() -> void:

	if (
		gizmo_overlay == null
		or
		camera == null
		or
		image_model == null
	):

		return


	if not is_instance_valid(
		image_model
	):

		return


	if (
		not camera.is_inside_tree()
		or
		not image_model.is_inside_tree()
	):

		return


	var image_position := (
		image_model.global_position
	)


	var center := _project_world_to_preview(
		image_position
	)


	if center == Vector2.ZERO:

		return


	var x_axis := (
		_project_gizmo_axis(
			Vector3.RIGHT
		)
	)


	var y_axis := (
		_project_gizmo_axis(
			Vector3.UP
		)
	)


	var z_axis := (
		_project_gizmo_axis(
			Vector3.BACK
		)
	)


	var overlay := (
		gizmo_overlay
		as
		GizmoOverlay
	)


	if overlay != null:

		overlay.refresh(
			center,
			x_axis,
			y_axis,
			z_axis,
			gizmo_hover_axis,
			gizmo_drag_axis
		)


# =============================================================
# GIZMO HIT
# =============================================================

func _gizmo_axis_at(
	screen_position: Vector2
) -> int:

	if (
		image_model == null
		or
		camera == null
	):

		return GIZMO_AXIS_NONE


	if not image_model.is_inside_tree():

		return GIZMO_AXIS_NONE


	var center := _project_world_to_preview(
		image_model.global_position
	)


	if center == Vector2.ZERO:

		return GIZMO_AXIS_NONE


	var axes: Array[Dictionary] = [

		{
			"axis":
				GIZMO_AXIS_X,

			"direction":
				_project_gizmo_axis(
					Vector3.RIGHT
				)
		},

		{
			"axis":
				GIZMO_AXIS_Y,

			"direction":
				_project_gizmo_axis(
					Vector3.UP
				)
		},

		{
			"axis":
				GIZMO_AXIS_Z,

			"direction":
				_project_gizmo_axis(
					Vector3.BACK
				)
		}
	]


	var best_axis := (
		GIZMO_AXIS_NONE
	)

	var best_distance := (
		GIZMO_HIT_RADIUS
	)


	for data: Dictionary in axes:

		var direction := (
			data["direction"]
			as
			Vector2
		)


		if direction.length() < 0.001:

			continue


		var distance := (
			_distance_to_segment(
				screen_position,
				center,
				center + direction
			)
		)


		if distance < best_distance:

			best_distance = distance

			best_axis = int(
				data["axis"]
			)


	return best_axis


func _distance_to_segment(
	point: Vector2,
	start: Vector2,
	finish: Vector2
) -> float:

	var segment := (
		finish
		-
		start
	)


	var length_sq := (
		segment.length_squared()
	)


	if length_sq <= 0.0001:

		return point.distance_to(
			start
		)


	var ratio := clampf(
		(point - start).dot(segment)
		/
		length_sq,
		0.0,
		1.0
	)


	return point.distance_to(
		start + segment * ratio
	)


func _update_gizmo_hover(
	screen_position: Vector2
) -> void:

	gizmo_hover_axis = (
		_gizmo_axis_at(
			screen_position
		)
	)

	_refresh_gizmo_overlay()


# =============================================================
# GIZMO DRAG
# =============================================================

func _begin_gizmo_drag(
	screen_position: Vector2
) -> bool:

	var axis := _gizmo_axis_at(
		screen_position
	)


	if axis == GIZMO_AXIS_NONE:

		return false


	gizmo_dragging = true

	gizmo_drag_axis = axis

	gizmo_drag_start_mouse = (
		screen_position
	)

	gizmo_drag_start_offset = (
		current_offset
	)


	return true


func _update_gizmo_drag(
	screen_position: Vector2
) -> void:

	if (
		not gizmo_dragging
		or
		gizmo_drag_axis == GIZMO_AXIS_NONE
	):

		return


	var direction: Vector2

	var local_axis: Vector3


	match gizmo_drag_axis:

		GIZMO_AXIS_X:

			direction = (
				_project_gizmo_axis(
					Vector3.RIGHT
				)
				.normalized()
			)

			local_axis = Vector3.RIGHT


		GIZMO_AXIS_Y:

			direction = (
				_project_gizmo_axis(
					Vector3.UP
				)
				.normalized()
			)

			local_axis = Vector3.UP


		GIZMO_AXIS_Z:

			direction = (
				_project_gizmo_axis(
					Vector3.BACK
				)
				.normalized()
			)

			local_axis = Vector3.BACK


		_:

			return


	if direction.length() < 0.001:

		return


	var mouse_delta := (
		screen_position
		-
		gizmo_drag_start_mouse
	)


	var projected_pixels := (
		mouse_delta.dot(
			direction
		)
	)


	var world_amount := (
		projected_pixels
		*
		0.003
	)


	current_offset = (
		gizmo_drag_start_offset
		+
		local_axis
		*
		world_amount
	)


	_sync_current_transform_to_live_state()

	_update_image_transform()

	_emit_settings_changed()

	_emit_live_settings()


func _end_gizmo_drag() -> void:

	gizmo_dragging = false

	gizmo_drag_axis = (
		GIZMO_AXIS_NONE
	)

	_refresh_gizmo_overlay()


# =============================================================
# IMAGE HIT TEST
# =============================================================

func _image_contains_screen_point(
	screen_position: Vector2
) -> bool:

	if (
		image_model == null
		or
		image_model.texture == null
		or
		camera == null
	):

		return false


	if not is_instance_valid(
		image_model
	):

		return false


	var center := _project_world_to_preview(
		image_model.global_position
	)


	if center == Vector2.ZERO:

		return false


	var basis := (
		image_model.global_transform.basis
	)


	var half_width := (
		float(
			image_model.texture.get_width()
		)
		*
		image_model.pixel_size
		*
		0.5
		*
		absf(
			image_model.scale.x
		)
	)


	var half_height := (
		float(
			image_model.texture.get_height()
		)
		*
		image_model.pixel_size
		*
		0.5
		*
		absf(
			image_model.scale.y
		)
	)


	var x_axis := (
		basis.x.normalized()
		*
		half_width
	)


	var y_axis := (
		basis.y.normalized()
		*
		half_height
	)


	var corners := PackedVector2Array()


	for world_corner: Vector3 in [

		image_model.global_position
		-
		x_axis
		-
		y_axis,

		image_model.global_position
		+
		x_axis
		-
		y_axis,

		image_model.global_position
		+
		x_axis
		+
		y_axis,

		image_model.global_position
		-
		x_axis
		+
		y_axis

	]:

		var screen_corner := (
			_project_world_to_preview(
				world_corner
			)
		)


		if screen_corner == Vector2.ZERO:

			return false


		corners.append(
			screen_corner
		)


	return Geometry2D.is_point_in_polygon(
		screen_position,
		corners
	)


# =============================================================
# IMAGE PLANE
# =============================================================

func _intersect_image_plane(
	screen_position: Vector2
) -> Variant:

	if (
		image_model == null
		or
		camera == null
	):

		return null


	var viewport_position := (
		_preview_screen_to_viewport(
			screen_position
		)
	)


	var normal := (
		image_model.global_transform
		.basis
		.z
		.normalized()
	)


	var point := (
		image_model.global_position
	)


	var plane := Plane(
		normal,
		normal.dot(point)
	)


	var ray_origin := (
		camera.project_ray_origin(
			viewport_position
		)
	)


	var ray_direction := (
		camera.project_ray_normal(
			viewport_position
		)
	)


	return plane.intersects_ray(
		ray_origin,
		ray_direction
	)


# =============================================================
# IMAGE DRAG BEGIN
# =============================================================

func _begin_image_drag(
	screen_position: Vector2,
	mode: int
) -> bool:

	if not _image_contains_screen_point(
		screen_position
	):

		return false


	var plane_hit: Variant = (
		_intersect_image_plane(
			screen_position
		)
	)


	if not plane_hit is Vector3:

		return false


	var parent_node := (
		image_model.get_parent()
		as
		Node3D
	)


	if parent_node == null:

		return false


	image_dragging = true

	image_drag_mode = mode

	image_drag_start_mouse = (
		screen_position
	)

	image_drag_start_offset = (
		current_offset
	)

	image_drag_start_scale = (
		current_scale
	)

	image_drag_start_rotation = (
		current_rotation
	)

	image_drag_parent = (
		parent_node
	)

	image_drag_start_local_point = (
		parent_node.to_local(
			plane_hit as Vector3
		)
	)


	return true


# =============================================================
# IMAGE DRAG UPDATE
# =============================================================

func _update_image_drag(
	screen_position: Vector2,
	_mouse_delta: Vector2
) -> void:

	if not image_dragging:

		return


	match image_drag_mode:

		IMAGE_DRAG_MOVE:

			var plane_hit: Variant = (
				_intersect_image_plane(
					screen_position
				)
			)


			if (
				plane_hit is Vector3
				and
				image_drag_parent != null
			):

				var local_point := (
					image_drag_parent.to_local(
						plane_hit as Vector3
					)
				)


				var local_delta := (
					local_point
					-
					image_drag_start_local_point
				)


				current_offset = (
					image_drag_start_offset
					+
					local_delta
				)


		IMAGE_DRAG_SCALE:

			var vertical_delta := (
				image_drag_start_mouse.y
				-
				screen_position.y
			)


			current_scale = clampf(
				image_drag_start_scale
				+
				vertical_delta
				*
				0.01,
				0.01,
				10.0
			)


		IMAGE_DRAG_ROTATE:

			var total_mouse_delta := (
				screen_position
				-
				image_drag_start_mouse
			)

			var next_rotation := (
				image_drag_start_rotation
			)

			# Esquerda / direita = rotação Z
			next_rotation.z = clampf(
				image_drag_start_rotation.z
				+
				total_mouse_delta.x
				*
				0.40,
				-180.0,
				180.0
			)

			# Cima / baixo = inclinação X
			next_rotation.x = clampf(
				image_drag_start_rotation.x
				+
				total_mouse_delta.y
				*
				0.40,
				-180.0,
				180.0
			)

			current_rotation = (
				next_rotation
			)


	_sync_current_transform_to_live_state()

	_update_image_transform()

	_emit_settings_changed()

	_emit_live_settings()


# =============================================================
# VIEWPORT INPUT
# =============================================================

func _on_viewport_gui_input(
	event: InputEvent
) -> void:

	if viewport_container == null:

		return


	# =========================================================
	# MOUSE BUTTON
	# =========================================================

	if event is InputEventMouseButton:

		var mouse_button := (
			event
			as
			InputEventMouseButton
		)


		var preview_position := (
			_viewport_event_to_preview_screen(
				mouse_button.position
			)
		)


		# -----------------------------------------------------
		# WHEEL UP
		# -----------------------------------------------------

		if (
			mouse_button.button_index
			==
			MOUSE_BUTTON_WHEEL_UP
			and
			mouse_button.pressed
		):

			_zoom_camera(
				-1.0
			)

			viewport_container.accept_event()

			return


		# -----------------------------------------------------
		# WHEEL DOWN
		# -----------------------------------------------------

		if (
			mouse_button.button_index
			==
			MOUSE_BUTTON_WHEEL_DOWN
			and
			mouse_button.pressed
		):

			_zoom_camera(
				1.0
			)

			viewport_container.accept_event()

			return


		# -----------------------------------------------------
		# RIGHT MOUSE
		# -----------------------------------------------------

		if (
			mouse_button.button_index
			==
			MOUSE_BUTTON_RIGHT
		):

			if mouse_button.pressed:

				camera_dragging = true

				camera_drag_mode = (
					CAMERA_PAN
					if mouse_button.ctrl_pressed
					else
					CAMERA_ORBIT
				)

			else:

				camera_dragging = false

				camera_drag_mode = 0


			viewport_container.accept_event()

			return


		# -----------------------------------------------------
		# LEFT MOUSE
		# -----------------------------------------------------

		if (
			mouse_button.button_index
			==
			MOUSE_BUTTON_LEFT
		):

			if mouse_button.pressed:

				# -------------------------------------------------
				# GIZMO FIRST
				# -------------------------------------------------

				if _begin_gizmo_drag(
					preview_position
				):

					viewport_container.accept_event()

					return


				var mode := (
					IMAGE_DRAG_MOVE
				)


				if mouse_button.ctrl_pressed:

					mode = (
						IMAGE_DRAG_SCALE
					)

				elif mouse_button.shift_pressed:

					mode = (
						IMAGE_DRAG_ROTATE
					)


				if _begin_image_drag(
					preview_position,
					mode
				):

					viewport_container.accept_event()

					return

			else:

				_end_gizmo_drag()

				image_dragging = false

				image_drag_mode = 0

				image_drag_parent = null

				viewport_container.accept_event()

				return


	# =========================================================
	# MOUSE MOTION
	# =========================================================

	if event is InputEventMouseMotion:

		var motion := (
			event
			as
			InputEventMouseMotion
		)


		var preview_position := (
			_viewport_event_to_preview_screen(
				motion.position
			)
		)


		if gizmo_dragging:

			_update_gizmo_drag(
				preview_position
			)

			viewport_container.accept_event()

			return


		_update_gizmo_hover(
			preview_position
		)


		if image_dragging:

			_update_image_drag(
				preview_position,
				motion.relative
			)

			viewport_container.accept_event()

			return


		if camera_dragging:

			if camera_drag_mode == CAMERA_PAN:

				_pan_camera(
					motion.relative
				)

			else:

				_orbit_camera(
					motion.relative
				)


			viewport_container.accept_event()


# =============================================================
# PROCESS
# =============================================================

func _process(
	_delta: float
) -> void:

	if (
		image_model != null
		and
		is_instance_valid(
			image_model
		)
	):

		if (
			current_texture != null
			and
			image_model.texture == null
		):

			_update_image_texture()


	_refresh_gizmo_overlay()
