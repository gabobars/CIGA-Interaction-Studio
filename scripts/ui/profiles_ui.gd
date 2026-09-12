class_name CIGAProfilesUI
extends RefCounted


# =============================================================
# CIGA PROFILES UI
# Godot 4.7.2
#
# SISTEMA DE CONFIGURAÇÃO ÚNICA
#
# Não existem múltiplos profiles nesta versão.
#
# A página serve para:
#
# - mostrar a configuração actual
# - exportar configuração
# - importar configuração
# - substituir a configuração actual
# - restaurar configuração por defeito
#
#
# IMPORTANTE:
#
# O manager continua a chamar-se CIGAProfiles para manter
# compatibilidade com o restante projecto.
# =============================================================


# =============================================================
# REFERENCES
# =============================================================

var root: PanelContainer

var manager: CIGAProfiles

var theme: CIGATheme


# =============================================================
# CONTROLS
# =============================================================

var status: Label

var configuration_name_label: Label

var export_button: Button

var import_button: Button

var reset_button: Button


# =============================================================
# FILE DIALOGS
# =============================================================

var export_dialog: FileDialog

var import_dialog: FileDialog


# =============================================================
# RESET DIALOG
# =============================================================

var reset_dialog: ConfirmationDialog


# =============================================================
# SETUP
# =============================================================

func setup(
	parent: Control,
	profile_manager: CIGAProfiles,
	ui_theme: CIGATheme
) -> Control:

	manager = profile_manager

	theme = ui_theme


	root = PanelContainer.new()

	root.name = (
		"ProfilesPage"
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


	return root


# =============================================================
# BUILD
# =============================================================

func build() -> void:

	var scroll := ScrollContainer.new()

	scroll.name = (
		"ProfilesScroll"
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
		22
	)


	margin.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	scroll.add_child(
		margin
	)


	var box := VBoxContainer.new()

	box.name = (
		"ProfilesContent"
	)


	box.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	box.size_flags_vertical = (
		Control.SIZE_SHRINK_BEGIN
	)


	box.add_theme_constant_override(
		"separation",
		12
	)


	margin.add_child(
		box
	)


	# =========================================================
	# TITLE
	# =========================================================

	box.add_child(
		theme.create_title(
			"PROFILE"
		)
	)


	var description := theme.create_status_label(
		"CIGA currently uses one persistent configuration. "
		+ "All character, object, interaction, event, output, "
		+ "camera, viewport and settings data are stored here."
	)


	description.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)


	description.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	box.add_child(
		description
	)


	# =========================================================
	# CURRENT CONFIGURATION
	# =========================================================

	box.add_child(
		theme.create_section_label(
			"CURRENT CONFIGURATION"
		)
	)


	var configuration_panel := PanelContainer.new()

	configuration_panel.name = (
		"CurrentConfigurationPanel"
	)


	configuration_panel.custom_minimum_size = Vector2(
		0.0,
		90.0
	)


	theme.style_panel(
		configuration_panel,
		CIGATheme.PANEL_LIGHT,
		CIGATheme.BORDER
	)


	box.add_child(
		configuration_panel
	)


	var configuration_margin := MarginContainer.new()

	theme.set_margins(
		configuration_margin,
		16
	)


	configuration_panel.add_child(
		configuration_margin
	)


	var configuration_box := VBoxContainer.new()

	configuration_box.add_theme_constant_override(
		"separation",
		4
	)


	configuration_margin.add_child(
		configuration_box
	)


	configuration_name_label = Label.new()


	configuration_name_label.name = (
		"ConfigurationName"
	)


	configuration_name_label.text = (
		"CIGA CONFIGURATION"
	)


	configuration_name_label.add_theme_font_size_override(
		"font_size",
		20
	)


	configuration_name_label.add_theme_color_override(
		"font_color",
		CIGATheme.TEXT
	)


	configuration_box.add_child(
		configuration_name_label
	)


	var id_label := Label.new()


	id_label.text = (
		"ID: profile_current"
	)


	id_label.add_theme_font_size_override(
		"font_size",
		11
	)


	id_label.add_theme_color_override(
		"font_color",
		CIGATheme.TEXT_DIM
	)


	configuration_box.add_child(
		id_label
	)


	# =========================================================
	# EXPORT
	# =========================================================

	export_button = theme.create_button(
		"EXPORT CONFIGURATION"
	)


	export_button.custom_minimum_size = Vector2(
		0.0,
		44.0
	)


	export_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	box.add_child(
		export_button
	)


	export_button.pressed.connect(
		_open_export_dialog
	)


	# =========================================================
	# IMPORT
	# =========================================================

	import_button = theme.create_button(
		"IMPORT CONFIGURATION"
	)


	import_button.custom_minimum_size = Vector2(
		0.0,
		44.0
	)


	import_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	box.add_child(
		import_button
	)


	import_button.pressed.connect(
		_open_import_dialog
	)


	# =========================================================
	# RESET
	# =========================================================

	reset_button = theme.create_button(
		"RESET CONFIGURATION"
	)


	reset_button.custom_minimum_size = Vector2(
		0.0,
		44.0
	)


	reset_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	box.add_child(
		reset_button
	)


	reset_button.pressed.connect(
		_open_reset_dialog
	)


	# =========================================================
	# STATUS
	# =========================================================

	status = theme.create_status_label(
		"CIGA CONFIGURATION READY"
	)


	status.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)


	status.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	box.add_child(
		status
	)


	# =========================================================
	# INFORMATION
	# =========================================================

	var info := theme.create_status_label(
		"This configuration is persistent and is automatically "
		+ "saved when settings are changed. Importing a "
		+ "configuration replaces the current configuration."
	)


	info.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)


	info.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	box.add_child(
		info
	)


	refresh()


