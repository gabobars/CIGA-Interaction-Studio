class_name CIGACalibrationAvatar
extends Node3D


# =============================================================
# CIGA CALIBRATION AVATAR
# Godot 4.7.2
#
# STICKMAN 3D DE CALIBRAÇÃO
#
# Este avatar não tenta ser realista.
#
# Serve para:
# - alinhar HitPoints
# - testar interação
# - testar proporções
# - testar outputs
# - preview
#
# A geometria é deliberadamente simples e fina.
# =============================================================


# =============================================================
# CHARACTER
# =============================================================

const CHARACTER_TYPE: String = "native_3d"

const DEFINITION_VERSION: int = 4


# =============================================================
# PROPORTIONS
# =============================================================

const DEFAULT_BODY_HEIGHT: float = 1.70

const DEFAULT_HEAD_RADIUS: float = 0.115

const DEFAULT_SHOULDER_WIDTH: float = 0.40

const DEFAULT_TORSO_WIDTH: float = 0.22

const DEFAULT_TORSO_DEPTH: float = 0.12

const DEFAULT_ARM_LENGTH: float = 0.58

const DEFAULT_LEG_LENGTH: float = 0.82


# =============================================================
# STICKMAN THICKNESS
# =============================================================

const ARM_THICKNESS: float = 0.035

const LEG_THICKNESS: float = 0.045

const HAND_RADIUS: float = 0.040

const FOOT_LENGTH: float = 0.15


# =============================================================
# TAIL
# =============================================================

const DEFAULT_TAIL_LENGTH: float = 0.55

const DEFAULT_TAIL_THICKNESS: float = 0.025

const DEFAULT_TAIL_SEGMENTS: int = 6


# =============================================================
# ROOT
# =============================================================

var body_root: Node3D = null


# =============================================================
# BODY
# =============================================================

var pelvis: MeshInstance3D = null

var waist: MeshInstance3D = null

var torso: MeshInstance3D = null

var chest: MeshInstance3D = null

var abdomen: MeshInstance3D = null

var neck: MeshInstance3D = null


# =============================================================
# HEAD
# =============================================================

var head_pivot: Node3D = null

var head_mesh: MeshInstance3D = null

var jaw: MeshInstance3D = null

var chin: MeshInstance3D = null

var hair: MeshInstance3D = null

var hair_back: MeshInstance3D = null

var hair_side_left: MeshInstance3D = null

var hair_side_right: MeshInstance3D = null

var fringe: MeshInstance3D = null

var nose: MeshInstance3D = null

var left_ear: MeshInstance3D = null

var right_ear: MeshInstance3D = null


# =============================================================
# FACE
# =============================================================

var left_eye: MeshInstance3D = null

var right_eye: MeshInstance3D = null

var left_eye_pupil: MeshInstance3D = null

var right_eye_pupil: MeshInstance3D = null

var left_eyebrow: MeshInstance3D = null

var right_eyebrow: MeshInstance3D = null

var mouth: MeshInstance3D = null


# =============================================================
# ARMS
# =============================================================

var left_shoulder: Node3D = null

var right_shoulder: Node3D = null

var left_upper_arm: Node3D = null

var right_upper_arm: Node3D = null

var left_forearm: Node3D = null

var right_forearm: Node3D = null

var left_hand: MeshInstance3D = null

var right_hand: MeshInstance3D = null


# =============================================================
# LEGS
# =============================================================

var left_leg: Node3D = null

var right_leg: Node3D = null

var left_lower_leg: Node3D = null

var right_lower_leg: Node3D = null

var left_foot: MeshInstance3D = null

var right_foot: MeshInstance3D = null


# =============================================================
# TAIL
# =============================================================

var tail_root: Node3D = null

var tail_segments: Array[MeshInstance3D] = []

var tail_enabled: bool = false

var tail_length: float = DEFAULT_TAIL_LENGTH


# =============================================================
# HITPOINTS
# =============================================================

var head_hit_point: Marker3D = null

var chest_hit_point: Marker3D = null

var left_shoulder_hit_point: Marker3D = null

var right_shoulder_hit_point: Marker3D = null

var left_arm_hit_point: Marker3D = null

var right_arm_hit_point: Marker3D = null

