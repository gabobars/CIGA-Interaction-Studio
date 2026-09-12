class_name CIGAInteractionUI
extends RefCounted


# =============================================================
# CIGA INTERACTION UI
# Godot 4.7.2
#
# A Interaction UI NÃO controla a escala dos objectos.
#
# A escala é responsabilidade exclusiva de CIGAObjects.
#
# A Interaction UI controla:
#
#     OBJECT
#     TARGET
#     SPAWN
#     FORCE
#     SPEED
#     AMOUNT
#
# O scale multiplier pertence ao sistema de objectos e é
# resolvido através do CIGAObjects.
# =============================================================


# =============================================================
# SIGNALS
# =============================================================

signal interaction_requested(
	interaction_data: Dictionary
)


# =============================================================
# ROOT
# =============================================================

var root: PanelContainer


# =============================================================
# REFERENCES
# =============================================================

var object_manager: CIGAObjects

var profile_manager: CIGAProfiles

var theme: CIGATheme

var interaction: CIGAInteraction

var interaction_runtime: CIGAInteractionRuntime

var character_runtime: CIGACharacterRuntime

var responsive_layout: CIGAResponsiveLayout


# =============================================================
# CHARACTER
# =============================================================

var active_character_data: Dictionary = {}

var active_bone_map: Dictionary = {}

var active_enabled_hitpoints: Array[String] = []


# =============================================================
# RESPONSIVE
# =============================================================

var responsive_columns: BoxContainer

var configuration_column: PanelContainer

var preview_column: PanelContainer

var selection_row: BoxContainer


# =============================================================
# CONTROLS
# =============================================================

var object_selector: OptionButton

var random_object: CheckBox

var target_selector: OptionButton

var random_target: CheckBox

var spawn_selector: OptionButton

var force_spin: SpinBox

var speed_spin: SpinBox

var amount_spin: SpinBox

var status_label: Label


# =============================================================
# CAMERA
# =============================================================

var camera_x: SpinBox

var camera_y: SpinBox

var camera_z: SpinBox

var camera_fov: SpinBox

var camera_status: Label


# =============================================================
# PREVIEW
# =============================================================

var preview: CIGAPreview3D

var preview_active: bool = false

var preview_controls_label: Label


# =============================================================
# TEST
# =============================================================

var test_locked: bool = false

var preview_test_pending: bool = false


# =============================================================
# SETUP
# =============================================================

func setup(
	parent: Control,
	manager: CIGAObjects,
	ui_theme: CIGATheme,
	runtime: CIGAInteractionRuntime,
	char_runtime: CIGACharacterRuntime,
	profiles: CIGAProfiles
) -> Control:

	object_manager = manager

	theme = ui_theme

	interaction_runtime = runtime

	character_runtime = char_runtime

	profile_manager = profiles


	# =========================================================
	# INTERACTION
	# =========================================================

	interaction = CIGAInteraction.new()

	interaction.setup(
		object_manager,
		profile_manager
	)


	# =========================================================
	# RUNTIME SIGNAL
	# =========================================================

	if interaction_runtime != null:

		if not interaction_runtime.interaction_burst_started.is_connected(
			_on_runtime_burst_started
		):

			interaction_runtime.interaction_burst_started.connect(
				_on_runtime_burst_started
			)


	# =========================================================
	# PROFILE SIGNAL
	# =========================================================

	if profile_manager != null:

		if not profile_manager.active_profile_changed.is_connected(
			_on_profile_changed
		):

			profile_manager.active_profile_changed.connect(
				_on_profile_changed
			)


	# =========================================================
	# ROOT
	# =========================================================

	root = PanelContainer.new()

	root.name = (
		"InteractionPage"
	)

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

	load_profile_configuration()

	refresh()


	return root


# =============================================================
# BUILD
# =============================================================

