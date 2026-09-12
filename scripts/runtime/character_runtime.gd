class_name CIGACharacterRuntime
extends Node


# =============================================================
# CIGA CHARACTER RUNTIME
# Godot 4.7.2
#
# RESPONSABILIDADE:
# - carregar VRM / GLB / GLTF
# - cache de PackedScene
# - instanciar personagens
# - carregar CIGA Native 3D
# - encontrar Skeleton3D
# - criar HitPoints
# - guardar/aplicar mapping
#
# =============================================================


# =============================================================
# SIGNALS
# =============================================================

signal character_loaded(
	character: Node3D
)

signal character_unloaded

signal hitpoints_created(
	bone_map: Dictionary
)


# =============================================================
# HITPOINT BONE CANDIDATES
# =============================================================

const HIT_POINT_BONES: Dictionary = {

	"HeadHitPoint": [
		"J_Bip_C_Head",
		"Head",
		"head"
	],

	"ChestHitPoint": [
		"J_Bip_C_Chest",
		"Chest",
		"chest"
	],

	"LeftShoulderHitPoint": [
		"J_Bip_L_Shoulder",
		"LeftShoulder",
		"leftShoulder",
		"left_shoulder"
	],

	"RightShoulderHitPoint": [
		"J_Bip_R_Shoulder",
		"RightShoulder",
		"rightShoulder",
		"right_shoulder"
	],

	"LeftArmHitPoint": [
		"J_Bip_L_UpperArm",
		"LeftUpperArm",
		"leftUpperArm",
		"left_upper_arm"
	],

	"RightArmHitPoint": [
		"J_Bip_R_UpperArm",
		"RightUpperArm",
		"rightUpperArm",
		"right_upper_arm"
	],

	"LeftLegHitPoint": [
		"J_Bip_L_UpperLeg",
		"LeftUpperLeg",
		"leftUpperLeg",
		"left_upper_leg"
	],

	"RightLegHitPoint": [
		"J_Bip_R_UpperLeg",
		"RightUpperLeg",
		"rightUpperLeg",
		"right_upper_leg"
	]
}


# =============================================================
# CACHE
# =============================================================

var scene_cache: Dictionary = {}

var bone_cache: Dictionary = {}


# =============================================================
# CHARACTER MANAGER
# =============================================================

var character_manager: CIGACharacters = null


# =============================================================
# ACTIVE CHARACTER
# =============================================================

var active_character: Node3D = null

var active_character_path: String = ""

var active_bone_map: Dictionary = {}


# =============================================================
# ACTIVE CHARACTER TYPE
# =============================================================

var active_character_type: String = ""


# =============================================================
# ACTIVE NATIVE AVATAR DEFINITION
# =============================================================

var active_native_definition: Dictionary = {}


# =============================================================
# READY
# =============================================================

func _ready() -> void:

	# ---------------------------------------------------------
	# Criar manager local caso ainda não tenha sido fornecido.
	#
	# Mais tarde o Viewport/UI poderá injectar a instância
	# global através de set_character_manager().
	# ---------------------------------------------------------

	if character_manager == null:

		character_manager = CIGACharacters.new()

		character_manager.initialize()


	print(
		"CIGA CHARACTER RUNTIME READY"
	)


# =============================================================
# SET CHARACTER MANAGER
# =============================================================

func set_character_manager(
	manager: CIGACharacters
) -> void:

	if manager == null:

		return


	character_manager = manager


# =============================================================
# LOAD CHARACTER DATA
# =============================================================
#
# Decide automaticamente se o personagem é:
#
# - Native 3D
# - VRM
# - GLB
# - GLTF
#
# =============================================================

func load_character_data(
	character: Dictionary
) -> Node3D:

	if character.is_empty():

		return null


	if character_manager == null:

		push_error(
			"CIGA CHARACTER RUNTIME: Character manager is not assigned."
		)

		return null


	# ---------------------------------------------------------
	# NATIVE 3D
	# ---------------------------------------------------------

	if character_manager.is_native_character(
		character
	):

		return load_native_character(
			character
		)


	# ---------------------------------------------------------
	# IMPORTED MODEL
	# ---------------------------------------------------------

	var path := character_manager.get_runtime_path(
		character
	)


	if path.is_empty():

		print(
			"CIGA CHARACTER RUNTIME: Invalid runtime path."
		)

		return null


	return load_character(
		path
	)


# =============================================================
# LOAD NATIVE CHARACTER
# =============================================================
#
# Constrói um CIGACalibrationAvatar directamente em runtime.
#
# O .cigaavatar contém apenas a definição/configuração.
# Não é carregado pelo GLTFDocument.
#
# =============================================================

