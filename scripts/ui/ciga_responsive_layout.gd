class_name CIGAResponsiveLayout
extends Control


# =============================================================
# CIGA RESPONSIVE LAYOUT
# Godot 4.7.2
#
# Epa, esta merda trata só de uma coisa:
#
#     "onde é que a página fica?"
#
# Não queremos que esta classe invente coordenadas para os
# botões nem que ande a empurrar roots para cima e para baixo.
#
# A regra é:
#
#     configuration_root
#            ↓
#     responsive layout
#            ↓
#     page container
#            ↓
#     page host
#            ↓
#     page root
#
# Tudo fica EXACTAMENTE alinhado.
#
# Se o botão aparece numa posição,
# o rato deve clicar nessa mesma posição.
#
# =============================================================


# =============================================================
# ENUM
# =============================================================

enum LayoutMode {
	WIDE,
	COMPACT,
	NARROW
}


# =============================================================
# REFERENCES
# =============================================================

var page_container: Control = null

var page_roots: Dictionary = {}

var page_hosts: Dictionary = {}

var responsive_modules: Array[Object] = []

var current_page: String = ""


# =============================================================
# STATE
# =============================================================

var current_mode: LayoutMode = LayoutMode.WIDE

var last_width: float = -1.0


# =============================================================
# BREAKPOINTS
# =============================================================

const WIDE_WIDTH: float = 1150.0

const NARROW_WIDTH: float = 760.0


# =============================================================
# CONTENT AREA
#
# Epa, estes são os offsets da área de configuração.
#
# Só o PAGE CONTAINER conhece estes offsets.
#
# Tudo lá dentro é FULL RECT.
#
# Portanto:
#
#     PAGE CONTAINER
#         ↓
#     HOST
#         ↓
#     PAGE ROOT
#
# nenhum destes três volta a aplicar margem própria.
#
# =============================================================

const CONTENT_LEFT: float = 24.0

const CONTENT_RIGHT: float = -24.0

const CONTENT_TOP: float = 170.0

const CONTENT_BOTTOM: float = -24.0


# =============================================================
# SETUP
# =============================================================

func setup(
	parent: Control,
	pages: Dictionary
) -> Control:

	if parent == null:

		return self


	# =========================================================
	# RESET
	#
	# Epa, limpar isto antes de montar outra vez evita hosts
	# fantasmas se o layout for inicializado novamente.
	# =========================================================

	page_roots = pages.duplicate()

	page_hosts.clear()

	current_page = ""

	responsive_modules.clear()

	current_mode = LayoutMode.WIDE

	last_width = -1.0


	# =========================================================
	# ROOT
	# =========================================================

	name = "CIGAResponsiveLayout"


	set_anchors_and_offsets_preset(
		PRESET_FULL_RECT
	)


	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0


	# Esta camada não recebe clique nenhum.
	mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	# =========================================================
	# PARENT
	# =========================================================

	if get_parent() != null:

		get_parent().remove_child(
			self
		)


	parent.add_child(
		self
	)


	# =========================================================
	# PAGE CONTAINER
	#
	# Epa, aqui vive a única margem real.
	# =========================================================

	page_container = Control.new()

	page_container.name = (
		"PageContainer"
	)


	page_container.set_anchors_and_offsets_preset(
		PRESET_FULL_RECT
	)


	page_container.offset_left = CONTENT_LEFT

	page_container.offset_top = CONTENT_TOP

	page_container.offset_right = CONTENT_RIGHT

	page_container.offset_bottom = CONTENT_BOTTOM


	# O container não come input.
	#
	# Os botões dentro das páginas tratam disso.
	page_container.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	add_child(
		page_container
	)


	# =========================================================
	# CREATE HOSTS
	# =========================================================

	for page_key: Variant in page_roots.keys():

		var page_name: String = (
			str(
				page_key
			)
		)


		var root_value: Variant = (
			page_roots.get(
				page_key,
				null
			)
		)


		if not root_value is Control:

			continue


		var page_root: Control = (
			root_value
			as
			Control
		)


		create_page_host(
			page_name,
			page_root
		)


	# =========================================================
	# REFRESH
	# =========================================================

	call_deferred(
		"refresh_layout"
	)


	return page_container


# =============================================================
# CREATE PAGE HOST
# =============================================================

func create_page_host(
	page_name: String,
	page_root: Control
) -> void:

	if page_root == null:

		return


	# =========================================================
	# HOST
	#
	# Epa, host é só uma caixa invisível para organizar a página.
	# Não recebe input.
	# =========================================================

	var host := Control.new()

	host.name = (
		page_name
		+
		"PageHost"
	)


	host.set_anchors_and_offsets_preset(
		PRESET_FULL_RECT
	)


	host.offset_left = 0.0

	host.offset_top = 0.0

	host.offset_right = 0.0

	host.offset_bottom = 0.0


	host.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	host.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)


	host.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	host.visible = false


	page_container.add_child(
		host
	)


	# =========================================================
	# TIRAR DO PAI ANTIGO
	# =========================================================

	var old_parent := (
		page_root.get_parent()
	)


	if old_parent != null:

		old_parent.remove_child(
			page_root
		)


	# =========================================================
	# PAGE ROOT
	#
	# Epa, aqui estava uma das merdas suspeitas.
	#
	# O root inteiro não precisa de STOP.
	#
	# Deixamos PASS para que os filhos tratem dos cliques.
	# =========================================================

	page_root.set_anchors_and_offsets_preset(
		PRESET_FULL_RECT
	)


	page_root.offset_left = 0.0

	page_root.offset_top = 0.0

	page_root.offset_right = 0.0

	page_root.offset_bottom = 0.0


	page_root.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	page_root.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)


	page_root.mouse_filter = (
		Control.MOUSE_FILTER_PASS
	)


	page_root.visible = true


	host.add_child(
		page_root
	)


	page_hosts[page_name] = host