func build() -> void:

	var scroll := ScrollContainer.new()

	scroll.name = (
		"InteractionScroll"
	)

	scroll.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	scroll.horizontal_scroll_mode = (
		ScrollContainer.SCROLL_MODE_DISABLED
	)

	scroll.vertical_scroll_mode = (
		ScrollContainer.SCROLL_MODE_AUTO
	)

	scroll.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	root.add_child(
		scroll
	)


	var margin := MarginContainer.new()

	theme.set_margins(
		margin,
		14
	)

	margin.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	scroll.add_child(
		margin
	)


	var main := VBoxContainer.new()

	main.name = (
		"InteractionMain"
	)

	main.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	main.size_flags_vertical = (
		Control.SIZE_SHRINK_BEGIN
	)

	main.add_theme_constant_override(
		"separation",
		10
	)

	margin.add_child(
		main
	)


	main.add_child(
		theme.create_title(
			"INTERACTION"
		)
	)


	main.add_child(
		theme.create_status_label(
			"Configure an object, target and launch behaviour."
		)
	)


	# =========================================================
	# COLUMNS
	# =========================================================

	responsive_columns = BoxContainer.new()

	responsive_columns.name = (
		"InteractionColumns"
	)

	responsive_columns.vertical = false

	responsive_columns.custom_minimum_size = Vector2(
		0.0,
		500.0
	)

	responsive_columns.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	main.add_child(
		responsive_columns
	)


	# =========================================================
	# CONFIGURATION COLUMN
	# =========================================================

	configuration_column = PanelContainer.new()

	configuration_column.name = (
		"ConfigurationColumn"
	)

	configuration_column.custom_minimum_size = Vector2(
		430.0,
		0.0
	)

	configuration_column.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	configuration_column.size_flags_vertical = (
		Control.SIZE_SHRINK_BEGIN
	)

	configuration_column.size_flags_stretch_ratio = 1.0

	theme.style_panel(
		configuration_column,
		CIGATheme.PANEL_LIGHT,
		CIGATheme.BORDER
	)

	responsive_columns.add_child(
		configuration_column
	)


	var config_margin := MarginContainer.new()

	theme.set_margins(
		config_margin,
		12
	)

	configuration_column.add_child(
		config_margin
	)


	var config := VBoxContainer.new()

	config.name = (
		"ConfigurationContent"
	)

	config.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	config.add_theme_constant_override(
		"separation",
		10
	)

	config_margin.add_child(
		config
	)


	build_selection(
		config
	)

	build_spawn(
		config
	)

	build_test(
		config
	)

	build_physics(
		config
	)


	# =========================================================
	# PREVIEW COLUMN
	# =========================================================

	preview_column = PanelContainer.new()

	preview_column.name = (
		"PreviewColumn"
	)

	preview_column.custom_minimum_size = Vector2(
		520.0,
		0.0
	)

	preview_column.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	preview_column.size_flags_vertical = (
		Control.SIZE_SHRINK_BEGIN
	)

	preview_column.size_flags_stretch_ratio = 1.25

	theme.style_panel(
		preview_column,
		CIGATheme.PANEL_LIGHT,
		CIGATheme.BORDER
	)

	responsive_columns.add_child(
		preview_column
	)


	var preview_margin := MarginContainer.new()

	theme.set_margins(
		preview_margin,
		12
	)

	preview_column.add_child(
		preview_margin
	)


	var preview_content := VBoxContainer.new()

	preview_content.name = (
		"PreviewContent"
	)

	preview_content.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	preview_content.add_theme_constant_override(
		"separation",
		10
	)

	preview_margin.add_child(
		preview_content
	)


	preview_content.add_child(
		theme.create_section_label(
			"INTERACTION PREVIEW"
		)
	)


	# =========================================================
	# PREVIEW
	# =========================================================

	preview = CIGAPreview3D.new()

	preview.setup(
		preview_content,
		"INTERACTION",
		340.0
	)

	preview.set_object_manager(
		object_manager
	)

	preview.clear_object()

	preview.clear_launch_objects()

	preview.set_active(
		false
	)


	# =========================================================
	# PREVIEW CONTROLS HELP
	#
	# Estes controlos aplicam-se APENAS à preview 3D.
	# =========================================================

	preview_controls_label = theme.create_status_label(
		"PREVIEW CONTROLS"
	)

	preview_controls_label.custom_minimum_size = Vector2(
		0.0,
		72.0
	)

	preview_controls_label.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	preview_controls_label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	preview_controls_label.text = (
		"LEFT MOUSE BUTTON: ROTATE CAMERA\n"
		+
		"RIGHT MOUSE BUTTON: PAN / MOVE CAMERA\n"
		+
		"SCROLL WHEEL: ZOOM\n"
		+
		"THESE CONTROLS ONLY APPLY INSIDE THE 3D PREVIEW."
	)

	preview_content.add_child(
		preview_controls_label
	)


	# =========================================================
	# CAMERA
	# =========================================================

	create_camera_controls(
		preview_content
	)


	responsive_columns.queue_sort()


# =============================================================
# SELECTION
# =============================================================