func load_native_character(
	character: Dictionary
) -> Node3D:

	if character.is_empty():

		return null


	if character_manager == null:

		push_error(
			"CIGA CHARACTER RUNTIME: Character manager is not assigned."
		)

		return null


	# ---------------------------------------------------------
	# UNLOAD CURRENT
	# ---------------------------------------------------------

	if active_character != null:

		unload_character()


	# ---------------------------------------------------------
	# LOAD DEFINITION
	# ---------------------------------------------------------

	var definition := (
		character_manager
		.load_native_avatar_definition(
			character
		)
	)


	if definition.is_empty():

		print(
			"CIGA CHARACTER RUNTIME: Could not load native definition."
		)

		return null


	# ---------------------------------------------------------
	# CREATE AVATAR
	# ---------------------------------------------------------

	var avatar := CIGACalibrationAvatar.new()

	avatar.name = "CIGACharacter"


	# ---------------------------------------------------------
	# ADD TO RUNTIME
	# ---------------------------------------------------------

	add_child(
		avatar
	)


	# ---------------------------------------------------------
	# SAVE STATE
	# ---------------------------------------------------------

	active_character = avatar

	active_character_path = str(
		character.get(
			"source_path",
			""
		)
	)

	active_character_type = "native_3d"

	active_native_definition = (
		definition.duplicate(
			true
		)
	)

	active_bone_map.clear()


	# ---------------------------------------------------------
	# APPLY SAVED DEFINITION
	# ---------------------------------------------------------

	apply_native_definition(
		avatar,
		definition
	)


	print(
		"CIGA CHARACTER RUNTIME: NATIVE CHARACTER LOADED: ",
		character.get(
			"name",
			""
		)
	)


	character_loaded.emit(
		avatar
	)


	return avatar


# =============================================================
# APPLY NATIVE DEFINITION
# =============================================================

func apply_native_definition(
	avatar: CIGACalibrationAvatar,
	definition: Dictionary
) -> void:

	if avatar == null:

		return


	if definition.is_empty():

		return


	# ---------------------------------------------------------
	# AVATAR SETTINGS
	# ---------------------------------------------------------

	var avatar_data: Variant = (
		definition.get(
			"avatar",
			{}
		)
	)


	if avatar_data is Dictionary:

		var avatar_dict := (
			avatar_data
			as Dictionary
		)


		var body_scale := float(
			avatar_dict.get(
				"body_scale",
				1.0
			)
		)


		var head_scale := float(
			avatar_dict.get(
				"head_scale",
				1.0
			)
		)


		avatar.set_avatar_scale(
			body_scale,
			head_scale
		)


	# ---------------------------------------------------------
	# POSE
	# ---------------------------------------------------------

	var pose_data: Variant = (
		definition.get(
			"pose",
			{}
		)
	)


	if pose_data is Dictionary:

		var pose := (
			pose_data
			as Dictionary
		)


		# -----------------------------------------------------
		# HEAD
		# -----------------------------------------------------

		var raw_head_rotation: Variant = (
			pose.get(
				"head_rotation",
				{}
			)
		)


		if raw_head_rotation is Dictionary:

			var head_rotation_dict := (
				raw_head_rotation
				as Dictionary
			)


			var head_rotation := Vector3(
				float(
					head_rotation_dict.get(
						"x",
						0.0
					)
				),

				float(
					head_rotation_dict.get(
						"y",
						0.0
					)
				),

				float(
					head_rotation_dict.get(
						"z",
						0.0
					)
				)
			)


			avatar.set_head_rotation(
				head_rotation
			)


		# -----------------------------------------------------
		# ARMS
		# -----------------------------------------------------

		var left_arm := float(
			pose.get(
				"left_arm",
				0.0
			)
		)


		var right_arm := float(
			pose.get(
				"right_arm",
				0.0
			)
		)


		avatar.set_arm_pose(
			left_arm,
			right_arm
		)


# =============================================================
# LOAD CHARACTER SCENE
# =============================================================

