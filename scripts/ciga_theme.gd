class_name CIGATheme
extends RefCounted
# TEMA DA CIGA YAAAA BEBE CHUPA Q É DE UVA CABRÃO AUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU

const BACKGROUND := Color("#080808")

const PANEL := Color("#101010")
const PANEL_LIGHT := Color("#151515")
const PANEL_HOVER := Color("#1b1b1b")

const BORDER := Color("#292929")
const BORDER_LIGHT := Color("#3a3a3a")

const ACCENT := Color("#8f1018")
const ACCENT_BRIGHT := Color("#b51b25")
const ACCENT_DARK := Color("#28090b")

const TEXT := Color("#dedede")
const TEXT_DIM := Color("#888888")


func create_button(
	text_value: String
) -> Button:

	var button := Button.new()

	button.text = text_value

	button.custom_minimum_size = Vector2(
		0.0,
		42.0
	)

	button.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND
	)

	style_button(button)

	return button


func create_title(
	text_value: String
) -> Label:

	var label := Label.new()

	label.text = text_value

	label.add_theme_font_size_override(
		"font_size",
		26
	)

	label.add_theme_color_override(
		"font_color",
		TEXT
	)

	return label


func create_section_label(
	text_value: String
) -> Label:

	var label := Label.new()

	label.text = text_value

	label.add_theme_font_size_override(
		"font_size",
		15
	)

	label.add_theme_color_override(
		"font_color",
		TEXT_DIM
	)

	return label


func create_status_label(
	text_value: String
) -> Label:

	var label := Label.new()

	label.text = text_value

	label.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	label.add_theme_color_override(
		"font_color",
		TEXT_DIM
	)

	return label


func create_spinbox(
	minimum: float,
	maximum: float,
	step_value: float,
	initial_value: float
) -> SpinBox:

	var spin := SpinBox.new()

	spin.min_value = minimum
	spin.max_value = maximum
	spin.step = step_value
	spin.value = initial_value

	spin.custom_minimum_size = Vector2(
		0.0,
		40.0
	)

	spin.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	return spin


func labeled_control(
	label_text: String,
	control: Control
) -> VBoxContainer:

	var box := VBoxContainer.new()

	box.add_theme_constant_override(
		"separation",
		4
	)

	var label := Label.new()

	label.text = label_text

	box.add_child(label)
	box.add_child(control)

	return box


func set_margins(
	margin: MarginContainer,
	value: int
) -> void:

	margin.add_theme_constant_override(
		"margin_left",
		value
	)

	margin.add_theme_constant_override(
		"margin_right",
		value
	)

	margin.add_theme_constant_override(
		"margin_top",
		value
	)

	margin.add_theme_constant_override(
		"margin_bottom",
		value
	)


func style_panel(
	panel: PanelContainer,
	background: Color = PANEL,
	border: Color = BORDER
) -> void:

	if panel == null:
		return

	var style := StyleBoxFlat.new()

	style.bg_color = background
	style.border_color = border

	style.set_border_width_all(1)

	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10

	panel.add_theme_stylebox_override(
		"panel",
		style
	)


func style_button(
	button: Button
) -> void:

	if button == null:
		return

	var normal := StyleBoxFlat.new()

	normal.bg_color = PANEL
	normal.border_color = BORDER

	normal.set_border_width_all(1)


	var hover := StyleBoxFlat.new()

	hover.bg_color = PANEL_HOVER
	hover.border_color = ACCENT

	hover.set_border_width_all(1)


	var pressed := StyleBoxFlat.new()

	pressed.bg_color = PANEL_LIGHT
	pressed.border_color = ACCENT_BRIGHT

	pressed.set_border_width_all(1)


	button.add_theme_stylebox_override(
		"normal",
		normal
	)

	button.add_theme_stylebox_override(
		"hover",
		hover
	)

	button.add_theme_stylebox_override(
		"pressed",
		pressed
	)

	button.add_theme_stylebox_override(
		"focus",
		hover
	)

	button.add_theme_color_override(
		"font_color",
		TEXT
	)

	button.add_theme_color_override(
		"font_hover_color",
		TEXT
	)

	button.add_theme_color_override(
		"font_pressed_color",
		Color.WHITE
	)


func style_light_button(
	button: Button
) -> void:

	if button == null:
		return

	var normal := StyleBoxFlat.new()

	normal.bg_color = Color("#eeeeee")
	normal.border_color = Color("#bdbdbd")

	normal.set_border_width_all(1)


	var hover := StyleBoxFlat.new()

	hover.bg_color = Color("#e3e3e3")
	hover.border_color = Color("#777777")

	hover.set_border_width_all(1)


	var pressed := StyleBoxFlat.new()

	pressed.bg_color = Color("#d3d3d3")
	pressed.border_color = ACCENT

	pressed.set_border_width_all(1)


	button.add_theme_stylebox_override(
		"normal",
		normal
	)

	button.add_theme_stylebox_override(
		"hover",
		hover
	)

	button.add_theme_stylebox_override(
		"pressed",
		pressed
	)

	button.add_theme_color_override(
		"font_color",
		Color("#202020")
	)


func apply_dark(
	root: Node
) -> void:

	if root == null:
		return

	for node in root.find_children(
		"*",
		"*",
		true,
		false
	):

		if node is Button:

			style_button(
				node as Button
			)

		elif node is PanelContainer:

			style_panel(
				node as PanelContainer
			)


func apply_light(
	root: Node
) -> void:

	if root == null:
		return

	for node in root.find_children(
		"*",
		"*",
		true,
		false
	):

		if node is Button:

			style_light_button(
				node as Button
			)

		elif node is PanelContainer:

			style_panel(
				node as PanelContainer,
				Color("#eeeeee"),
				Color("#bdbdbd")
			)
