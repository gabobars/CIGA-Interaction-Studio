class_name CIGACharacterUI
extends RefCounted


# =============================================================
# SIGNALS
# =============================================================

signal character_loaded(
	character_data: Dictionary
)

signal mapping_changed(
	mapping: Dictionary
)


# =============================================================
# REFERENCES
# =============================================================

var root: PanelContainer

var manager: CIGACharacters

# Alias público.
#
# O CIGAViewportRuntime procura esta propriedade através de:
#
#     ui.get("character_manager")
#
var character_manager: CIGACharacters

var profile_manager: CIGAProfiles

var theme: CIGATheme

var character_runtime: CIGACharacterRuntime


# =============================================================
# CONTROLS
# =============================================================

var selector: OptionButton

var status: Label

var info: Label

var load_button: Button

var create_native_button: Button

var native_name_input: LineEdit

var tail_checkbox: CheckBox

var map_button: Button

var launch_toggle: CheckBox

var mapping_profile_selector: OptionButton

var mapping_status: Label

var mapping_container: VBoxContainer

var runtime_log: RichTextLabel


# =============================================================
# MAPPING CHECKS
# =============================================================

var mapping_checks: Dictionary = {}


# =============================================================
# IMPORT
# =============================================================

var file_dialog: FileDialog


# =============================================================
# STATE
# =============================================================

var syncing_profile_selection: bool = false

var active_character_data: Dictionary = {}

var avatar_loaded: bool = false

var current_bone_map: Dictionary = {}

var saved_bone_map: Dictionary = {}


# =============================================================
# HITPOINTS
# =============================================================

const HIT_POINT_NAMES: Array[String] = [

	"HeadHitPoint",

	"ChestHitPoint",

	"LeftShoulderHitPoint",

	"RightShoulderHitPoint",

	"LeftArmHitPoint",

	"RightArmHitPoint",

	"LeftLegHitPoint",

	"RightLegHitPoint"
]


# =============================================================
# MAPPING PROFILES
# =============================================================

const MAPPING_PROFILES: Array[String] = [

	"DEFAULT",

	"BUST UP",

	"FULL"
]


const MAPPING_DEFAULT: Array[String] = [

	"HeadHitPoint",

	"ChestHitPoint",

	"LeftShoulderHitPoint",

	"RightShoulderHitPoint",

	"LeftArmHitPoint",

	"RightArmHitPoint"
]


const MAPPING_BUST_UP: Array[String] = [

	"HeadHitPoint",

	"ChestHitPoint",

	"LeftShoulderHitPoint",

	"RightShoulderHitPoint"
]


const MAPPING_FULL: Array[String] = [

	"HeadHitPoint",

	"ChestHitPoint",

	"LeftShoulderHitPoint",

	"RightShoulderHitPoint",

	"LeftArmHitPoint",

	"RightArmHitPoint",

	"LeftLegHitPoint",

	"RightLegHitPoint"
]


# =============================================================
# SETUP
# =============================================================

func setup(
	parent: Control,
	character_manager_input: CIGACharacters,
	profiles: CIGAProfiles,
	ui_theme: CIGATheme,
	char_runtime: CIGACharacterRuntime = null
) -> Control:

	manager = character_manager_input

	character_manager = character_manager_input

	profile_manager = profiles

	theme = ui_theme

	character_runtime = char_runtime


	root = PanelContainer.new()

	root.name = (
		"CharacterPage"
	)

	root.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	root.visible = false


	if theme != null:

		theme.style_panel(
			root
		)


	parent.add_child(
		root
	)


	build()


	call_deferred(
		"refresh"
	)


	return root


# =============================================================
# BUILD
# =============================================================

