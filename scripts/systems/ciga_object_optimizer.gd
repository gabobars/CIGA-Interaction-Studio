class_name CIGAObjectOptimizer
extends RefCounted


# =============================================================
# CIGA OBJECT OPTIMIZER
# Godot 4.7.2
#
# OBJECTIVO
#
# Recebe um GLB / GLTF e cria uma versão optimizada AUTÓNOMA
# para o CIGA.
#
# O ficheiro original NUNCA é alterado.
#
# FLUXO:
#
#     ORIGINAL GLB / GLTF
#              ↓
#        importação única
#              ↓
#       CIGA OPTIMIZER
#              ↓
#     remover nodes inúteis
#     optimizar materiais
#     reduzir texturas grandes
#     gerar LODs quando apropriado
#              ↓
#       PackedScene CACHE
#              ↓
#       recursos externos EMBUTIDOS
#              ↓
#       runtime usa apenas cache
#
# =============================================================


# =============================================================
# OPTIMIZER QUALITY
# =============================================================

enum OptimizerQuality {

	QUALITY,
	BALANCED,
	PERFORMANCE
}


var optimizer_quality: OptimizerQuality = (
	OptimizerQuality.BALANCED
)


# =============================================================
# CACHE
# =============================================================

const CACHE_ROOT: String = (
	"user://ciga/cache"
)


const OBJECT_CACHE_FOLDER: String = (
	CACHE_ROOT
	+
	"/objects"
)


# =============================================================
# TEXTURE LIMITS
#
# QUALITY:
#     até 4096
#
# BALANCED:
#     até 2048
#
# PERFORMANCE:
#     até 1024
#
# =============================================================

const TEXTURE_MAX_SIZE_QUALITY: int = 4096

const TEXTURE_MAX_SIZE_BALANCED: int = 2048

const TEXTURE_MAX_SIZE_PERFORMANCE: int = 1024


# =============================================================
# OPTIMIZER VERSION
# =============================================================

const OPTIMIZER_VERSION: int = 2


# =============================================================
# NODES QUE NÃO PRECISAMOS
# =============================================================

const REMOVE_NODE_TYPES: Array[String] = [

	"Camera3D",

	"DirectionalLight3D",

	"OmniLight3D",

	"SpotLight3D",

	"WorldEnvironment",

	"ReflectionProbe",

	"LightmapGI",

	"VoxelGI",

	"GPUParticles3D",

	"CPUParticles3D",

	"AudioStreamPlayer3D"
]


# =============================================================
# MAIN
# =============================================================

