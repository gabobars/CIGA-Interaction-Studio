class_name CIGAPreview3D
extends Control


# =============================================================
# CIGA PREVIEW 3D
# Godot 4.7.2
#
# RESPONSABILIDADES
#
# - Preview 3D isolado
# - Character preview
# - Object preview
# - Instanciação a partir do cache central
# - Lançamento de ThrowableObject
# - Mesma trajetória do sistema principal
# - Mesma interacção física através de CIGAinteractionManager
#
#
# OBJECTOS
#
# O PREVIEW NÃO CARREGA GLB/GLTF.
#
# Fluxo:
#
#     CIGAObjects
#          |
#          v
#     prepare_object_for_startup()
#          |
#          v
#     get_cached_packed_scene()
#          |
#          v
#     PackedScene em RAM
#          |
#          v
#     CIGAPreview3D
#          |
#          v
#     instantiate()
#
# Isto significa:
#
# - nenhum GLTFDocument aqui
# - nenhum append_from_file()
# - nenhum import GLB durante uso
# - nenhum load() do objecto durante burst
#
# =============================================================


# =============================================================
# VIEWPORT
# =============================================================

var viewport_container: SubViewportContainer

var viewport: SubViewport


# =============================================================
# WORLD
# =============================================================

var stage: Node3D

var camera: Camera3D

var environment: WorldEnvironment

var light: DirectionalLight3D

var ground: MeshInstance3D


# =============================================================
# OBJECT MANAGER
# =============================================================

# CIGAObjects é RefCounted.
# NÃO é Node.
var object_manager: CIGAObjects = null


# =============================================================
# HOLDERS
# =============================================================

var character_holder: Node3D

var object_holder: Node3D

var launch_holder: Node3D


# =============================================================
# MODELS
# =============================================================

var character_model: Node3D

var object_model: Node3D


# =============================================================
# CHARACTER RUNTIME
# =============================================================

var character_runtime: CIGACharacterRuntime


# =============================================================
# INTERACTION MANAGER
# =============================================================

var interaction_manager: CIGAinteractionManager


# =============================================================
# PREVIEW OBJECT CACHE
#
# IMPORTANT:
#
# Este cache NÃO carrega recursos.
#
# Guarda apenas uma instância-template criada a partir do
# PackedScene central já carregado pelo CIGAObjects.
#
# source_path -> Node3D template
# =============================================================

var object_templates: Dictionary = {}

var object_cache_ready: Dictionary = {}


# =============================================================
# STATE
# =============================================================

var preview_name: String = ""

var active: bool = false

var current_object_path: String = ""

var current_object_scale: float = -1.0


# =============================================================
# CAMERA
# =============================================================

var camera_manual_mode: bool = false


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

var last_mouse_position: Vector2 = Vector2.ZERO


const CAMERA_ROTATE_SENSITIVITY: float = 0.003

const CAMERA_PAN_SENSITIVITY: float = 0.0015

const CAMERA_ZOOM_STEP: float = 0.12

const CAMERA_MIN_DISTANCE: float = 0.20

const CAMERA_MAX_DISTANCE: float = 100.0


# =============================================================
# SPAWN NODES
# =============================================================

var spawn_top_right: Marker3D

var spawn_right_high: Marker3D

var spawn_right_mid: Marker3D

var spawn_top_sky: Marker3D

var spawn_bottom_right: Marker3D

var spawn_front_stream: Marker3D


# =============================================================
# SPAWN CONTROL
# =============================================================

const SPAWN_TOP_RIGHT: Vector3 = Vector3(
	2.4,
	1.4,
	2.2
)


const SPAWN_RIGHT_HIGH: Vector3 = Vector3(
	2.6,
	0.8,
	2.2
)


const SPAWN_RIGHT_MID: Vector3 = Vector3(
	2.7,
	0.1,
	2.2
)


const SPAWN_TOP_SKY: Vector3 = Vector3(
	0.5,
	1.6,
	2.2
)


const SPAWN_BOTTOM_RIGHT: Vector3 = Vector3(
	2.5,
	-0.7,
	2.2
)


const SPAWN_FRONT_STREAM: Vector3 = Vector3(
	0.6,
	0.3,
	1.8
)


# =============================================================
# SETUP
# =============================================================

func setup(
	parent: Control,
	new_preview_name: String,
	height: float
) -> Control:

	preview_name = new_preview_name

	name = (
		new_preview_name
		+
		"_Preview"
	)

	custom_minimum_size = Vector2(
		0.0,
		height
	)

	size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	size_flags_vertical = (
		Control.SIZE_SHRINK_BEGIN
	)

	mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	visible = true


	if get_parent() == null:

		parent.add_child(
			self
		)


	viewport_container = (
		SubViewportContainer.new()
	)

	viewport_container.name = (
		preview_name
		+
		"_Container"
	)

	viewport_container.set_anchors_and_offsets_preset(
		PRESET_FULL_RECT
	)

	viewport_container.stretch = true

	viewport_container.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	add_child(
		viewport_container
	)


	viewport = SubViewport.new()

	viewport.name = (
		preview_name
		+
		"_Viewport"
	)

	viewport.size = Vector2i(
		1000,
		max(
			int(height * 2.0),
			500
		)
	)

	viewport.render_target_update_mode = (
		SubViewport.UPDATE_DISABLED
	)

	viewport.transparent_bg = false

	viewport.handle_input_locally = false

	viewport.world_3d = World3D.new()

	viewport_container.add_child(
		viewport
	)


	create_stage()

	create_interaction_manager()

	auto_resolve_object_manager()

	auto_resolve_character_runtime()

	set_active(
		false
	)


	# =========================================================
	# CHARACTER PREVIEW
	#
	# O runtime pode ainda estar a terminar de inicializar
	# quando o preview é criado.
	#
	# Por isso carregamos no frame seguinte.
	# =========================================================

	call_deferred(
		"auto_load_character_preview"
	)


	return self


# =============================================================
# OBJECT MANAGER
# =============================================================

func set_object_manager(
	new_manager: CIGAObjects
) -> void:

	object_manager = new_manager


# =============================================================
# AUTO RESOLVE OBJECT MANAGER
#
# O CIGAObjects não é Node.
# =============================================================

func auto_resolve_object_manager() -> void:

	if object_manager != null:

		return


	var tree := get_tree()

	if tree == null:

		return


	var current_scene := tree.current_scene

	if current_scene == null:

		return


	var ui_nodes := (
		current_scene.find_children(
			"*",
			"CIGAUI",
			true,
			false
		)
	)


	for node: Node in ui_nodes:

		if not node is CIGAUI:

			continue


		var ui := (
			node
			as
			CIGAUI
		)


		if ui.object_manager == null:

			continue


		object_manager = ui.object_manager

		return

# =============================================================
# AUTO RESOLVE CHARACTER RUNTIME
#
# Procura o CIGACharacterRuntime ativo na cena principal.
#
# O preview usa depois o personagem ativo desse runtime,
# incluindo o avatar nativo de calibração.
# =============================================================

