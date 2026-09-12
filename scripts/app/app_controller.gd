class_name CIGAAppController
extends Node


# =============================================================
# CIGA SYSTEMS
# APPLICATION CONTROLLER
# se isto vai á vida adues ya meu bro
# freaky eu sinto me freky
# =============================================================


var ui: CIGAUI


# =============================================================
# READY
# =============================================================

func _ready() -> void:

	print("")
	print("############################")
	print("APP CONTROLLER ESTÁ A EXECUTAR")
	print("############################")


	# =========================================================
	# PROTECÇÃO CONTRA DUPLICAÇÃO
	# =========================================================

	var existing_controllers: Array[Node] = (
		get_tree().get_nodes_in_group(
			"ciga_app_controller"
		)
	)


	if not existing_controllers.is_empty():

		for controller: Node in existing_controllers:

			if controller != self:

				print(
					"CIGA: OUTRO APP CONTROLLER JÁ EXISTE"
				)

				print(
					"CIGA: ESTE APP CONTROLLER SERÁ REMOVIDO"
				)

				queue_free()

				return


	add_to_group(
		"ciga_app_controller"
	)


	# =========================================================
	# CIGA UI
	# =========================================================

	ui = CIGAUI.new()

	ui.name = (
		"CIGAUI"
	)

	add_child(
		ui
	)


	# =========================================================
	# UI READY
	# =========================================================

	if not ui.application_started.is_connected(
		_on_ui_ready
	):

		ui.application_started.connect(
			_on_ui_ready
		)


	print(
		"CIGA UI INSTANCE CREATED"
	)


# =============================================================
# UI READY
# =============================================================

func _on_ui_ready() -> void:

	print(
		"CIGA APPLICATION READY"
	)

	print(
		"============================================================"
	)