var left_leg_hit_point: Marker3D = null

var right_leg_hit_point: Marker3D = null


# =============================================================
# MATERIALS
# =============================================================

var body_material: StandardMaterial3D = null

var body_secondary_material: StandardMaterial3D = null

var skin_material: StandardMaterial3D = null

var skin_secondary_material: StandardMaterial3D = null

var hair_material: StandardMaterial3D = null

var eye_material: StandardMaterial3D = null

var pupil_material: StandardMaterial3D = null

var eyebrow_material: StandardMaterial3D = null

var mouth_material: StandardMaterial3D = null

var shoe_material: StandardMaterial3D = null

var tail_material: StandardMaterial3D = null


# =============================================================
# AVATAR PARAMETERS
# =============================================================

var body_scale: float = 1.0

var head_scale: float = 1.0

var arm_length_scale: float = 1.0

var leg_length_scale: float = 1.0

var body_width_scale: float = 1.0

var shoulder_width_scale: float = 1.0


# =============================================================
# HEAD
# =============================================================

var head_rotation: Vector3 = Vector3.ZERO


# =============================================================
# ARMS
# =============================================================

var left_arm_pose: float = 0.0

var right_arm_pose: float = 0.0


# =============================================================
# FACE
# =============================================================

var left_eye_open: float = 1.0

var right_eye_open: float = 1.0

var mouth_open: float = 0.0


# =============================================================
# READY
# =============================================================

func _ready() -> void:

	build_avatar()


# =============================================================
# BUILD
# =============================================================

func build_avatar() -> void:

	for child: Node in get_children():

		child.free()


	_reset_references()

	create_materials()


	body_root = Node3D.new()

	body_root.name = "BodyRoot"

	add_child(
		body_root
	)


	_create_torso()

	_create_head()

	_create_arms()

	_create_legs()

	create_tail()


	rebuild_transform()

	set_eye_open(
		left_eye_open,
		right_eye_open
	)

	set_mouth_open(
		mouth_open
	)

	set_tail_enabled(
		tail_enabled
	)


# =============================================================
# RESET REFERENCES
# =============================================================

func _reset_references() -> void:

	body_root = null


	pelvis = null

	waist = null

	torso = null

	chest = null

	abdomen = null

	neck = null


	head_pivot = null

	head_mesh = null

	jaw = null

	chin = null

	hair = null

	hair_back = null

	hair_side_left = null

	hair_side_right = null

	fringe = null

	nose = null

	left_ear = null

	right_ear = null


	left_eye = null

	right_eye = null

	left_eye_pupil = null

	right_eye_pupil = null

	left_eyebrow = null

	right_eyebrow = null

	mouth = null


	left_shoulder = null

	right_shoulder = null

	left_upper_arm = null

	right_upper_arm = null

	left_forearm = null

	right_forearm = null

	left_hand = null

	right_hand = null


	left_leg = null

	right_leg = null

	left_lower_leg = null

	right_lower_leg = null

	left_foot = null

	right_foot = null


	tail_root = null

	tail_segments.clear()


	head_hit_point = null

	chest_hit_point = null

	left_shoulder_hit_point = null

	right_shoulder_hit_point = null

	left_arm_hit_point = null

	right_arm_hit_point = null

	left_leg_hit_point = null

	right_leg_hit_point = null


# =============================================================
# TORSO
# =============================================================

