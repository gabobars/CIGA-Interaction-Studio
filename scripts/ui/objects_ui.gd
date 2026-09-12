class_name CIGAObjectsUI
extends RefCounted


# =============================================================
# CIGA OBJECTS UI
# Godot 4.7.2
#
# RESPONSABILIDADES
#
# - biblioteca de objetos
# - importação GLB / GLTF
# - remoção
# - seleção
# - auto-scale
# - multiplicador de escala
# - preview
# - otimização
# - optimizer quality
# - camera do preview
#
#
# SCALE ARCHITECTURE
#
# CIGAObjects:
#
#     base_scale
#
# CIGAProfiles:
#
#     scale_multipliers[object_id]
#
# FINAL:
#
#     base_scale × profile_multiplier
#
# =============================================================


# =============================================================
# ROOT
# =============================================================

var root: PanelContainer


# =============================================================
# REFERENCES
# =============================================================

var object_manager: CIGAObjects

var profile_manager: CIGAProfiles

var character_runtime: CIGACharacterRuntime

var theme: CIGATheme

var optimizer_controller: CIGAOPTrue


# =============================================================
# CONTROLS
# =============================================================

var object_list: ItemList

var object_name_label: Label

var object_format_label: Label

var object_status_label: Label

var object_scale: SpinBox

var auto_scale_checkbox: CheckBox

var optimize_checkbox: CheckBox

var optimizer_quality_selector: OptionButton

var optimizer_quality_status: Label


# =============================================================
# IMPORT
# =============================================================

var import_dialog: FileDialog


# =============================================================
# PREVIEW
# =============================================================

var preview: CIGAPreview3D

var preview_object_id: String = ""

var preview_scale: float = 1.0

var preview_active: bool = false


# =============================================================
# PREVIEW HELP
# =============================================================

var preview_controls_label: Label


# =============================================================
# CHARACTER
# =============================================================

var active_character_data: Dictionary = {}


# =============================================================
# CAMERA
# =============================================================

var camera_x: SpinBox

var camera_y: SpinBox

var camera_z: SpinBox

var camera_fov: SpinBox

var camera_status: Label


# =============================================================
# SETUP
# =============================================================