func build() -> void:

	if root == null:

		return


	if theme == null:

		return


	var scroll := ScrollContainer.new()

	scroll.name = (
		"CharacterScroll"
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


	var content := VBoxContainer.new()

	content.name = (
		"CharacterContent"
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
			"CHARACTER"
		)
	)


	content.add_child(
		theme.create_status_label(
			"Manage the character assigned to the active CIGA profile."
		)
	)


	# =========================================================
	# ACTIVE CHARACTER
	# =========================================================

	content.add_child(
		theme.create_section_label(
			"ACTIVE CHARACTER"
		)
	)


	selector = OptionButton.new()

	selector.name = (
		"CharacterSelector"
	)

	selector.custom_minimum_size = Vector2(
		0.0,
		44.0
	)

	selector.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	content.add_child(
		selector
	)


	selector.item_selected.connect(
		_on_character_selected
	)


	# =========================================================
	# STATUS
	# =========================================================

	content.add_child(
		theme.create_section_label(
			"STATUS"
		)
	)


	status = theme.create_status_label(
		"NO CHARACTER SELECTED"
	)

	status.custom_minimum_size = Vector2(
		0.0,
		34.0
	)

	status.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	content.add_child(
		status
	)


	# =========================================================
	# INFORMATION
	# =========================================================

	content.add_child(
		theme.create_section_label(
			"CHARACTER INFORMATION"
		)
	)


	info = theme.create_status_label(
		"NO CHARACTER LOADED."
	)

	info.custom_minimum_size = Vector2(
		0.0,
		110.0
	)

	info.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	info.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	content.add_child(
		info
	)


	# =========================================================
	# CHARACTER ACTIONS
	# =========================================================

	content.add_child(
		theme.create_section_label(
			"CHARACTER ACTIONS"
		)
	)


	var actions := HBoxContainer.new()

	actions.name = (
		"CharacterActions"
	)

	actions.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	actions.add_theme_constant_override(
		"separation",
		8
	)

	content.add_child(
		actions
	)


	# =========================================================
	# LOAD AVATAR
	# =========================================================

	load_button = theme.create_button(
		"LOAD AVATAR"
	)

	load_button.custom_minimum_size = Vector2(
		0.0,
		46.0
	)

	load_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	actions.add_child(
		load_button
	)


	load_button.pressed.connect(
		_load_avatar
	)


	# =========================================================
	# CREATE NATIVE AVATAR
	# =========================================================

	content.add_child(
		theme.create_section_label(
			"CIGA NATIVE AVATAR"
		)
	)


	var native_name_row := HBoxContainer.new()

	native_name_row.name = (
		"NativeAvatarNameRow"
	)

	native_name_row.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	native_name_row.add_theme_constant_override(
		"separation",
		8
	)

	content.add_child(
		native_name_row
	)


	native_name_input = LineEdit.new()

	native_name_input.name = (
		"NativeAvatarNameInput"
	)

	native_name_input.placeholder_text = (
		"Avatar name..."
	)

	native_name_input.text = (
		"CIGA Avatar"
	)

	native_name_input.custom_minimum_size = Vector2(
		0.0,
		42.0
	)

	native_name_input.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	native_name_row.add_child(
		native_name_input
	)


	create_native_button = theme.create_button(
		"CREATE CIGA AVATAR"
	)

	create_native_button.custom_minimum_size = Vector2(
		0.0,
		42.0
	)

	create_native_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	native_name_row.add_child(
		create_native_button
	)


	create_native_button.pressed.connect(
		_create_native_avatar
	)


	# =========================================================
	# NATIVE AVATAR OPTIONS
	# =========================================================

	tail_checkbox = CheckBox.new()

	tail_checkbox.name = (
		"TailCheckbox"
	)

	tail_checkbox.text = (
		"TAIL"
	)

	tail_checkbox.custom_minimum_size = Vector2(
		0.0,
		38.0
	)

	tail_checkbox.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	tail_checkbox.disabled = true

	content.add_child(
		tail_checkbox
	)


	tail_checkbox.toggled.connect(
		_on_tail_toggled
	)


	# =========================================================
	# LIVE RUNTIME LOG
	# =========================================================

	content.add_child(
		theme.create_section_label(
			"LIVE RUNTIME LOG"
		)
	)


	runtime_log = RichTextLabel.new()

	runtime_log.name = (
		"CharacterRuntimeLog"
	)

	runtime_log.custom_minimum_size = Vector2(
		0.0,
		220.0
	)

	runtime_log.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	runtime_log.bbcode_enabled = false

	runtime_log.fit_content = false

	runtime_log.scroll_active = true

	runtime_log.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	content.add_child(
		runtime_log
	)


	# =========================================================
	# MAP
	# =========================================================

	map_button = theme.create_button(
		"MAP AVATAR"
	)

	map_button.custom_minimum_size = Vector2(
		0.0,
		46.0
	)

	map_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	map_button.disabled = true

	content.add_child(
		map_button
	)


	map_button.pressed.connect(
		_map_avatar
	)


	# =========================================================
	# STARTUP
	# =========================================================

	content.add_child(
		theme.create_section_label(
			"STARTUP"
		)
	)


	launch_toggle = CheckBox.new()

	launch_toggle.text = (
		"LOAD CHARACTER ON LAUNCH"
	)

	launch_toggle.custom_minimum_size = Vector2(
		0.0,
		40.0
	)

	launch_toggle.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	content.add_child(
		launch_toggle
	)


	launch_toggle.toggled.connect(
		_on_load_on_launch_changed
	)


	# =========================================================
	# MAPPING PROFILE
	# =========================================================

	content.add_child(
		theme.create_section_label(
			"MAPPING PROFILE"
		)
	)


	mapping_profile_selector = OptionButton.new()

	mapping_profile_selector.custom_minimum_size = Vector2(
		0.0,
		40.0
	)

	mapping_profile_selector.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)


	for profile_name: String in MAPPING_PROFILES:

		mapping_profile_selector.add_item(
			profile_name
		)


	content.add_child(
		mapping_profile_selector
	)


	mapping_profile_selector.item_selected.connect(
		_on_mapping_profile_selected
	)


	# =========================================================
	# MAPPING STATUS
	# =========================================================

	content.add_child(
		theme.create_section_label(
			"AVATAR MAPPING"
		)
	)


	mapping_status = theme.create_status_label(
		"AVATAR NOT LOADED"
	)

	mapping_status.custom_minimum_size = Vector2(
		0.0,
		42.0
	)

	mapping_status.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	content.add_child(
		mapping_status
	)


	# =========================================================
	# MAPPING CHECKS
	# =========================================================

	mapping_container = VBoxContainer.new()

	mapping_container.name = (
		"MappingContainer"
	)

	mapping_container.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	mapping_container.add_theme_constant_override(
		"separation",
		5
	)

	content.add_child(
		mapping_container
	)


	build_mapping_controls()


	# =========================================================
	# IMPORT
	# =========================================================

	content.add_child(
		theme.create_section_label(
			"IMPORT"
		)
	)


	var import_button := theme.create_button(
		"IMPORT CHARACTER"
	)

	import_button.custom_minimum_size = Vector2(
		0.0,
		46.0
	)

	import_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	content.add_child(
		import_button
	)


	import_button.pressed.connect(
		_open_import
	)


	# =========================================================
	# REMOVE
	# =========================================================

	var remove_button := theme.create_button(
		"REMOVE CHARACTER"
	)

	remove_button.custom_minimum_size = Vector2(
		0.0,
		46.0
	)

	remove_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	content.add_child(
		remove_button
	)


	remove_button.pressed.connect(
		_remove_character
	)


	# =========================================================
	# INITIAL STATE
	# =========================================================

	_update_native_controls()


	_append_runtime_log(
		"Character UI initialized."
	)


# =============================================================
# RUNTIME LOG
# =============================================================