func _create_torso() -> void:

	# ---------------------------------------------------------
	# Main torso
	# ---------------------------------------------------------

	torso = create_box(
		"Torso",
		Vector3(
			DEFAULT_TORSO_WIDTH,
			0.68,
			DEFAULT_TORSO_DEPTH
		),
		body_material
	)

	torso.position = Vector3(
		0.0,
		1.02,
		0.0
	)

	body_root.add_child(
		torso
	)


	# ---------------------------------------------------------
	# Chest
	# ---------------------------------------------------------

	chest = create_box(
		"Chest",
		Vector3(
			0.27,
			0.18,
			0.13
		),
		body_secondary_material
	)

	chest.position = Vector3(
		0.0,
		1.30,
		-0.005
	)

	body_root.add_child(
		chest
	)


	# ---------------------------------------------------------
	# Pelvis
	# ---------------------------------------------------------

	pelvis = create_box(
		"Pelvis",
		Vector3(
			0.29,
			0.15,
			0.13
		),
		body_secondary_material
	)

	pelvis.position = Vector3(
		0.0,
		0.69,
		0.0
	)

	body_root.add_child(
		pelvis
	)


	# ---------------------------------------------------------
	# Neck
	# ---------------------------------------------------------

	neck = create_cylinder(
		"Neck",
		0.042,
		0.11,
		skin_material
	)

	neck.position = Vector3(
		0.0,
		1.49,
		0.0
	)

	body_root.add_child(
		neck
	)


	# ---------------------------------------------------------
	# Chest hitpoint
	# ---------------------------------------------------------

	chest_hit_point = create_hit_point(
		"ChestHitPoint",
		Vector3(
			0.0,
			1.27,
			-0.075
		)
	)

	body_root.add_child(
		chest_hit_point
	)


# =============================================================
# HEAD
# =============================================================

func _create_head() -> void:

	head_pivot = Node3D.new()

	head_pivot.name = "Head"

	head_pivot.position = Vector3(
		0.0,
		1.69,
		0.0
	)

	body_root.add_child(
		head_pivot
	)


	# ---------------------------------------------------------
	# Head
	# ---------------------------------------------------------

	head_mesh = create_sphere(
		"HeadMesh",
		DEFAULT_HEAD_RADIUS,
		skin_material
	)

	head_mesh.scale = Vector3(
		0.95,
		1.05,
		0.90
	)

	head_pivot.add_child(
		head_mesh
	)


	# ---------------------------------------------------------
	# Head hitpoint
	# ---------------------------------------------------------

	head_hit_point = create_hit_point(
		"HeadHitPoint",
		Vector3(
			0.0,
			0.0,
			-0.02
		)
	)

	head_pivot.add_child(
		head_hit_point
	)


	# ---------------------------------------------------------
	# Simple hair
	# ---------------------------------------------------------

	hair = create_sphere(
		"Hair",
		DEFAULT_HEAD_RADIUS + 0.006,
		hair_material
	)

	hair.position.y = 0.035

	hair.scale = Vector3(
		1.02,
		0.55,
		1.02
	)

	head_pivot.add_child(
		hair
	)


# =============================================================
# ARMS
# =============================================================

func _create_arms() -> void:

	_create_single_arm(
		true
	)

	_create_single_arm(
		false
	)