# =============================================================
# REFRESH
# =============================================================

func refresh() -> void:

	if manager == null:

		return


	var configuration := (
		manager.get_active_profile()
	)


	if configuration.is_empty():

		if configuration_name_label != null:

			configuration_name_label.text = (
				"CIGA CONFIGURATION"
			)


		if status != null:

			status.text = (
				"CIGA CONFIGURATION UNAVAILABLE"
			)


		return


	var configuration_name := str(
		configuration.get(
			"name",
			"CIGA Configuration"
		)
	)


	if configuration_name.strip_edges().is_empty():

		configuration_name = (
			"CIGA Configuration"
		)


	if configuration_name_label != null:

		configuration_name_label.text = (
			configuration_name
		)


	if status != null:

		status.text = (
			"CURRENT CONFIGURATION ACTIVE"
		)


# =============================================================
# RESET DIALOG
# =============================================================

func _open_reset_dialog() -> void:

	if manager == null:

		return


	if reset_dialog != null:

		if is_instance_valid(
			reset_dialog
		):

			return


	reset_dialog = ConfirmationDialog.new()


	reset_dialog.name = (
		"ResetConfigurationDialog"
	)


	reset_dialog.title = (
		"RESET CIGA CONFIGURATION"
	)


	reset_dialog.dialog_text = (
		"Reset the current CIGA configuration?\n"
		+ "All saved configuration values will be replaced "
		+ "with the default configuration."
	)


	reset_dialog.ok_button_text = (
		"RESET"
	)


	reset_dialog.cancel_button_text = (
		"CANCEL"
	)


	root.add_child(
		reset_dialog
	)


	reset_dialog.confirmed.connect(
		_reset_configuration
	)


	reset_dialog.close_requested.connect(
		_close_reset_dialog
	)


	reset_dialog.canceled.connect(
		_close_reset_dialog
	)


	reset_dialog.popup_centered(
		Vector2i(
			480,
			220
		)
	)


# =============================================================
# RESET
# =============================================================

func _reset_configuration() -> void:

	if manager == null:

		_close_reset_dialog()

		return


	var result = (
		manager.reset_current_profile()
	)


	if result.is_empty():

		status.text = (
			"CONFIGURATION RESET FAILED"
		)


	else:

		status.text = (
			"CONFIGURATION RESET TO DEFAULTS"
		)


	refresh()


	_close_reset_dialog()


# =============================================================
# CLOSE RESET
# =============================================================

func _close_reset_dialog() -> void:

	if reset_dialog != null:

		if is_instance_valid(
			reset_dialog
		):

			reset_dialog.queue_free()


	reset_dialog = null


# =============================================================
# EXPORT DIALOG
# =============================================================