func optimize_file(
	source_path: String,
	object_id: String
) -> Dictionary:

	if source_path.is_empty():

		return {}


	if object_id.is_empty():

		return {}


	if not FileAccess.file_exists(
		source_path
	):

		push_error(
			"CIGA OPTIMIZER: Source file not found: "
			+
			source_path
		)

		return {}


	if not _is_supported_model(
		source_path
	):

		push_error(
			"CIGA OPTIMIZER: Unsupported model format: "
			+
			source_path
		)

		return {}


	_ensure_cache_directories()


	var optimized_path := (
		OBJECT_CACHE_FOLDER
		+
		"/"
		+
		object_id
		+
		".tscn"
	)


	# =========================================================
	# CACHE HIT
	#
	# O cache existente continua a ser considerado válido
	# pelo caminho actual do CIGA.
	#
	# A versão / qualidade são guardadas em metadata para
	# futuras extensões de validação do cache.
	# =========================================================

	if FileAccess.file_exists(
		optimized_path
	):

		print(
			"CIGA OPTIMIZER CACHE HIT | ",
			object_id,
			" | QUALITY=",
			get_quality_name(),
			" | ",
			optimized_path
		)

		return {

			"success":
				true,

			"path":
				optimized_path,

			"cached":
				true,

			"quality":
				get_quality_name(),

			"quality_id":
				int(
					optimizer_quality
				),

			"optimizer_version":
				OPTIMIZER_VERSION
		}


	print(
		"CIGA OPTIMIZER START | ",
		source_path,
		" | QUALITY=",
		get_quality_name()
	)


	# =========================================================
	# IMPORT ORIGINAL
	# =========================================================

	var model := (
		_load_model(
			source_path
		)
	)


	if model == null:

		push_error(
			"CIGA OPTIMIZER: Could not import model."
		)

		return {}


	# =========================================================
	# STATS
	# =========================================================

	var stats := {

		"removed_nodes":
			0,

		"optimized_textures":
			0,

		"materials":
			0,

		"lod_meshes":
			0
	}


	# =========================================================
	# REMOVE NODES
	# =========================================================

	_remove_unnecessary_nodes(
		model,
		stats
	)


	# =========================================================
	# OPTIMISE MODEL
	# =========================================================

	_optimize_model(
		model,
		stats
	)


	# =========================================================
	# METADATA
	# =========================================================

	model.set_meta(
		"ciga_optimized",
		true
	)


	model.set_meta(
		"ciga_source_path",
		source_path
	)


	model.set_meta(
		"ciga_object_id",
		object_id
	)


	model.set_meta(
		"ciga_optimizer_version",
		OPTIMIZER_VERSION
	)


	model.set_meta(
		"ciga_optimizer_quality",
		int(
			optimizer_quality
		)
	)


	model.set_meta(
		"ciga_optimizer_quality_name",
		get_quality_name()
	)


	model.set_meta(
		"ciga_optimizer_texture_max",
		get_texture_max_size()
	)


	# =========================================================
	# OWNERSHIP
	#
	# Todos os nodes precisam de owner válido para o PackedScene
	# poder guardar correctamente a árvore.
	# =========================================================

	_set_owner_recursive(
		model,
		model
	)


	# =========================================================
	# PACK
	# =========================================================

	var packed_scene := (
		PackedScene.new()
	)


	var pack_error := (
		packed_scene.pack(
			model
		)
	)


	if pack_error != OK:

		push_error(
			"CIGA OPTIMIZER: PackedScene.pack failed: "
			+
			error_string(
				pack_error
			)
		)

		model.free()

		return {}


	# =========================================================
	# SAVE
	#
	# FLAG_BUNDLE_RESOURCES:
	#
	#     coloca recursos externos dentro do cache.
	#
	# FLAG_CHANGE_PATH:
	#
	#     permite que os recursos guardados adoptem o novo
	#     contexto do ficheiro que está a ser salvo.
	#
	# =========================================================

	var save_flags: ResourceSaver.SaverFlags = (
		ResourceSaver.FLAG_BUNDLE_RESOURCES
		|
		ResourceSaver.FLAG_CHANGE_PATH
	)


	print(
		"CIGA OPTIMIZER SAVING SELF-CONTAINED CACHE | ",
		object_id
	)


	var save_error := (
		ResourceSaver.save(
			packed_scene,
			optimized_path,
			save_flags
		)
	)


	if save_error != OK:

		push_error(
			"CIGA OPTIMIZER: Could not save optimized scene: "
			+
			error_string(
				save_error
			)
		)

		model.free()

		return {}


	# =========================================================
	# LIBERTAR MODELO TEMPORÁRIO
	# =========================================================

	model.free()


	# =========================================================
	# RESULTADO
	# =========================================================

	print(
		"CIGA OPTIMIZER COMPLETE | ",
		object_id,
		" | quality=",
		get_quality_name(),
		" | removed=",
		stats["removed_nodes"],
		" | textures=",
		stats["optimized_textures"],
		" | materials=",
		stats["materials"],
		" | lod_meshes=",
		stats["lod_meshes"],
		" | CACHE=",
		optimized_path
	)


	return {

		"success":
			true,

		"path":
			optimized_path,

		"cached":
			false,

		"quality":
			get_quality_name(),

		"quality_id":
			int(
				optimizer_quality
			),

		"optimizer_version":
			OPTIMIZER_VERSION,

		"removed_nodes":
			stats["removed_nodes"],

		"optimized_textures":
			stats["optimized_textures"],

		"materials":
			stats["materials"],

		"lod_meshes":
			stats["lod_meshes"]
	}


# =============================================================
# SET QUALITY
# =============================================================

func set_quality(
	quality: int
) -> void:

	optimizer_quality = (
		clampi(
			quality,
			OptimizerQuality.QUALITY,
			OptimizerQuality.PERFORMANCE
		)
	)


# =============================================================
# GET QUALITY
# =============================================================

func get_quality() -> int:

	return int(
		optimizer_quality
	)


# =============================================================
# GET QUALITY NAME
# =============================================================

func get_quality_name() -> String:

	match optimizer_quality:

		OptimizerQuality.QUALITY:

			return "QUALITY"


		OptimizerQuality.BALANCED:

			return "BALANCED"


		OptimizerQuality.PERFORMANCE:

			return "PERFORMANCE"


	return "BALANCED"


# =============================================================
# GET TEXTURE MAX SIZE
# =============================================================