func load_character_scene(
	path: String
) -> PackedScene:

	if path.is_empty():

		return null


	if scene_cache.has(
		path
	):

		var cached: Variant = (
			scene_cache[path]
		)


		if cached is PackedScene:

			return (
				cached
				as PackedScene
			)


		scene_cache.erase(
			path
		)


	if not FileAccess.file_exists(
		path
	):

		print(
			"CIGA CHARACTER: FILE NOT FOUND: ",
			path
		)

		return null


	var extension: String = (
		path
		.get_extension()
		.to_lower()
	)


	var generated: Node = null


	# =========================================================
	# VRM / GLB
	# =========================================================

	if (
		extension == "vrm"
		or
		extension == "glb"
	):

		var bytes: PackedByteArray = (
			FileAccess.get_file_as_bytes(
				path
			)
		)


		if bytes.is_empty():

			return null


		var document: GLTFDocument = (
			GLTFDocument.new()
		)


		var state: GLTFState = (
			GLTFState.new()
		)


		var error: Error = (
			document.append_from_buffer(
				bytes,
				path.get_base_dir(),
				state
			)
		)


		if error != OK:

			print(
				"CIGA CHARACTER LOAD ERROR: ",
				error_string(
					error
				)
			)

			return null


		generated = (
			document.generate_scene(
				state
			)
		)


	# =========================================================
	# GLTF
	# =========================================================

	elif extension == "gltf":

		var document: GLTFDocument = (
			GLTFDocument.new()
		)


		var state: GLTFState = (
			GLTFState.new()
		)


		var error: Error = (
			document.append_from_file(
				path,
				state
			)
		)


		if error != OK:

			print(
				"CIGA CHARACTER LOAD ERROR: ",
				error_string(
					error
				)
			)

			return null


		generated = (
			document.generate_scene(
				state
			)
		)


	# =========================================================
	# CIGA NATIVE AVATAR
	# =========================================================
	#
	# .cigaavatar NÃO é um modelo GLTF.
	#
	# É uma definição JSON usada para construir
	# um CIGACalibrationAvatar.
	#
	# O native avatar deve ser carregado através de
	# load_character_data() / load_native_character().
	#
	# Portanto, se este método for chamado diretamente
	# com .cigaavatar, simplesmente não tentamos usar
	# o GLTF loader.
	# =========================================================

	elif extension == "cigaavatar":

		return null


	else:

		print(
			"CIGA CHARACTER: UNSUPPORTED FORMAT: ",
			extension
		)

		return null

	# =========================================================
	# VALIDATE
	# =========================================================

	if generated == null:

		return null


	if not generated is Node3D:

		generated.free()

		return null


	var model: Node3D = (
		generated
		as Node3D
	)


	# =========================================================
	# BONE CACHE
	# =========================================================

	var skeleton: Skeleton3D = (
		find_skeleton(
			model
		)
	)


	if skeleton != null:

		bone_cache[path] = (
			build_bone_map(
				skeleton
			)
		)


	# =========================================================
	# PACK
	# =========================================================

	var packed: PackedScene = (
		PackedScene.new()
	)


	var pack_error: Error = (
		packed.pack(
			model
		)
	)


	model.free()


	if pack_error != OK:

		print(
			"CIGA CHARACTER: PACK FAILED: ",
			error_string(
				pack_error
			)
		)

		return null


	scene_cache[path] = (
		packed
	)


	return packed


# =============================================================
# INSTANTIATE
# =============================================================

func instantiate_character(
	path: String
) -> Node3D:

	var packed: PackedScene = (
		load_character_scene(
			path
		)
	)


	if packed == null:

		return null


	var instance: Node3D = (
		packed.instantiate()
		as Node3D
	)


	if instance == null:

		return null


	instance.name = (
		"CIGACharacter"
	)


	return instance


# =============================================================
# LOAD CHARACTER
# =============================================================
#
# Carrega um personagem através do caminho.
#
# IMPORTANTE:
# -------------------------------------------------------------
# .vrm / .glb / .gltf
#     -> loader normal
#
# .cigaavatar
#     -> procura o personagem correspondente na biblioteca
#     -> carrega como CIGACalibrationAvatar
#
# Assim qualquer sistema antigo que ainda chame:
#
#     load_character(source_path)
#
# continua a funcionar com personagens nativos.
# =============================================================