func _open_export_dialog() -> void:

	if manager == null:

		return


	if export_dialog != null:

		if is_instance_valid(
			export_dialog
		):

			return


	export_dialog = FileDialog.new()


	export_dialog.name = (
		"ExportConfigurationDialog"
	)


	export_dialog.title = (
		"EXPORT CIGA CONFIGURATION"
	)


	export_dialog.file_mode = (
		FileDialog.FILE_MODE_SAVE_FILE
	)


	export_dialog.access = (
		FileDialog.ACCESS_FILESYSTEM
	)


	export_dialog.add_filter(
		"*.cigaprofile",
		"CIGA Profile"
	)


	var configuration := (
		manager.get_active_profile()
	)


	var configuration_name := str(
		configuration.get(
			"name",
			"CIGA_Configuration"
		)
	)


	if configuration_name.strip_edges().is_empty():

		configuration_name = (
			"CIGA_Configuration"
		)


	export_dialog.current_file = (
		configuration_name
		+
		".cigaprofile"
	)


	root.add_child(
		export_dialog
	)


	export_dialog.file_selected.connect(
		_export_configuration
	)


	export_dialog.canceled.connect(
		_close_export_dialog
	)


	export_dialog.popup_centered_ratio(
		0.7
	)


# =============================================================
# EXPORT
# =============================================================

func _export_configuration(
	file_path: String
) -> void:

	if manager == null:

		_close_export_dialog()

		return


	var final_path := (
		file_path
	)


	if not final_path.to_lower().ends_with(
		".cigaprofile"
	):

		final_path += (
			".cigaprofile"
		)


	if manager.export_active_profile(
		final_path
	):

		status.text = (
			"CONFIGURATION EXPORTED"
		)

	else:

		status.text = (
			"CONFIGURATION EXPORT FAILED"
		)


	_close_export_dialog()


# =============================================================
# CLOSE EXPORT
# =============================================================

func _close_export_dialog() -> void:

	if export_dialog != null:

		if is_instance_valid(
			export_dialog
		):

			export_dialog.queue_free()


	export_dialog = null


# =============================================================
# IMPORT DIALOG
# =============================================================

func _open_import_dialog() -> void:

	if manager == null:

		return


	if import_dialog != null:

		if is_instance_valid(
			import_dialog
		):

			return


	import_dialog = FileDialog.new()


	import_dialog.name = (
		"ImportConfigurationDialog"
	)


	import_dialog.title = (
		"IMPORT CIGA CONFIGURATION"
	)


	import_dialog.file_mode = (
		FileDialog.FILE_MODE_OPEN_FILE
	)


	import_dialog.access = (
		FileDialog.ACCESS_FILESYSTEM
	)


	import_dialog.add_filter(
		"*.cigaprofile",
		"CIGA Profile"
	)


	root.add_child(
		import_dialog
	)


	import_dialog.file_selected.connect(
		_import_configuration
	)


	import_dialog.canceled.connect(
		_close_import_dialog
	)


	import_dialog.popup_centered_ratio(
		0.7
	)


# =============================================================
# IMPORT
# =============================================================

func _import_configuration(
	file_path: String
) -> void:

	if manager == null:

		_close_import_dialog()

		return


	var imported := (
		manager.import_profile(
			file_path
		)
	)


	if imported.is_empty():

		status.text = (
			"CONFIGURATION IMPORT FAILED"
		)


	else:

		status.text = (
			"CONFIGURATION IMPORTED AND APPLIED"
		)


	refresh()


	_close_import_dialog()


# =============================================================
# CLOSE IMPORT
# =============================================================

func _close_import_dialog() -> void:

	if import_dialog != null:

		if is_instance_valid(
			import_dialog
		):

			import_dialog.queue_free()


	import_dialog = null


# =============================================================
# CLEANUP
# =============================================================

func close() -> void:

	if export_dialog != null:

		if is_instance_valid(
			export_dialog
		):

			export_dialog.queue_free()


	if import_dialog != null:

		if is_instance_valid(
			import_dialog
		):

			import_dialog.queue_free()


	if reset_dialog != null:

		if is_instance_valid(
			reset_dialog
		):

			reset_dialog.queue_free()


	export_dialog = null

	import_dialog = null

	reset_dialog = null