func _append_runtime_log(
	message: String
) -> void:

	if runtime_log == null:

		return


	var timestamp := (
		Time
		.get_time_string_from_system()
	)


	var line := (
		"["
		+
		timestamp
		+
		"] "
		+
		message
	)


	var lines: Array[String] = []


	for existing_line in runtime_log.text.split(
		"\n"
	):

		if not str(existing_line).is_empty():

			lines.append(
				str(existing_line)
			)


	lines.append(
		line
	)


	const MAX_LOG_LINES: int = 40


	while lines.size() > MAX_LOG_LINES:

		lines.remove_at(
			0
		)


	runtime_log.text = (
		"\n".join(
			lines
		)
	)


# =============================================================
# BUILD MAPPING CONTROLS
# =============================================================

func build_mapping_controls() -> void:

	mapping_checks.clear()


	if mapping_container == null:

		return


	for child: Node in mapping_container.get_children():

		child.queue_free()


	for hitpoint: String in HIT_POINT_NAMES:

		var check := CheckBox.new()

		check.text = hitpoint

		check.custom_minimum_size = Vector2(
			0.0,
			34.0
		)

		check.size_flags_horizontal = (
			Control.SIZE_EXPAND_FILL
		)

		mapping_container.add_child(
			check
		)


		mapping_checks[
			hitpoint
		] = check


		check.toggled.connect(
			_on_mapping_check_changed
		)


	refresh_mapping_controls()


# =============================================================
# MAPPING
# =============================================================

func _on_mapping_check_changed(
	_pressed: bool
) -> void:

	_save_enabled_mapping()


func refresh_mapping_controls() -> void:

	if mapping_checks.is_empty():

		return


	var enabled: Array[String] = []


	if profile_manager != null:

		enabled = (
			profile_manager
			.get_active_enabled_hitpoints()
		)


	for hitpoint: String in HIT_POINT_NAMES:

		var check: CheckBox = (
			mapping_checks.get(
				hitpoint
			)
		)


		if check == null:

			continue


		check.set_pressed_no_signal(
			enabled.has(
				hitpoint
			)
		)


	update_mapping_profile_selector(
		enabled
	)

	update_mapping_status()


func _save_enabled_mapping() -> void:

	if profile_manager == null:

		return


	var enabled: Array[String] = []


	for hitpoint: String in HIT_POINT_NAMES:

		var check: CheckBox = (
			mapping_checks.get(
				hitpoint
			)
		)


		if check != null:

			if check.button_pressed:

				enabled.append(
					hitpoint
				)


	if active_character_data.is_empty():

		update_mapping_status()

		return


	var character_id := str(
		active_character_data.get(
			"id",
			""
		)
	)


	if character_id.is_empty():

		update_mapping_status()

		return


	var mapping := (
		profile_manager.get_active_avatar_mapping(
			character_id
		)
	)


	if mapping.is_empty():

		mapping = {

			"bone_map":
				current_bone_map.duplicate(
					true
				),

			"enabled_hitpoints":
				enabled.duplicate(),

			"mapped":
				not current_bone_map.is_empty()
		}

	else:

		mapping[
			"enabled_hitpoints"
		] = (
			enabled.duplicate()
		)


	var mappings := (
		profile_manager.get_active_avatar_mappings()
	)


	mappings[
		character_id
	] = mapping


	profile_manager.set_active_value(
		"character",
		"avatar_mappings",
		mappings
	)


	update_mapping_profile_selector(
		enabled
	)

	update_mapping_status()


# =============================================================
# MAPPING PROFILE SELECTED
# =============================================================

func _on_mapping_profile_selected(
	index: int
) -> void:

	if index < 0:

		return


	if index >= MAPPING_PROFILES.size():

		return


	var hitpoints := (
		get_preset_hitpoints(
			MAPPING_PROFILES[index]
		)
	)


	for hitpoint: String in HIT_POINT_NAMES:

		var check: CheckBox = (
			mapping_checks.get(
				hitpoint
			)
		)


		if check == null:

			continue


		check.set_pressed_no_signal(
			hitpoints.has(
				hitpoint
			)
		)


	_save_enabled_mapping()


func get_preset_hitpoints(
	profile_name: String
) -> Array[String]:

	match profile_name:

		"DEFAULT":

			return MAPPING_DEFAULT.duplicate()

		"BUST UP":

			return MAPPING_BUST_UP.duplicate()

		"FULL":

			return MAPPING_FULL.duplicate()


	return []


func update_mapping_profile_selector(
	enabled: Array[String]
) -> void:

	if mapping_profile_selector == null:

		return


	var selected_index := 0


	for index in range(
		MAPPING_PROFILES.size()
	):

		var preset := (
			get_preset_hitpoints(
				MAPPING_PROFILES[index]
			)
		)


		if arrays_match(
			preset,
			enabled
		):

			selected_index = index

			break


	mapping_profile_selector.select(
		selected_index
	)


func arrays_match(
	a: Array[String],
	b: Array[String]
) -> bool:

	if a.size() != b.size():

		return false


	for value: String in a:

		if not b.has(
			value
		):

			return false


	return true


# =============================================================
# MAPPING STATUS
# =============================================================

func update_mapping_status() -> void:

	if mapping_status == null:

		return


	if not avatar_loaded:

		if not saved_bone_map.is_empty():

			mapping_status.text = (
				"MAPPING SAVED | AVATAR NOT LOADED"
			)

		else:

			mapping_status.text = (
				"AVATAR NOT LOADED"
			)

		return


	# ---------------------------------------------------------
	# Native avatar
	# ---------------------------------------------------------

	if _is_active_native_character():

		var enabled_count := 0


		for hitpoint: String in HIT_POINT_NAMES:

			var check: CheckBox = (
				mapping_checks.get(
					hitpoint
				)
			)


			if check != null:

				if check.button_pressed:

					enabled_count += 1


		mapping_status.text = (
			"NATIVE 3D | HITPOINTS READY | ENABLED "
			+
			str(
				enabled_count
			)
			+
			"/"
			+
			str(
				HIT_POINT_NAMES.size()
			)
		)

		return


	# ---------------------------------------------------------
	# Imported avatar
	# ---------------------------------------------------------

	if current_bone_map.is_empty():

		if saved_bone_map.is_empty():

			mapping_status.text = (
				"AVATAR LOADED | NO SAVED MAPPING"
			)

		else:

			mapping_status.text = (
				"MAPPING SAVED | LOAD APPLY FAILED"
			)

		return


	var enabled_count := 0


	for hitpoint: String in HIT_POINT_NAMES:

		var check: CheckBox = (
			mapping_checks.get(
				hitpoint
			)
		)


		if check != null:

			if check.button_pressed:

				enabled_count += 1


	mapping_status.text = (
		"MAPPED | FOUND "
		+
		str(
			current_bone_map.size()
		)
		+
		"/"
		+
		str(
			HIT_POINT_NAMES.size()
		)
		+
		" | ENABLED "
		+
		str(
			enabled_count
		)
	)