func auto_resolve_character_runtime() -> void:

	if character_runtime != null:

		return


	var tree := get_tree()

	if tree == null:

		return


	var current_scene := tree.current_scene

	if current_scene == null:

		return


	var runtime_nodes := (
		current_scene.find_children(
			"*",
			"CIGACharacterRuntime",
			true,
			false
		)
	)


	for node: Node in runtime_nodes:

		if not node is CIGACharacterRuntime:

			continue


		character_runtime = (
			node
			as
			CIGACharacterRuntime
		)

		return
# =============================================================
# AUTO LOAD CHARACTER PREVIEW
#
# Carrega o personagem ativo do CIGACharacterRuntime.
#
# Isto permite que os previews de Objects e Interaction
# mostrem o mesmo avatar de calibração usado pelo sistema.
# =============================================================

func auto_load_character_preview() -> void:

	if character_runtime == null:

		auto_resolve_character_runtime()


	if character_runtime == null:

		return


	load_character(
		"",
		character_runtime
	)

# =============================================================
# CREATE INTERACTION MANAGER
# =============================================================

func create_interaction_manager() -> void:

	if interaction_manager != null:

		return


	interaction_manager = (
		CIGAinteractionManager.new()
	)

	interaction_manager.name = (
		"PreviewInteractionManager"
	)

	add_child(
		interaction_manager
	)


# =============================================================
# STAGE
# =============================================================

func create_stage() -> void:

	stage = Node3D.new()

	stage.name = (
		preview_name
		+
		"_Stage"
	)

	viewport.add_child(
		stage
	)


	# =========================================================
	# ENVIRONMENT
	# =========================================================

	environment = WorldEnvironment.new()

	var env: Environment = Environment.new()

	env.background_mode = (
		Environment.BG_COLOR
	)

	env.background_color = Color(
		"#070707"
	)

	env.ambient_light_source = (
		Environment.AMBIENT_SOURCE_COLOR
	)

	env.ambient_light_color = Color(
		"#777777"
	)

	env.ambient_light_energy = 0.9

	environment.environment = env

	stage.add_child(
		environment
	)


	# =========================================================
	# CAMERA
	# =========================================================

	camera = Camera3D.new()

	camera.name = (
		preview_name
		+
		"_Camera"
	)

	camera.current = true

	camera.fov = manual_camera_fov

	camera.near = 0.01

	camera.far = 1000.0

	stage.add_child(
		camera
	)


	# =========================================================
	# LIGHT
	# =========================================================

	light = DirectionalLight3D.new()

	light.rotation_degrees = Vector3(
		-35.0,
		-25.0,
		0.0
	)

	light.light_energy = 1.5

	stage.add_child(
		light
	)


	# =========================================================
	# GROUND
	# =========================================================

	ground = MeshInstance3D.new()

	var ground_mesh: PlaneMesh = PlaneMesh.new()

	ground_mesh.size = Vector2(
		20.0,
		20.0
	)

	ground.mesh = ground_mesh

	stage.add_child(
		ground
	)


	# =========================================================
	# HOLDERS
	# =========================================================

	character_holder = Node3D.new()

	character_holder.name = (
		"CharacterHolder"
	)

	stage.add_child(
		character_holder
	)


	object_holder = Node3D.new()

	object_holder.name = (
		"ObjectHolder"
	)

	stage.add_child(
		object_holder
	)


	launch_holder = Node3D.new()

	launch_holder.name = (
		"LaunchHolder"
	)

	stage.add_child(
		launch_holder
	)


	create_spawn_nodes()


# =============================================================
# SPAWN NODES
# =============================================================

func create_spawn_nodes() -> void:

	spawn_top_right = Marker3D.new()

	spawn_top_right.name = (
		"SpawnTopRight"
	)

	stage.add_child(
		spawn_top_right
	)


	spawn_right_high = Marker3D.new()

	spawn_right_high.name = (
		"SpawnRightHigh"
	)

	stage.add_child(
		spawn_right_high
	)


	spawn_right_mid = Marker3D.new()

	spawn_right_mid.name = (
		"SpawnRightMid"
	)

	stage.add_child(
		spawn_right_mid
	)


	spawn_top_sky = Marker3D.new()

	spawn_top_sky.name = (
		"SpawnTopSky"
	)

	stage.add_child(
		spawn_top_sky
	)


	spawn_bottom_right = Marker3D.new()

	spawn_bottom_right.name = (
		"SpawnBottomRight"
	)

	stage.add_child(
		spawn_bottom_right
	)


	spawn_front_stream = Marker3D.new()

	spawn_front_stream.name = (
		"SpawnFrontStream"
	)

	stage.add_child(
		spawn_front_stream
	)


	update_spawn_positions()


# =============================================================
# UPDATE SPAWN POSITIONS
# =============================================================

func update_spawn_positions() -> void:

	if camera == null:

		return


	if spawn_top_right == null:

		return


	if spawn_right_high == null:

		return


	if spawn_right_mid == null:

		return


	if spawn_top_sky == null:

		return


	if spawn_bottom_right == null:

		return


	if spawn_front_stream == null:

		return


	spawn_top_right.global_position = (
		camera.to_global(
			SPAWN_TOP_RIGHT
		)
	)

	spawn_right_high.global_position = (
		camera.to_global(
			SPAWN_RIGHT_HIGH
		)
	)

	spawn_right_mid.global_position = (
		camera.to_global(
			SPAWN_RIGHT_MID
		)
	)

	spawn_top_sky.global_position = (
		camera.to_global(
			SPAWN_TOP_SKY
		)
	)

	spawn_bottom_right.global_position = (
		camera.to_global(
			SPAWN_BOTTOM_RIGHT
		)
	)

	spawn_front_stream.global_position = (
		camera.to_global(
			SPAWN_FRONT_STREAM
		)
	)


# =============================================================
# ACTIVE
# =============================================================

func set_active(
	value: bool
) -> void:

	active = value

	visible = true

	if viewport == null:

		return

	if active:

		viewport.render_target_update_mode = (
			SubViewport.UPDATE_ALWAYS
		)

	else:

		viewport.render_target_update_mode = (
			SubViewport.UPDATE_DISABLED
		)


# =============================================================
# CHARACTER LOAD
# =============================================================