func load_character(
	path: String
) -> Node3D:

	if path.is_empty():

		return null


	# =========================================================
	# NATIVE AVATAR
	# =========================================================

	var extension := (
		path
		.get_extension()
		.to_lower()
	)


	if extension == "cigaavatar":

		if character_manager == null:

			push_error(
				"CIGA CHARACTER RUNTIME: Character manager is not assigned."
			)

			return null


		var native_character: Dictionary = {}


		# -----------------------------------------------------
		# Procurar o registo da biblioteca que corresponde
		# exactamente a este ficheiro.
		# -----------------------------------------------------

		for character_data: Dictionary in character_manager.characters:

			var source_path := str(
				character_data.get(
					"source_path",
					""
				)
			)


			if source_path == path:

				native_character = (
					character_data
				)

				break


		# -----------------------------------------------------
		# Se o caminho usar diferenças de capitalização,
		# tentar novamente de forma case-insensitive.
		# -----------------------------------------------------

		if native_character.is_empty():

			var normalized_path := (
				path.to_lower()
			)


			for character_data: Dictionary in character_manager.characters:

				var source_path := str(
					character_data.get(
						"source_path",
						""
					)
				)


				if source_path.to_lower() == normalized_path:

					native_character = (
						character_data
					)

					break


		if native_character.is_empty():

			push_error(
				"CIGA CHARACTER RUNTIME: Native character record not found for: "
				+
				path
			)

			return null


		return load_native_character(
			native_character
		)


	# =========================================================
	# IMPORTED CHARACTER
	# =========================================================

	if active_character != null:

		unload_character()


	var instance: Node3D = (
		instantiate_character(
			path
		)
	)


	if instance == null:

		return null


	add_child(
		instance
	)


	active_character = instance

	active_character_path = path

	active_character_type = extension

	active_native_definition.clear()

	active_bone_map.clear()


	# ---------------------------------------------------------
	# FIND SKELETON
	# ---------------------------------------------------------

	var skeleton: Skeleton3D = (
		find_skeleton(
			instance
		)
	)


	if skeleton != null:

		active_bone_map = (
			build_bone_map(
				skeleton
			)
		)


	print(
		"CIGA CHARACTER LOADED: ",
		path
	)


	character_loaded.emit(
		instance
	)


	return instance

# =============================================================
# APPLY SAVED MAPPING
# =============================================================

func apply_saved_mapping(
	saved_bone_map: Dictionary
) -> Dictionary:

	if active_character == null:

		return {}


	var skeleton: Skeleton3D = (
		find_skeleton(
			active_character
		)
	)


	if skeleton == null:

		return {}


	var applied: Dictionary = {}


	for hitpoint_value: Variant in saved_bone_map.keys():

		var hitpoint_name: String = str(
			hitpoint_value
		)


		var bone_name: String = str(
			saved_bone_map[
				hitpoint_value
			]
		)


		if skeleton.find_bone(
			bone_name
		) < 0:

			print(
				"CIGA SAVED MAP: BONE NOT FOUND: ",
				bone_name
			)

			continue


		var point: Node3D = (
			create_hit_point(
				active_character,
				skeleton,
				hitpoint_name,
				bone_name
			)
		)


		if point != null:

			applied[hitpoint_name] = (
				bone_name
			)


	active_bone_map = (
		applied.duplicate(
			true
		)
	)


	if not applied.is_empty():

		hitpoints_created.emit(
			applied
		)


	return (
		applied.duplicate(
			true
		)
	)


# =============================================================
# MAP ACTIVE CHARACTER
# =============================================================

func map_active_character() -> Dictionary:

	if active_character == null:

		return {}


	var skeleton: Skeleton3D = (
		find_skeleton(
			active_character
		)
	)


	if skeleton == null:

		return {}


	var bone_map: Dictionary = (
		build_bone_map(
			skeleton
		)
	)


	active_bone_map.clear()


	for hitpoint_name: String in bone_map.keys():

		var bone_name: String = str(
			bone_map[
				hitpoint_name
			]
		)


		var point: Node3D = (
			create_hit_point(
				active_character,
				skeleton,
				hitpoint_name,
				bone_name
			)
		)


		if point != null:

			active_bone_map[hitpoint_name] = (
				bone_name
			)


	hitpoints_created.emit(
		active_bone_map
	)


	return (
		active_bone_map.duplicate(
			true
		)
	)


# =============================================================
# CREATE HITPOINT
# =============================================================

func create_hit_point(
	character: Node3D,
	skeleton: Skeleton3D,
	hitpoint_name: String,
	bone_name: String
) -> Node3D:

	if character == null:

		return null


	if skeleton == null:

		return null


	if bone_name.is_empty():

		return null


	var existing: Node = (
		character.find_child(
			hitpoint_name,
			true,
			false
		)
	)


	if existing != null:

		if existing is Node3D:

			return (
				existing
				as Node3D
			)

		return null


	var attachment: BoneAttachment3D = (
		BoneAttachment3D.new()
	)


	attachment.name = (
		hitpoint_name
	)

	attachment.bone_name = (
		bone_name
	)


	skeleton.add_child(
		attachment
	)


	return attachment


# =============================================================
# FIND SKELETON
# =============================================================