func _create_single_arm(
	is_left: bool
) -> void:

	var side: float = -1.0

	if not is_left:

		side = 1.0


	var shoulder_name: String = "LeftShoulder"

	var upper_name: String = "LeftUpperArm"

	var forearm_name: String = "LeftForearm"

	var shoulder_hit_name: String = "LeftShoulderHitPoint"

	var arm_hit_name: String = "LeftArmHitPoint"


	if not is_left:

		shoulder_name = "RightShoulder"

		upper_name = "RightUpperArm"

		forearm_name = "RightForearm"

		shoulder_hit_name = "RightShoulderHitPoint"

		arm_hit_name = "RightArmHitPoint"


	# ---------------------------------------------------------
	# Shoulder
	# ---------------------------------------------------------

	var shoulder := Node3D.new()

	shoulder.name = shoulder_name

	shoulder.position = Vector3(
		side
		*
		(
			DEFAULT_SHOULDER_WIDTH
			*
			0.5
		),
		1.36,
		0.0
	)

	body_root.add_child(
		shoulder
	)


	# ---------------------------------------------------------
	# Shoulder hitpoint
	# ---------------------------------------------------------

	var shoulder_hit := create_hit_point(
		shoulder_hit_name,
		Vector3.ZERO
	)

	shoulder.add_child(
		shoulder_hit
	)


	# ---------------------------------------------------------
	# Upper arm pivot
	# ---------------------------------------------------------

	var upper_arm := Node3D.new()

	upper_arm.name = upper_name

	upper_arm.position = Vector3(
		0.0,
		-0.18,
		0.0
	)

	shoulder.add_child(
		upper_arm
	)


	# ---------------------------------------------------------
	# Upper arm geometry
	# ---------------------------------------------------------

	var upper_mesh := create_cylinder(
		"UpperArmMesh",
		ARM_THICKNESS,
		0.36,
		body_material
	)

	upper_mesh.position = Vector3(
		0.0,
		-0.18,
		0.0
	)

	upper_arm.add_child(
		upper_mesh
	)


	# ---------------------------------------------------------
	# Forearm pivot
	# ---------------------------------------------------------

	var forearm := Node3D.new()

	forearm.name = forearm_name

	forearm.position = Vector3(
		0.0,
		-0.36,
		0.0
	)

	upper_arm.add_child(
		forearm
	)


	# ---------------------------------------------------------
	# Forearm geometry
	# ---------------------------------------------------------

	var forearm_mesh := create_cylinder(
		"ForearmMesh",
		ARM_THICKNESS * 0.90,
		0.30,
		body_material
	)

	forearm_mesh.position = Vector3(
		0.0,
		-0.15,
		0.0
	)

	forearm.add_child(
		forearm_mesh
	)


	# ---------------------------------------------------------
	# Hand
	# ---------------------------------------------------------

	var hand := create_sphere(
		"Hand",
		HAND_RADIUS,
		skin_material
	)

	hand.position = Vector3(
		0.0,
		-0.32,
		0.0
	)

	hand.scale = Vector3(
		0.80,
		1.15,
		0.65
	)

	forearm.add_child(
		hand
	)


	# ---------------------------------------------------------
	# Arm hitpoint
	# ---------------------------------------------------------

	var arm_hit := create_hit_point(
		arm_hit_name,
		Vector3(
			0.0,
			-0.16,
			-0.02
		)
	)

	forearm.add_child(
		arm_hit
	)


	# ---------------------------------------------------------
	# Store references
	# ---------------------------------------------------------

	if is_left:

		left_shoulder = shoulder

		left_upper_arm = upper_arm

		left_forearm = forearm

		left_hand = hand

		left_shoulder_hit_point = shoulder_hit

		left_arm_hit_point = arm_hit

	else:

		right_shoulder = shoulder

		right_upper_arm = upper_arm

		right_forearm = forearm

		right_hand = hand

		right_shoulder_hit_point = shoulder_hit

		right_arm_hit_point = arm_hit


# =============================================================
# LEGS
# =============================================================

func _create_legs() -> void:

	_create_single_leg(
		true
	)

	_create_single_leg(
		false
	)


func _create_single_leg(
	is_left: bool
) -> void:

	var side: float = -1.0

	if not is_left:

		side = 1.0


	var leg_name: String = "LeftLeg"

	var lower_name: String = "LeftLowerLeg"

	var hit_name: String = "LeftLegHitPoint"

	if not is_left:

		leg_name = "RightLeg"

		lower_name = "RightLowerLeg"

		hit_name = "RightLegHitPoint"


	# ---------------------------------------------------------
	# Leg root
	# ---------------------------------------------------------

	var leg := Node3D.new()

	leg.name = leg_name

	leg.position = Vector3(
		side * 0.09,
		0.66,
		0.0
	)

	body_root.add_child(
		leg
	)


	# ---------------------------------------------------------
	# Upper leg
	# ---------------------------------------------------------

	var upper_leg := create_cylinder(
		"UpperLegMesh",
		LEG_THICKNESS,
		0.43,
		body_material
	)

	upper_leg.position = Vector3(
		0.0,
		-0.215,
		0.0
	)

	leg.add_child(
		upper_leg
	)


	# ---------------------------------------------------------
	# Lower leg
	# ---------------------------------------------------------

	var lower_leg := Node3D.new()

	lower_leg.name = lower_name

	lower_leg.position = Vector3(
		0.0,
		-0.43,
		0.0
	)

	leg.add_child(
		lower_leg
	)


	var lower_mesh := create_cylinder(
		"LowerLegMesh",
		LEG_THICKNESS * 0.90,
		0.39,
		body_material
	)

	lower_mesh.position = Vector3(
		0.0,
		-0.195,
		0.0
	)

	lower_leg.add_child(
		lower_mesh
	)


	# ---------------------------------------------------------
	# Foot
	# ---------------------------------------------------------

	var foot := create_box(
		"Foot",
		Vector3(
			0.085,
			0.06,
			FOOT_LENGTH
		),
		shoe_material
	)

	foot.position = Vector3(
		0.0,
		-0.405,
		-0.045
	)

	lower_leg.add_child(
		foot
	)


	# ---------------------------------------------------------
	# Hitpoint
	# ---------------------------------------------------------

	var leg_hit := create_hit_point(
		hit_name,
		Vector3(
			0.0,
			-0.72,
			-0.02
		)
	)

	leg.add_child(
		leg_hit
	)


	# ---------------------------------------------------------
	# Store
	# ---------------------------------------------------------

	if is_left:

		left_leg = leg

		left_lower_leg = lower_leg

		left_foot = foot

		left_leg_hit_point = leg_hit

	else:

		right_leg = leg

		right_lower_leg = lower_leg

		right_foot = foot

		right_leg_hit_point = leg_hit


