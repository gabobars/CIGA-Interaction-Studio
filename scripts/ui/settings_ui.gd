class_name CIGASettingsUI
extends RefCounted


# =============================================================
# CIGA SETTINGS UI
# Godot 4.7.2
#
# SETTINGS:
#
# GENERAL
#   OBJECT LIFETIME
#   MAX OBJECTS
#
# PHYSICS
#   DEFAULT FORCE
#   DEFAULT SPEED
#   DEFAULT BOUNCE
#   BOUNCE TIME
#   DEFAULT SPIN
#
# IMPACT RESPONSE
#   IMPACT MOVEMENT
#
# =============================================================


signal theme_changed


# =============================================================
# REFERENCES
# =============================================================

var root: PanelContainer = null

var theme: CIGATheme = null

var settings_runtime: CIGASettings = null

var profile_manager: CIGAProfiles = null


# =============================================================
# CONTROLS
# =============================================================

var lifetime_spin: SpinBox = null

var max_objects_spin: SpinBox = null

var force_spin: SpinBox = null

var speed_spin: SpinBox = null

var bounce_spin: SpinBox = null

var bounce_time_spin: SpinBox = null

var spin_spin: SpinBox = null

var impact_movement_spin: SpinBox = null

var defaults_button: Button = null

var status_label: Label = null


# =============================================================
# SETUP
# =============================================================