func find_skeleton(
	root: Node3D
) -> Skeleton3D:

	if root == null:

		return null


	if root is Skeleton3D:

		return (
			root
			as Skeleton3D
		)


	var found: Array[Node] = (
		root.find_children(
			"*",
			"Skeleton3D",
			true,
			false
		)
	)


	for node: Node in found:

		if node is Skeleton3D:

			return (
				node
				as Skeleton3D
			)


	return null


# =============================================================
# BUILD BONE MAP
# =============================================================

func build_bone_map(
	skeleton: Skeleton3D
) -> Dictionary:

	var result: Dictionary = {}


	if skeleton == null:

		return result


	for hitpoint_name: String in HIT_POINT_BONES.keys():

		var aliases: Array = (
			HIT_POINT_BONES[
				hitpoint_name
			]
		)


		var bone_name: String = (
			find_bone_from_aliases(
				skeleton,
				aliases
			)
		)


		if not bone_name.is_empty():

			result[hitpoint_name] = (
				bone_name
			)


	return result


# =============================================================
# FIND BONE
# =============================================================

func find_bone_from_aliases(
	skeleton: Skeleton3D,
	aliases: Array
) -> String:

	if skeleton == null:

		return ""


	for alias_value: Variant in aliases:

		var alias_name: String = str(
			alias_value
		)


		if skeleton.find_bone(
			alias_name
		) >= 0:

			return alias_name


	for index: int in range(
		skeleton.get_bone_count()
	):

		var actual_name: String = (
			skeleton.get_bone_name(
				index
			)
		)


		var actual_lower: String = (
			actual_name.to_lower()
		)


		for alias_value: Variant in aliases:

			var alias_lower: String = (
				str(
					alias_value
				)
				.to_lower()
			)


			if actual_lower == alias_lower:

				return actual_name


	return ""


# =============================================================
# GETTERS
# =============================================================

func get_active_character() -> Node3D:

	if active_character == null:

		return null


	if not is_instance_valid(
		active_character
	):

		active_character = null

		active_character_path = ""

		active_character_type = ""

		active_native_definition.clear()

		active_bone_map.clear()

		return null


	return active_character


# =============================================================

func get_loaded_character() -> Node3D:

	return (
		get_active_character()
	)


# =============================================================

func get_character_model() -> Node3D:

	return (
		get_active_character()
	)


# =============================================================

func get_active_character_path() -> String:

	return active_character_path


# =============================================================

func get_active_bone_map() -> Dictionary:

	return (
		active_bone_map.duplicate(
			true
		)
	)


# =============================================================
# CHARACTER TYPE
# =============================================================

func get_active_character_type() -> String:

	return active_character_type


# =============================================================
# NATIVE DEFINITION
# =============================================================

func get_active_native_definition() -> Dictionary:

	return (
		active_native_definition.duplicate(
			true
		)
	)


# =============================================================
# IS NATIVE
# =============================================================

func is_active_character_native() -> bool:

	return (
		active_character_type
		==
		"native_3d"
	)


# =============================================================
# HITPOINT
# =============================================================

func get_hit_point(
	character: Node3D,
	hitpoint_name: String
) -> Node3D:

	if character == null:

		return null


	var node: Node = (
		character.find_child(
			hitpoint_name,
			true,
			false
		)
	)


	if node is Node3D:

		return (
			node
			as Node3D
		)


	return null


# =============================================================

func get_active_hit_point(
	hitpoint_name: String
) -> Node3D:

	return (
		get_hit_point(
			active_character,
			hitpoint_name
		)
	)


# =============================================================

func get_hit_point_world_position(
	character: Node3D,
	hitpoint_name: String
) -> Vector3:

	var point: Node3D = (
		get_hit_point(
			character,
			hitpoint_name
		)
	)


	if point == null:

		return Vector3.INF


	return point.global_position


# =============================================================
# STATE
# =============================================================

func is_character_loaded() -> bool:

	return (
		active_character != null
		and
		is_instance_valid(
			active_character
		)
	)


# =============================================================
# UNLOAD
# =============================================================

func unload_character() -> void:

	if active_character != null:

		if is_instance_valid(
			active_character
		):

			active_character.queue_free()


	active_character = null

	active_character_path = ""

	active_character_type = ""

	active_native_definition.clear()

	active_bone_map.clear()


	character_unloaded.emit()


	print(
		"CIGA CHARACTER UNLOADED"
	)


# =============================================================
# CACHE
# =============================================================

func clear_cache() -> void:

	scene_cache.clear()

	bone_cache.clear()


	print(
		"CIGA CHARACTER CACHE CLEARED"
	)


# =============================================================
# CLEAR ALL
# =============================================================

func clear_all() -> void:

	unload_character()

	clear_cache()