# =============================================================
# TAIL
# =============================================================

func create_tail() -> void:

	tail_root = Node3D.new()

	tail_root.name = "Tail"

	tail_root.position = Vector3(
		0.0,
		0.78,
		0.06
	)

	tail_root.rotation_degrees.x = 12.0

	body_root.add_child(
		tail_root
	)


	tail_segments.clear()


	for index: int in range(
		DEFAULT_TAIL_SEGMENTS
	):

		var thickness := maxf(
			DEFAULT_TAIL_THICKNESS
			*
			(
				1.0
				-
				(
					float(index)
					/
					float(
						DEFAULT_TAIL_SEGMENTS + 1
					)
				)
			),
			0.008
		)


		var segment := create_cylinder(
			"TailSegment_%02d" % index,
			thickness,
			DEFAULT_TAIL_LENGTH
			/
			float(DEFAULT_TAIL_SEGMENTS),
			tail_material
		)


		segment.position = Vector3(
			0.0,
			-
			float(index)
			*
			(
				DEFAULT_TAIL_LENGTH
				/
				float(DEFAULT_TAIL_SEGMENTS)
			),
			0.0
		)


		tail_root.add_child(
			segment
		)


		tail_segments.append(
			segment
		)


func set_tail_enabled(
	enabled: bool
) -> void:

	tail_enabled = enabled


	if tail_root == null:

		return


	tail_root.visible = enabled


func set_tail_length(
	new_length: float
) -> void:

	tail_length = clampf(
		new_length,
		0.05,
		3.0
	)


	if tail_root == null:

		return


	var count: int = maxi(
		tail_segments.size(),
		1
	)


	for index: int in range(
		tail_segments.size()
	):

		var segment := tail_segments[index]


		var ratio: float = (
			float(index)
			/
			float(
				maxi(
					tail_segments.size() - 1,
					1
				)
			)
		)


		segment.position.y = (
			-ratio
			*
			tail_length
		)


		var base_length: float = (
			DEFAULT_TAIL_LENGTH
			/
			float(DEFAULT_TAIL_SEGMENTS)
		)


		var segment_length: float = (
			tail_length
			/
			float(count)
		)


		var scale_ratio: float = (
			segment_length
			/
			base_length
		)


		segment.scale = Vector3(
			1.0,
			scale_ratio,
			1.0
		)


# =============================================================
# HITPOINT
# =============================================================

func create_hit_point(
	hitpoint_name: String,
	local_position: Vector3
) -> Marker3D:

	var marker := Marker3D.new()

	marker.name = hitpoint_name

	marker.position = local_position

	return marker


# =============================================================
# MATERIALS
# =============================================================