func build_selection(
	parent: VBoxContainer
) -> void:

	parent.add_child(
		theme.create_section_label(
			"SELECTION"
		)
	)


	selection_row = BoxContainer.new()

	selection_row.vertical = false

	selection_row.name = (
		"SelectionRow"
	)

	selection_row.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	selection_row.add_theme_constant_override(
		"separation",
		8
	)

	parent.add_child(
		selection_row
	)


	# =========================================================
	# OBJECT
	# =========================================================

	var object_panel := create_section_panel(
		"OBJECT"
	)

	selection_row.add_child(
		object_panel
	)


	var object_content := get_panel_content(
		object_panel
	)


	object_content.add_child(
		create_small_label(
			"SELECT OBJECT"
		)
	)


	object_selector = OptionButton.new()

	object_selector.custom_minimum_size = Vector2(
		0.0,
		40.0
	)

	object_selector.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	object_content.add_child(
		object_selector
	)


	random_object = create_toggle(
		"RANDOM OBJECT"
	)

	object_content.add_child(
		random_object
	)


	object_selector.item_selected.connect(
		_on_object_selected
	)

	random_object.toggled.connect(
		_on_random_object_toggled
	)


	# =========================================================
	# TARGET
	# =========================================================

	var target_panel := create_section_panel(
		"TARGET"
	)

	selection_row.add_child(
		target_panel
	)


	var target_content := get_panel_content(
		target_panel
	)


	target_content.add_child(
		create_small_label(
			"SELECT HIT POINT"
		)
	)


	target_selector = OptionButton.new()

	target_selector.custom_minimum_size = Vector2(
		0.0,
		40.0
	)

	target_selector.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	target_content.add_child(
		target_selector
	)


	random_target = create_toggle(
		"RANDOM HIT POINT"
	)

	target_content.add_child(
		random_target
	)


	target_selector.item_selected.connect(
		_on_target_selected
	)

	random_target.toggled.connect(
		_on_random_target_toggled
	)


# =============================================================
# SPAWN
# =============================================================

func build_spawn(
	parent: VBoxContainer
) -> void:

	var panel := create_section_panel(
		"SPAWN"
	)

	parent.add_child(
		panel
	)


	var content := get_panel_content(
		panel
	)


	content.add_child(
		create_small_label(
			"SPAWN POSITION"
		)
	)


	spawn_selector = OptionButton.new()

	spawn_selector.custom_minimum_size = Vector2(
		0.0,
		40.0
	)

	spawn_selector.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	content.add_child(
		spawn_selector
	)


	spawn_selector.item_selected.connect(
		_on_spawn_selected
	)


# =============================================================
# PHYSICS
# =============================================================

func build_physics(
	parent: VBoxContainer
) -> void:

	var panel := create_section_panel(
		"PHYSICS"
	)

	parent.add_child(
		panel
	)


	var content := get_panel_content(
		panel
	)


	force_spin = theme.create_spinbox(
		0.0,
		100.0,
		0.1,
		1.8
	)

	content.add_child(
		theme.labeled_control(
			"FORCE",
			force_spin
		)
	)


	speed_spin = theme.create_spinbox(
		0.1,
		100.0,
		0.1,
		5.4
	)

	content.add_child(
		theme.labeled_control(
			"SPEED",
			speed_spin
		)
	)


	amount_spin = theme.create_spinbox(
		1.0,
		100.0,
		1.0,
		1.0
	)

	content.add_child(
		theme.labeled_control(
			"AMOUNT",
			amount_spin
		)
	)


	force_spin.value_changed.connect(
		_on_force_changed
	)

	speed_spin.value_changed.connect(
		_on_speed_changed
	)

	amount_spin.value_changed.connect(
		_on_amount_changed
	)


	var reset_defaults_button := theme.create_button(
		"RESTORE PHYSICS DEFAULTS"
	)

	reset_defaults_button.custom_minimum_size = Vector2(
		0.0,
		40.0
	)

	reset_defaults_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	content.add_child(
		reset_defaults_button
	)


	reset_defaults_button.pressed.connect(
		restore_physics_defaults
	)


# =============================================================
# TEST
# =============================================================

func build_test(
	parent: VBoxContainer
) -> void:

	var panel := create_section_panel(
		"TEST"
	)

	parent.add_child(
		panel
	)


	var content := get_panel_content(
		panel
	)


	status_label = theme.create_status_label(
		"SELECT AN OBJECT TO TEST"
	)

	status_label.custom_minimum_size = Vector2(
		0.0,
		48.0
	)

	content.add_child(
		status_label
	)


	var test_button := theme.create_button(
		"TEST INTERACTION"
	)

	test_button.custom_minimum_size = Vector2(
		0.0,
		48.0
	)

	test_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	content.add_child(
		test_button
	)


	test_button.pressed.connect(
		_on_test_pressed
	)


# =============================================================
# CAMERA
# =============================================================