func load_character(
	_path: String,
	runtime: CIGACharacterRuntime
) -> bool:

	if runtime == null:

		return false


	character_runtime = runtime


	var loaded_character: Node3D = (
		runtime.get_active_character()
	)


	if loaded_character == null:

		clear_character()

		return false


	var loaded_path: String = (
		runtime.get_active_character_path()
	)


	var is_native_character: bool = (
		runtime.is_active_character_native()
	)


	# =========================================================
	# SOURCE
	#
	# IMPORTED:
	#     usamos o path.
	#
	# NATIVE:
	#     usamos o active_character directamente e fazemos
	#     uma cópia para o preview.
	# =========================================================

	var preview_source: String = ""


	if is_native_character:

		preview_source = (
			"__ciga_native_calibration__"
		)

	else:

		preview_source = (
			loaded_path
		)


	# =========================================================
	# JÁ ESTÁ NO PREVIEW
	# =========================================================

	if (
		character_model != null
		and
		is_instance_valid(
			character_model
		)
	):

		var current_source: String = str(
			character_model.get_meta(
				"ciga_source_path",
				""
			)
		)


		if current_source == preview_source:

			if interaction_manager != null:

				interaction_manager.set_character(
					character_model
				)

				interaction_manager.set_hit_points(
					character_model
				)

			return true


	clear_character()


	# =========================================================
	# INSTANCE
	# =========================================================

	var instance: Node3D = null


	# =========================================================
	# NATIVE CIGA CALIBRATION AVATAR
	# =========================================================
	#
	# IMPORTANTE:
	#
	# O .cigaavatar NÃO é uma PackedScene.
	#
	# O Runtime já construiu o CIGACalibrationAvatar.
	#
	# Portanto fazemos uma cópia desse Node3D directamente.
	# =========================================================

	if is_native_character:

		var duplicate_value: Variant = (
			loaded_character.duplicate(
				true
			)
		)


		if duplicate_value is Node3D:

			instance = (
				duplicate_value
				as
				Node3D
			)


	# =========================================================
	# IMPORTED CHARACTER
	# =========================================================

	else:

		if loaded_path.is_empty():

			return false


		instance = (
			runtime.instantiate_character(
				loaded_path
			)
		)


	if instance == null:

		return false


	# =========================================================
	# CHARACTER MODEL
	# =========================================================

	character_model = instance


	character_model.set_meta(
		"ciga_source_path",
		preview_source
	)


	character_model.position = Vector3.ZERO

	character_model.rotation = Vector3.ZERO

	character_model.scale = Vector3.ONE


	character_holder.add_child(
		character_model
	)


	# =========================================================
	# INTERACTION MANAGER
	# =========================================================

	if interaction_manager != null:

		interaction_manager.set_character(
			character_model
		)

		interaction_manager.set_hit_points(
			character_model
		)


	# =========================================================
	# HITPOINTS
	# =========================================================

	restore_preview_hitpoints()


	# =========================================================
	# FINALIZE
	# =========================================================

	call_deferred(
		"finalize_character"
	)


	return true

# =============================================================
# RESTORE HITPOINTS
# =============================================================

func restore_preview_hitpoints() -> void:

	if character_model == null:

		return


	if character_runtime == null:

		return


	var bone_map: Dictionary = (
		character_runtime.get_active_bone_map()
	)


	if bone_map.is_empty():

		return


	var preview_skeleton: Skeleton3D = (
		character_runtime.find_skeleton(
			character_model
		)
	)


	if preview_skeleton == null:

		return


	for hitpoint_value: Variant in bone_map.keys():

		var hitpoint_name: String = str(
			hitpoint_value
		)

		var bone_name: String = str(
			bone_map[hitpoint_value]
		)


		if hitpoint_name.is_empty():

			continue


		if bone_name.is_empty():

			continue


		character_runtime.create_hit_point(
			character_model,
			preview_skeleton,
			hitpoint_name,
			bone_name
		)


# =============================================================
# CHARACTER FINALIZE
# =============================================================

func finalize_character() -> void:

	if character_model == null:

		return


	center_character_on_ground()

	frame_camera_to_character()

	update_spawn_positions()


# =============================================================
# CLEAR CHARACTER
# =============================================================

func clear_character() -> void:

	if interaction_manager != null:

		interaction_manager.set_character(
			null
		)


	if character_model != null:

		if is_instance_valid(
			character_model
		):

			character_model.queue_free()


	character_model = null


# =============================================================
# OBJECT PATH -> OBJECT ID
#
# Aceita:
#
# source_path
# optimized_path
#
# e resolve sempre para o object_id central.
# =============================================================

func get_object_id_from_path(
	path: String
) -> String:

	if path.is_empty():

		return ""


	if object_manager == null:

		auto_resolve_object_manager()


	if object_manager == null:

		return ""


	for object_data: Dictionary in object_manager.objects:

		var object_id: String = str(
			object_data.get(
				"id",
				""
			)
		)


		if object_id.is_empty():

			continue


		var source_path: String = str(
			object_data.get(
				"source_path",
				""
			)
		)


		var optimized_path: String = str(
			object_data.get(
				"optimized_path",
				""
			)
		)


		if path == source_path:

			return object_id


		if path == optimized_path:

			return object_id


	return ""


# =============================================================
# OBJECT ID -> PREVIEW TEMPLATE
#
# IMPORTANTE:
#
# Esta função NÃO faz load().
#
# O PackedScene já deve existir no CIGAObjects.
#
# Se existir no cache global:
#
#     PackedScene.instantiate()
#
# Se não existir:
#
#     falha.
#
# Não existe fallback GLTF aqui.
# =============================================================

func ensure_object_cached(
	path: String
) -> Node3D:

	if path.is_empty():

		return null


	# =========================================================
	# CACHE LOCAL HIT
	# =========================================================

	if object_templates.has(
		path
	):

		var cached_value: Variant = (
			object_templates[path]
		)


		if cached_value is Node3D:

			var cached_model: Node3D = (
				cached_value
				as
				Node3D
			)


			if is_instance_valid(
				cached_model
			):

				return cached_model


		object_templates.erase(
			path
		)

		object_cache_ready.erase(
			path
		)


	# =========================================================
	# MANAGER
	# =========================================================

	if object_manager == null:

		auto_resolve_object_manager()


	if object_manager == null:

		return null


	# =========================================================
	# OBJECT ID
	# =========================================================

	var object_id: String = (
		get_object_id_from_path(
			path
		)
	)


	if object_id.is_empty():

		return null


	# =========================================================
	# GLOBAL PACKED SCENE CACHE
	# =========================================================

	var packed_scene: PackedScene = (
		object_manager.get_cached_packed_scene(
			object_id
		)
	)


	if packed_scene == null:

		return null


	# =========================================================
	# INSTANTIATE TEMPLATE
	# =========================================================

	var instance: Node = (
		packed_scene.instantiate()
	)


	if instance == null:

		return null


	if not instance is Node3D:

		instance.queue_free()

		return null


	var model: Node3D = (
		instance
		as
		Node3D
	)


	_fix_model_materials(
		model
	)


	model.visible = false

	model.process_mode = (
		Node.PROCESS_MODE_DISABLED
	)


	model.set_meta(
		"ciga_preview_template",
		true
	)


	model.set_meta(
		"ciga_object_id",
		object_id
	)


	model.set_meta(
		"ciga_source_path",
		str(
			object_manager.get_object_path(
				object_id
			)
		)
	)


	model.set_meta(
		"ciga_load_path",
		str(
			object_manager.get_object_load_path(
				object_id
			)
		)
)

	object_templates[path] = model

	object_cache_ready[path] = true


	return model


# =============================================================
# PREWARM OBJECT PATHS
#
# Usado pelo BOOT, não pelo utilizador.
# =============================================================

func preload_object_paths(
	paths: Array
) -> void:

	var prepared_count: int = 0


	for value: Variant in paths:

		var path: String = str(
			value
		)


		if path.is_empty():

			continue


		var template: Node3D = (
			ensure_object_cached(
				path
			)
		)


		if template != null:

			prepared_count += 1


		await get_tree().process_frame