func get_texture_max_size() -> int:

	match optimizer_quality:

		OptimizerQuality.QUALITY:

			return TEXTURE_MAX_SIZE_QUALITY


		OptimizerQuality.BALANCED:

			return TEXTURE_MAX_SIZE_BALANCED


		OptimizerQuality.PERFORMANCE:

			return TEXTURE_MAX_SIZE_PERFORMANCE


	return TEXTURE_MAX_SIZE_BALANCED


# =============================================================
# CACHE PATH
# =============================================================

func get_cache_path(
	object_id: String
) -> String:

	if object_id.is_empty():

		return ""


	return (
		OBJECT_CACHE_FOLDER
		+
		"/"
		+
		object_id
		+
		".tscn"
	)


# =============================================================
# CACHE EXISTS
# =============================================================

func has_cache(
	object_id: String
) -> bool:

	if object_id.is_empty():

		return false


	return FileAccess.file_exists(
		get_cache_path(
			object_id
		)
	)


# =============================================================
# REMOVE CACHE
# =============================================================

func remove_cache(
	object_id: String
) -> bool:

	var path := (
		get_cache_path(
			object_id
		)
	)


	if path.is_empty():

		return false


	if not FileAccess.file_exists(
		path
	):

		return true


	var error := (
		DirAccess.remove_absolute(
			path
		)
	)


	if error != OK:

		push_error(
			"CIGA OPTIMIZER: Could not remove cache: "
			+
			error_string(
				error
			)
		)

		return false


	print(
		"CIGA OPTIMIZER CACHE REMOVED | ",
		object_id
	)


	return true


# =============================================================
# CLEAR ALL CACHE
# =============================================================

func clear_all_cache() -> void:

	_ensure_cache_directories()


	var directory := (
		DirAccess.open(
			OBJECT_CACHE_FOLDER
		)
	)


	if directory == null:

		return


	directory.list_dir_begin()


	while true:

		var file_name := (
			directory.get_next()
		)


		if file_name.is_empty():

			break


		if directory.current_is_dir():

			continue


		if not file_name.ends_with(
			".tscn"
		):

			continue


		var path := (
			OBJECT_CACHE_FOLDER
			+
			"/"
			+
			file_name
		)


		var error := (
			DirAccess.remove_absolute(
				path
			)
		)


		if error != OK:

			print(
				"CIGA OPTIMIZER: Could not remove cache file | ",
				path,
				" | ",
				error_string(
					error
				)
			)


	directory.list_dir_end()


	print(
		"CIGA OPTIMIZER: ALL OBJECT CACHE CLEARED"
	)


# =============================================================
# DIRECTORIES
# =============================================================

func _ensure_cache_directories() -> void:

	DirAccess.make_dir_recursive_absolute(
		OBJECT_CACHE_FOLDER
	)


# =============================================================
# SUPPORTED MODEL
# =============================================================

func _is_supported_model(
	path: String
) -> bool:

	var extension := (
		path
		.get_extension()
		.to_lower()
	)


	return (
		extension == "glb"
		or
		extension == "gltf"
	)


# =============================================================
# LOAD MODEL
# =============================================================

func _load_model(
	path: String
) -> Node3D:

	if not FileAccess.file_exists(
		path
	):

		push_error(
			"CIGA OPTIMIZER: Model file does not exist | ",
			path
		)

		return null


	var document := (
		GLTFDocument.new()
	)


	var state := (
		GLTFState.new()
	)


	var error := (
		document.append_from_file(
			path,
			state
		)
	)


	if error != OK:

		push_error(
			"CIGA OPTIMIZER: GLTF import failed: "
			+
			error_string(
				error
			)
		)

		return null


	# =========================================================
	# MESH LOD GENERATION
	#
	# O Godot usa meshoptimizer internamente para gerar LODs.
	#
	# Não substituímos a mesh original.
	# As variantes são usadas automaticamente pelo renderer.
	#
	# Meshes com blend shapes são ignoradas por segurança.
	# =========================================================

	var meshes: Array[GLTFMesh] = (
		state.get_meshes()
	)


	for gltf_mesh: GLTFMesh in meshes:

		if gltf_mesh == null:

			continue


		var importer_mesh: ImporterMesh = (
			gltf_mesh.mesh
		)


		if importer_mesh == null:

			continue


		if (
			importer_mesh.get_blend_shape_count()
			>
			0
		):

			continue


		if not _should_generate_lods():

			continue


		var lod_angles := (
			_get_lod_angles()
		)


		importer_mesh.generate_lods(
			lod_angles["normal_merge_angle"],
			lod_angles["normal_split_angle"],
			[]
		)


	return (
		document.generate_scene(
			state
		)
	)


