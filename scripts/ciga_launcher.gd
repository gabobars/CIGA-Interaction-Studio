class_name CIGALauncher
extends RefCounted


signal profile_opened


# =============================================================
# SUPPORT
# =============================================================

const SUPPORT_URL: String = (
	"https://ciga-website.ciga-hq.workers.dev/cigastudio"
)


# =============================================================
# REFERENCES
# =============================================================

var root: Control

var profile_manager: CIGAProfiles
var theme: CIGATheme


var profile_selector: OptionButton

var status_label: Label


# =============================================================
# HELP
# =============================================================

var help_button: Button

var help_container: VBoxContainer

var help_text: Label

var support_button: Button


# =============================================================
# SCROLL
# =============================================================

var launcher_scroll: ScrollContainer

var launcher_center: CenterContainer


# =============================================================
# STATE
# =============================================================

var help_expanded: bool = false


# =============================================================
# SETUP
# =============================================================

func setup(
	parent: Control,
	manager: CIGAProfiles,
	ui_theme: CIGATheme
) -> Control:

	profile_manager = manager

	theme = ui_theme


	root = Control.new()

	root.name = (
		"Launcher"
	)

	root.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
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

	# =========================================================
	# BACKGROUND
	# =========================================================

	var background := ColorRect.new()

	background.color = (
		theme.BACKGROUND
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


	# =========================================================
	# SCROLL CONTAINER
	# =========================================================

	launcher_scroll = ScrollContainer.new()

	launcher_scroll.name = (
		"LauncherScroll"
	)

	launcher_scroll.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	launcher_scroll.horizontal_scroll_mode = (
		ScrollContainer.SCROLL_MODE_DISABLED
	)

	launcher_scroll.vertical_scroll_mode = (
		ScrollContainer.SCROLL_MODE_DISABLED
	)

	launcher_scroll.mouse_filter = (
		Control.MOUSE_FILTER_PASS
	)

	root.add_child(
		launcher_scroll
	)


	# =========================================================
	# CENTER CONTAINER
	#
	# IMPORTANT:
	#
	# O CenterContainer recebe sempre pelo menos o tamanho
	# do root.
	#
	# Desta forma:
	#
	# painel pequeno -> centro do ecrã
	# painel grande  -> conteúdo passa a poder fazer scroll
	#
	# =========================================================

	launcher_center = CenterContainer.new()

	launcher_center.name = (
		"LauncherCenter"
	)

	launcher_center.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	launcher_center.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)

	launcher_center.custom_minimum_size = (
		root.size
	)

	launcher_scroll.add_child(
		launcher_center
	)


	# =========================================================
	# LAUNCHER PANEL
	# =========================================================

	var panel := PanelContainer.new()

	panel.name = (
		"LauncherPanel"
	)

	panel.custom_minimum_size = Vector2(
		560.0,
		0.0
	)

	panel.size_flags_horizontal = (
		Control.SIZE_SHRINK_CENTER
	)

	panel.size_flags_vertical = (
		Control.SIZE_SHRINK_CENTER
	)

	theme.style_panel(
		panel
	)

	launcher_center.add_child(
		panel
	)


	# =========================================================
	# MARGIN
	# =========================================================

	var margin := MarginContainer.new()

	theme.set_margins(
		margin,
		32
	)

	panel.add_child(
		margin
	)


	# =========================================================
	# CONTENT
	# =========================================================

	var box := VBoxContainer.new()

	box.name = (
		"LauncherContent"
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

	var logo := Label.new()

	logo.text = (
		"CIGA SYSTEMS"
	)

	logo.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	logo.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	logo.add_theme_font_size_override(
		"font_size",
		34
	)

	box.add_child(
		logo
	)


	# =========================================================
	# SUBTITLE
	# =========================================================

	var subtitle := Label.new()

	subtitle.text = (
		"INTERACTION CONTROL ENVIRONMENT"
	)

	subtitle.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	subtitle.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	subtitle.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	subtitle.add_theme_color_override(
		"font_color",
		theme.TEXT_DIM
	)

	box.add_child(
		subtitle
	)


	box.add_child(
		HSeparator.new()
	)


	# =========================================================
	# ACTIVE CONFIGURATION
	# =========================================================

	box.add_child(
		theme.create_section_label(
			"ACTIVE CONFIGURATION"
		)
	)


	profile_selector = OptionButton.new()

	profile_selector.name = (
		"ProfileSelector"
	)

	profile_selector.custom_minimum_size = Vector2(
		0.0,
		44.0
	)

	profile_selector.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	profile_selector.focus_mode = (
		Control.FOCUS_NONE
	)

	box.add_child(
		profile_selector
	)


	# =========================================================
	# OPEN
	# =========================================================

	var open_button := theme.create_button(
		"OPEN CONFIGURATION"
	)

	open_button.custom_minimum_size = Vector2(
		0.0,
		44.0
	)

	open_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	open_button.focus_mode = (
		Control.FOCUS_NONE
	)

	box.add_child(
		open_button
	)

	open_button.pressed.connect(
		_open_profile
	)


	# =========================================================
	# STATUS
	# =========================================================

	status_label = theme.create_status_label(
		"SYSTEM READY"
	)

	status_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	status_label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	status_label.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	status_label.custom_minimum_size = Vector2(
		0.0,
		32.0
	)

	box.add_child(
		status_label
	)


	# =========================================================
	# SUPPORT
	# =========================================================

	box.add_child(
		theme.create_section_label(
			"SUPPORT"
		)
	)


	help_button = theme.create_button(
		"NEED HELP"
	)

	help_button.custom_minimum_size = Vector2(
		0.0,
		40.0
	)

	help_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	help_button.focus_mode = (
		Control.FOCUS_NONE
	)

	box.add_child(
		help_button
	)

	help_button.pressed.connect(
		_toggle_help
	)


	# =========================================================
	# HELP CONTENT
	# =========================================================

	help_container = VBoxContainer.new()

	help_container.name = (
		"HelpContainer"
	)

	help_container.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	help_container.size_flags_vertical = (
		Control.SIZE_SHRINK_BEGIN
	)

	help_container.add_theme_constant_override(
		"separation",
		8
	)

	help_container.visible = false

	box.add_child(
		help_container
	)


	# =========================================================
	# HELP TEXT
	# =========================================================

	help_text = theme.create_status_label(
		"Need help with CIGA Interaction Studio?\n\n"
		+
		"Open the CIGA documentation for setup instructions, "
		+
		"troubleshooting information and common problems.\n\n"
		+
		"The documentation also includes information about "
		+
		"object loading, avatar mapping, VMC, events and "
		+
		"performance."
	)

	help_text.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	help_text.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	help_text.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	help_text.custom_minimum_size = Vector2(
		0.0,
		90.0
	)

	help_container.add_child(
		help_text
	)


	# =========================================================
	# SUPPORT BUTTON
	# =========================================================

	support_button = theme.create_button(
		"OPEN CIGA SUPPORT"
	)

	support_button.custom_minimum_size = Vector2(
		0.0,
		40.0
	)

	support_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	support_button.focus_mode = (
		Control.FOCUS_NONE
	)

	help_container.add_child(
		support_button
	)


	support_button.pressed.connect(
		_open_support
	)


	_update_support_button()


	refresh_profiles()


	# =========================================================
	# INITIAL LAYOUT
	# =========================================================

	_update_launcher_layout()


# =============================================================
# LAYOUT UPDATE
# =============================================================

func _update_launcher_layout() -> void:

	if root == null:

		return


	if launcher_center == null:

		return


	launcher_center.custom_minimum_size = (
		root.size
	)


	if launcher_scroll == null:

		return


	# =========================================================
	# SCROLL ONLY WHEN HELP IS OPEN
	# =========================================================

	if help_expanded:

		launcher_scroll.vertical_scroll_mode = (
			ScrollContainer.SCROLL_MODE_AUTO
		)

	else:

		launcher_scroll.vertical_scroll_mode = (
			ScrollContainer.SCROLL_MODE_DISABLED
		)

		launcher_scroll.set_v_scroll(
			0
		)


# =============================================================
# PROCESS
#
# Mantém o CenterContainer sincronizado com o tamanho real
# do launcher, incluindo resize da janela.
# =============================================================

func _process(
	_delta: float
) -> void:

	if root == null:

		return


	if launcher_center == null:

		return


	if launcher_center.custom_minimum_size != root.size:

		_update_launcher_layout()


# =============================================================
# HELP TOGGLE
# =============================================================

func _toggle_help() -> void:

	help_expanded = not help_expanded


	if help_container != null:

		help_container.visible = (
			help_expanded
		)


	if help_expanded:

		help_button.text = (
			"HIDE HELP"
		)

	else:

		help_button.text = (
			"NEED HELP"
		)


	# =========================================================
	# UPDATE LAYOUT
	# =========================================================

	_update_launcher_layout()


	# =========================================================
	# LET GODOT RECALCULATE THE CONTROL TREE
	# =========================================================

	if launcher_scroll != null:

		launcher_scroll.queue_sort()


	# =========================================================
	# RESET SCROLL WHEN OPENING
	# =========================================================

	if (
		help_expanded
		and
		launcher_scroll != null
	):

		call_deferred(
			"_reset_launcher_scroll"
		)


# =============================================================
# RESET SCROLL
# =============================================================

func _reset_launcher_scroll() -> void:

	if launcher_scroll == null:

		return


	launcher_scroll.set_v_scroll(
		0
	)


# =============================================================
# SUPPORT BUTTON STATE
# =============================================================

func _update_support_button() -> void:

	if support_button == null:

		return


	var valid_url := (
		not SUPPORT_URL.is_empty()
		and
		not SUPPORT_URL.begins_with(
			"https://YOUR-LINK"
		)
	)


	support_button.disabled = (
		not valid_url
	)


# =============================================================
# OPEN SUPPORT
# =============================================================

func _open_support() -> void:

	var valid_url := (
		not SUPPORT_URL.is_empty()
		and
		not SUPPORT_URL.begins_with(
			"https://YOUR-LINK"
		)
	)


	if not valid_url:

		if status_label != null:

			status_label.text = (
				"SUPPORT LINK NOT CONFIGURED"
			)

		return


	var result := OS.shell_open(
		SUPPORT_URL
	)


	if result != OK:

		if status_label != null:

			status_label.text = (
				"COULD NOT OPEN SUPPORT LINK"
			)

		return


	if status_label != null:

		status_label.text = (
			"OPENING SUPPORT..."
		)


# =============================================================
# REFRESH CONFIGURATION
# =============================================================

func refresh_profiles() -> void:

	if profile_selector == null:

		return


	profile_selector.clear()


	if profile_manager == null:

		return


	for profile: Dictionary in profile_manager.profiles:

		profile_selector.add_item(
			str(
				profile.get(
					"name",
					"CIGA Configuration"
				)
			)
		)


	var active_id := (
		profile_manager.active_profile_id
	)


	for index in range(
		profile_manager.profiles.size()
	):

		var profile: Dictionary = (
			profile_manager.profiles[index]
		)


		if str(
			profile.get(
				"id",
				""
			)
		) == active_id:

			profile_selector.select(
				index
			)

			return


	if profile_selector.item_count > 0:

		profile_selector.select(
			0
		)


# =============================================================
# OPEN CONFIGURATION
# =============================================================

func _open_profile() -> void:

	if profile_manager == null:

		return


	if profile_selector == null:

		return


	var index := (
		profile_selector.selected
	)


	if index < 0:

		return


	if index >= profile_manager.profiles.size():

		return


	var profile: Dictionary = (
		profile_manager.profiles[index]
	)


	var id := str(
		profile.get(
			"id",
			""
		)
	)


	if id.is_empty():

		return


	if not profile_manager.set_active_profile(
		id
	):

		if status_label != null:

			status_label.text = (
				"CONFIGURATION COULD NOT BE OPENED"
			)

		return


	if status_label != null:

		status_label.text = (
			"CONFIGURATION OPENED: "
			+
			str(
				profile.get(
					"name",
					"CIGA Configuration"
				)
			)
		)


	profile_opened.emit()