func setup(
	parent: Control,
	manager: CIGAObjects,
	ui_theme: CIGATheme,
	char_runtime: CIGACharacterRuntime,
	profiles: CIGAProfiles
) -> Control:

	object_manager = manager

	theme = ui_theme

	character_runtime = char_runtime

	profile_manager = profiles


	# =========================================================
	# ROOT
	# =========================================================

	root = PanelContainer.new()

	root.name = (
		"ObjectsPage"
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


	# =========================================================
	# OPTIMIZER CONTROLLER
	# =========================================================

	optimizer_controller = CIGAOPTrue.new()

	optimizer_controller.name = (
		"CIGAOPTrue"
	)

	parent.add_child(
		optimizer_controller
	)


	if not optimizer_controller.optimization_started.is_connected(
		_on_optimization_started
	):

		optimizer_controller.optimization_started.connect(
			_on_optimization_started
		)


	if not optimizer_controller.optimization_finished.is_connected(
		_on_optimization_finished
	):

		optimizer_controller.optimization_finished.connect(
			_on_optimization_finished
		)


	# =========================================================
	# BUILD
	# =========================================================

	build()


	call_deferred(
		"refresh"
	)


	return root


# =============================================================
# BUILD
# =============================================================

func build() -> void:

	var scroll := ScrollContainer.new()

	scroll.name = "ObjectsScroll"

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
		22
	)

	margin.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	scroll.add_child(
		margin
	)


	var content := VBoxContainer.new()

	content.name = (
		"ObjectsContent"
	)

	content.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	content.size_flags_vertical = (
		Control.SIZE_SHRINK_BEGIN
	)

	content.add_theme_constant_override(
		"separation",
		12
	)

	margin.add_child(
		content
	)


	# =========================================================
	# TITLE
	# =========================================================

	content.add_child(
		theme.create_title(
			"OBJECT LIBRARY"
		)
	)


	content.add_child(
		theme.create_status_label(
			"Import and manage 3D objects used by CIGA interactions."
		)
	)


	# =========================================================
	# OBJECT LIST
	# =========================================================

	content.add_child(
		theme.create_section_label(
			"IMPORTED OBJECTS"
		)
	)


	object_list = ItemList.new()

	object_list.name = (
		"ObjectList"
	)

	object_list.custom_minimum_size = Vector2(
		0.0,
		150.0
	)

	object_list.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	object_list.allow_reselect = false

	content.add_child(
		object_list
	)


	object_list.item_selected.connect(
		_on_object_selected
	)


	# =========================================================
	# BUTTONS
	# =========================================================

	var buttons := HBoxContainer.new()

	buttons.custom_minimum_size = Vector2(
		0.0,
		44.0
	)

	buttons.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	buttons.add_theme_constant_override(
		"separation",
		10
	)

	content.add_child(
		buttons
	)


	var import_button := theme.create_button(
		"IMPORT GLB / GLTF"
	)

	import_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	buttons.add_child(
		import_button
	)

	import_button.pressed.connect(
		_open_import
	)


	var remove_button := theme.create_button(
		"REMOVE SELECTED"
	)

	remove_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	buttons.add_child(
		remove_button
	)

	remove_button.pressed.connect(
		_remove_selected
	)


	# =========================================================
	# AUTO SCALE
	# =========================================================

	auto_scale_checkbox = CheckBox.new()

	auto_scale_checkbox.name = (
		"AutoScaleObjectCheckbox"
	)

	auto_scale_checkbox.text = (
		"AUTO SCALE OBJECT ON IMPORT"
	)

	auto_scale_checkbox.custom_minimum_size = Vector2(
		0.0,
		38.0
	)

	auto_scale_checkbox.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	auto_scale_checkbox.button_pressed = true

	auto_scale_checkbox.tooltip_text = (
		"The CIGA calculates a normalized base size for the "
		+
		"object. 1.00 scale then represents that recommended size. "
		+
		"The original GLB/GLTF is not modified."
	)

	content.add_child(
		auto_scale_checkbox
	)


	# =========================================================
	# OPTIMIZATION
	# =========================================================

	optimize_checkbox = CheckBox.new()

	optimize_checkbox.name = (
		"OptimizeObjectCheckbox"
	)

	optimize_checkbox.text = (
		"OPTIMIZE OBJECT ON IMPORT"
	)

	optimize_checkbox.custom_minimum_size = Vector2(
		0.0,
		38.0
	)

	optimize_checkbox.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	optimize_checkbox.button_pressed = true

	optimize_checkbox.tooltip_text = (
		"Create an optimized CIGA cache when importing the object."
	)

	content.add_child(
		optimize_checkbox
	)


	# =========================================================
	# OPTIMIZER QUALITY
	# =========================================================

	content.add_child(
		theme.create_section_label(
			"OPTIMIZER QUALITY"
		)
	)


	optimizer_quality_selector = OptionButton.new()

	optimizer_quality_selector.name = (
		"OptimizerQualitySelector"
	)

	optimizer_quality_selector.add_item(
		"QUALITY"
	)


	optimizer_quality_selector.add_item(
		"BALANCED"
	)


	optimizer_quality_selector.add_item(
		"PERFORMANCE"
	)


	optimizer_quality_selector.custom_minimum_size = Vector2(
		0.0,
		38.0
	)

	optimizer_quality_selector.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	optimizer_quality_selector.focus_mode = (
		Control.FOCUS_NONE
	)

	optimizer_quality_selector.tooltip_text = (
		"Controls how aggressively CIGA prepares imported objects. "
		+
		"BALANCED is recommended for most objects."
	)

	content.add_child(
		optimizer_quality_selector
	)


	optimizer_quality_selector.item_selected.connect(
		_on_optimizer_quality_changed
	)


	# =========================================================
	# OPTIMIZER STATUS
	# =========================================================

	optimizer_quality_status = (
		theme.create_status_label(
			"OPTIMIZER QUALITY: BALANCED"
		)
	)

	optimizer_quality_status.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	optimizer_quality_status.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	content.add_child(
		optimizer_quality_status
	)


	# =========================================================
	# INITIAL QUALITY
	# =========================================================

	_refresh_optimizer_quality_ui()


	# =========================================================
	# WARNING
	# =========================================================

	var warning_label := theme.create_status_label(
		"Some extremely heavy or complex objects may fail to load "
		+
		"or optimize. If this happens, remove their cache before "
		+
		"starting CIGA again."
	)

	warning_label.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	content.add_child(
		warning_label
	)


	# =========================================================
	# SCALE
	#
	# O SpinBox representa EXCLUSIVAMENTE o multiplier.
	#
	# 1.00 = base_scale
	# 0.50 = metade
	# 2.00 = dobro
	#
	# =========================================================

	var scale_panel := create_section_panel(
		"OBJECT SCALE"
	)

	content.add_child(
		scale_panel
	)


	var scale_content := get_panel_content(
		scale_panel
	)


	if scale_content != null:

		object_scale = theme.create_spinbox(
			CIGAObjects.MIN_SCALE_MULTIPLIER,
			CIGAObjects.MAX_SCALE_MULTIPLIER,
			0.01,
			1.0
		)

		object_scale.allow_greater = false

		object_scale.allow_lesser = false

		object_scale.custom_minimum_size = Vector2(
			0.0,
			40.0
		)

		object_scale.size_flags_horizontal = (
			Control.SIZE_EXPAND_FILL
		)

		object_scale.tooltip_text = (
			"Scale multiplier. 1.00 = the normalized CIGA object size."
		)

		scale_content.add_child(
			theme.labeled_control(
				"SCALE MULTIPLIER",
				object_scale
			)
		)


		object_scale.value_changed.connect(
			_on_scale_changed
		)


	# =========================================================
	# PREVIEW
	# =========================================================

	content.add_child(
		theme.create_section_label(
			"3D PREVIEW"
		)
	)


	preview = CIGAPreview3D.new()


	preview.setup(
		content,
		"OBJECTS",
		420.0
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

	content.add_child(
		preview_controls_label
	)


	# =========================================================
	# CAMERA
	# =========================================================

	create_camera_controls(
		content
	)


	# =========================================================
	# INFORMATION
	# =========================================================

	object_name_label = theme.create_status_label(
		"NAME: NONE"
	)

	object_name_label.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	content.add_child(
		object_name_label
	)


	object_format_label = theme.create_status_label(
		"FORMAT: NONE"
	)

	object_format_label.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	content.add_child(
		object_format_label
	)


	object_status_label = theme.create_status_label(
		"STATUS: READY"
	)

	object_status_label.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	content.add_child(
		object_status_label
	)


# =============================================================
# OPTIMIZER QUALITY UI
# =============================================================

func _refresh_optimizer_quality_ui() -> void:

	var quality: int = (
		CIGAObjects.DEFAULT_OPTIMIZER_QUALITY
	)


	if object_manager != null:

		quality = (
			object_manager.get_optimizer_quality()
		)


	quality = clampi(
		quality,
		CIGAObjects.OPTIMIZER_QUALITY_QUALITY,
		CIGAObjects.OPTIMIZER_QUALITY_PERFORMANCE
	)


	if optimizer_quality_selector != null:

		optimizer_quality_selector.select(
			quality
		)


	if optimizer_quality_status != null:

		var quality_name := (
			_get_optimizer_quality_name(
				quality
			)
		)


		optimizer_quality_status.text = (
			"OPTIMIZER QUALITY: "
			+
			quality_name
			+
			"\n"
			+
			_get_optimizer_quality_description(
				quality
			)
		)


# =============================================================
# OPTIMIZER QUALITY NAME
# =============================================================

func _get_optimizer_quality_name(
	quality: int
) -> String:

	match quality:

		CIGAObjects.OPTIMIZER_QUALITY_QUALITY:

			return "QUALITY"


		CIGAObjects.OPTIMIZER_QUALITY_BALANCED:

			return "BALANCED"


		CIGAObjects.OPTIMIZER_QUALITY_PERFORMANCE:

			return "PERFORMANCE"


	return "BALANCED"


# =============================================================
# OPTIMIZER QUALITY DESCRIPTION
# =============================================================

func _get_optimizer_quality_description(
	quality: int
) -> String:

	match quality:

		CIGAObjects.OPTIMIZER_QUALITY_QUALITY:

			return (
				"Higher visual fidelity with lighter optimization."
			)


		CIGAObjects.OPTIMIZER_QUALITY_BALANCED:

			return (
				"Recommended for most objects."
			)


		CIGAObjects.OPTIMIZER_QUALITY_PERFORMANCE:

			return (
				"More aggressive optimization for heavy objects."
			)


	return (
		"Recommended for most objects."
	)


# =============================================================
# OPTIMIZER QUALITY CHANGED
# =============================================================

func _on_optimizer_quality_changed(
	index: int
) -> void:

	var quality: int = clampi(
		index,
		CIGAObjects.OPTIMIZER_QUALITY_QUALITY,
		CIGAObjects.OPTIMIZER_QUALITY_PERFORMANCE
	)


	if object_manager == null:

		return


	# =========================================================
	# APPLY AS DEFAULT QUALITY
	#
	# Não reconstruímos automaticamente todos os caches.
	# A escolha passa a ser usada nas próximas optimizações.
	#
	# =========================================================

	object_manager.set_optimizer_quality(
		quality,
		false
	)


	# =========================================================
	# CONTROLLER
	#
	# Se CIGAOPTrue possuir uma API de qualidade, usamos.
	# Mantemos fallback para o CIGAObjects optimizer.
	# =========================================================

	if optimizer_controller != null:

		if optimizer_controller.has_method(
			"set_optimizer_quality"
		):

			optimizer_controller.call(
				"set_optimizer_quality",
				quality
			)


	elif object_manager.get_optimizer() != null:

		object_manager.get_optimizer().set_quality(
			quality
		)


	_refresh_optimizer_quality_ui()


# =============================================================
# SECTION PANEL
# =============================================================

func create_section_panel(
	title_text: String
) -> PanelContainer:

	var panel := PanelContainer.new()

	panel.custom_minimum_size = Vector2(
		0.0,
		100.0
	)

	panel.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
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


	var box := VBoxContainer.new()

	box.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	box.add_theme_constant_override(
		"separation",
		7
	)

	margin.add_child(
		box
	)


	box.add_child(
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
# ACTIVE CHARACTER
# =============================================================

func set_active_character_data(
	character_data: Dictionary
) -> void:

	active_character_data = (
		character_data.duplicate(
			true
		)
	)


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
	# Isso é normal para o CIGA Avatar nativo.
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
# GET OBJECT DATA FOR UI
# =============================================================

func get_ui_object_data(
	object_id: String
) -> Dictionary:

	if object_id.is_empty():

		return {}


	if object_manager == null:

		return {}


	return (
		object_manager.get_object(
			object_id
		)
	)


# =============================================================
# PROFILE SCALE
# =============================================================

func get_profile_scale(
	object_data: Dictionary
) -> float:

	if object_data.is_empty():

		return CIGAObjects.DEFAULT_OBJECT_SCALE


	var base_scale := float(
		object_data.get(
			"base_scale",
			CIGAObjects.DEFAULT_OBJECT_SCALE
		)
	)


	if not is_finite(
		base_scale
	):

		base_scale = (
			CIGAObjects.DEFAULT_OBJECT_SCALE
		)


	base_scale = clampf(
		base_scale,
		CIGAObjects.MIN_OBJECT_SCALE,
		CIGAObjects.MAX_OBJECT_SCALE
	)


	var multiplier := float(
		object_data.get(
			"scale_multiplier",
			CIGAObjects.DEFAULT_SCALE_MULTIPLIER
		)
	)


	if not is_finite(
		multiplier
	):

		multiplier = (
			CIGAObjects.DEFAULT_SCALE_MULTIPLIER
		)


	multiplier = clampf(
		multiplier,
		CIGAObjects.MIN_SCALE_MULTIPLIER,
		CIGAObjects.MAX_SCALE_MULTIPLIER
	)


	var final_scale := (
		base_scale
		*
		multiplier
	)


	if not is_finite(
		final_scale
	):

		final_scale = (
			base_scale
		)


	return clampf(
		final_scale,
		CIGAObjects.MIN_OBJECT_SCALE,
		CIGAObjects.MAX_OBJECT_SCALE
	)


# =============================================================
# GET OBJECT MULTIPLIER
# =============================================================

func get_object_multiplier(
	object_data: Dictionary
) -> float:

	if object_data.is_empty():

		return CIGAObjects.DEFAULT_SCALE_MULTIPLIER


	var multiplier := float(
		object_data.get(
			"scale_multiplier",
			CIGAObjects.DEFAULT_SCALE_MULTIPLIER
		)
	)


	if not is_finite(
		multiplier
	):

		multiplier = (
			CIGAObjects.DEFAULT_SCALE_MULTIPLIER
		)


	return clampf(
		multiplier,
		CIGAObjects.MIN_SCALE_MULTIPLIER,
		CIGAObjects.MAX_SCALE_MULTIPLIER
	)


# =============================================================
# REFRESH
# =============================================================

func refresh() -> void:

	if object_list == null:

		return


	if object_manager == null:

		return


	_refresh_optimizer_quality_ui()


	var selected_id := (
		object_manager.active_object_id
	)


	object_list.clear()


	for object_data: Dictionary in object_manager.objects:

		object_list.add_item(
			str(
				object_data.get(
					"name",
					"UNKNOWN OBJECT"
				)
			)
		)


	if selected_id.is_empty():

		clear_information()

		return


	var index := (
		object_manager.find_object_index(
			selected_id
		)
	)


	if index < 0:

		clear_information()

		return


	if index >= object_manager.objects.size():

		clear_information()

		return


	object_list.select(
		index
	)


	var object_data := (
		get_ui_object_data(
			selected_id
		)
	)


	if object_data.is_empty():

		clear_information()

		return


	update_information(
		object_data
	)


	if preview_active:

		load_preview(
			object_data
		)


# =============================================================
# SELECT OBJECT
# =============================================================

func _on_object_selected(
	index: int
) -> void:

	if object_manager == null:

		return


	if (
		index < 0
		or
		index >= object_manager.objects.size()
	):

		return


	var raw_object_data := (
		object_manager.objects[
			index
		]
	)


	var object_id := str(
		raw_object_data.get(
			"id",
			""
		)
	)


	if object_id.is_empty():

		return


	if not object_manager.set_active_object(
		object_id
	):

		return


	var object_data := (
		get_ui_object_data(
			object_id
		)
	)


	if object_data.is_empty():

		return


	update_information(
		object_data
	)


	load_preview(
		object_data
	)


# =============================================================
# INFORMATION
# =============================================================

func update_information(
	object_data: Dictionary
) -> void:

	if object_data.is_empty():

		clear_information()

		return


	var object_id := str(
		object_data.get(
			"id",
			""
		)
	)


	if (
		object_manager != null
		and
		not object_id.is_empty()
	):

		var resolved_data := (
			get_ui_object_data(
				object_id
			)
		)


		if not resolved_data.is_empty():

			object_data = (
				resolved_data
			)


	if object_name_label != null:

		object_name_label.text = (
			"NAME: "
			+
			str(
				object_data.get(
					"name",
					"UNKNOWN"
				)
			)
		)


	if object_format_label != null:

		object_format_label.text = (
			"FORMAT: "
			+
			str(
				object_data.get(
					"extension",
					""
				)
			)
			.to_upper()
		)


	if object_status_label != null:

		var size_text := "UNKNOWN"


		if object_manager != null:

			size_text = (
				object_manager.format_file_size(
					int(
						object_data.get(
							"file_size",
							0
						)
					)
				)
			)


		var optimization_state := (
			"NOT OPTIMIZED"
		)


		if object_manager != null:

			if object_manager.object_has_optimized_cache(
				str(
					object_data.get(
						"id",
						""
					)
				)
			):

				optimization_state = (
					"OPTIMIZED CACHE READY"
				)


		var auto_scale_state := (
			"MANUAL SCALE"
		)


		if bool(
			object_data.get(
				"auto_scale",
				false
			)
		):

			auto_scale_state = (
				"AUTO SCALE"
			)


		var base_scale := float(
			object_data.get(
				"base_scale",
				CIGAObjects.DEFAULT_OBJECT_SCALE
			)
		)


		if not is_finite(
			base_scale
		):

			base_scale = (
				CIGAObjects.DEFAULT_OBJECT_SCALE
			)


		base_scale = clampf(
			base_scale,
			CIGAObjects.MIN_OBJECT_SCALE,
			CIGAObjects.MAX_OBJECT_SCALE
		)


		var multiplier := (
			get_object_multiplier(
				object_data
			)
		)


		var final_scale := (
			get_profile_scale(
				object_data
			)
		)


		object_status_label.text = (
			"STATUS: READY"
			+
			"\nSIZE: "
			+
			size_text
			+
			"\n"
			+
			optimization_state
			+
			"\n"
			+
			auto_scale_state
			+
			"\nBASE SCALE: "
			+
			("%.8f" % base_scale)
			+
			"\nSCALE MULTIPLIER: "
			+
			("%.2fx" % multiplier)
			+
			"\nFINAL SCALE: "
			+
			("%.8f" % final_scale)
		)


	if object_scale != null:

		object_scale.set_value_no_signal(
			get_object_multiplier(
				object_data
			)
		)


# =============================================================
# PREVIEW
# =============================================================

func load_preview(
	object_data: Dictionary
) -> void:

	if preview == null:

		return


	if object_data.is_empty():

		preview.clear_object()

		return


	var object_id := str(
		object_data.get(
			"id",
			""
		)
	)


	if object_id.is_empty():

		return


	var resolved_data := (
		get_ui_object_data(
			object_id
		)
	)


	if not resolved_data.is_empty():

		object_data = (
			resolved_data
		)


	var path := str(
		object_data.get(
			"source_path",
			""
		)
	)


	if path.is_empty():

		return


	var scale_value := (
		get_profile_scale(
			object_data
		)
	)


	preview_object_id = (
		object_id
	)

	preview_scale = (
		scale_value
	)


	preview.load_object(
		path,
		scale_value
	)


	call_deferred(
		"sync_camera_controls"
	)


# =============================================================
# CLEAR INFORMATION
# =============================================================

func clear_information() -> void:

	if object_name_label != null:

		object_name_label.text = (
			"NAME: NONE"
		)


	if object_format_label != null:

		object_format_label.text = (
			"FORMAT: NONE"
		)


	if object_status_label != null:

		object_status_label.text = (
			"STATUS: NO OBJECT SELECTED"
		)


	if object_scale != null:

		object_scale.set_value_no_signal(
			CIGAObjects.DEFAULT_SCALE_MULTIPLIER
		)


	preview_object_id = ""

	preview_scale = 1.0


	if preview != null:

		preview.clear_object()


# =============================================================
# SCALE
# =============================================================

func _on_scale_changed(
	value: float
) -> void:

	if object_manager == null:

		return


	var active_id := (
		object_manager.active_object_id
	)


	if active_id.is_empty():

		return


	var multiplier := float(
		value
	)


	if not is_finite(
		multiplier
	):

		multiplier = (
			CIGAObjects.DEFAULT_SCALE_MULTIPLIER
		)


	multiplier = snappedf(
		multiplier,
		0.01
	)


	multiplier = clampf(
		multiplier,
		CIGAObjects.MIN_SCALE_MULTIPLIER,
		CIGAObjects.MAX_SCALE_MULTIPLIER
	)


	if not object_manager.set_object_scale_multiplier(
		active_id,
		multiplier
	):

		return


	var resolved_data := (
		get_ui_object_data(
			active_id
		)
	)


	if resolved_data.is_empty():

		return


	var final_scale := (
		get_profile_scale(
			resolved_data
		)
	)


	preview_scale = (
		final_scale
	)


	if preview != null:

		var path := str(
			resolved_data.get(
				"source_path",
				""
			)
		)


		if not path.is_empty():

			preview.load_object(
				path,
				final_scale
			)


			call_deferred(
				"sync_camera_controls"
			)


	if object_status_label != null:

		var base_scale := float(
			resolved_data.get(
				"base_scale",
				CIGAObjects.DEFAULT_OBJECT_SCALE
			)
		)


		if not is_finite(
			base_scale
		):

			base_scale = (
				CIGAObjects.DEFAULT_OBJECT_SCALE
			)


		object_status_label.text = (
			"STATUS: READY"
			+
			"\nBASE SCALE: "
			+
			("%.8f" % base_scale)
			+
			"\nSCALE MULTIPLIER: "
			+
			("%.2fx" % multiplier)
			+
			"\nFINAL SCALE: "
			+
			("%.8f" % final_scale)
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

	box.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

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

	auto_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	box.add_child(
		auto_button
	)


	auto_button.pressed.connect(
		_auto_frame_camera
	)


	var row := HBoxContainer.new()

	row.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

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


	var camera_position := (
		preview.get_camera_position()
	)


	camera_x.set_value_no_signal(
		camera_position.x
	)

	camera_y.set_value_no_signal(
		camera_position.y
	)

	camera_z.set_value_no_signal(
		camera_position.z
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

		refresh()


# =============================================================
# REMOVE
# =============================================================

func _remove_selected() -> void:

	if object_list == null:

		return


	var selected_items := (
		object_list.get_selected_items()
	)


	if selected_items.is_empty():

		return


	var index := selected_items[0]


	if object_manager == null:

		return


	if (
		index < 0
		or
		index >= object_manager.objects.size()
	):

		return


	var data := (
		object_manager.objects[
			index
		]
	)


	var id := str(
		data.get(
			"id",
			""
		)
	)


	if id.is_empty():

		return


	object_manager.remove_object(
		id
	)


	call_deferred(
		"refresh"
	)


# =============================================================
# IMPORT
# =============================================================

func _open_import() -> void:

	if import_dialog != null:

		return


	import_dialog = FileDialog.new()

	import_dialog.name = (
		"ObjectImportDialog"
	)

	import_dialog.access = (
		FileDialog.ACCESS_FILESYSTEM
	)

	import_dialog.file_mode = (
		FileDialog.FILE_MODE_OPEN_FILE
	)

	import_dialog.title = (
		"IMPORT CIGA OBJECT"
	)


	import_dialog.add_filter(
		"*.glb",
		"GLB 3D MODEL"
	)

	import_dialog.add_filter(
		"*.gltf",
		"GLTF 3D MODEL"
	)


	root.add_child(
		import_dialog
	)


	import_dialog.file_selected.connect(
		_import_file
	)

	import_dialog.canceled.connect(
		_close_import
	)


	import_dialog.popup_centered(
		Vector2i(
			900,
			600
		)
	)


# =============================================================
# IMPORT FILE
# =============================================================

func _import_file(
	path: String
) -> void:

	if object_manager == null:

		_close_import()

		return


	var ciga_ui := CIGAUI.instance


	# =========================================================
	# LOADING
	# =========================================================

	if ciga_ui != null:

		ciga_ui.set_corner_loading_visible(
			true,
			"IMPORTING OBJECT..."
		)


		var ui_tree := ciga_ui.get_tree()


		if ui_tree != null:

			await ui_tree.process_frame


	# =========================================================
	# AUTO SCALE SETTING
	# =========================================================

	var auto_scale_enabled := true


	if auto_scale_checkbox != null:

		auto_scale_enabled = (
			auto_scale_checkbox.button_pressed
		)


	# =========================================================
	# IMPORT
	# =========================================================

	var imported := (
		object_manager.import_object(
			path,
			auto_scale_enabled
		)
	)


	if imported.is_empty():

		if object_status_label != null:

			object_status_label.text = (
				"STATUS: IMPORT FAILED"
			)


		if ciga_ui != null:

			ciga_ui.set_corner_loading_visible(
				false
			)


		_close_import()

		return


	_close_import()


	var object_id := str(
		imported.get(
			"id",
			""
		)
	)


	var source_path := str(
		imported.get(
			"source_path",
			""
		)
	)


	if (
		object_id.is_empty()
		or
		source_path.is_empty()
	):

		if object_status_label != null:

			object_status_label.text = (
				"STATUS: INVALID IMPORT DATA"
			)


		if ciga_ui != null:

			ciga_ui.set_corner_loading_visible(
				false
			)


		refresh()

		return


	# =========================================================
	# IMPORT CONCLUÍDO
	# =========================================================

	refresh()


	# =========================================================
	# OPTIMIZATION CHECK
	# =========================================================

	if optimize_checkbox == null:

		if object_status_label != null:

			object_status_label.text = (
				"STATUS: OPTIMIZER CHECKBOX ERROR"
			)


		if ciga_ui != null:

			ciga_ui.set_corner_loading_visible(
				false
			)


		return


	# =========================================================
	# OPTIMIZATION ENABLED
	# =========================================================

	if optimize_checkbox.button_pressed:

		if optimizer_controller == null:

			if object_status_label != null:

				object_status_label.text = (
					"STATUS: OPTIMIZER UNAVAILABLE"
				)


			if ciga_ui != null:

				ciga_ui.set_corner_loading_visible(
					false
				)


			return


		if object_status_label != null:

			object_status_label.text = (
				"STATUS: OPTIMIZING..."
			)


		if ciga_ui != null:

			ciga_ui.set_corner_loading_visible(
				true,
				"OPTIMIZING OBJECT..."
			)


		# =====================================================
		# GARANTIR QUALIDADE ACTUAL NO OPTIMIZER
		# =====================================================

		if object_manager.get_optimizer() != null:

			object_manager.get_optimizer().set_quality(
				object_manager.get_optimizer_quality()
			)


		if optimizer_controller.has_method(
			"set_optimizer_quality"
		):

			optimizer_controller.call(
				"set_optimizer_quality",
				object_manager.get_optimizer_quality()
			)


		var started := (
			optimizer_controller.optimize_async(
				source_path,
				object_id
			)
		)


		if started:

			return


		if object_status_label != null:

			object_status_label.text = (
				"STATUS: OPTIMIZATION FAILED TO START"
			)


		if ciga_ui != null:

			ciga_ui.set_corner_loading_visible(
				false
			)


		return


	# =========================================================
	# WITHOUT OPTIMIZATION
	# =========================================================

	if object_status_label != null:

		object_status_label.text = (
			"STATUS: IMPORTED WITHOUT OPTIMIZATION"
		)


	if ciga_ui != null:

		ciga_ui.set_corner_loading_visible(
			false
		)


# =============================================================
# OPTIMIZATION STARTED
# =============================================================

func _on_optimization_started(
	_object_id: String
) -> void:

	if object_status_label != null:

		object_status_label.text = (
			"STATUS: OPTIMIZING..."
		)


	var ciga_ui := CIGAUI.instance


	if ciga_ui != null:

		ciga_ui.set_corner_loading_visible(
			true,
			"OPTIMIZING OBJECT..."
		)


# =============================================================
# OPTIMIZATION FINISHED
# =============================================================

func _on_optimization_finished(
	object_id: String,
	result: Dictionary
) -> void:

	var ciga_ui := CIGAUI.instance


	var success := bool(
		result.get(
			"success",
			false
		)
	)


	if success:

		if object_manager != null:

			var index := (
				object_manager.find_object_index(
					object_id
				)
			)


			if index >= 0:

				var object_data := (
					object_manager.objects[
						index
					]
				)


				object_data["optimized"] = true

				object_data["optimized_path"] = str(
					result.get(
						"path",
						""
					)
				)


				object_data["optimizer_quality"] = (
					int(
						result.get(
							"quality_id",
							object_manager.get_optimizer_quality()
						)
					)
				)


				object_data["optimizer_quality_name"] = (
					str(
						result.get(
							"quality",
							object_manager.get_optimizer_quality_name()
						)
					)
				)


				object_manager.objects[
					index
				] = object_data


				object_manager.save_library()


		if object_status_label != null:

			object_status_label.text = (
				"STATUS: OPTIMIZED CACHE READY"
			)


		refresh()


	else:

		if object_status_label != null:

			object_status_label.text = (
				"STATUS: OPTIMIZATION FAILED"
			)


	if ciga_ui != null:

		ciga_ui.set_corner_loading_visible(
			false
		)


# =============================================================
# CLOSE IMPORT
# =============================================================

func _close_import() -> void:

	if import_dialog != null:

		import_dialog.queue_free()


	import_dialog = null