func setup(
	parent: Control,
	ui_theme: CIGATheme,
	runtime: CIGASettings,
	profiles: CIGAProfiles
) -> Control:

	theme = ui_theme

	settings_runtime = runtime

	profile_manager = profiles


	root = PanelContainer.new()

	root.name = (
		"SettingsPage"
	)

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


	if theme != null:

		theme.style_panel(
			root
		)


	parent.add_child(
		root
	)


	build()

	load_from_active_profile()

	refresh_controls()


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
		"SettingsScroll"
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
		"SettingsContent"
	)

	box.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	box.size_flags_vertical = (
		Control.SIZE_SHRINK_BEGIN
	)

	box.add_theme_constant_override(
		"separation",
		10
	)

	margin.add_child(
		box
	)


	# =========================================================
	# TITLE
	# =========================================================

	box.add_child(
		theme.create_title(
			"SETTINGS"
		)
	)


	box.add_child(
		theme.create_status_label(
			"Global CIGA runtime configuration."
		)
	)


	# =========================================================
	# GENERAL
	# =========================================================

	box.add_child(
		theme.create_section_label(
			"GENERAL"
		)
	)


	# ---------------------------------------------------------
	# OBJECT LIFETIME
	# ---------------------------------------------------------

	lifetime_spin = theme.create_spinbox(
		0.1,
		60.0,
		0.1,
		CIGASettings.DEFAULT_OBJECT_LIFETIME
	)

	lifetime_spin.allow_greater = false

	lifetime_spin.allow_lesser = false

	lifetime_spin.custom_minimum_size = Vector2(
		0.0,
		40.0
	)

	lifetime_spin.tooltip_text = (
		"How long a spawned object can exist before "
		+
		"it is automatically removed."
	)

	box.add_child(
		theme.labeled_control(
			"OBJECT LIFETIME",
			lifetime_spin
		)
	)


	box.add_child(
		theme.create_status_label(
			"Maximum lifetime of spawned objects in seconds. "
			+
			"Lower values keep the scene cleaner."
		)
	)


	# ---------------------------------------------------------
	# MAX OBJECTS
	# ---------------------------------------------------------

	max_objects_spin = theme.create_spinbox(
		1.0,
		500.0,
		1.0,
		float(
			CIGASettings.DEFAULT_MAX_OBJECTS
		)
	)

	max_objects_spin.allow_greater = false

	max_objects_spin.allow_lesser = false

	max_objects_spin.custom_minimum_size = Vector2(
		0.0,
		40.0
	)

	max_objects_spin.tooltip_text = (
		"Maximum number of spawned objects that may exist "
		+
		"at the same time."
	)

	box.add_child(
		theme.labeled_control(
			"MAX OBJECTS",
			max_objects_spin
		)
	)


	box.add_child(
		theme.create_status_label(
			"Safety limit for simultaneous spawned objects. "
			+
			"Higher values allow larger object bursts but use more resources."
		)
	)


	# =========================================================
	# PHYSICS
	# =========================================================

	box.add_child(
		theme.create_section_label(
			"PHYSICS DEFAULTS"
		)
	)


	# ---------------------------------------------------------
	# DEFAULT FORCE
	# ---------------------------------------------------------

	force_spin = theme.create_spinbox(
		0.0,
		100.0,
		0.1,
		CIGASettings.DEFAULT_FORCE
	)

	force_spin.allow_greater = false

	force_spin.allow_lesser = false

	force_spin.custom_minimum_size = Vector2(
		0.0,
		40.0
	)

	force_spin.tooltip_text = (
		"How strongly an object transfers impact force "
		+
		"to the character."
	)

	box.add_child(
		theme.labeled_control(
			"DEFAULT FORCE",
			force_spin
		)
	)


	box.add_child(
		theme.create_status_label(
			"Controls the strength of the impact itself. "
			+
			"It affects the character's physical reaction, "
			+
			"not how fast the object travels."
		)
	)


	# ---------------------------------------------------------
	# DEFAULT SPEED
	# ---------------------------------------------------------

	speed_spin = theme.create_spinbox(
		0.1,
		100.0,
		0.1,
		CIGASettings.DEFAULT_SPEED
	)

	speed_spin.allow_greater = false

	speed_spin.allow_lesser = false

	speed_spin.custom_minimum_size = Vector2(
		0.0,
		40.0
	)

	speed_spin.tooltip_text = (
		"Initial movement speed of spawned objects."
	)

	box.add_child(
		theme.labeled_control(
			"DEFAULT SPEED",
			speed_spin
		)
	)


	box.add_child(
		theme.create_status_label(
			"Controls how quickly spawned objects travel "
			+
			"towards their target."
		)
	)


	# ---------------------------------------------------------
	# DEFAULT BOUNCE
	# ---------------------------------------------------------

	bounce_spin = theme.create_spinbox(
		0.0,
		1.0,
		0.05,
		CIGASettings.DEFAULT_BOUNCE
	)

	bounce_spin.allow_greater = false

	bounce_spin.allow_lesser = false

	bounce_spin.custom_minimum_size = Vector2(
		0.0,
		40.0
	)

	bounce_spin.tooltip_text = (
		"Controls how much energy remains after an object "
		+
		"hits something."
	)

	box.add_child(
		theme.labeled_control(
			"DEFAULT BOUNCE",
			bounce_spin
		)
	)


	box.add_child(
		theme.create_status_label(
			"0.00 = almost no bounce. "
			+
			"1.00 = maximum configured bounce response."
		)
	)


	# ---------------------------------------------------------
	# BOUNCE TIME
	# ---------------------------------------------------------

	bounce_time_spin = theme.create_spinbox(
		0.0,
		10.0,
		0.05,
		CIGASettings.DEFAULT_BOUNCE_TIME
	)

	bounce_time_spin.allow_greater = false

	bounce_time_spin.allow_lesser = false

	bounce_time_spin.custom_minimum_size = Vector2(
		0.0,
		40.0
	)

	bounce_time_spin.tooltip_text = (
		"How long an impacted object remains in its "
		+
		"post-impact state."
	)

	box.add_child(
		theme.labeled_control(
			"BOUNCE TIME",
			bounce_time_spin
		)
	)


	box.add_child(
		theme.create_status_label(
			"Independent from OBJECT LIFETIME. "
			+
			"After impact, the object may continue bouncing "
			+
			"for this amount of time, unless its total lifetime "
			+
			"expires first."
		)
	)


	# ---------------------------------------------------------
	# DEFAULT SPIN
	# ---------------------------------------------------------

	spin_spin = theme.create_spinbox(
		-100.0,
		100.0,
		1.0,
		CIGASettings.DEFAULT_SPIN
	)

	spin_spin.allow_greater = false

	spin_spin.allow_lesser = false

	spin_spin.custom_minimum_size = Vector2(
		0.0,
		40.0
	)

	spin_spin.tooltip_text = (
		"Controls the default rotational behaviour of spawned objects."
	)

	box.add_child(
		theme.labeled_control(
			"DEFAULT SPIN",
			spin_spin
		)
	)


	box.add_child(
		theme.create_status_label(
			"Controls how much spawned objects rotate while travelling."
		)
	)


	# =========================================================
	# IMPACT RESPONSE
	# =========================================================

	box.add_child(
		theme.create_section_label(
			"IMPACT RESPONSE"
		)
	)


	# ---------------------------------------------------------
	# IMPACT MOVEMENT
	# ---------------------------------------------------------

	impact_movement_spin = theme.create_spinbox(
		0.0,
		5.0,
		0.05,
		CIGASettings.DEFAULT_IMPACT_MOVEMENT
	)

	impact_movement_spin.allow_greater = false

	impact_movement_spin.allow_lesser = false

	impact_movement_spin.custom_minimum_size = Vector2(
		0.0,
		40.0
	)

	impact_movement_spin.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	impact_movement_spin.tooltip_text = (
		"Controls the amount of body reaction generated by impacts."
	)

	box.add_child(
		theme.labeled_control(
			"IMPACT MOVEMENT",
			impact_movement_spin
		)
	)


	box.add_child(
		theme.create_status_label(
			"0.00 = no body recoil. "
			+
			"1.00 = normal response. "
			+
			"2.00 = stronger displacement. "
			+
			"5.00 = maximum configured response."
		)
	)


	box.add_child(
		theme.create_status_label(
			"This setting controls how far and how strongly "
			+
			"the character reacts to an impact. "
			+
			"It does not change projectile speed or force."
		)
	)


	# =========================================================
	# STATUS
	# =========================================================

	box.add_child(
		theme.create_section_label(
			"STATUS"
		)
	)


	status_label = theme.create_status_label(
		"SETTINGS READY"
	)

	status_label.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	box.add_child(
		status_label
	)


	# =========================================================
	# RESET
	# =========================================================

	box.add_child(
		theme.create_section_label(
			"RESET"
		)
	)


	defaults_button = theme.create_button(
		"RESTORE DEFAULT SETTINGS"
	)

	defaults_button.custom_minimum_size = Vector2(
		0.0,
		44.0
	)

	defaults_button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	box.add_child(
		defaults_button
	)


	# =========================================================
	# CONNECTIONS
	# =========================================================

	lifetime_spin.value_changed.connect(
		_on_lifetime_changed
	)

	max_objects_spin.value_changed.connect(
		_on_max_objects_changed
	)

	force_spin.value_changed.connect(
		_on_force_changed
	)

	speed_spin.value_changed.connect(
		_on_speed_changed
	)

	bounce_spin.value_changed.connect(
		_on_bounce_changed
	)

	bounce_time_spin.value_changed.connect(
		_on_bounce_time_changed
	)

	spin_spin.value_changed.connect(
		_on_spin_changed
	)

	impact_movement_spin.value_changed.connect(
		_on_impact_movement_changed
	)

	defaults_button.pressed.connect(
		restore_defaults
	)