# =============================================================
# SHOULD GENERATE LODS
# =============================================================

func _should_generate_lods() -> bool:

	match optimizer_quality:

		OptimizerQuality.QUALITY:

			return false


		OptimizerQuality.BALANCED:

			return true


		OptimizerQuality.PERFORMANCE:

			return true


	return true


# =============================================================
# GET LOD ANGLES
#
# A API do ImporterMesh recebe o normal merge angle em graus.
# O segundo argumento permanece por compatibilidade.
# =============================================================

func _get_lod_angles() -> Dictionary:

	match optimizer_quality:

		OptimizerQuality.BALANCED:

			return {

				"normal_merge_angle":
					45.0,

				"normal_split_angle":
					0.0
			}


		OptimizerQuality.PERFORMANCE:

			return {

				"normal_merge_angle":
					60.0,

				"normal_split_angle":
					0.0
			}


	return {

		"normal_merge_angle":
			45.0,

		"normal_split_angle":
			0.0
	}


# =============================================================
# REMOVE UNNECESSARY NODES
# =============================================================

func _remove_unnecessary_nodes(
	root: Node,
	stats: Dictionary
) -> void:

	if root == null:

		return


	var children := (
		root.get_children()
	)


	for child: Node in children:

		if child == null:

			continue


		var type_name := (
			child.get_class()
		)


		if REMOVE_NODE_TYPES.has(
			type_name
		):

			# O modelo ainda não está na SceneTree.
			# free() remove imediatamente.
			child.free()


			stats["removed_nodes"] += 1

			continue


		_remove_unnecessary_nodes(
			child,
			stats
		)


# =============================================================
# OPTIMIZE MODEL
# =============================================================

func _optimize_model(
	root: Node,
	stats: Dictionary
) -> void:

	if root == null:

		return


	if root is GeometryInstance3D:

		var geometry := (
			root
			as
			GeometryInstance3D
		)


		geometry.cast_shadow = (
			GeometryInstance3D
			.SHADOW_CASTING_SETTING_OFF
		)


	# ---------------------------------------------------------
	# MESH
	# ---------------------------------------------------------

	if root is MeshInstance3D:

		var mesh_instance := (
			root
			as
			MeshInstance3D
		)


		mesh_instance.cast_shadow = (
			GeometryInstance3D
			.SHADOW_CASTING_SETTING_OFF
		)


		_optimize_mesh_materials(
			mesh_instance,
			stats
		)


	# ---------------------------------------------------------
	# RECURSE
	# ---------------------------------------------------------

	for child: Node in root.get_children():

		_optimize_model(
			child,
			stats
		)


# =============================================================
# MATERIALS
# =============================================================

func _optimize_mesh_materials(
	mesh_instance: MeshInstance3D,
	stats: Dictionary
) -> void:

	if mesh_instance == null:

		return


	if mesh_instance.mesh == null:

		return


	# =========================================================
	# MATERIAL OVERRIDE
	#
	# Duplicação superficial.
	#
	# Não copiamos profundamente texturas e outros recursos.
	# =========================================================

	if mesh_instance.material_override != null:

		var duplicated_override := (
			mesh_instance.material_override
			.duplicate()
		)


		if duplicated_override is BaseMaterial3D:

			mesh_instance.material_override = (
				duplicated_override
			)


			_optimize_material(
				duplicated_override,
				stats
			)


	# =========================================================
	# SURFACES
	# =========================================================

	for surface_index in range(
		mesh_instance.mesh.get_surface_count()
	):

		var material := (
			mesh_instance.get_active_material(
				surface_index
			)
		)


		if material == null:

			continue


		if not material is BaseMaterial3D:

			continue


		var duplicated_material := (
			material.duplicate()
		)


		if not duplicated_material is BaseMaterial3D:

			continue


		mesh_instance.set_surface_override_material(
			surface_index,
			duplicated_material
		)


		_optimize_material(
			duplicated_material,
			stats
		)


		stats["materials"] += 1


# =============================================================
# MATERIAL OPTIMIZATION
# =============================================================