# =============================================================
# CACHE OBJECT WITH LOADING
#
# Mantido apenas por compatibilidade.
#
# Não faz qualquer importação própria.
# =============================================================

func ensure_object_cached_with_loading(
	path: String
) -> Node3D:

	if path.is_empty():

		return null


	# =========================================================
	# CACHE HIT
	# =========================================================

	if object_templates.has(
		path
	):

		var existing_value: Variant = (
			object_templates[path]
		)


		if existing_value is Node3D:

			var existing: Node3D = (
				existing_value
				as
				Node3D
			)


			if is_instance_valid(
				existing
			):

				return existing


	# =========================================================
	# NÃO HÁ FALLBACK DE IMPORTAÇÃO
	#
	# O boot deve ter preparado isto.
	# =========================================================

	return ensure_object_cached(
		path
	)


# =============================================================
# GET CACHED OBJECT
# =============================================================

func get_cached_object(
	path: String
) -> Node3D:

	return ensure_object_cached(
		path
	)


# =============================================================
# LOAD OBJECT
#
# IMPORTANTE:
#
# A escala final NÃO é confiada ao argumento scale_value.
#
# O argumento existe apenas por compatibilidade com código
# antigo que ainda chama:
#
#     load_object(path, scale)
#
# A verdadeira fonte da escala é:
#
#     CIGAObjects
#          +
#     CIGAProfiles
#
# FINAL:
#
#     base_scale × profile_multiplier
#
# Isto impede que uma mudança de profile volte a injectar
# SCALE=1.0 no preview.
# =============================================================

func load_object(
	path: String,
	scale_value: float = -1.0
) -> void:

	if object_holder == null:

		return


	if path.is_empty():

		clear_object()

		return


	if object_manager == null:

		auto_resolve_object_manager()


	var object_id := (
		get_object_id_from_path(
			path
		)
	)


	# =========================================================
	# RESOLVE FINAL SCALE
	#
	# PRIORIDADE:
	#
	# 1. escala explícita recebida
	# 2. CIGAObjects
	# 3. object data
	#
	# A UI pode portanto passar directamente:
	#
	#     base_scale × multiplier
	#
	# sem a preview recalcular outra vez.
	# =========================================================

	var safe_scale: float = -1.0


	if (
		scale_value > 0.0
		and
		is_finite(
			scale_value
		)
	):

		safe_scale = (
			scale_value
		)


	# =========================================================
	# FALLBACK OBJECT MANAGER
	# =========================================================

	if safe_scale <= 0.0:

		if (
			object_manager != null
			and
			not object_id.is_empty()
		):

			safe_scale = (
				object_manager.get_effective_object_scale(
					object_id
				)
			)


	# =========================================================
	# FALLBACK OBJECT SCALE
	# =========================================================

	if safe_scale <= 0.0:

		if (
			object_manager != null
			and
			not object_id.is_empty()
		):

			safe_scale = (
				object_manager.get_object_scale(
					object_id
				)
			)


	# =========================================================
	# FALLBACK OBJECT DATA
	# =========================================================

	if safe_scale <= 0.0:

		if (
			object_manager != null
			and
			not object_id.is_empty()
		):

			var managed_object := (
				object_manager.get_object(
					object_id
				)
			)


			if not managed_object.is_empty():

				safe_scale = float(
					managed_object.get(
						"effective_scale",
						managed_object.get(
							"scale",
							0.0
						)
					)
				)


	# =========================================================
	# FALLBACK BASE × MULTIPLIER
	# =========================================================

	if safe_scale <= 0.0:

		if (
			object_manager != null
			and
			not object_id.is_empty()
		):

			var managed_object := (
				object_manager.get_object(
					object_id
				)
			)


			if not managed_object.is_empty():

				var base_scale := float(
					managed_object.get(
						"base_scale",
						CIGAObjects.DEFAULT_OBJECT_SCALE
					)
				)


				var multiplier := float(
					managed_object.get(
						"scale_multiplier",
						CIGAObjects.DEFAULT_SCALE_MULTIPLIER
					)
				)


				if not is_finite(
					base_scale
				):

					base_scale = (
						CIGAObjects.DEFAULT_OBJECT_SCALE
					)


				if not is_finite(
					multiplier
				):

					multiplier = (
						CIGAObjects.DEFAULT_SCALE_MULTIPLIER
					)


				safe_scale = (
					base_scale
					*
					multiplier
				)


	# =========================================================
	# LEGACY FALLBACK
	# =========================================================

	if safe_scale <= 0.0:

		safe_scale = float(
			CIGAObjects.DEFAULT_OBJECT_SCALE
		)


	if not is_finite(
		safe_scale
	):

		safe_scale = (
			CIGAObjects.DEFAULT_OBJECT_SCALE
		)


	safe_scale = maxf(
		safe_scale,
		CIGAObjects.MIN_OBJECT_SCALE
	)


	# =========================================================
	# JÁ CARREGADO
	# =========================================================

	if (
		path == current_object_path
		and
		object_model != null
		and
		is_instance_valid(
			object_model
		)
	):

		current_object_scale = (
			safe_scale
		)


		object_model.scale = (
			Vector3.ONE
			*
			safe_scale
		)


		object_model.visible = true

		object_model.process_mode = (
			Node.PROCESS_MODE_INHERIT
		)


		center_object_on_ground(
			object_model
		)


		return


	# =========================================================
	# CLEAR
	# =========================================================

	clear_object()


	# =========================================================
	# CACHE
	# =========================================================

	var template: Node3D = (
		ensure_object_cached(
			path
		)
	)


	if template == null:

		return


	# =========================================================
	# DUPLICATE
	# =========================================================

	var duplicate_value: Variant = (
		template.duplicate(
			true
		)
	)


	if not duplicate_value is Node3D:

		return


	object_model = (
		duplicate_value
		as
		Node3D
	)


	object_model.name = (
		"ObjectModel"
	)


	# =========================================================
	# VISIBILITY
	# =========================================================

	object_model.visible = true

	object_model.process_mode = (
		Node.PROCESS_MODE_INHERIT
	)


	# =========================================================
	# SCALE
	# =========================================================

	object_model.scale = (
		Vector3.ONE
		*
		safe_scale
	)


	# =========================================================
	# ADD
	# =========================================================

	object_holder.add_child(
		object_model
	)


	current_object_path = (
		path
	)

	current_object_scale = (
		safe_scale
	)


	call_deferred(
		"finalize_object"
	)


# =============================================================
# FINALIZE OBJECT
# =============================================================

func finalize_object() -> void:

	if object_model == null:

		return


	object_model.visible = true

	object_model.process_mode = (
		Node.PROCESS_MODE_INHERIT
	)


	center_object_on_ground(
		object_model
	)


	if character_model == null:

		frame_camera()


	update_spawn_positions()


# =============================================================
# CLEAR OBJECT
# =============================================================

func clear_object() -> void:

	if object_model != null:

		if is_instance_valid(
			object_model
		):

			object_model.queue_free()


	object_model = null

	current_object_path = ""

	current_object_scale = -1.0