# =============================================================
# REFRESH
# =============================================================

func refresh() -> void:

	if selector == null:

		return


	if manager == null:

		return


	_append_runtime_log(
		"Refreshing character UI."
	)


	if not syncing_profile_selection:

		sync_selection_from_profile()


	selector.clear()


	for character_data: Dictionary in manager.characters:

		var character_name := str(
			character_data.get(
				"name",
				""
			)
		)


		if character_name.is_empty():

			character_name = str(
				character_data.get(
					"id",
					"CHARACTER"
				)
			)


		selector.add_item(
			character_name
		)


	var active_id := ""


	if profile_manager != null:

		var profile := (
			profile_manager.get_active_profile()
		)


		if not profile.is_empty():

			active_id = str(
				profile.get(
					"character_id",
					""
				)
			)


	if active_id.is_empty():

		active_id = (
			manager.active_character_id
		)


	if active_id.is_empty():

		_clear_character_ui()

		return


	var active_index := -1


	for index in range(
		manager.characters.size()
	):

		var character_data: Dictionary = (
			manager.characters[index]
		)


		if str(
			character_data.get(
				"id",
				""
			)
		) == active_id:

			active_index = index

			break


	if active_index < 0:

		_clear_character_ui()

		return


	selector.select(
		active_index
	)


	active_character_data = (
		manager.characters[
			active_index
		].duplicate(
			true
		)
	)


	load_saved_mapping()


	update_character_information(
		active_character_data
	)


	sync_startup_toggle()

	_update_native_controls()


	if avatar_loaded:

		update_mapping_status()

	else:

		if mapping_status != null:

			if saved_bone_map.is_empty():

				mapping_status.text = (
					"AVATAR NOT LOADED"
				)

			else:

				mapping_status.text = (
					"MAPPING SAVED | AVATAR NOT LOADED"
				)


	map_button.disabled = not avatar_loaded


# =============================================================
# CLEAR CHARACTER UI
# =============================================================

func _clear_character_ui() -> void:

	_append_runtime_log(
		"Character selection cleared."
	)


	active_character_data.clear()

	avatar_loaded = false

	current_bone_map.clear()

	saved_bone_map.clear()


	status.text = (
		"NO CHARACTER SELECTED"
	)

	info.text = (
		"NO CHARACTER LOADED."
	)

	mapping_status.text = (
		"AVATAR NOT LOADED"
	)

	map_button.disabled = true


	if tail_checkbox != null:

		tail_checkbox.set_pressed_no_signal(
			false
		)

		tail_checkbox.disabled = true


	refresh_mapping_controls()

	sync_startup_toggle()


# =============================================================
# LOAD SAVED MAPPING
# =============================================================

func load_saved_mapping() -> void:

	saved_bone_map.clear()

	current_bone_map.clear()


	if profile_manager == null:

		refresh_mapping_controls()

		return


	var character_id := str(
		active_character_data.get(
			"id",
			""
		)
	)


	if character_id.is_empty():

		refresh_mapping_controls()

		return


	var mapping := (
		profile_manager.get_active_avatar_mapping(
			character_id
		)
	)


	if mapping.is_empty():

		refresh_mapping_controls()

		return


	var bone_map: Variant = (
		mapping.get(
			"bone_map",
			{}
		)
	)


	if bone_map is Dictionary:

		saved_bone_map = (
			(bone_map as Dictionary).duplicate(
				true
			)
		)


	refresh_mapping_controls()


# =============================================================
# LOAD ON LAUNCH
# =============================================================

func sync_startup_toggle() -> void:

	if launch_toggle == null:

		return


	if profile_manager == null:

		launch_toggle.set_pressed_no_signal(
			false
		)

		return


	launch_toggle.set_pressed_no_signal(
		profile_manager
		.get_active_character_load_on_launch()
	)


func _on_load_on_launch_changed(
	enabled: bool
) -> void:

	if profile_manager == null:

		return


	profile_manager.set_active_character_load_on_launch(
		enabled
	)


	if enabled:

		status.text = (
			"LOAD ON LAUNCH ENABLED"
		)

		_append_runtime_log(
			"LOAD ON LAUNCH enabled."
		)

	else:

		status.text = (
			"LOAD ON LAUNCH DISABLED"
		)

		_append_runtime_log(
			"LOAD ON LAUNCH disabled."
		)


func auto_load_if_enabled() -> void:

	if profile_manager == null:

		return


	if not profile_manager.get_active_character_load_on_launch():

		return


	if active_character_data.is_empty():

		return


	_append_runtime_log(
		"LOAD ON LAUNCH active."
	)


	_load_avatar()


# =============================================================
# INFORMATION
# =============================================================