func create_materials() -> void:

	body_material = StandardMaterial3D.new()

	body_material.albedo_color = Color(
		0.16,
		0.18,
		0.22
	)

	body_material.roughness = 0.90


	body_secondary_material = StandardMaterial3D.new()

	body_secondary_material.albedo_color = Color(
		0.24,
		0.26,
		0.30
	)

	body_secondary_material.roughness = 0.90


	skin_material = StandardMaterial3D.new()

	skin_material.albedo_color = Color(
		0.62,
		0.52,
		0.46
	)

	skin_material.roughness = 0.84


	skin_secondary_material = StandardMaterial3D.new()

	skin_secondary_material.albedo_color = Color(
		0.56,
		0.46,
		0.40
	)

	skin_secondary_material.roughness = 0.88


	hair_material = StandardMaterial3D.new()

	hair_material.albedo_color = Color(
		0.025,
		0.028,
		0.035
	)

	hair_material.roughness = 0.75


	eye_material = StandardMaterial3D.new()

	eye_material.albedo_color = Color(
		0.90,
		0.92,
		0.95
	)

	eye_material.roughness = 0.25


	pupil_material = StandardMaterial3D.new()

	pupil_material.albedo_color = Color(
		0.015,
		0.018,
		0.022
	)

	pupil_material.roughness = 0.15


	eyebrow_material = StandardMaterial3D.new()

	eyebrow_material.albedo_color = Color(
		0.025,
		0.027,
		0.032
	)

	eyebrow_material.roughness = 0.80


	mouth_material = StandardMaterial3D.new()

	mouth_material.albedo_color = Color(
		0.12,
		0.045,
		0.055
	)

	mouth_material.roughness = 0.75


	shoe_material = StandardMaterial3D.new()

	shoe_material.albedo_color = Color(
		0.025,
		0.028,
		0.034
	)

	shoe_material.roughness = 0.92


	tail_material = StandardMaterial3D.new()

	tail_material.albedo_color = Color(
		0.17,
		0.18,
		0.22
	)

	tail_material.roughness = 0.88


# =============================================================
# MESH HELPERS
# =============================================================

func create_sphere(
	node_name: String,
	radius: float,
	material: Material
) -> MeshInstance3D:

	var mesh_instance := MeshInstance3D.new()

	mesh_instance.name = node_name


	var mesh := SphereMesh.new()

	mesh.radius = radius

	mesh.height = radius * 2.0

	mesh.radial_segments = 20

	mesh.rings = 12


	mesh_instance.mesh = mesh

	mesh_instance.material_override = material

	return mesh_instance


func create_box(
	node_name: String,
	size: Vector3,
	material: Material
) -> MeshInstance3D:

	var mesh_instance := MeshInstance3D.new()

	mesh_instance.name = node_name


	var mesh := BoxMesh.new()

	mesh.size = size


	mesh_instance.mesh = mesh

	mesh_instance.material_override = material

	return mesh_instance


func create_cylinder(
	node_name: String,
	radius: float,
	height: float,
	material: Material
) -> MeshInstance3D:

	var mesh_instance := MeshInstance3D.new()

	mesh_instance.name = node_name


	var mesh := CylinderMesh.new()

	mesh.top_radius = radius

	mesh.bottom_radius = radius

	mesh.height = height

	mesh.radial_segments = 16


	mesh_instance.mesh = mesh

	mesh_instance.material_override = material

	return mesh_instance


# =============================================================
# HEAD ROTATION
# =============================================================

func set_head_rotation(
	rotation_degrees: Vector3
) -> void:

	head_rotation = rotation_degrees


	if head_pivot == null:

		return


	head_pivot.rotation_degrees = (
		head_rotation
	)


# =============================================================
# ARM POSE
# =============================================================

func set_arm_pose(
	left_value: float,
	right_value: float
) -> void:

	left_arm_pose = clampf(
		left_value,
		0.0,
		1.0
	)

	right_arm_pose = clampf(
		right_value,
		0.0,
		1.0
	)


	if left_shoulder != null:

		left_shoulder.rotation_degrees.z = lerpf(
			0.0,
			90.0,
			left_arm_pose
		)


	if right_shoulder != null:

		right_shoulder.rotation_degrees.z = lerpf(
			0.0,
			-90.0,
			right_arm_pose
		)


# =============================================================
# EYES
# =============================================================

func set_eye_open(
	left_value: float,
	right_value: float
) -> void:

	left_eye_open = clampf(
		left_value,
		0.0,
		1.0
	)

	right_eye_open = clampf(
		right_value,
		0.0,
		1.0
	)


	if left_eye != null:

		var left_scale := left_eye.scale

		left_scale.y = lerpf(
			0.08,
			1.0,
			left_eye_open
		)

		left_eye.scale = left_scale


	if right_eye != null:

		var right_scale := right_eye.scale

		right_scale.y = lerpf(
			0.08,
			1.0,
			right_eye_open
		)

		right_eye.scale = right_scale