# =============================================================
# CLEAR LAUNCH OBJECTS
# =============================================================

func clear_launch_objects() -> void:

	if launch_holder == null:

		return


	for child: Node in launch_holder.get_children():

		if is_instance_valid(
			child
		):

			child.queue_free()


# =============================================================
# CENTER OBJECT
# =============================================================

func center_object_on_ground(
	model: Node3D
) -> void:

	if model == null:

		return


	model.position = Vector3.ZERO


	var bounds: AABB = (
		calculate_bounds(
			model
		)
	)


	if bounds.size == Vector3.ZERO:

		return


	model.position.x -= (
		bounds.position.x
		+
		bounds.size.x
		*
		0.5
	)


	model.position.z -= (
		bounds.position.z
		+
		bounds.size.z
		*
		0.5
	)


	bounds = calculate_bounds(
		model
	)


	if bounds.size != Vector3.ZERO:

		model.position.y -= (
			bounds.position.y
		)


# =============================================================
# CENTER CHARACTER
# =============================================================

func center_character_on_ground() -> void:

	if character_model == null:

		return


	var bounds: AABB = (
		calculate_bounds(
			character_model
		)
	)


	if bounds.size == Vector3.ZERO:

		return


	character_model.position.x -= (
		bounds.position.x
		+
		bounds.size.x
		*
		0.5
	)


	character_model.position.z -= (
		bounds.position.z
		+
		bounds.size.z
		*
		0.5
	)


	bounds = calculate_bounds(
		character_model
	)


	if bounds.size != Vector3.ZERO:

		character_model.position.y -= (
			bounds.position.y
		)


# =============================================================
# FRAME CAMERA
# =============================================================

func frame_camera() -> void:

	if camera == null:

		return


	camera_manual_mode = false


	var bounds: AABB = (
		calculate_display_bounds()
	)


	if bounds.size == Vector3.ZERO:

		camera_target = Vector3(
			0.0,
			1.0,
			0.0
		)

		camera.position = Vector3(
			0.0,
			1.5,
			4.0
		)

		camera.look_at(
			camera_target,
			Vector3.UP
		)

		update_spawn_positions()

		return


	frame_camera_to_bounds(
		bounds
	)


	update_spawn_positions()


# =============================================================
# FRAME CHARACTER
# =============================================================

func frame_camera_to_character() -> void:

	if camera == null:

		return


	if character_model == null:

		return


	var bounds: AABB = (
		calculate_bounds(
			character_model
		)
	)


	if bounds.size == Vector3.ZERO:

		return


	frame_camera_to_bounds(
		bounds
	)


	update_spawn_positions()


# =============================================================
# FRAME BOUNDS
# =============================================================