func update_character_information(
	character_data: Dictionary
) -> void:

	if info == null:

		return


	if character_data.is_empty():

		info.text = (
			"NO CHARACTER LOADED."
		)

		return


	var character_type := str(
		character_data.get(
			"character_type",
			""
		)
	)


	var format_name := ""


	if character_type == "native_3d":

		format_name = (
			"CIGA NATIVE 3D"
		)

	else:

		format_name = str(
			character_data.get(
				"original_format",
				character_data.get(
					"extension",
					"VRM"
				)
			)
		).to_upper()


	var size_text := "NATIVE"


	if manager != null:

		if character_type != "native_3d":

			size_text = (
				manager.format_file_size(
					int(
						character_data.get(
							"file_size",
							0
						)
					)
				)
)

	info.text = (
		"NAME: "
		+
		str(
			character_data.get(
				"name",
				"UNKNOWN"
			)
		)
		+
		"\nTYPE: "
		+
		format_name
		+
		"\nSOURCE: LOCAL CIGA CHARACTER LIBRARY"
		+
		"\nSIZE: "
		+
		size_text
	)


# =============================================================
# CHARACTER SELECTED
# =============================================================

func _on_character_selected(
	index: int
) -> void:

	if manager == null:

		return


	if (
		index < 0
		or
		index >= manager.characters.size()
	):

		return


	var character_data: Dictionary = (
		manager.characters[index]
	)


	var character_id := str(
		character_data.get(
			"id",
			""
		)
	)


	if character_id.is_empty():

		return


	if syncing_profile_selection:

		return


	_append_runtime_log(
		"Character selected: "
		+
		str(
			character_data.get(
				"name",
				character_id
			)
		)
	)


	syncing_profile_selection = true


	if profile_manager != null:

		var profile := (
			profile_manager.get_active_profile()
		)


		if not profile.is_empty():

			profile["character_id"] = (
				character_id
			)

			profile_manager.save_profiles()


	manager.set_active_character(
		character_id
	)


	syncing_profile_selection = false


	active_character_data = (
		character_data.duplicate(
			true
		)
	)


	if character_runtime != null:

		if character_runtime.is_character_loaded():

			var loaded_path: String = (
				character_runtime
				.get_active_character_path()
			)


			var selected_path := str(
				character_data.get(
					"source_path",
					""
				)
			)


			if loaded_path != selected_path:

				_append_runtime_log(
					"Loaded avatar belongs to another character. Unloading old avatar."
				)


				character_runtime.unload_character()


	avatar_loaded = false

	current_bone_map.clear()

	saved_bone_map.clear()


	load_saved_mapping()


	update_character_information(
		character_data
	)


	sync_startup_toggle()


	_update_native_controls()


	status.text = (
		"CHARACTER SELECTED — LOAD AVATAR"
	)

	map_button.disabled = true

	update_mapping_status()


# =============================================================
# LOAD AVATAR
# =============================================================

func _load_avatar() -> void:

	_append_runtime_log(
		"LOAD AVATAR requested."
	)


	if active_character_data.is_empty():

		status.text = (
			"NO CHARACTER SELECTED"
		)

		_append_runtime_log(
			"LOAD FAILED | no character selected."
		)

		return


	if character_runtime == null:

		status.text = (
			"CHARACTER RUNTIME NOT AVAILABLE"
		)

		_append_runtime_log(
			"LOAD FAILED | CharacterRuntime unavailable."
		)

		return


	var selected_path := str(
		active_character_data.get(
			"source_path",
			""
		)
	)


	if selected_path.is_empty():

		status.text = (
			"CHARACTER PATH NOT FOUND"
		)

		_append_runtime_log(
			"LOAD FAILED | character path missing."
		)

		return


	# =========================================================
	# ALREADY LOADED
	# =========================================================

	if character_runtime.is_character_loaded():

		var loaded_path: String = (
			character_runtime
			.get_active_character_path()
		)


		if loaded_path == selected_path:

			avatar_loaded = true

			map_button.disabled = false


			_append_runtime_log(
				"Avatar already loaded."
			)


			if _is_active_native_character():

				_load_native_visual_state()

				status.text = (
					"AVATAR ALREADY LOADED — NATIVE 3D"
				)

			elif not saved_bone_map.is_empty():

				status.text = (
					"AVATAR ALREADY LOADED — MAPPING ACTIVE"
				)

				_load_saved_mapping_into_runtime()

			else:

				status.text = (
					"AVATAR ALREADY LOADED — PRESS MAP AVATAR"
				)


			_update_native_controls()

			update_mapping_status()

			return


	# =========================================================
	# LOAD
	# =========================================================

	status.text = (
		"LOADING AVATAR..."
	)


	_append_runtime_log(
		"Loading avatar from asset library."
	)


	var loaded: Node3D = (
		character_runtime.load_character_data(
			active_character_data
		)
	)


	if loaded == null:

		avatar_loaded = false

		map_button.disabled = true

		status.text = (
			"AVATAR LOAD FAILED"
		)

		_append_runtime_log(
			"LOAD FAILED | CharacterRuntime returned null."
		)

		return


	avatar_loaded = true

	map_button.disabled = false


	_append_runtime_log(
		"AVATAR LOADED | instance created."
	)


	# =========================================================
	# NATIVE 3D
	# =========================================================

	if _is_active_native_character():

		current_bone_map.clear()

		saved_bone_map.clear()


		_load_native_visual_state()


		status.text = (
			"NATIVE 3D AVATAR LOADED"
		)


		_append_runtime_log(
			"Native 3D avatar active."
		)


		update_mapping_status()

		_update_native_controls()


		character_loaded.emit(
			active_character_data
		)

		return


	# =========================================================
	# IMPORTED AVATAR
	# =========================================================

	if not saved_bone_map.is_empty():

		var applied: Dictionary = (
			character_runtime.apply_saved_mapping(
				saved_bone_map
			)
		)


		current_bone_map = (
			applied.duplicate(
				true
			)
		)


		if current_bone_map.size() == saved_bone_map.size():

			status.text = (
				"AVATAR LOADED — SAVED MAPPING RESTORED"
			)

			_append_runtime_log(
				"SAVED MAPPING RESTORED."
			)

		else:

			status.text = (
				"AVATAR LOADED — MAPPING PARTIALLY RESTORED"
			)

			_append_runtime_log(
				"SAVED MAPPING PARTIALLY RESTORED."
			)

	else:

		status.text = (
			"AVATAR LOADED — PRESS MAP AVATAR"
		)


	update_mapping_status()


	character_loaded.emit(
		active_character_data
	)