func create_camera_controls(
	parent: VBoxContainer
) -> void:

	var panel := PanelContainer.new()

	panel.name = (
		"CameraPanel"
	)

	panel.custom_minimum_size = Vector2(
		0.0,
		150.0
	)

	panel.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	theme.style_panel(
		panel,
		CIGATheme.PANEL_LIGHT,
		CIGATheme.BORDER
	)

	parent.add_child(
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

	box.add_theme_constant_override(
		"separation",
		7
	)

	margin.add_child(
		box
	)


	box.add_child(
		theme.create_section_label(
			"CAMERA"
		)
	)


	var auto_button := theme.create_button(
		"AUTO FRAME"
	)

	auto_button.custom_minimum_size = Vector2(
		0.0,
		38.0
	)

	box.add_child(
		auto_button
	)


	auto_button.pressed.connect(
		_auto_frame_camera
	)


	var row := HBoxContainer.new()

	row.add_theme_constant_override(
		"separation",
		6
	)

	box.add_child(
		row
	)


	camera_x = theme.create_spinbox(
		-50.0,
		50.0,
		0.01,
		0.0
	)

	row.add_child(
		theme.labeled_control(
			"X",
			camera_x
		)
	)


	camera_y = theme.create_spinbox(
		-50.0,
		50.0,
		0.01,
		1.5
	)

	row.add_child(
		theme.labeled_control(
			"Y",
			camera_y
		)
	)


	camera_z = theme.create_spinbox(
		-50.0,
		50.0,
		0.01,
		4.0
	)

	row.add_child(
		theme.labeled_control(
			"Z",
			camera_z
		)
	)


	camera_fov = theme.create_spinbox(
		10.0,
		120.0,
		1.0,
		42.0
	)

	box.add_child(
		theme.labeled_control(
			"FOV",
			camera_fov
		)
	)


	camera_status = theme.create_status_label(
		"AUTO"
	)

	box.add_child(
		camera_status
	)


	camera_x.value_changed.connect(
		_on_camera_changed
	)

	camera_y.value_changed.connect(
		_on_camera_changed
	)

	camera_z.value_changed.connect(
		_on_camera_changed
	)

	camera_fov.value_changed.connect(
		_on_camera_changed
	)


# =============================================================
# PROFILE CONFIGURATION
# =============================================================

func load_profile_configuration() -> void:

	if interaction == null:

		return


	if profile_manager == null:

		return


	var data := (
		profile_manager.get_active_interaction()
	)


	if not data.is_empty():

		interaction.from_dictionary(
			data
		)


	refresh_object_selector()

	refresh_target_selector()

	refresh_spawn_selector()

	refresh_values()

	load_character_mapping()


# =============================================================
# PROFILE CHANGED
# =============================================================

func _on_profile_changed(
	_profile: Dictionary
) -> void:

	load_profile_configuration()

	clear_preview()

	test_locked = false

	preview_test_pending = false


	if status_label != null:

		status_label.text = (
			"PROFILE CONFIGURATION LOADED"
		)


# =============================================================
# SAVE PROFILE
# =============================================================

func save_current_profile_interaction() -> void:

	if profile_manager == null:

		return


	if interaction == null:

		return


	profile_manager.set_active_interaction(
		interaction.to_dictionary()
	)


# =============================================================
# CHARACTER DATA
# =============================================================

func set_active_character_data(
	character_data: Dictionary
) -> void:

	active_character_data = (
		character_data.duplicate(
			true
		)
	)

	active_bone_map.clear()

	active_enabled_hitpoints.clear()

	load_character_mapping()

	refresh_target_selector()


	if preview == null:
		return


	if character_runtime == null:

		preview.clear_character()

		return


	if not character_runtime.is_character_loaded():

		preview.clear_character()

		return


	# =========================================================
	# O PATH PODE ESTAR VAZIO
	#
	# Isto acontece normalmente com o CIGA Avatar nativo.
	# O CIGAPreview3D trata esse caso directamente através
	# do character_runtime.
	# =========================================================

	var loaded_path := str(
		character_runtime.get_active_character_path()
	)


	preview.load_character(
		loaded_path,
		character_runtime
	)


	call_deferred(
		"sync_camera_controls"
	)


# =============================================================
# LOAD CHARACTER MAPPING
# =============================================================

func load_character_mapping() -> void:

	active_bone_map.clear()

	active_enabled_hitpoints.clear()


	if profile_manager == null:

		return


	if active_character_data.is_empty():

		return


	var character_id := str(
		active_character_data.get(
			"id",
			""
		)
	)


	if character_id.is_empty():

		return


	var mapping := (
		profile_manager.get_active_avatar_mapping(
			character_id
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
			bone_map.duplicate(
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

			active_enabled_hitpoints.append(
				str(
					value
				)
			)


# =============================================================
# ACTIVE CHARACTER INTO PREVIEW
# =============================================================

func load_active_character_into_preview() -> void:

	if preview == null:
		return


	if character_runtime == null:
		return


	if not character_runtime.is_character_loaded():

		preview.clear_character()

		return


	# =========================================================
	# O PATH PODE ESTAR VAZIO
	#
	# Para o CIGA Avatar nativo isso é esperado.
	# =========================================================

	var path := str(
		character_runtime.get_active_character_path()
	)


	preview.load_character(
		path,
		character_runtime
	)


	call_deferred(
		"sync_camera_controls"
	)

# =============================================================
# CAMERA CHANGED
# =============================================================

func _on_camera_changed(
	_unused_value: float
) -> void:

	if preview == null:

		return


	preview.set_camera_manual(
		camera_x.value,
		camera_y.value,
		camera_z.value,
		camera_fov.value
	)


	if camera_status != null:

		camera_status.text = (
			"MANUAL"
		)


# =============================================================
# AUTO FRAME
# =============================================================

func _auto_frame_camera() -> void:

	if preview == null:

		return


	if preview.character_model != null:

		preview.frame_camera_to_character()

	elif preview.object_model != null:

		preview.frame_camera()

	else:

		preview.frame_camera()


	sync_camera_controls()


	if camera_status != null:

		camera_status.text = (
			"AUTO"
		)


# =============================================================
# CAMERA SYNC
# =============================================================

func sync_camera_controls() -> void:

	if preview == null:

		return


	if camera_x == null:

		return


	var position := (
		preview.get_camera_position()
	)


	camera_x.set_value_no_signal(
		position.x
	)

	camera_y.set_value_no_signal(
		position.y
	)

	camera_z.set_value_no_signal(
		position.z
	)

	camera_fov.set_value_no_signal(
		preview.get_camera_fov()
	)


# =============================================================
# PREVIEW ACTIVE
# =============================================================

func set_preview_active(
	active: bool
) -> void:

	preview_active = active


	if preview == null:

		return


	preview.visible = true

	preview.set_active(
		active
	)


	if active:

		load_active_character_into_preview()

		refresh()


# =============================================================
# CLEAR PREVIEW
# =============================================================

func clear_preview() -> void:

	if preview == null:

		return


	preview.clear_object()

	preview.clear_launch_objects()


# =============================================================
# TEST
# =============================================================

func _on_test_pressed() -> void:

	if test_locked:

		return


	if interaction == null:

		return


	if interaction_runtime == null:

		if status_label != null:

			status_label.text = (
				"RUNTIME NOT READY"
			)

		return


	if not interaction.validate():

		if status_label != null:

			status_label.text = (
				"INTERACTION NOT READY"
			)

		return


	if not interaction.random_object:

		if interaction.get_selected_object().is_empty():

			if status_label != null:

				status_label.text = (
					"NO OBJECT SELECTED"
				)

			return


	save_current_profile_interaction()


	print(
		"CIGA UI TEST | AMOUNT=",
		interaction.amount,
		" | OBJECT=",
		(
			"RANDOM"
			if interaction.random_object
			else
			str(
				interaction
				.get_selected_object()
				.get(
					"name",
					"OBJECT"
				)
			)
		),
		" | TARGET=",
		(
			"RANDOM"
			if interaction.random_target
			else
			interaction.selected_target
		)
	)


	test_locked = true

	preview_test_pending = true


	var result := (
		interaction_runtime.execute_configuration(
			interaction
		)
	)


	if not result:

		preview_test_pending = false

		test_locked = false


		if status_label != null:

			status_label.text = (
				"INTERACTION FAILED"
			)

		return


	if status_label != null:

		status_label.text = (
			"INTERACTION STARTED ×"
			+
			str(
				interaction.amount
			)
		)


	if preview != null:

		var scene_tree := (
			preview.get_tree()
		)


		if scene_tree != null:

			scene_tree.create_timer(
				0.20
			).timeout.connect(
				func() -> void:

					test_locked = false
			)

			return


	test_locked = false


# =============================================================
# RUNTIME BURST
#
# IMPORTANTE:
#
# A escala pertence ao CIGAObjects.
#
# O Interaction Runtime pode gerar os launches sem transportar
# explicitamente a escala final.
#
# Aqui apenas resolvemos a escala através do object_manager.
# =============================================================

func _on_runtime_burst_started(
	launches: Array
) -> void:

	if not preview_test_pending:
		return


	preview_test_pending = false


	if preview == null:
		return


	if launches.is_empty():
		return


	var preview_launches: Array = []


	# =========================================================
	# NORMALIZE LAUNCH DATA
	# =========================================================

	for launch_value: Variant in launches:

		if not launch_value is Dictionary:
			continue


		var launch_data: Dictionary = (
			(
				launch_value
				as
				Dictionary
			)
			.duplicate(
				true
			)
		)


		# =====================================================
		# OBJECT ID
		# =====================================================

		var object_id := str(
			launch_data.get(
				"object_id",
				""
			)
		)


		# =====================================================
		# FALLBACK OBJECT DATA
		# =====================================================

		if object_id.is_empty():

			var object_value: Variant = (
				launch_data.get(
					"object_data",
					{}
				)
			)


			if object_value is Dictionary:

				object_id = str(
					(
						object_value
						as
						Dictionary
					)
					.get(
						"id",
						""
					)
				)


		# =====================================================
		# RESOLVE SCALE THROUGH CIGAOBJECTS
		# =====================================================

		if (
			object_manager != null
			and
			not object_id.is_empty()
		):

			var object_data := (
				object_manager.get_object(
					object_id
				)
			)


			if not object_data.is_empty():

				var effective_scale := (
					object_manager.get_effective_object_scale(
						object_id
					)
				)


				launch_data["scale"] = (
					effective_scale
				)

				launch_data["object_scale"] = (
					effective_scale
				)

				launch_data["effective_scale"] = (
					effective_scale
				)


		# =====================================================
		# FALLBACK
		# =====================================================

		if not launch_data.has("scale"):

			if launch_data.has("object_scale"):

				launch_data["scale"] = float(
					launch_data.get(
						"object_scale",
						1.0
					)
				)

			elif launch_data.has("effective_scale"):

				launch_data["scale"] = float(
					launch_data.get(
						"effective_scale",
						1.0
					)
				)

			elif interaction != null:

				launch_data["scale"] = (
					interaction.object_scale
				)

			else:

				launch_data["scale"] = 1.0


		preview_launches.append(
			launch_data
		)


	if preview_launches.is_empty():
		return




	# =========================================================
	# SEND TO PREVIEW
	# =========================================================

	preview.clear_launch_objects()


	preview.launch_burst(
		preview_launches
	)


# =============================================================
# RESPONSIVE
# =============================================================

func register_responsive_layout(
	layout: CIGAResponsiveLayout
) -> void:

	if layout == null:

		return


	responsive_layout = layout


	layout.register_module(
		self
	)


func set_responsive_mode(
	mode: CIGAResponsiveLayout.LayoutMode
) -> void:

	if responsive_columns == null:

		return


	match mode:

		CIGAResponsiveLayout.LayoutMode.WIDE:

			responsive_columns.vertical = false

			configuration_column.custom_minimum_size = Vector2(
				430.0,
				0.0
			)

			preview_column.custom_minimum_size = Vector2(
				520.0,
				0.0
			)

			selection_row.vertical = false


		CIGAResponsiveLayout.LayoutMode.COMPACT:

			responsive_columns.vertical = true

			configuration_column.custom_minimum_size = Vector2(
				0.0,
				0.0
			)

			preview_column.custom_minimum_size = Vector2(
				0.0,
				0.0
			)

			selection_row.vertical = false


		CIGAResponsiveLayout.LayoutMode.NARROW:

			responsive_columns.vertical = true

			configuration_column.custom_minimum_size = Vector2(
				0.0,
				0.0
			)

			preview_column.custom_minimum_size = Vector2(
				0.0,
				0.0
			)

			selection_row.vertical = true


	responsive_columns.queue_sort()

	selection_row.queue_sort()


# =============================================================
# SECTION PANEL
# =============================================================

func create_section_panel(
	title_text: String
) -> PanelContainer:

	var panel := PanelContainer.new()

	panel.custom_minimum_size = Vector2(
		0.0,
		125.0
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


	var margin := MarginContainer.new()

	theme.set_margins(
		margin,
		10
	)

	panel.add_child(
		margin
	)


	var content := VBoxContainer.new()

	content.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	content.add_theme_constant_override(
		"separation",
		7
	)

	margin.add_child(
		content
	)


	content.add_child(
		theme.create_section_label(
			title_text
		)
	)


	return panel


# =============================================================
# PANEL CONTENT
# =============================================================

func get_panel_content(
	panel: PanelContainer
) -> VBoxContainer:

	if panel == null:

		return null


	if panel.get_child_count() == 0:

		return null


	var margin := panel.get_child(
		0
	)


	if not margin is MarginContainer:

		return null


	if margin.get_child_count() == 0:

		return null


	var content := margin.get_child(
		0
	)


	if not content is VBoxContainer:

		return null


	return (
		content
		as
		VBoxContainer
	)


# =============================================================
# SMALL LABEL
# =============================================================

func create_small_label(
	text_value: String
) -> Label:

	var label := Label.new()

	label.text = (
		text_value
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
# TOGGLE
# =============================================================

func create_toggle(
	text_value: String
) -> CheckBox:

	var checkbox := CheckBox.new()

	checkbox.text = (
		text_value
	)


	checkbox.custom_minimum_size = Vector2(
		0.0,
		38.0
	)


	checkbox.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	checkbox.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND
	)


	checkbox.add_theme_font_size_override(
		"font_size",
		13
	)


	checkbox.add_theme_color_override(
		"font_color",
		CIGATheme.TEXT
	)


	return checkbox


# =============================================================
# OBJECT SELECT
# =============================================================

func _on_object_selected(
	index: int
) -> void:

	if interaction == null:

		return


	if index <= 0:

		interaction.set_object(
			""
		)


		clear_preview()


		if status_label != null:

			status_label.text = (
				"SELECT AN OBJECT TO TEST"
			)


		save_current_profile_interaction()

		return


	var object_index := (
		index - 1
	)


	if object_manager == null:

		return


	if (
		object_index < 0
		or
		object_index >= object_manager.objects.size()
	):

		return


	var object_data := (
		object_manager.objects[
			object_index
		]
	)


	var object_id := str(
		object_data.get(
			"id",
			""
		)
	)


	if object_id.is_empty():

		return


	if not interaction.set_object(
		object_id
	):

		return


	save_current_profile_interaction()


	if status_label != null:

		status_label.text = (
			"OBJECT READY — PRESS TEST INTERACTION"
		)


# =============================================================
# RANDOM OBJECT
# =============================================================

func _on_random_object_toggled(
	enabled: bool
) -> void:

	if interaction == null:

		return


	interaction.set_random_object(
		enabled
	)


	save_current_profile_interaction()

	clear_preview()


	if enabled:

		if status_label != null:

			status_label.text = (
				"RANDOM OBJECT READY — PRESS TEST INTERACTION"
			)

	else:

		if status_label != null:

			status_label.text = (
				"OBJECT READY — PRESS TEST INTERACTION"
			)


# =============================================================
# TARGET
# =============================================================

func _on_target_selected(
	index: int
) -> void:

	if interaction == null:

		return


	if (
		index < 0
		or
		index >= CIGAInteraction.TARGETS.size()
	):

		return


	interaction.set_target(
		CIGAInteraction.TARGETS[
			index
		]
	)


	save_current_profile_interaction()


# =============================================================
# RANDOM TARGET
# =============================================================

func _on_random_target_toggled(
	enabled: bool
) -> void:

	if interaction == null:

		return


	interaction.set_random_target(
		enabled
	)


	save_current_profile_interaction()


# =============================================================
# SPAWN
# =============================================================

func _on_spawn_selected(
	index: int
) -> void:

	if interaction == null:

		return


	if (
		index < 0
		or
		index >= CIGAInteraction.SPAWNS.size()
	):

		return


	interaction.set_spawn(
		CIGAInteraction.SPAWNS[
			index
		]
	)


	save_current_profile_interaction()


# =============================================================
# FORCE
# =============================================================

func _on_force_changed(
	value: float
) -> void:

	if interaction == null:

		return


	interaction.set_force(
		value
	)


	save_current_profile_interaction()


# =============================================================
# SPEED
# =============================================================

func _on_speed_changed(
	value: float
) -> void:

	if interaction == null:

		return


	interaction.set_speed(
		value
	)


	save_current_profile_interaction()


# =============================================================
# AMOUNT
# =============================================================

func _on_amount_changed(
	value: float
) -> void:

	if interaction == null:

		return


	var exact_amount := clampi(
		int(
			round(
				value
			)
		),
		1,
		100
	)


	interaction.set_amount(
		exact_amount
	)


	save_current_profile_interaction()




# =============================================================
# REFRESH
# =============================================================

func refresh() -> void:

	refresh_object_selector()

	refresh_target_selector()

	refresh_spawn_selector()

	refresh_values()

	sync_camera_controls()


# =============================================================
# OBJECT SELECTOR
# =============================================================

func refresh_object_selector() -> void:

	if object_selector == null:

		return


	object_selector.clear()

	object_selector.add_item(
		"SELECT OBJECT"
	)


	if object_manager == null:

		return


	for object_data: Dictionary in object_manager.objects:

		var object_name := str(
			object_data.get(
				"name",
				"OBJECT"
			)
		)


		object_selector.add_item(
			object_name
		)


	if interaction == null:

		return


	var selected_id := (
		interaction.selected_object_id
	)


	if selected_id.is_empty():

		object_selector.select(
			0
		)

		return


	for index in range(
		object_manager.objects.size()
	):

		var data := (
			object_manager.objects[
				index
			]
		)


		if str(
			data.get(
				"id",
				""
			)
		) == selected_id:

			object_selector.select(
				index + 1
			)

			return


	object_selector.select(
		0
	)


# =============================================================
# TARGET SELECTOR
# =============================================================

func refresh_target_selector() -> void:

	if target_selector == null:

		return


	if interaction == null:

		return


	target_selector.clear()


	var available_targets: Array[String] = []


	if not active_enabled_hitpoints.is_empty():

		for hitpoint: String in active_enabled_hitpoints:

			var target_name := (
				hitpoint_to_target(
					hitpoint
				)
			)


			if not target_name.is_empty():

				available_targets.append(
					target_name
				)

	else:

		available_targets = (
			CIGAInteraction.TARGETS.duplicate()
		)


	for target_name: String in available_targets:

		target_selector.add_item(
			target_name
		)


	var current_target := (
		interaction.selected_target
	)


	var selected_index := (
		available_targets.find(
			current_target
		)
	)


	if selected_index >= 0:

		target_selector.select(
			selected_index
		)

	elif target_selector.item_count > 0:

		target_selector.select(
			0
		)


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
# SPAWN SELECTOR
# =============================================================

func refresh_spawn_selector() -> void:

	if spawn_selector == null:

		return


	if interaction == null:

		return


	spawn_selector.clear()


	for spawn_name: String in CIGAInteraction.SPAWNS:

		spawn_selector.add_item(
			spawn_name
		)


	var selected_index := (
		CIGAInteraction.SPAWNS.find(
			interaction.selected_spawn
		)
	)


	if selected_index >= 0:

		spawn_selector.select(
			selected_index
		)


# =============================================================
# VALUES
# =============================================================

func refresh_values() -> void:

	if interaction == null:

		return


	if random_object != null:

		random_object.set_pressed_no_signal(
			interaction.random_object
		)


	if random_target != null:

		random_target.set_pressed_no_signal(
			interaction.random_target
		)


	if force_spin != null:

		force_spin.set_value_no_signal(
			interaction.force
		)


	if speed_spin != null:

		speed_spin.set_value_no_signal(
			interaction.speed
		)


	if amount_spin != null:

		amount_spin.set_value_no_signal(
			float(
				interaction.amount
			)
		)


# =============================================================
# CHARACTER MAPPING
# =============================================================

func refresh_character_mapping() -> void:

	load_character_mapping()

	refresh_target_selector()


func load_character_mapping_from_profile() -> void:

	load_character_mapping()


# =============================================================
# ACTIVE CHARACTER ID
# =============================================================

func get_active_character_id() -> String:

	return str(
		active_character_data.get(
			"id",
			""
		)
	)


# =============================================================
# VALID TARGET
# =============================================================

func has_valid_target(
	target_name: String
) -> bool:

	if active_enabled_hitpoints.is_empty():

		return true


	var hitpoint := (
		target_to_hitpoint(
			target_name
		)
	)


	return active_enabled_hitpoints.has(
		hitpoint
	)


# =============================================================
# PROFILE MAPPING INFO
# =============================================================

func get_active_mapping() -> Dictionary:

	return {
		"bone_map":
			active_bone_map.duplicate(
				true
			),

		"enabled_hitpoints":
			active_enabled_hitpoints.duplicate(),

		"character_id":
			get_active_character_id()
	}


# =============================================================
# RESTORE PHYSICS DEFAULTS
# =============================================================

func restore_physics_defaults() -> void:

	if interaction == null:

		return


	interaction.set_force(
		CIGASettings.DEFAULT_FORCE
	)

	interaction.set_speed(
		CIGASettings.DEFAULT_SPEED
	)

	interaction.set_amount(
		1
	)


	if force_spin != null:

		force_spin.set_value_no_signal(
			CIGASettings.DEFAULT_FORCE
		)


	if speed_spin != null:

		speed_spin.set_value_no_signal(
			CIGASettings.DEFAULT_SPEED
		)


	if amount_spin != null:

		amount_spin.set_value_no_signal(
			1.0
		)


	save_current_profile_interaction()


	if status_label != null:

		status_label.text = (
			"PHYSICS DEFAULTS RESTORED"
		)