# =============================================================
# REGISTER MODULE
# =============================================================

func register_module(
	module: Object
) -> void:

	if module == null:

		return


	if responsive_modules.has(
		module
	):

		return


	responsive_modules.append(
		module
	)


	call_deferred(
		"notify_modules"
	)


# =============================================================
# UNREGISTER MODULE
# =============================================================

func unregister_module(
	module: Object
) -> void:

	if module == null:

		return


	var index := (
		responsive_modules.find(
			module
		)
	)


	if index >= 0:

		responsive_modules.remove_at(
			index
		)


# =============================================================
# SHOW PAGE
# =============================================================

func show_page(
	page_name: String
) -> void:

	if page_hosts.is_empty():

		return


	if not page_hosts.has(
		page_name
	):

		print(
			"CIGA RESPONSIVE: PAGE NOT FOUND = ",
			page_name
		)

		return


	# =========================================================
	# ESCONDER TODAS AS PÁGINAS
	# =========================================================

	for key: Variant in page_hosts.keys():

		var key_name: String = (
			str(
				key
			)
		)


		var host_value: Variant = (
			page_hosts.get(
				key,
				null
			)
		)


		if not host_value is Control:

			continue


		var host: Control = (
			host_value
			as
			Control
		)


		host.visible = (
			key_name
			==
			page_name
		)


	# =========================================================
	# CURRENT PAGE
	# =========================================================

	current_page = page_name


	# =========================================================
	# REFRESH
	# =========================================================

	call_deferred(
		"refresh_layout"
	)


# =============================================================
# GET MODE
# =============================================================

func get_layout_mode(
	width: float
) -> LayoutMode:

	if width < NARROW_WIDTH:

		return LayoutMode.NARROW


	if width < WIDE_WIDTH:

		return LayoutMode.COMPACT


	return LayoutMode.WIDE


# =============================================================
# REFRESH
#
# Epa, agora esta merda não inventa tamanhos novos.
#
# Só garante:
#
#     host = full rect
#     root = full rect
#
# O espaço real já foi decidido pelo page_container.
#
# =============================================================

func refresh_layout() -> void:

	if page_container == null:

		return


	if not is_inside_tree():

		return


	# =========================================================
	# SIZE
	# =========================================================

	var width: float = (
		page_container.size.x
	)


	if width <= 0.0:

		call_deferred(
			"refresh_layout"
		)

		return


	last_width = width


	# =========================================================
	# MODE
	# =========================================================

	var new_mode: LayoutMode = (
		get_layout_mode(
			width
		)
	)


	var changed: bool = (
		new_mode
		!=
		current_mode
	)


	if changed:

		current_mode = new_mode


		notify_modules()


	# =========================================================
	# GARANTIR GEOMETRIA DOS HOSTS
	# =========================================================

	for key: Variant in page_hosts.keys():

		var host_value: Variant = (
			page_hosts.get(
				key,
				null
			)
		)


		if not host_value is Control:

			continue


		var host: Control = (
			host_value
			as
			Control
		)


		host.set_anchors_and_offsets_preset(
			PRESET_FULL_RECT
		)


		host.offset_left = 0.0

		host.offset_top = 0.0

		host.offset_right = 0.0

		host.offset_bottom = 0.0


		# =====================================================
		# ROOT DENTRO DO HOST
		# =====================================================

		var root_value: Variant = (
			page_roots.get(
				key,
				null
			)
		)


		if not root_value is Control:

			continue


		var page_root: Control = (
			root_value
			as
			Control
		)


		page_root.set_anchors_and_offsets_preset(
			PRESET_FULL_RECT
		)


		page_root.offset_left = 0.0

		page_root.offset_top = 0.0

		page_root.offset_right = 0.0

		page_root.offset_bottom = 0.0


		page_root.mouse_filter = (
			Control.MOUSE_FILTER_PASS
		)


	# =========================================================
	# PÁGINA ACTIVA
	# =========================================================

	if not current_page.is_empty():

		if page_hosts.has(
			current_page
		):

			for key: Variant in page_hosts.keys():

				var host_value: Variant = (
					page_hosts.get(
						key,
						null
					)
				)


				if not host_value is Control:

					continue


				var host: Control = (
					host_value
					as
					Control
				)


				host.visible = (
					str(key)
					==
					current_page
				)


# =============================================================
# NOTIFY MODULES
# =============================================================

func notify_modules() -> void:

	for module: Object in responsive_modules:

		if module == null:

			continue


		if not is_instance_valid(
			module
		):

			continue


		if module.has_method(
			"set_responsive_mode"
		):

			module.call(
				"set_responsive_mode",
				current_mode
			)


# =============================================================
# CURRENT MODE
# =============================================================

func get_current_mode() -> LayoutMode:

	return current_mode


# =============================================================
# CURRENT PAGE
# =============================================================

func get_current_page() -> String:

	return current_page


# =============================================================
# RESIZE
#
# Epa, resize = recalcular.
# Nada de andar a mexer à posição dos botões.
# =============================================================

func _notification(
	what: int
) -> void:

	if what != NOTIFICATION_RESIZED:

		return


	if not is_inside_tree():

		return


	call_deferred(
		"refresh_layout"
	)


# =============================================================
# FORCE
# =============================================================

func force_refresh() -> void:

	last_width = -1.0


	call_deferred(
		"refresh_layout"
	)