func frame_camera_to_bounds(
	bounds: AABB
) -> void:

	if camera == null:

		return


	var width: float = maxf(
		bounds.size.x,
		0.001
	)


	var height: float = maxf(
		bounds.size.y,
		0.001
	)


	var depth: float = maxf(
		bounds.size.z,
		0.001
	)


	camera_target = (
		bounds.position
		+
		bounds.size
		*
		0.5
	)


	var vertical_fov: float = deg_to_rad(
		camera.fov
	)


	var distance: float = (
		height
		*
		0.5
		/
		tan(
			vertical_fov
			*
			0.5
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


	camera.position = Vector3(
		camera_target.x,
		camera_target.y,
		camera_target.z + distance
	)


	camera.look_at(
		camera_target,
		Vector3.UP
	)


	manual_camera_position = (
		camera.position
	)

	manual_camera_fov = (
		camera.fov
	)


	update_spawn_positions()


# =============================================================
# DISPLAY BOUNDS
# =============================================================

func calculate_display_bounds() -> AABB:

	if character_model != null:

		return calculate_bounds(
			character_model
		)


	if object_model != null:

		return calculate_bounds(
			object_model
		)


	return AABB()


# =============================================================
# BOUNDS
# =============================================================

func calculate_bounds(
	root: Node3D
) -> AABB:

	var result: AABB = AABB()

	var found: bool = false


	if root == null:

		return result


	var nodes: Array[Node] = (
		root.find_children(
			"*",
			"MeshInstance3D",
			true,
			false
		)
	)


	for node: Node in nodes:

		if not node is MeshInstance3D:

			continue


		var mesh_instance: MeshInstance3D = (
			node
			as
			MeshInstance3D
		)


		if mesh_instance.mesh == null:

			continue


		var local_bounds: AABB = (
			mesh_instance.mesh.get_aabb()
		)


		var transformed_bounds: AABB = (
			transform_aabb(
				local_bounds,
				mesh_instance.global_transform
			)
		)


		if not found:

			result = transformed_bounds

			found = true

		else:

			result = result.merge(
				transformed_bounds
			)


	if not found:

		return AABB(
			Vector3.ZERO,
			Vector3.ZERO
		)


	return result


# =============================================================
# TRANSFORM AABB
# =============================================================

func transform_aabb(
	aabb: AABB,
	transform: Transform3D
) -> AABB:

	var points: Array[Vector3] = [

		Vector3(
			aabb.position.x,
			aabb.position.y,
			aabb.position.z
		),

		Vector3(
			aabb.end.x,
			aabb.position.y,
			aabb.position.z
		),

		Vector3(
			aabb.position.x,
			aabb.end.y,
			aabb.position.z
		),

		Vector3(
			aabb.end.x,
			aabb.end.y,
			aabb.position.z
		),

		Vector3(
			aabb.position.x,
			aabb.position.y,
			aabb.end.z
		),

		Vector3(
			aabb.end.x,
			aabb.position.y,
			aabb.end.z
		),

		Vector3(
			aabb.position.x,
			aabb.end.y,
			aabb.end.z
		),

		Vector3(
			aabb.end.x,
			aabb.end.y,
			aabb.end.z
		)
	]


	var result: AABB = AABB()

	var initialized: bool = false


	for point: Vector3 in points:

		var transformed: Vector3 = (
			transform
			*
			point
		)


		if not initialized:

			result = AABB(
				transformed,
				Vector3.ZERO
			)

			initialized = true

		else:

			result = result.merge(
				AABB(
					transformed,
					Vector3.ZERO
				)
			)


	return result


# =============================================================
# CAMERA TARGET
# =============================================================

func get_camera_target() -> Vector3:

	return camera_target


# =============================================================
# CAMERA POSITION
# =============================================================

func get_camera_position() -> Vector3:

	if camera == null:

		return Vector3(
			0.0,
			1.5,
			4.0
		)


	return camera.position


# =============================================================
# CAMERA FOV
# =============================================================

func get_camera_fov() -> float:

	if camera == null:

		return 42.0


	return camera.fov


# =============================================================
# MANUAL CAMERA
# =============================================================

func set_camera_manual(
	x: float,
	y: float,
	z: float,
	fov_value: float
) -> void:

	if camera == null:

		return


	camera_manual_mode = true


	camera.position = Vector3(
		x,
		y,
		z
	)


	camera.fov = clampf(
		fov_value,
		10.0,
		120.0
	)


	camera.look_at(
		camera_target,
		Vector3.UP
	)


	manual_camera_position = (
		camera.position
	)

	manual_camera_fov = (
		camera.fov
	)


	update_spawn_positions()


# =============================================================
# ZOOM
# =============================================================

func zoom_camera(
	amount: float
) -> void:

	if camera == null:

		return


	var offset: Vector3 = (
		camera.global_position
		-
		camera_target
	)


	if offset.length() <= 0.001:

		offset = Vector3(
			0.0,
			0.0,
			1.0
		)


	var distance: float = (
		offset.length()
	)


	var zoom_amount: float = (
		distance
		*
		CAMERA_ZOOM_STEP
	)


	distance += (
		amount
		*
		zoom_amount
	)


	distance = clampf(
		distance,
		CAMERA_MIN_DISTANCE,
		CAMERA_MAX_DISTANCE
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


	camera_manual_mode = true


	manual_camera_position = (
		camera.position
	)

	manual_camera_fov = (
		camera.fov
	)


	update_spawn_positions()


# =============================================================
# ORBIT
# =============================================================

func orbit_camera(
	mouse_delta: Vector2
) -> void:

	if camera == null:

		return


	var offset: Vector3 = (
		camera.global_position
		-
		camera_target
	)


	if offset.length() <= 0.001:

		offset = Vector3(
			0.0,
			0.0,
			1.0
		)


	offset = (
		Basis(
			Vector3.UP,
			-mouse_delta.x
			*
			CAMERA_ROTATE_SENSITIVITY
		)
		*
		offset
	)


	var right: Vector3 = (
		camera.global_transform
		.basis
		.x
	)


	offset = (
		Basis(
			right,
			-mouse_delta.y
			*
			CAMERA_ROTATE_SENSITIVITY
		)
		*
		offset
	)


	camera.global_position = (
		camera_target
		+
		offset.normalized()
		*
		offset.length()
	)


	camera.look_at(
		camera_target,
		Vector3.UP
	)


	camera_manual_mode = true


	update_spawn_positions()


# =============================================================
# PAN
# =============================================================

func pan_camera(
	mouse_delta: Vector2
) -> void:

	if camera == null:

		return


	var distance: float = (
		camera.global_position
		.distance_to(
			camera_target
		)
	)


	var amount: float = (
		distance
		*
		CAMERA_PAN_SENSITIVITY
	)


	var right: Vector3 = (
		camera.global_transform
		.basis
		.x
	)


	var up: Vector3 = (
		camera.global_transform
		.basis
		.y
	)


	var movement: Vector3 = (
		-right
		*
		mouse_delta.x
		*
		amount
	)


	movement += (
		up
		*
		mouse_delta.y
		*
		amount
	)


	camera.global_position += movement

	camera_target += movement


	camera.look_at(
		camera_target,
		Vector3.UP
	)


	camera_manual_mode = true


	update_spawn_positions()


# =============================================================
# MOUSE INPUT
# =============================================================

func _gui_input(
	event: InputEvent
) -> void:

	if camera == null:

		return


	if event is InputEventMouseButton:

		var button: InputEventMouseButton = (
			event
			as
			InputEventMouseButton
		)


		if button.pressed:

			match button.button_index:

				MOUSE_BUTTON_WHEEL_UP:

					zoom_camera(
						-1.0
					)

					accept_event()

					return


				MOUSE_BUTTON_WHEEL_DOWN:

					zoom_camera(
						1.0
					)

					accept_event()

					return


				MOUSE_BUTTON_RIGHT:

					camera_dragging = true

					last_mouse_position = (
						button.position
					)


					if (
						button.get_modifiers_mask()
						&
						KEY_MASK_CTRL
					) != 0:

						camera_drag_mode = 1

					else:

						camera_drag_mode = 0


					accept_event()

					return


		else:

			if (
				button.button_index
				==
				MOUSE_BUTTON_RIGHT
			):

				camera_dragging = false

				accept_event()

				return


	if event is InputEventMouseMotion:

		var motion: InputEventMouseMotion = (
			event
			as
			InputEventMouseMotion
		)


		if not camera_dragging:

			return


		var mouse_delta: Vector2 = (
			motion.position
			-
			last_mouse_position
		)


		last_mouse_position = (
			motion.position
		)


		if camera_drag_mode == 0:

			orbit_camera(
				mouse_delta
			)

		else:

			pan_camera(
				mouse_delta
			)


		accept_event()


# =============================================================
# TARGET FALLBACK
# =============================================================

func get_target_position(
	target_name: String
) -> Vector3:

	match target_name:

		"HEAD":

			return Vector3(
				0.0,
				2.2,
				0.0
			)


		"CHEST":

			return Vector3(
				0.0,
				1.45,
				0.0
			)


		"LEFT SHOULDER":

			return Vector3(
				-0.65,
				1.7,
				0.0
			)


		"RIGHT SHOULDER":

			return Vector3(
				0.65,
				1.7,
				0.0
			)


		"LEFT ARM":

			return Vector3(
				-0.95,
				1.15,
				0.0
			)


		"RIGHT ARM":

			return Vector3(
				0.95,
				1.15,
				0.0
			)


		"LEFT LEG":

			return Vector3(
				-0.35,
				0.45,
				0.0
			)


		"RIGHT LEG":

			return Vector3(
				0.35,
				0.45,
				0.0
			)


		_:

			return Vector3(
				0.0,
				1.2,
				0.0
			)


# =============================================================
# HITPOINT POSITION
# =============================================================

func get_hit_point_position(
	hit_point_name: String
) -> Vector3:

	if character_model == null:

		return Vector3.INF


	if character_runtime == null:

		return Vector3.INF


	var hitpoint: Node3D = (
		character_runtime.get_hit_point(
			character_model,
			hit_point_name
		)
	)


	if hitpoint == null:

		return Vector3.INF


	return hitpoint.global_position


# =============================================================
# TARGET -> HITPOINT
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


		_:

			return "ChestHitPoint"


# =============================================================
# RESOLVE TARGET
# =============================================================

func resolve_target_position(
	target_name: String
) -> Vector3:

	var hitpoint_name: String = (
		target_to_hitpoint(
			target_name
		)
	)


	var hitpoint_position: Vector3 = (
		get_hit_point_position(
			hitpoint_name
		)
	)


	if not hitpoint_position.is_finite():

		return get_target_position(
			target_name
		)


	return hitpoint_position


# =============================================================
# SPAWN NODE
# =============================================================

func get_spawn_node(
	spawn_name: String
) -> Marker3D:

	var normalized: String = (
		spawn_name
		.to_upper()
		.strip_edges()
	)


	if (
		normalized == "TOP_RIGHT"
		or
		normalized == "TOPRIGHT"
		or
		normalized == "UP_RIGHT"
	):

		return spawn_top_right


	if (
		normalized == "RIGHT_HIGH"
		or
		normalized == "RIGHTHIGH"
	):

		return spawn_right_high


	if (
		normalized == "RIGHT_MID"
		or
		normalized == "RIGHT"
		or
		normalized == "SIDE"
	):

		return spawn_right_mid


	if (
		normalized == "TOP_SKY"
		or
		normalized == "TOP"
		or
		normalized == "SKY"
	):

		return spawn_top_sky


	if (
		normalized == "BOTTOM_RIGHT"
		or
		normalized == "BOTTOMRIGHT"
	):

		return spawn_bottom_right


	if (
		normalized == "FRONT_STREAM"
		or
		normalized == "FRONT"
		or
		normalized == "CENTER"
		or
		normalized == "NORTH"
	):

		return spawn_front_stream


	if normalized == "SOUTH":

		return spawn_bottom_right


	if normalized == "EAST":

		return spawn_right_mid


	if normalized == "WEST":

		return spawn_top_right


	var choices: Array[Marker3D] = [

		spawn_top_right,
		spawn_right_high,
		spawn_right_mid,
		spawn_top_sky,
		spawn_bottom_right,
		spawn_front_stream
	]


	return choices.pick_random()


# =============================================================
# SPAWN POSITION
# =============================================================

func get_test_spawn_position(
	spawn_name: String
) -> Vector3:

	var spawn_node: Marker3D = (
		get_spawn_node(
			spawn_name
		)
	)


	if spawn_node != null:

		return spawn_node.global_position


	return Vector3(
		0.0,
		1.5,
		2.2
	)


# =============================================================
# RESOLVE OBJECT SCALE FOR BURST
#
# CIGAObjects é SEMPRE a fonte de verdade.
#
# FINAL:
#
#     base_scale × active_profile_multiplier
#
# Nunca usamos directamente object_data["scale"] antes
# de consultar o Object Manager.
# =============================================================

func get_burst_object_scale(
	object_data: Dictionary
) -> float:

	if object_data.is_empty():

		return (
			CIGAObjects.DEFAULT_OBJECT_SCALE
		)


	var object_id := str(
		object_data.get(
			"id",
			""
		)
	)


	# =========================================================
	# OBJECT MANAGER
	# =========================================================

	if object_manager == null:

		auto_resolve_object_manager()


	if (
		object_manager != null
		and
		not object_id.is_empty()
	):

		var effective_scale := (
			object_manager.get_effective_object_scale(
				object_id
			)
		)


		if (
			is_finite(
				effective_scale
			)
			and
			effective_scale > 0.0
		):

			return maxf(
				effective_scale,
				CIGAObjects.MIN_OBJECT_SCALE
			)


	# =========================================================
	# OBJECT MANAGER PUBLIC OBJECT
	# =========================================================

	if (
		object_manager != null
		and
		not object_id.is_empty()
	):

		var managed_object := (
			object_manager.get_object(
				object_id
			)
		)


		if not managed_object.is_empty():

			var managed_effective := float(
				managed_object.get(
					"effective_scale",
					0.0
				)
			)


			if (
				is_finite(
					managed_effective
				)
				and
				managed_effective > 0.0
			):

				return maxf(
					managed_effective,
					CIGAObjects.MIN_OBJECT_SCALE
				)


	# =========================================================
	# FALLBACK: EXPLICIT EFFECTIVE SCALE
	# =========================================================

	if object_data.has(
		"effective_scale"
	):

		var explicit_effective := float(
			object_data.get(
				"effective_scale",
				0.0
			)
		)


		if (
			is_finite(
				explicit_effective
			)
			and
			explicit_effective > 0.0
		):

			return maxf(
				explicit_effective,
				CIGAObjects.MIN_OBJECT_SCALE
			)


	# =========================================================
	# FALLBACK: BASE × MULTIPLIER
	# =========================================================

	var base_scale := float(
		object_data.get(
			"base_scale",
			CIGAObjects.DEFAULT_OBJECT_SCALE
		)
	)


	var multiplier := float(
		object_data.get(
			"scale_multiplier",
			CIGAObjects.DEFAULT_SCALE_MULTIPLIER
		)
	)


	if not is_finite(
		base_scale
	):

		base_scale = (
			CIGAObjects.DEFAULT_OBJECT_SCALE
		)


	if not is_finite(
		multiplier
	):

		multiplier = (
			CIGAObjects.DEFAULT_SCALE_MULTIPLIER
		)


	base_scale = maxf(
		base_scale,
		CIGAObjects.MIN_OBJECT_SCALE
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


	return maxf(
		final_scale,
		CIGAObjects.MIN_OBJECT_SCALE
	)


# =============================================================
# LAUNCH BURST
# =============================================================

func launch_burst(
	launches: Array
) -> void:

	if launch_holder == null:

		return


	if launches.is_empty():

		return


	clear_launch_objects()

	update_spawn_positions()


	var total: int = (
		launches.size()
	)


	for launch_data_value: Variant in launches:

		if not launch_data_value is Dictionary:

			continue


		var data: Dictionary = (
			launch_data_value
			as
			Dictionary
		)


		var object_value: Variant = (
			data.get(
				"object_data",
				{}
			)
		)


		if not object_value is Dictionary:

			continue


		var object_data: Dictionary = (
			object_value
			as
			Dictionary
		)


		if object_data.is_empty():

			continue


		var path: String = str(
			object_data.get(
				"source_path",
				""
			)
		)


		if path.is_empty():

			continue


		# =====================================================
		# OBJECT ID
		# =====================================================

		var object_id := str(
			object_data.get(
				"id",
				""
			)
		)


		# =====================================================
		# CACHE CENTRAL -> PREVIEW TEMPLATE
		# =====================================================

		var template: Node3D = (
			ensure_object_cached(
				path
			)
		)


		if template == null:

			continue


		# =====================================================
		# SCALE
		#
		# IMPORTANT:
		#
		# Não usamos mais:
		#
		#     data.scale -> clamp 0.01
		#
		# porque isso confundia o SCALE MULTIPLIER do UI
		# com a escala física final do objecto.
		#
		# A escala efectiva vem do CIGAObjects.
		# =====================================================

		var scale_value: float = (
			get_burst_object_scale(
				object_data
			)
		)


		scale_value = maxf(
			scale_value,
			CIGAObjects.MIN_OBJECT_SCALE
		)


		# =====================================================
		# TARGET
		# =====================================================

		var target_name: String = str(
			data.get(
				"target",
				"CHEST"
			)
		)


		# =====================================================
		# SPAWN
		# =====================================================

		var spawn_name: String = str(
			data.get(
				"spawn",
				"RANDOM"
			)
		)


		# =====================================================
		# SPEED
		# =====================================================

		var speed: float = maxf(
			float(
				data.get(
					"speed",
					5.4
				)
			),
			0.1
		)


		# =====================================================
		# FORCE
		# =====================================================

		var force: float = maxf(
			float(
				data.get(
					"force",
					1.8
				)
			),
			0.0
		)


		# =====================================================
		# INDEX
		# =====================================================

		var index: int = int(
			data.get(
				"index",
				0
			)
		)


		# =====================================================
		# SPAWN
		# =====================================================

		var spawn_position: Vector3 = (
			get_test_spawn_position(
				spawn_name
			)
		)


		# =====================================================
		# LANE
		# =====================================================

		var lane: float = 0.0


		if total > 1:

			lane = (
				(
					float(index)
					/
					float(total - 1)
				)
				*
				2.0
				-
				1.0
			)


		var start_offset: Vector3 = Vector3(
			lane * 0.55,
			abs(lane) * 0.12,
			0.0
		)


		var start_position: Vector3 = (
			spawn_position
			+
			start_offset
		)


		# =====================================================
		# TARGET
		# =====================================================

		var target_position: Vector3 = (
			resolve_target_position(
				target_name
			)
		)


		if total > 1:

			target_position.x += (
				lane
				*
				0.08
			)


		# =====================================================
		# THROWABLE
		# =====================================================

		var throwable: ThrowableObject = (
			ThrowableObject.new()
		)


		if throwable == null:

			continue


		throwable.name = (
			"CIGAProjectile_"
			+
			str(index)
		)


		launch_holder.add_child(
			throwable
		)


		# =====================================================
		# DUPLICATE TEMPLATE
		# =====================================================

		var visual_value: Variant = (
			template.duplicate(
				true
			)
		)


		if not visual_value is Node3D:

			throwable.queue_free()

			continue


		var visual: Node3D = (
			visual_value
			as
			Node3D
		)


		visual.visible = true

		visual.process_mode = (
			Node.PROCESS_MODE_INHERIT
		)


		throwable.pre_instantiated_model = (
			visual
		)


		# =====================================================
		# IMPACT SIGNAL
		# =====================================================

		if not throwable.impacted.is_connected(
			_on_projectile_impacted
		):

			throwable.impacted.connect(
				_on_projectile_impacted
			)


		# =====================================================
		# SETUP
		# =====================================================

		throwable.setup(
			start_position,
			target_position,
			str(
				object_data.get(
					"name",
					object_id if not object_id.is_empty() else "OBJECT"
				)
			),
			speed,
			force,
			target_to_hitpoint(
				target_name
			),
			5.0,
			CIGASettings.DEFAULT_BOUNCE_TIME
		)


		# =====================================================
		# VISUAL SCALE
		#
		# ThrowableObject pode ter um visual_container.
		#
		# A escala real do modelo deve ficar apenas no
		# pre_instantiated_model.
		# =====================================================

		if throwable.visual_container != null:

			throwable.visual_container.scale = (
				Vector3.ONE
			)


		if throwable.pre_instantiated_model != null:

			throwable.pre_instantiated_model.scale = (
				Vector3.ONE
				*
				scale_value
			)


# =============================================================
# PROJECTILE IMPACT
# =============================================================
func _on_projectile_impacted(
	object_type: String,
	impact_direction: Vector3,
	impact_force: float,
	hit_point_name: String
) -> void:

	if interaction_manager == null:

		push_error(
			"[CIGA IMPACT ERROR] Interaction Manager unavailable | "
			+ "OBJECT="
			+ object_type
			+ " | HIT="
			+ hit_point_name
		)

		return


	interaction_manager.receive_impact(
		hit_point_name,
		impact_force,
		null,
		impact_direction
	)


# =============================================================
# PHYSICS PROCESS
# =============================================================

func _physics_process(
	_delta: float
) -> void:

	update_spawn_positions()


# =============================================================
# OBJECT SCALE
# =============================================================

func get_object_scale() -> float:

	return current_object_scale


# =============================================================
# SET PREVIEW SCALE
#
# A escala recebida é tratada como escala FINAL.
#
# IMPORTANTE:
#
# Esta função não grava nada no profile.
#
# Para alterações persistentes, a UI deve usar:
#
#     CIGAObjects.set_object_scale()
#
# ou directamente:
#
#     CIGAProfiles.set_active_object_scale_multiplier()
#
# =============================================================

func set_preview_scale(
	scale_value: float
) -> void:

	var safe_scale := float(
		scale_value
	)


	if not is_finite(
		safe_scale
	):

		safe_scale = (
			CIGAObjects.DEFAULT_OBJECT_SCALE
		)


	safe_scale = maxf(
		safe_scale,
		CIGAObjects.MIN_OBJECT_SCALE
	)


	current_object_scale = (
		safe_scale
	)


	# =========================================================
	# CURRENT OBJECT PREVIEW
	# =========================================================

	if object_model != null:

		if is_instance_valid(
			object_model
		):

			object_model.scale = (
				Vector3.ONE
				*
				safe_scale
			)


			center_object_on_ground(
				object_model
			)


	# =========================================================
	# ACTIVE LAUNCH OBJECTS
	# =========================================================

	if launch_holder != null:

		for child: Node in launch_holder.get_children():

			if not child is ThrowableObject:

				continue


			var throwable := (
				child
				as
				ThrowableObject
			)


			if throwable.pre_instantiated_model != null:

				throwable.pre_instantiated_model.scale = (
					Vector3.ONE
					*
					safe_scale
				)


# =============================================================
# MATERIALS
# =============================================================

func _fix_model_materials(
	root_node: Node
) -> void:

	if root_node == null:

		return


	var mesh_instances: Array[MeshInstance3D] = []


	_find_meshes_recursive(
		root_node,
		mesh_instances
	)


	for mesh_instance: MeshInstance3D in mesh_instances:

		if mesh_instance == null:

			continue


		mesh_instance.visible = true

		mesh_instance.cast_shadow = (
			GeometryInstance3D
			.SHADOW_CASTING_SETTING_OFF
		)


		if (
			mesh_instance.material_override != null
			and
			mesh_instance.material_override
			is
			StandardMaterial3D
		):

			var override_material: StandardMaterial3D = (
				mesh_instance.material_override
				as
				StandardMaterial3D
			)


			override_material.cull_mode = (
				BaseMaterial3D
				.CULL_DISABLED
			)


		if mesh_instance.mesh == null:

			continue


		for surface_index in range(
			mesh_instance.mesh.get_surface_count()
		):

			var surface_material: Material = (
				mesh_instance.get_active_material(
					surface_index
				)
			)


			if surface_material == null:

				continue


			if surface_material is StandardMaterial3D:

				var standard_material: StandardMaterial3D = (
					surface_material
					as
					StandardMaterial3D
				)


				standard_material.cull_mode = (
					BaseMaterial3D
					.CULL_DISABLED
				)


# =============================================================
# FIND MESHES
# =============================================================

func _find_meshes_recursive(
	node: Node,
	result: Array[MeshInstance3D]
) -> void:

	if node is MeshInstance3D:

		result.append(
			node
			as
			MeshInstance3D
		)


	for child: Node in node.get_children():

		_find_meshes_recursive(
			child,
			result
		)


# =============================================================
# GET OBJECT TEMPLATE BY ID
#
# Helper adicional.
# Útil quando no futuro a UI passar directamente o ID.
# =============================================================

func get_object_template_by_id(
	object_id: String
) -> Node3D:

	if object_id.is_empty():

		return null


	if object_manager == null:

		auto_resolve_object_manager()


	if object_manager == null:

		return null


	var source_path: String = (
		object_manager.get_object_path(
			object_id
		)
	)


	if source_path.is_empty():

		return null


	return ensure_object_cached(
		source_path
	)