# =============================================================
# LOAD ACTIVE PROFILE
# =============================================================

func load_from_active_profile() -> void:

	if settings_runtime == null:

		return


	if profile_manager == null:

		settings_runtime.reset_to_defaults()

		refresh_controls()

		return


	settings_runtime.load_from_active_profile(
		profile_manager
	)


# =============================================================
# REFRESH
# =============================================================

func refresh_controls() -> void:

	if settings_runtime == null:

		return


	if lifetime_spin != null:

		lifetime_spin.set_value_no_signal(
			settings_runtime.get_object_lifetime()
		)


	if max_objects_spin != null:

		max_objects_spin.set_value_no_signal(
			float(
				settings_runtime.get_max_objects()
			)
		)


	if force_spin != null:

		force_spin.set_value_no_signal(
			settings_runtime.get_default_force()
		)


	if speed_spin != null:

		speed_spin.set_value_no_signal(
			settings_runtime.get_default_speed()
		)


	if bounce_spin != null:

		bounce_spin.set_value_no_signal(
			settings_runtime.get_default_bounce()
		)


	if bounce_time_spin != null:

		bounce_time_spin.set_value_no_signal(
			settings_runtime.get_bounce_time()
		)


	if spin_spin != null:

		spin_spin.set_value_no_signal(
			settings_runtime.get_default_spin()
		)


	if impact_movement_spin != null:

		impact_movement_spin.set_value_no_signal(
			settings_runtime.get_impact_movement()
		)


	if status_label != null:

		status_label.text = (
			"SETTINGS LOADED"
		)