# =============================================================
# LOAD NATIVE VISUAL STATE
# =============================================================

func _load_native_visual_state() -> void:

	if character_runtime == null:

		return


	var active_node := (
		character_runtime
		.get_active_character()
	)


	if not active_node is CIGACalibrationAvatar:

		return


	var avatar := (
		active_node
		as
		CIGACalibrationAvatar
	)


	var definition := (
		avatar.get_definition()
	)


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


		if tail_checkbox != null:

			tail_checkbox.set_pressed_no_signal(
				bool(
					tail_data.get(
						"enabled",
						false
					)
				)
			)


	_update_native_controls()


# =============================================================
# NATIVE CONTROLS
# =============================================================

func _update_native_controls() -> void:

	var is_native := (
		str(
			active_character_data.get(
				"character_type",
				""
			)
		)
		==
		"native_3d"
	)


	if tail_checkbox != null:

		tail_checkbox.disabled = not is_native


	if create_native_button != null:

		create_native_button.disabled = false


	if native_name_input != null:

		if avatar_loaded and is_native:

			native_name_input.editable = false

		else:

			native_name_input.editable = true


# =============================================================
# NATIVE CHARACTER CHECK
# =============================================================

func _is_active_native_character() -> bool:

	if active_character_data.is_empty():

		return false


	return (
		str(
			active_character_data.get(
				"character_type",
				""
			)
		)
		==
		"native_3d"
	)


# =============================================================
# CREATE NATIVE AVATAR
# =============================================================

func _create_native_avatar() -> void:

	if manager == null:

		status.text = (
			"CHARACTER MANAGER NOT AVAILABLE"
		)

		return


	var character_name := "CIGA Avatar"


	if native_name_input != null:

		var typed_name := (
			native_name_input
			.text
			.strip_edges()
		)


		if not typed_name.is_empty():

			character_name = typed_name


	_append_runtime_log(
		"Creating CIGA native avatar: "
		+
		character_name
	)


	var character_data: Dictionary = (
		manager.create_native_character(
			character_name
		)
	)


	if character_data.is_empty():

		status.text = (
			"NATIVE AVATAR CREATION FAILED"
		)

		_append_runtime_log(
			"CREATE FAILED | Character manager returned empty data."
		)

		return


	var character_id := str(
		character_data.get(
			"id",
			""
		)
	)


	if character_id.is_empty():

		status.text = (
			"NATIVE AVATAR CREATION FAILED"
		)

		_append_runtime_log(
			"CREATE FAILED | no character ID."
		)

		return


	# =========================================================
	# Make active in profile.
	# =========================================================

	if profile_manager != null:

		var profile := (
			profile_manager.get_active_profile()
		)


		if not profile.is_empty():

			profile["character_id"] = character_id

			profile_manager.save_profiles()


	manager.set_active_character(
		character_id
	)


	active_character_data = (
		character_data.duplicate(
			true
		)
	)


	avatar_loaded = false

	current_bone_map.clear()

	saved_bone_map.clear()


	refresh_mapping_controls()

	update_character_information(
		active_character_data
	)

	sync_startup_toggle()

	_update_native_controls()


	# =========================================================
	# Refresh selector.
	# =========================================================

	refresh()


	# =========================================================
	# Select newly-created character.
	# =========================================================

	for index in range(
		manager.characters.size()
	):

		var entry: Dictionary = (
			manager.characters[index]
		)


		if str(
			entry.get(
				"id",
				""
			)
		) == character_id:

			selector.select(
				index
			)

			break


	# =========================================================
	# Load immediately.
	# =========================================================

	_load_avatar()


	# =========================================================
	# Apply initial Tail state.
	# =========================================================

	if tail_checkbox != null:

		_on_tail_toggled(
			tail_checkbox.button_pressed
		)


	status.text = (
		"NATIVE AVATAR CREATED"
	)


	_append_runtime_log(
		"Native avatar created and loaded: "
		+
		character_id
	)


# =============================================================
# TAIL
# =============================================================

func _on_tail_toggled(
	enabled: bool
) -> void:

	if not _is_active_native_character():

		return


	if character_runtime == null:

		return


	var active_node := (
		character_runtime
		.get_active_character()
	)


	if not active_node is CIGACalibrationAvatar:

		return


	var avatar := (
		active_node
		as
		CIGACalibrationAvatar
	)


	avatar.set_tail_enabled(
		enabled
	)


	_save_native_avatar_definition(
		avatar
	)


	if enabled:

		_append_runtime_log(
			"Native avatar tail enabled."
		)

	else:

		_append_runtime_log(
			"Native avatar tail disabled."
		)


	update_mapping_status()


# =============================================================
# SAVE NATIVE AVATAR DEFINITION
# =============================================================

func _save_native_avatar_definition(
	avatar: CIGACalibrationAvatar
) -> bool:

	if avatar == null:

		return false


	if active_character_data.is_empty():

		return false


	var path := str(
		active_character_data.get(
			"source_path",
			""
		)
	)


	if path.is_empty():

		return false


	var definition := (
		avatar.get_definition()
	)


	var file := FileAccess.open(
		path,
		FileAccess.WRITE
	)


	if file == null:

		_append_runtime_log(
			"NATIVE SAVE FAILED | Could not open definition file."
		)

		return false


	file.store_string(
		JSON.stringify(
			definition,
			"\t"
		)
	)

	file.close()


	# =========================================================
	# Update cached metadata.
	# =========================================================

	var character_id := str(
		active_character_data.get(
			"id",
			""
		)
	)


	if manager != null:

		var index := (
			manager.find_character_index(
				character_id
			)
		)


		if index >= 0:

			var record: Dictionary = (
				manager.characters[index]
			)


			record["file_size"] = (
				FileAccess
				.get_file_as_bytes(
					path
				)
				.size()
			)


			record["character_type"] = (
				"native_3d"
			)


			manager.characters[index] = record

			active_character_data = (
				record.duplicate(
					true
				)
			)


			manager.save_library()


	return true