# =============================================================
# MOUTH
# =============================================================

func set_mouth_open(
	value: float
) -> void:

	mouth_open = clampf(
		value,
		0.0,
		1.0
	)


	if mouth == null:

		return


	mouth.scale.y = lerpf(
		1.0,
		3.0,
		mouth_open
	)


# =============================================================
# AVATAR SCALE
# =============================================================

func set_avatar_scale(
	new_body_scale: float,
	new_head_scale: float
) -> void:

	body_scale = clampf(
		new_body_scale,
		0.70,
		1.50
	)

	head_scale = clampf(
		new_head_scale,
		0.75,
		1.30
	)

	rebuild_transform()


# =============================================================
# BODY WIDTH
# =============================================================

func set_body_width(
	value: float
) -> void:

	body_width_scale = clampf(
		value,
		0.75,
		1.35
	)

	rebuild_transform()


# =============================================================
# SHOULDER WIDTH
# =============================================================

func set_shoulder_width(
	value: float
) -> void:

	shoulder_width_scale = clampf(
		value,
		0.75,
		1.35
	)

	rebuild_transform()


# =============================================================
# ARM LENGTH
# =============================================================

func set_arm_length(
	value: float
) -> void:

	arm_length_scale = clampf(
		value,
		0.75,
		1.30
	)

	rebuild_transform()


# =============================================================
# LEG LENGTH
# =============================================================

func set_leg_length(
	value: float
) -> void:

	leg_length_scale = clampf(
		value,
		0.75,
		1.30
	)

	rebuild_transform()


# =============================================================
# REBUILD TRANSFORM
# =============================================================

func rebuild_transform() -> void:

	if body_root == null:

		return


	body_root.scale = Vector3(
		body_scale * body_width_scale,
		body_scale,
		body_scale
	)


	if head_pivot != null:

		head_pivot.scale = (
			Vector3.ONE
			*
			head_scale
		)


	var shoulder_x := (
		DEFAULT_SHOULDER_WIDTH
	*
	0.5
	*
	shoulder_width_scale
	)


	if left_shoulder != null:

		left_shoulder.position.x = (
			-shoulder_x
		)


	if right_shoulder != null:

		right_shoulder.position.x = (
			shoulder_x
		)


	var arm_scale := Vector3(
		1.0,
		arm_length_scale,
		1.0
	)


	if left_upper_arm != null:

		left_upper_arm.scale = arm_scale


	if right_upper_arm != null:

		right_upper_arm.scale = arm_scale


	var leg_scale := Vector3(
		1.0,
		leg_length_scale,
		1.0
	)


	if left_leg != null:

		left_leg.scale = leg_scale


	if right_leg != null:

		right_leg.scale = leg_scale


	set_head_rotation(
		head_rotation
	)

	set_arm_pose(
		left_arm_pose,
		right_arm_pose
	)


# =============================================================
# GET HITPOINT
# =============================================================

func get_hit_point(
	hitpoint_name: String
) -> Node3D:

	var node: Node = find_child(
		hitpoint_name,
		true,
		false
	)


	if node is Node3D:

		return node as Node3D


	return null


# =============================================================
# GET DEFINITION
# =============================================================

func get_definition() -> Dictionary:

	return {

		"version":
			DEFINITION_VERSION,

		"character_type":
			CHARACTER_TYPE,

		"avatar":
			{
				"body_scale":
					body_scale,

				"head_scale":
					head_scale,

				"arm_length":
					arm_length_scale,

				"leg_length":
					leg_length_scale,

				"body_width":
					body_width_scale,

				"shoulder_width":
					shoulder_width_scale
			},

		"pose":
			{
				"head_rotation":
					{
						"x":
							head_rotation.x,

						"y":
							head_rotation.y,

						"z":
							head_rotation.z
					},

				"left_arm":
					left_arm_pose,

				"right_arm":
					right_arm_pose,

				"left_eye":
					left_eye_open,

				"right_eye":
					right_eye_open,

				"mouth":
					mouth_open
			},

		"tail":
			{
				"enabled":
					tail_enabled,

				"length":
					tail_length
			}
	}