func _optimize_material(
	material: BaseMaterial3D,
	stats: Dictionary
) -> void:

	if material == null:

		return


	material.shading_mode = (
		BaseMaterial3D.SHADING_MODE_PER_PIXEL
	)


	# =========================================================
	# STANDARD MATERIAL
	# =========================================================

	if material is StandardMaterial3D:

		var standard := (
			material
			as
			StandardMaterial3D
		)


		# -----------------------------------------------------
		# ALBEDO
		# -----------------------------------------------------

		var new_albedo := (
			_optimize_texture(
				standard.albedo_texture
			)
		)


		if (
			standard.albedo_texture != null
			and
			new_albedo != standard.albedo_texture
		):

			standard.albedo_texture = (
				new_albedo
			)


			stats["optimized_textures"] += 1


		# -----------------------------------------------------
		# NORMAL
		# -----------------------------------------------------

		var new_normal := (
			_optimize_texture(
				standard.normal_texture
			)
		)


		if (
			standard.normal_texture != null
			and
			new_normal != standard.normal_texture
		):

			standard.normal_texture = (
				new_normal
			)


			stats["optimized_textures"] += 1


		# -----------------------------------------------------
		# ROUGHNESS
		# -----------------------------------------------------

		var new_roughness := (
			_optimize_texture(
				standard.roughness_texture
			)
		)


		if (
			standard.roughness_texture != null
			and
			new_roughness != standard.roughness_texture
		):

			standard.roughness_texture = (
				new_roughness
			)


			stats["optimized_textures"] += 1


		# -----------------------------------------------------
		# METALLIC
		# -----------------------------------------------------

		var new_metallic := (
			_optimize_texture(
				standard.metallic_texture
			)
		)


		if (
			standard.metallic_texture != null
			and
			new_metallic != standard.metallic_texture
		):

			standard.metallic_texture = (
				new_metallic
			)


			stats["optimized_textures"] += 1


		# -----------------------------------------------------
		# EMISSION
		# -----------------------------------------------------

		var new_emission := (
			_optimize_texture(
				standard.emission_texture
			)
		)


		if (
			standard.emission_texture != null
			and
			new_emission != standard.emission_texture
		):

			standard.emission_texture = (
				new_emission
			)


			stats["optimized_textures"] += 1


	# =========================================================
	# CULLING
	# =========================================================

	material.cull_mode = (
		BaseMaterial3D.CULL_BACK
	)


# =============================================================
# TEXTURE OPTIMIZATION
# =============================================================

func _optimize_texture(
	texture: Texture2D
) -> Texture2D:

	if texture == null:

		return null


	# =========================================================
	# CHECK SIZE FIRST
	#
	# Evitamos get_image() para texturas que já estão dentro
	# do limite.
	# =========================================================

	var width: int = (
		texture.get_width()
	)


	var height: int = (
		texture.get_height()
	)


	if width <= 0 or height <= 0:

		return texture


	var texture_max_size := (
		get_texture_max_size()
	)


	# =========================================================
	# JÁ ESTÁ DENTRO DO LIMITE
	# =========================================================

	if (
		width <= texture_max_size
		and
		height <= texture_max_size
	):

		return texture


	# =========================================================
	# LOAD IMAGE
	# =========================================================

	var image := (
		texture.get_image()
	)


	if image == null:

		return texture


	if image.get_width() <= 0:

		return texture


	if image.get_height() <= 0:

		return texture


	# =========================================================
	# CALCULATE SCALE
	# =========================================================

	var scale_factor := minf(

		float(
			texture_max_size
		)
		/
		float(
			width
		),

		float(
			texture_max_size
		)
		/
		float(
			height
		)
	)


	var new_width := maxi(
		int(
			round(
				float(width)
				*
				scale_factor
			)
		),
		1
	)


	var new_height := maxi(
		int(
			round(
				float(height)
				*
				scale_factor
			)
		),
		1
	)


	print(
		"CIGA OPTIMIZER TEXTURE RESIZE | ",
		width,
		"x",
		height,
		" -> ",
		new_width,
		"x",
		new_height,
		" | QUALITY=",
		get_quality_name()
	)


	# =========================================================
	# DECOMPRESS ONLY WHEN NECESSARY
	# =========================================================

	if image.is_compressed():

		image.decompress()


	# =========================================================
	# RESIZE IN PLACE
	#
	# Não fazemos uma segunda cópia gigante da Image.
	# =========================================================

	image.resize(
		new_width,
		new_height,
		Image.INTERPOLATE_LANCZOS
	)


	# =========================================================
	# IMAGE TEXTURE
	# =========================================================

	var optimized_texture := (
		ImageTexture.create_from_image(
			image
		)
	)


	if optimized_texture == null:

		return texture


	return optimized_texture


# =============================================================
# OWNER
# =============================================================

func _set_owner_recursive(
	node: Node,
	owner: Node
) -> void:

	if node == null:

		return


	if node != owner:

		node.owner = owner


	for child: Node in node.get_children():

		_set_owner_recursive(
			child,
			owner
		)