# =============================================================
# RESTORE SAVED MAPPING
# =============================================================

func _load_saved_mapping_into_runtime() -> void:

	if character_runtime == null:

		return


	if saved_bone_map.is_empty():

		return


	var applied: Dictionary = (
		character_runtime.apply_saved_mapping(
			saved_bone_map
		)
	)


	current_bone_map = (
		applied.duplicate(
			true
		)
	)


	update_mapping_status()


	_append_runtime_log(
		"Saved mapping applied to runtime."
	)


# =============================================================
# MAP AVATAR
# =============================================================

func _map_avatar() -> void:

	if character_runtime == null:

		status.text = (
			"CHARACTER RUNTIME NOT AVAILABLE"
		)

		_append_runtime_log(
			"MAP FAILED | CharacterRuntime unavailable."
		)

		return


	if not avatar_loaded:

		status.text = (
			"LOAD AVATAR FIRST"
		)

		_append_runtime_log(
			"MAP FAILED | avatar not loaded."
		)

		return


	# =========================================================
	# Native 3D
	# =========================================================

	if _is_active_native_character():

		current_bone_map.clear()


		var active_node := (
			character_runtime
			.get_active_character()
		)


		if active_node == null:

			status.text = (
				"MAP FAILED | native avatar missing"
			)

			return


		for hitpoint: String in HIT_POINT_NAMES:

			var point := (
				active_node.find_child(
					hitpoint,
					true,
					false
				)
			)


			if point is Node3D:

				current_bone_map[
					hitpoint
				] = hitpoint


		saved_bone_map = (
			current_bone_map.duplicate(
				true
			)
		)


		_save_enabled_mapping()


		update_mapping_status()


		mapping_changed.emit(
			current_bone_map
		)


		status.text = (
			"NATIVE AVATAR MAPPED | FOUND "
			+
			str(
				current_bone_map.size()
			)
			+
			"/"
			+
			str(
				HIT_POINT_NAMES.size()
			)
		)


		_append_runtime_log(
			"NATIVE MAPPING COMPLETE | "
			+
			str(
				current_bone_map.size()
			)
			+
			"/"
			+
			str(
				HIT_POINT_NAMES.size()
			)
		)

		return


	# =========================================================
	# Imported avatar mapping
	# =========================================================

	status.text = (
		"MAPPING AVATAR..."
	)


	_append_runtime_log(
		"Mapping active avatar."
	)


	var result: Dictionary = (
		character_runtime.map_active_character()
	)


	if result.is_empty():

		current_bone_map.clear()

		mapping_status.text = (
			"NO COMPATIBLE BONES FOUND"
		)

		status.text = (
			"MAP FAILED — NO BONES FOUND"
		)

		_append_runtime_log(
			"MAP FAILED | no compatible bones found."
		)

		return


	current_bone_map = (
		result.duplicate(
			true
		)
	)


	saved_bone_map = (
		result.duplicate(
			true
		)
	)


	if profile_manager != null:

		var character_id := str(
			active_character_data.get(
				"id",
				""
			)
		)


		if not character_id.is_empty():

			var enabled := (
				profile_manager
				.get_active_enabled_hitpoints()
			)


			if enabled.is_empty():

				enabled = (
					MAPPING_DEFAULT.duplicate()
				)


			profile_manager.set_active_avatar_mapping(
				character_id,
				current_bone_map,
				enabled
			)


			for hitpoint: String in HIT_POINT_NAMES:

				var check: CheckBox = (
					mapping_checks.get(
						hitpoint
					)
				)


				if check == null:

					continue


				check.set_pressed_no_signal(
					enabled.has(
						hitpoint
					)
				)


			update_mapping_profile_selector(
				enabled
			)


	update_mapping_status()


	mapping_changed.emit(
		current_bone_map
	)


	status.text = (
		"AVATAR MAPPED | FOUND "
		+
		str(
			current_bone_map.size()
		)
		+
		"/"
		+
		str(
			HIT_POINT_NAMES.size()
		)
	)


	_append_runtime_log(
		"MAPPING COMPLETE | "
		+
		str(
			current_bone_map.size()
		)
		+
		"/"
		+
		str(
			HIT_POINT_NAMES.size()
		)
	)


# =============================================================
# ACTIVE CHARACTER DATA
# =============================================================

func set_active_character_data(
	character_data: Dictionary
) -> void:

	var new_id := str(
		character_data.get(
			"id",
			""
		)
	)


	var old_id := str(
		active_character_data.get(
			"id",
			""
		)
	)


	if old_id != new_id:

		_append_runtime_log(
			"Active character changed."
		)

		avatar_loaded = false

		current_bone_map.clear()

		saved_bone_map.clear()


	active_character_data = (
		character_data.duplicate(
			true
		)
	)


	load_saved_mapping()


	if active_character_data.is_empty():

		status.text = (
			"NO CHARACTER SELECTED"
		)

		map_button.disabled = true

		_update_native_controls()

		update_mapping_status()

		return


	update_character_information(
		active_character_data
	)


	map_button.disabled = not avatar_loaded

	_update_native_controls()


	if avatar_loaded:

		update_mapping_status()

	else:

		status.text = (
			"CHARACTER SELECTED — LOAD AVATAR"
		)


# =============================================================
# IMPORT DIALOG
#
# Apenas VRM é aceite como avatar importado.
#
# CIGA Native Avatar é criado pelo sistema e não passa
# por este importador.
# =============================================================