# =============================================================
# CHANGE CALLBACKS
# =============================================================

func _on_lifetime_changed(
	value: float
) -> void:

	if settings_runtime == null:

		return


	if settings_runtime.set_value(
		CIGASettings.KEY_OBJECT_LIFETIME,
		value
	):

		_set_status(
			"OBJECT LIFETIME SAVED"
		)


func _on_max_objects_changed(
	value: float
) -> void:

	if settings_runtime == null:

		return


	if settings_runtime.set_value(
		CIGASettings.KEY_MAX_OBJECTS,
		int(
			round(value)
		)
	):

		_set_status(
			"MAX OBJECTS SAVED"
		)


func _on_force_changed(
	value: float
) -> void:

	if settings_runtime == null:

		return


	if settings_runtime.set_value(
		CIGASettings.KEY_DEFAULT_FORCE,
		value
	):

		_set_status(
			"DEFAULT FORCE SAVED"
		)


func _on_speed_changed(
	value: float
) -> void:

	if settings_runtime == null:

		return


	if settings_runtime.set_value(
		CIGASettings.KEY_DEFAULT_SPEED,
		value
	):

		_set_status(
			"DEFAULT SPEED SAVED"
		)


func _on_bounce_changed(
	value: float
) -> void:

	if settings_runtime == null:

		return


	if settings_runtime.set_value(
		CIGASettings.KEY_DEFAULT_BOUNCE,
		value
	):

		_set_status(
			"DEFAULT BOUNCE SAVED"
		)


func _on_bounce_time_changed(
	value: float
) -> void:

	if settings_runtime == null:

		return


	if settings_runtime.set_value(
		CIGASettings.KEY_BOUNCE_TIME,
		value
	):

		_set_status(
			"BOUNCE TIME SAVED"
		)


func _on_spin_changed(
	value: float
) -> void:

	if settings_runtime == null:

		return


	if settings_runtime.set_value(
		CIGASettings.KEY_DEFAULT_SPIN,
		value
	):

		_set_status(
			"DEFAULT SPIN SAVED"
		)


# =============================================================
# IMPACT MOVEMENT
# =============================================================

func _on_impact_movement_changed(
	value: float
) -> void:

	if settings_runtime == null:

		return


	var safe_value := clampf(
		value,
		0.0,
		5.0
	)


	if settings_runtime.set_value(
		CIGASettings.KEY_IMPACT_MOVEMENT,
		safe_value
	):

		_set_status(
			"IMPACT MOVEMENT SAVED"
		)


# =============================================================
# RESTORE
# =============================================================

func restore_defaults() -> void:

	if settings_runtime == null:

		return


	settings_runtime.reset_to_defaults()

	settings_runtime.save_to_active_profile()

	refresh_controls()

	settings_runtime.emit_settings_changed()

	_set_status(
		"DEFAULT SETTINGS RESTORED"
	)


# =============================================================
# STATUS
# =============================================================

func _set_status(
	text_value: String
) -> void:

	if status_label == null:

		return


	status_label.text = text_value