func _open_import() -> void:

	if root == null:

		return


	if file_dialog != null:

		file_dialog.queue_free()

		file_dialog = null


	file_dialog = FileDialog.new()

	file_dialog.name = (
		"CharacterImportDialog"
	)

	file_dialog.file_mode = (
		FileDialog.FILE_MODE_OPEN_FILE
	)

	file_dialog.access = (
		FileDialog.ACCESS_FILESYSTEM
	)

	# =========================================================
	# VRM ONLY
	# =========================================================

	file_dialog.filters = PackedStringArray([
		"*.vrm ; VRM Character"
	])

	file_dialog.file_selected.connect(
		_import_file
	)

	file_dialog.canceled.connect(
		_close_dialog
	)

	root.add_child(
		file_dialog
	)

	file_dialog.popup_centered_ratio()


## =============================================================
# IMPORT FILE
#
# IMPORTAÇÃO DE AVATARES EXTERNOS:
#
#     VRM -> permitido
#
#     GLB  -> bloqueado
#     GLTF -> bloqueado
#
# CIGA Native Avatar não é importado aqui.
# =============================================================

func _import_file(
	path: String
) -> void:

	if manager == null:

		_close_dialog()

		return


	var extension := (
		path
		.get_extension()
		.to_lower()
	)


	# =========================================================
	# NATIVE AVATAR PROTECTION
	# =========================================================
	#
	# .cigaavatar não é um modelo externo importável.
	# =========================================================

	if extension == "cigaavatar":

		status.text = (
			"CIGA NATIVE AVATAR IS NOT IMPORTABLE"
		)

		_append_runtime_log(
			"IMPORT BLOCKED | native CIGA avatar."
		)

		_close_dialog()

		return


	# =========================================================
	# VRM ONLY
	# =========================================================

	if extension != "vrm":

		status.text = (
			"ONLY VRM AVATARS ARE SUPPORTED"
		)

		_append_runtime_log(
			"IMPORT BLOCKED | unsupported avatar format: "
			+
			extension
		)

		_close_dialog()

		return


	# =========================================================
	# IMPORT
	# =========================================================

	_append_runtime_log(
		"Importing VRM character: "
		+
		path.get_file()
	)


	var character_data: Dictionary = (
		manager.import_character(
			path
		)
	)


	if character_data.is_empty():

		status.text = (
			"VRM CHARACTER IMPORT FAILED"
		)

		_append_runtime_log(
			"IMPORT FAILED."
		)

		_close_dialog()

		return


	var character_id := str(
		character_data.get(
			"id",
			""
		)
	)


	if character_id.is_empty():

		status.text = (
			"VRM CHARACTER IMPORT FAILED"
		)

		_append_runtime_log(
			"IMPORT FAILED | no character ID."
		)

		_close_dialog()

		return


	# =========================================================
	# ACTIVE PROFILE
	# =========================================================

	if profile_manager != null:

		var profile := (
			profile_manager.get_active_profile()
		)


		if not profile.is_empty():

			profile["character_id"] = (
				character_id
			)

			profile_manager.save_profiles()


	manager.set_active_character(
		character_id
	)


	active_character_data = (
		character_data.duplicate(
			true
		)
	)


	avatar_loaded = false

	current_bone_map.clear()

	saved_bone_map.clear()


	load_saved_mapping()

	refresh()

	_close_dialog()


	status.text = (
		"VRM CHARACTER IMPORTED — LOAD AVATAR"
	)


	_append_runtime_log(
		"VRM IMPORT COMPLETE."
	)
# =============================================================
# REMOVE
# =============================================================

func _remove_character() -> void:

	if manager == null:

		return


	var active_id := (
		manager.active_character_id
	)


	if active_id.is_empty():

		return


	_append_runtime_log(
		"Removing character."
	)


	if character_runtime != null:

		if character_runtime.is_character_loaded():

			var loaded_path: String = (
				character_runtime
				.get_active_character_path()
			)


			var character_data: Dictionary = (
				manager.get_character(
					active_id
				)
			)


			var selected_path := str(
				character_data.get(
					"source_path",
					""
				)
			)


			if loaded_path == selected_path:

				character_runtime.unload_character()


	if not manager.remove_character(
		active_id
	):

		status.text = (
			"CHARACTER REMOVE FAILED"
		)

		_append_runtime_log(
			"REMOVE FAILED."
		)

		return


	if profile_manager != null:

		var profile := (
			profile_manager.get_active_profile()
		)


		if not profile.is_empty():

			if str(
				profile.get(
					"character_id",
					""
				)
			) == active_id:

				profile["character_id"] = ""


			profile_manager.remove_active_avatar_mapping(
				active_id
			)


			profile_manager.save_profiles()


	active_character_data.clear()

	avatar_loaded = false

	current_bone_map.clear()

	saved_bone_map.clear()


	_update_native_controls()

	refresh()


	_append_runtime_log(
		"REMOVE COMPLETE."
	)


# =============================================================
# CLOSE DIALOG
# =============================================================

func _close_dialog() -> void:

	if file_dialog != null:

		file_dialog.queue_free()

		file_dialog = null


# =============================================================
# SYNC PROFILE SELECTION
# =============================================================

func sync_selection_from_profile() -> void:

	if syncing_profile_selection:

		return


	if profile_manager == null:

		return


	if manager == null:

		return


	var profile := (
		profile_manager.get_active_profile()
	)


	if profile.is_empty():

		return


	var profile_character_id := str(
		profile.get(
			"character_id",
			""
		)
	)


	if profile_character_id.is_empty():

		return


	if not manager.has_character(
		profile_character_id
	):

		return


	if manager.active_character_id == profile_character_id:

		return


	syncing_profile_selection = true


	manager.set_active_character(
		profile_character_id
	)


	syncing_profile_selection = false


	_append_runtime_log(
		"Profile selection synchronized."
	)
