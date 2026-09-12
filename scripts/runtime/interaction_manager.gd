extends Node
class_name CIGAinteractionManager


signal impact_received(
	hit_point_name: String,
	force: float,
	impact_direction: Vector3
)


# =============================================================
# CIGA INTERACTION MANAGER
# Godot 4.7.2
#
# NORMAL MODE ONLY
#
# 3D:
#
#     Projectile
#         ↓
#     Impact
#         ↓
#     Body Spring
#         ↓
#     Character rotation
#         ↓
#     VMC
#
#
# 2D:
#
#     Projectile
#         ↓
#     Hit Point
#         ↓
#     2D Impact Pose
#         ↓
#     Hold
#         ↓
#     2D Spring Recovery
#         ↓
#     VTube Studio
#
#
#     Leg Hit
#         ↓
#     2D Root Spring
#         ↓
#     CIGARootX
#
#
# 2D NÃO TENTA MOVER O MEMBRO ATINGIDO.
#
# A ROOT DO PREVIEW GODOT PERMANECE FIXA.
#
# CIGARootX é apenas um OUTPUT 2D.
#
# VMC / 3D não recebe CIGARootX.
#
# =============================================================


# =============================================================
# STATE
# =============================================================

enum CharacterState {
	NORMAL,
	IMPACTED,
	RECOVERING
}


var character_state: CharacterState = (
	CharacterState.NORMAL
)


# =============================================================
# OUTPUT MODE
# =============================================================

var is_2d_mode: bool = false


# =============================================================
# HIT POINTS
# =============================================================

const HIT_POINT_NAMES: Array[String] = [

	"ChestHitPoint",
	"HeadHitPoint",
	"LeftShoulderHitPoint",
	"RightShoulderHitPoint",
	"LeftArmHitPoint",
	"RightArmHitPoint",
	"LeftLegHitPoint",
	"RightLegHitPoint"
]


# =============================================================
# OBJECT SETTINGS
# =============================================================

var object_type: String = "OBJECT"

var object_speed: float = 6.2

var object_force: float = 1.8

var target_hit_point: String = "ChestHitPoint"


# =============================================================
# CHARACTER
# =============================================================

var character: Node3D = null

var hit_points: Node3D = null

var original_position: Vector3 = Vector3.ZERO

var original_rotation: Vector3 = Vector3.ZERO


# =============================================================
# NORMAL 3D SPRING
# =============================================================

const BODY_SPRING_STIFFNESS: float = 80.0

const BODY_SPRING_DAMPING: float = 9.0

const HEAD_SPRING_STIFFNESS: float = 95.0

const HEAD_SPRING_DAMPING: float = 8.5


# =============================================================
# BODY OFFSET
# =============================================================

var body_rot_offset: Vector3 = Vector3.ZERO

var body_rot_velocity: Vector3 = Vector3.ZERO


# =============================================================
# HEAD OFFSET
# =============================================================

var head_rot_offset: Vector3 = Vector3.ZERO

var head_rot_velocity: Vector3 = Vector3.ZERO


# =============================================================
# LEGACY POSITION
# =============================================================

var body_pos_offset: Vector3 = Vector3.ZERO

var body_pos_velocity: Vector3 = Vector3.ZERO


# =============================================================
# NORMAL LIMITS
# =============================================================

const BASE_MAX_ROT_X: float = 0.32

const BASE_MAX_ROT_Y: float = 0.38

const BASE_MAX_ROT_Z: float = 0.28


const ABSOLUTE_MAX_ROT_X: float = 1.15

const ABSOLUTE_MAX_ROT_Y: float = 1.00

const ABSOLUTE_MAX_ROT_Z: float = 0.95


const MAX_HEAD_ROT: float = 0.65


# =============================================================
# NORMAL VELOCITIES
# =============================================================

const MAX_BODY_ROTATION_VELOCITY: float = 7.0

const MAX_HEAD_ROTATION_VELOCITY: float = 6.0


# =============================================================
# IMPACT FORCE
# =============================================================

const MAX_IMPACT_FORCE: float = 3.0

const MIN_IMPACT_FORCE: float = 0.0


# =============================================================
# IMPACT ACCUMULATION
# =============================================================

const MAX_IMPACTS_PER_WINDOW: int = 4

const IMPACT_WINDOW_TIME: float = 0.08

const IMPACT_OVERLOAD_REDUCTION: float = 0.35


var impact_window_timer: float = 0.0

var impact_window_count: int = 0


# =============================================================
# IMPACT MOVEMENT
# =============================================================

const MIN_IMPACT_MOVEMENT: float = 0.0

const MAX_IMPACT_MOVEMENT: float = 5.0

const DEFAULT_IMPACT_MOVEMENT: float = 1.0


var impact_movement: float = (
	DEFAULT_IMPACT_MOVEMENT
)


# =============================================================
# 2D GLOBAL BODY REACTION
# =============================================================

# Estes valores representam a força lógica do impacto.
#
# NÃO são multiplicadores gigantes de rotação.
#
# O resultado final é convertido numa POSE 2D.
#
# LEFT HIT  -> corpo reage para a direita
# RIGHT HIT -> corpo reage para a esquerda


const BODY_2D_SIDE_FORCE: float = 0.34

const BODY_2D_SIDE_ROLL: float = 0.55

const BODY_2D_SIDE_PITCH: float = 0.10


const BODY_2D_CHEST_FORCE: float = 0.30

const BODY_2D_CHEST_ROLL: float = 0.16


const BODY_2D_LEG_FORCE: float = 0.24

const BODY_2D_LEG_ROLL: float = 0.30


const BODY_2D_HEAD_FORCE: float = 0.26

const BODY_2D_HEAD_ROLL: float = 0.24


# =============================================================
# 2D IMPACT POSE
# =============================================================

# Esta é a principal alteração.
#
# Em vez de gerar uma velocidade enorme e esperar que o spring
# produza uma reação visível, o impacto gera uma pose alvo.
#
# A pose fica presente durante alguns frames.
#
# Depois o alvo decai para 0 e o spring faz o retorno.
#
# Isto é muito mais adequado para Live2D.


const BODY_2D_POSE_HOLD_TIME: float = 0.12

const BODY_2D_POSE_RECOVERY_SPEED: float = 7.0

const BODY_2D_POSE_FORCE_SCALE: float = 1.00

const BODY_2D_POSE_MAX_X: float = 0.22

const BODY_2D_POSE_MAX_Y: float = 0.30

const BODY_2D_POSE_MAX_Z: float = 0.32


var body_2d_target: Vector3 = Vector3.ZERO

var body_2d_pose_timer: float = 0.0


# =============================================================
# 2D IMMEDIATE BODY KICK
# =============================================================

# Pequeno kick inicial para evitar latência visual.
#
# A maior parte da reação vem agora da POSE TARGET.
#
# Isto apenas coloca a personagem imediatamente em movimento.


const BODY_2D_IMMEDIATE_SIDE_YAW: float = 0.030

const BODY_2D_IMMEDIATE_SIDE_ROLL: float = 0.045

const BODY_2D_IMMEDIATE_SIDE_PITCH: float = 0.015


const BODY_2D_IMMEDIATE_CHEST_PITCH: float = 0.040

const BODY_2D_IMMEDIATE_CHEST_ROLL: float = 0.020


const BODY_2D_IMMEDIATE_HEAD_BODY_PITCH: float = 0.030

const BODY_2D_IMMEDIATE_HEAD_BODY_ROLL: float = 0.020


# =============================================================
# HEAD 2D
# =============================================================

const HEAD_2D_IMPACT_FORCE: float = 2.2


# =============================================================
# 2D GLOBAL ROTATION LIMITS
# =============================================================

const BODY_2D_MAX_ROT_X: float = 0.40

const BODY_2D_MAX_ROT_Y: float = 0.55

const BODY_2D_MAX_ROT_Z: float = 0.55


# =============================================================
# 2D GLOBAL ROTATION VELOCITY
# =============================================================

const BODY_2D_MAX_ROTATION_VELOCITY: float = 5.5


# =============================================================
# 2D ROOT SPRING
# =============================================================

# CIGARootX é uma mola independente.
#
# LeftLegHitPoint:
#
#     root X +
#
#     lower body -> direita
#
# RightLegHitPoint:
#
#     root X -
#
#     lower body -> esquerda
#
# O Node3D NÃO é movido.
#
# Este valor existe apenas para o output 2D.


const ROOT_2D_SPRING_STIFFNESS: float = 30.0

const ROOT_2D_SPRING_DAMPING: float = 4.2

const ROOT_2D_IMPACT_FORCE: float = 2.75

const ROOT_2D_MAX_OFFSET: float = 0.35

const ROOT_2D_MAX_VELOCITY: float = 7.0


var root_2d_offset_x: float = 0.0

var root_2d_velocity_x: float = 0.0


# =============================================================
# READY
# =============================================================

func _ready() -> void:

	process_priority = 19000


# =============================================================
# OUTPUT MODE
# =============================================================

func set_2d_mode(
	enabled: bool
) -> void:

	is_2d_mode = enabled


	if not is_2d_mode:

		body_2d_target = Vector3.ZERO

		body_2d_pose_timer = 0.0

		root_2d_offset_x = 0.0

		root_2d_velocity_x = 0.0


func is_2d_output_mode() -> bool:

	return is_2d_mode


# =============================================================
# NORMAL HELPERS
# =============================================================

func get_effective_body_stiffness() -> float:

	var movement := maxf(
		impact_movement,
		0.01
	)

	return (
		BODY_SPRING_STIFFNESS
		/
		(
			movement
			*
			movement
		)
	)


func get_effective_body_damping() -> float:

	var movement := maxf(
		impact_movement,
		0.01
	)

	return (
		BODY_SPRING_DAMPING
		/
		movement
	)


func get_effective_max_rot_x() -> float:

	return minf(
		BASE_MAX_ROT_X
		*
		maxf(
			impact_movement,
			0.0
		),
		ABSOLUTE_MAX_ROT_X
	)


func get_effective_max_rot_y() -> float:

	return minf(
		BASE_MAX_ROT_Y
		*
		maxf(
			impact_movement,
			0.0
		),
		ABSOLUTE_MAX_ROT_Y
	)


func get_effective_max_rot_z() -> float:

	return minf(
		BASE_MAX_ROT_Z
		*
		maxf(
			impact_movement,
			0.0
		),
		ABSOLUTE_MAX_ROT_Z
	)


# =============================================================
# PROCESS
# =============================================================

func _process(
	delta: float
) -> void:

	if character == null:

		return


	var dt := minf(
		delta,
		0.033
	)


	# ---------------------------------------------------------
	# IMPACT WINDOW
	# ---------------------------------------------------------

	impact_window_timer -= delta


	if impact_window_timer <= 0.0:

		impact_window_timer = 0.0

		impact_window_count = 0


	# ---------------------------------------------------------
	# ROOT ALWAYS FIXED
	# ---------------------------------------------------------

	character.position = (
		original_position
	)


	# ---------------------------------------------------------
	# BODY / HEAD / 2D ROOT
	# ---------------------------------------------------------

	_process_normal(
		dt
	)


# =============================================================
# NORMAL PROCESS
# =============================================================

func _process_normal(
	dt: float
) -> void:

	# ---------------------------------------------------------
	# BODY
	# ---------------------------------------------------------

	if impact_movement > 0.0:

		if is_2d_mode:

			_process_2d_body(
				dt
			)

		else:

			_process_3d_body(
				dt
			)

	else:

		body_rot_offset = Vector3.ZERO

		body_rot_velocity = Vector3.ZERO

		body_2d_target = Vector3.ZERO

		body_2d_pose_timer = 0.0


	# ---------------------------------------------------------
	# HEAD
	# ---------------------------------------------------------

	var head_force := (

		-HEAD_SPRING_STIFFNESS
		*
		head_rot_offset

		-

		HEAD_SPRING_DAMPING
		*
		head_rot_velocity
	)


	head_rot_velocity += (
		head_force
		*
		dt
	)


	head_rot_velocity = (
		head_rot_velocity.limit_length(
			MAX_HEAD_ROTATION_VELOCITY
		)
	)


	head_rot_offset += (
		head_rot_velocity
		*
		dt
	)


	head_rot_offset.x = clampf(
		head_rot_offset.x,
		-MAX_HEAD_ROT,
		MAX_HEAD_ROT
	)

	head_rot_offset.y = clampf(
		head_rot_offset.y,
		-MAX_HEAD_ROT,
		MAX_HEAD_ROT
	)

	head_rot_offset.z = clampf(
		head_rot_offset.z,
		-MAX_HEAD_ROT,
		MAX_HEAD_ROT
	)


	# ---------------------------------------------------------
	# ROOT 2D SPRING
	# ---------------------------------------------------------

	if is_2d_mode:

		var root_spring_force := (

			-ROOT_2D_SPRING_STIFFNESS
			*
			root_2d_offset_x

			-

			ROOT_2D_SPRING_DAMPING
			*
			root_2d_velocity_x
		)


		root_2d_velocity_x += (
			root_spring_force
			*
			dt
		)


		root_2d_velocity_x = clampf(
			root_2d_velocity_x,
			-ROOT_2D_MAX_VELOCITY,
			ROOT_2D_MAX_VELOCITY
		)


		root_2d_offset_x += (
			root_2d_velocity_x
			*
			dt
		)


		root_2d_offset_x = clampf(
			root_2d_offset_x,
			-ROOT_2D_MAX_OFFSET,
			ROOT_2D_MAX_OFFSET
		)

	else:

		root_2d_offset_x = 0.0

		root_2d_velocity_x = 0.0


	# ---------------------------------------------------------
	# APPLY BODY TO GODOT PREVIEW
	# ---------------------------------------------------------

	character.rotation = (
		original_rotation
		+
		body_rot_offset
	)


# =============================================================
# 3D BODY SPRING
# =============================================================

func _process_3d_body(
	dt: float
) -> void:

	var stiffness := (
		get_effective_body_stiffness()
	)

	var damping := (
		get_effective_body_damping()
	)


	var spring_force := (

		-stiffness
		*
		body_rot_offset

		-

		damping
		*
		body_rot_velocity
	)


	body_rot_velocity += (
		spring_force
		*
		dt
	)


	body_rot_velocity = (
		body_rot_velocity.limit_length(
			MAX_BODY_ROTATION_VELOCITY
		)
	)


	body_rot_offset += (
		body_rot_velocity
		*
		dt
	)


	body_rot_offset.x = clampf(
		body_rot_offset.x,
		-get_effective_max_rot_x(),
		get_effective_max_rot_x()
	)


	body_rot_offset.y = clampf(
		body_rot_offset.y,
		-get_effective_max_rot_y(),
		get_effective_max_rot_y()
	)


	body_rot_offset.z = clampf(
		body_rot_offset.z,
		-get_effective_max_rot_z(),
		get_effective_max_rot_z()
	)


# =============================================================
# 2D BODY POSE
# =============================================================

func _process_2d_body(
	dt: float
) -> void:

	# ---------------------------------------------------------
	# POSE HOLD
	# ---------------------------------------------------------

	if body_2d_pose_timer > 0.0:

		body_2d_pose_timer -= dt

		if body_2d_pose_timer < 0.0:

			body_2d_pose_timer = 0.0


	else:

		body_2d_target = body_2d_target.move_toward(
			Vector3.ZERO,
			BODY_2D_POSE_RECOVERY_SPEED
			*
			dt
		)


	# ---------------------------------------------------------
	# FOLLOW TARGET
	#
	# Isto substitui a velha acumulação gigante de velocity.
	# ---------------------------------------------------------

	var follow_speed: float = (
		22.0
	)


	body_rot_offset = body_rot_offset.lerp(
		body_2d_target,
		1.0 - exp(
			-follow_speed
			*
			dt
		)
	)


	# ---------------------------------------------------------
	# SMALL PHYSICAL VELOCITY
	#
	# Mantemos apenas uma pequena parte do sistema antigo
	# para que a reação não fique completamente rígida.
	# ---------------------------------------------------------

	body_rot_velocity = body_rot_velocity.lerp(
		Vector3.ZERO,
		1.0 - exp(
			-12.0
			*
			dt
		)
	)


	# ---------------------------------------------------------
	# SAFETY
	# ---------------------------------------------------------

	body_rot_offset.x = clampf(
		body_rot_offset.x,
		-BODY_2D_MAX_ROT_X,
		BODY_2D_MAX_ROT_X
	)


	body_rot_offset.y = clampf(
		body_rot_offset.y,
		-BODY_2D_MAX_ROT_Y,
		BODY_2D_MAX_ROT_Y
	)


	body_rot_offset.z = clampf(
		body_rot_offset.z,
		-BODY_2D_MAX_ROT_Z,
		BODY_2D_MAX_ROT_Z
	)


# =============================================================
# RECEIVE IMPACT
# =============================================================

func receive_impact(
	hit_point_name: String,
	force: float,
	throwable: RigidBody3D = null,
	impact_direction: Vector3 = Vector3.ZERO
) -> void:

	if character == null:

		return


	var safe_force := clampf(
		force,
		MIN_IMPACT_FORCE,
		MAX_IMPACT_FORCE
	)


	if safe_force <= 0.0:

		return


	# =========================================================
	# IMPACT WINDOW
	# =========================================================

	if impact_window_timer <= 0.0:

		impact_window_timer = (
			IMPACT_WINDOW_TIME
		)

		impact_window_count = 0


	impact_window_count += 1


	if (
		impact_window_count
		>
		MAX_IMPACTS_PER_WINDOW
	):

		safe_force *= (
			IMPACT_OVERLOAD_REDUCTION
		)


	# =========================================================
	# DIRECTION
	# =========================================================

	var impact_dir := Vector3(
		0.0,
		0.0,
		1.0
	)


	if impact_direction.length() > 0.001:

		impact_dir = (
			impact_direction.normalized()
		)

	elif (
		throwable != null
		and
		is_instance_valid(
			throwable
		)
	):

		if throwable.linear_velocity.length() > 0.01:

			impact_dir = (
				throwable.linear_velocity.normalized()
			)


	# =========================================================
	# APPLY IMPACT PHYSICS
	# =========================================================
	#
	# ESTA PARTE É ESSENCIAL.
	#
	# O impacto tem dois caminhos:
	#
	#     2D -> pose target / root spring
	#
	#     3D -> body/head spring
	#
	# Sem estas chamadas o impacto é apenas emitido,
	# mas nenhuma física/reação é aplicada.
	# =========================================================

	if is_2d_mode:

		_receive_2d_impact(
			hit_point_name,
			safe_force,
			impact_dir
		)

	else:

		_receive_normal_impact(
			hit_point_name,
			safe_force,
			impact_dir
		)


	# =========================================================
	# STATE
	# =========================================================

	set_character_state(
		CharacterState.IMPACTED
	)


	# =========================================================
	# SIGNAL
	# =========================================================

	impact_received.emit(
		hit_point_name,
		safe_force,
		impact_dir
	)

# =============================================================
# 2D GLOBAL IMPACT
# =============================================================

func _receive_2d_impact(
	hit_point_name: String,
	safe_force: float,
	impact_dir: Vector3
) -> void:

	if impact_movement <= 0.0:

		body_2d_target = Vector3.ZERO

		body_rot_offset = Vector3.ZERO

		body_rot_velocity = Vector3.ZERO

		head_rot_offset = Vector3.ZERO

		head_rot_velocity = Vector3.ZERO

		root_2d_offset_x = 0.0

		root_2d_velocity_x = 0.0

		return


	# =========================================================
	# SIDE
	# =========================================================

	var hit_side: float = 0.0


	match hit_point_name:

		"LeftShoulderHitPoint":
			hit_side = -1.0

		"LeftArmHitPoint":
			hit_side = -1.0

		"LeftLegHitPoint":
			hit_side = -1.0

		"RightShoulderHitPoint":
			hit_side = 1.0

		"RightArmHitPoint":
			hit_side = 1.0

		"RightLegHitPoint":
			hit_side = 1.0


	# =========================================================
	# REAL IMPACT DIRECTION
	# =========================================================

	var direction_side := impact_dir.x


	if absf(direction_side) > 0.05:

		direction_side = signf(
			direction_side
		)

	else:

		direction_side = 0.0


	# =========================================================
	# CREATE NEW 2D TARGET
	# =========================================================

	var target := body_2d_target


	# =========================================================
	# SIDE HIT
	# =========================================================

	if absf(hit_side) > 0.01:

		target.y += (
			-hit_side
			*
			safe_force
			*
			BODY_2D_SIDE_FORCE
			*
			BODY_2D_POSE_FORCE_SCALE
		)


		target.z += (
			-hit_side
			*
			safe_force
			*
			BODY_2D_SIDE_ROLL
			*
			BODY_2D_POSE_FORCE_SCALE
		)


		target.x += (
			-safe_force
			*
			BODY_2D_SIDE_PITCH
			*
			BODY_2D_POSE_FORCE_SCALE
		)


		if absf(direction_side) > 0.01:

			target.y += (
				direction_side
				*
				safe_force
				*
				0.10
			)

			target.z += (
				-direction_side
				*
				safe_force
				*
				0.06
			)


		# -----------------------------------------------------
		# Immediate kick
		# -----------------------------------------------------

		body_rot_offset.y += (
			-hit_side
			*
			safe_force
			*
			BODY_2D_IMMEDIATE_SIDE_YAW
		)


		body_rot_offset.z += (
			-hit_side
			*
			safe_force
			*
			BODY_2D_IMMEDIATE_SIDE_ROLL
		)


		body_rot_offset.x += (
			-safe_force
			*
			BODY_2D_IMMEDIATE_SIDE_PITCH
		)


	# =========================================================
	# CHEST
	# =========================================================

	elif hit_point_name == "ChestHitPoint":

		target.x += (
			-safe_force
			*
			BODY_2D_CHEST_FORCE
		)


		if absf(direction_side) > 0.01:

			target.z += (
				-direction_side
				*
				safe_force
				*
				BODY_2D_CHEST_ROLL
			)


		body_rot_offset.x += (
			-safe_force
			*
			BODY_2D_IMMEDIATE_CHEST_PITCH
		)


		if absf(direction_side) > 0.01:

			body_rot_offset.z += (
				-direction_side
				*
				safe_force
				*
				BODY_2D_IMMEDIATE_CHEST_ROLL
			)


		head_rot_velocity.x += (
			-safe_force
			*
			0.35
		)


	# =========================================================
	# HEAD
	# =========================================================

	elif hit_point_name == "HeadHitPoint":

		target.x += (
			-safe_force
			*
			BODY_2D_HEAD_FORCE
		)


		if absf(direction_side) > 0.01:

			target.z += (
				-direction_side
				*
				safe_force
				*
				BODY_2D_HEAD_ROLL
			)


		body_rot_offset.x += (
			-safe_force
			*
			BODY_2D_IMMEDIATE_HEAD_BODY_PITCH
		)


		if absf(direction_side) > 0.01:

			body_rot_offset.z += (
				-direction_side
				*
				safe_force
				*
				BODY_2D_IMMEDIATE_HEAD_BODY_ROLL
			)


		head_rot_velocity.x += (
			-safe_force
			*
			HEAD_2D_IMPACT_FORCE
		)


		if absf(direction_side) > 0.01:

			head_rot_velocity.y += (
				direction_side
				*
				safe_force
				*
				0.75
			)

			head_rot_velocity.z += (
				-direction_side
				*
				safe_force
				*
				0.60
			)


	# =========================================================
	# UNKNOWN
	# =========================================================

	else:

		target.x += (
			-safe_force
			*
			BODY_2D_CHEST_FORCE
			*
			0.50
		)


	# =========================================================
	# LEG SPECIFIC BEHAVIOUR
	# =========================================================

	if hit_point_name == "LeftLegHitPoint":

		root_2d_velocity_x += (
			safe_force
			*
			ROOT_2D_IMPACT_FORCE
		)


		# Small lower-body contribution.
		target.z += (
			safe_force
			*
			BODY_2D_LEG_ROLL
		)


	elif hit_point_name == "RightLegHitPoint":

		root_2d_velocity_x -= (
			safe_force
			*
			ROOT_2D_IMPACT_FORCE
		)


		target.z += (
			safe_force
			*
			BODY_2D_LEG_ROLL
		)


	# =========================================================
	# NATURAL VARIATION
	# =========================================================

	target.y += (
		randf_range(
			-0.025,
			0.025
		)
		*
		safe_force
	)


	target.z += (
		randf_range(
			-0.020,
			0.020
		)
		*
		safe_force
	)


	# =========================================================
	# STORE TARGET
	# =========================================================

	target.x = clampf(
		target.x,
		-BODY_2D_POSE_MAX_X,
		BODY_2D_POSE_MAX_X
	)


	target.y = clampf(
		target.y,
		-BODY_2D_POSE_MAX_Y,
		BODY_2D_POSE_MAX_Y
	)


	target.z = clampf(
		target.z,
		-BODY_2D_POSE_MAX_Z,
		BODY_2D_POSE_MAX_Z
	)


	body_2d_target = target


	# =========================================================
	# HOLD
	# =========================================================

	body_2d_pose_timer = (
		BODY_2D_POSE_HOLD_TIME
	)


	# =========================================================
	# ROOT SAFETY
	# =========================================================

	root_2d_velocity_x = clampf(
		root_2d_velocity_x,
		-ROOT_2D_MAX_VELOCITY,
		ROOT_2D_MAX_VELOCITY
	)


	root_2d_offset_x = clampf(
		root_2d_offset_x,
		-ROOT_2D_MAX_OFFSET,
		ROOT_2D_MAX_OFFSET
	)


# =============================================================
# NORMAL IMPACT
# =============================================================

func _receive_normal_impact(
	hit_point_name: String,
	safe_force: float,
	impact_dir: Vector3
) -> void:

	if impact_movement <= 0.0:

		body_rot_offset = Vector3.ZERO

		body_rot_velocity = Vector3.ZERO

		head_rot_offset = Vector3.ZERO

		head_rot_velocity = Vector3.ZERO

		return


	var base_pitch := (
		-safe_force
		*
		1.15
	)


	var base_roll := (
		-impact_dir.x
		*
		safe_force
		*
		0.75
	)


	var base_yaw := (
		impact_dir.x
		*
		safe_force
		*
		0.35
	)


	match hit_point_name:

		"HeadHitPoint":

			body_rot_velocity.x += (
				base_pitch
				*
				0.80
			)

			body_rot_velocity.y += (
				base_yaw
				*
				0.70
			)

			body_rot_velocity.z += (
				base_roll
				*
				1.10
			)


			head_rot_velocity.x += (
				-safe_force
				*
				2.5
			)


			head_rot_velocity.y += (
				randf_range(
					-1.0,
					1.0
				)
				*
				safe_force
				*
				1.8
			)


			head_rot_velocity.z += (
				randf_range(
					-1.0,
					1.0
				)
				*
				safe_force
				*
				1.8
			)


		"ChestHitPoint":

			body_rot_velocity.x += (
				base_pitch
			)

			body_rot_velocity.y += (
				base_yaw
				*
				0.85
			)

			body_rot_velocity.z += (
				base_roll
			)

			head_rot_velocity.x += (
				-safe_force
				*
				0.8
			)


		"LeftShoulderHitPoint":

			body_rot_velocity.x += (
				base_pitch
				*
				0.55
			)

			body_rot_velocity.y += (
				safe_force
				*
				1.25
			)

			body_rot_velocity.z += (
				safe_force
				*
				0.55
			)


		"RightShoulderHitPoint":

			body_rot_velocity.x += (
				base_pitch
				*
				0.55
			)

			body_rot_velocity.y += (
				-safe_force
				*
				1.25
			)

			body_rot_velocity.z += (
				-safe_force
				*
				0.55
			)


		"LeftArmHitPoint":

			body_rot_velocity.y += (
				safe_force
				*
				0.85
			)

			body_rot_velocity.z += (
				safe_force
				*
				0.70
			)


		"RightArmHitPoint":

			body_rot_velocity.y += (
				-safe_force
				*
				0.85
			)

			body_rot_velocity.z += (
				-safe_force
				*
				0.70
			)


		"LeftLegHitPoint":

			body_rot_velocity.x += (
				-safe_force
				*
				0.65
			)

			body_rot_velocity.z += (
				safe_force
				*
				0.65
			)


		"RightLegHitPoint":

			body_rot_velocity.x += (
				-safe_force
				*
				0.65
			)

			body_rot_velocity.z += (
				safe_force
				*
				0.65
			)


		_:

			body_rot_velocity.x += (
				base_pitch
				*
				0.50
			)

			body_rot_velocity.y += (
				base_yaw
			)

			body_rot_velocity.z += (
				base_roll
				*
				0.50
			)


	body_rot_velocity.y += (
		randf_range(
			-0.15,
			0.15
		)
		*
		safe_force
	)


	body_rot_velocity.z += (
		randf_range(
			-0.10,
			0.10
		)
		*
		safe_force
	)


	body_rot_velocity = (
		body_rot_velocity.limit_length(
			MAX_BODY_ROTATION_VELOCITY
		)
	)


	head_rot_velocity = (
		head_rot_velocity.limit_length(
			MAX_HEAD_ROTATION_VELOCITY
		)
	)


# =============================================================
# CHARACTER
# =============================================================

func set_character(
	new_character: Node3D
) -> void:

	character = new_character


	if character == null:

		return


	sync_original_transform()


# =============================================================
# SYNC
# =============================================================

func sync_original_transform() -> void:

	if character == null:

		return


	original_position = (
		character.position
	)


	original_rotation = (
		character.rotation
	)


	body_pos_offset = Vector3.ZERO

	body_pos_velocity = Vector3.ZERO

	body_rot_offset = Vector3.ZERO

	body_rot_velocity = Vector3.ZERO

	body_2d_target = Vector3.ZERO

	body_2d_pose_timer = 0.0

	head_rot_offset = Vector3.ZERO

	head_rot_velocity = Vector3.ZERO

	root_2d_offset_x = 0.0

	root_2d_velocity_x = 0.0


	impact_window_timer = 0.0

	impact_window_count = 0


	character_state = (
		CharacterState.NORMAL
	)


# =============================================================
# ROTATE AVATAR
# =============================================================

func rotate_avatar_y(
	angle_radians: float
) -> void:

	original_rotation.y += (
		angle_radians
	)


	if character != null:

		character.rotation.y = (
			original_rotation.y
		)


# =============================================================
# HIT POINTS
# =============================================================

func set_hit_points(
	new_hit_points: Node3D
) -> void:

	hit_points = new_hit_points


# =============================================================
# OBJECT
# =============================================================

func set_object_type(
	new_type: String
) -> void:

	object_type = (
		new_type.to_upper()
	)


func set_target_hit_point(
	new_hit_point: String
) -> void:

	target_hit_point = (
		new_hit_point
	)


# =============================================================
# MODE COMPATIBILITY
# =============================================================

func is_realistic_mode_enabled() -> bool:

	return false


func get_realistic_mode() -> bool:

	return false


func set_realistic_mode(
	enabled_value: bool
) -> void:

	pass


# =============================================================
# IMPACT MOVEMENT
# =============================================================

func get_impact_movement() -> float:

	return impact_movement


func set_impact_movement(
	new_value: float
) -> void:

	impact_movement = clampf(
		new_value,
		MIN_IMPACT_MOVEMENT,
		MAX_IMPACT_MOVEMENT
	)


	if impact_movement <= 0.0:

		body_rot_offset = Vector3.ZERO

		body_rot_velocity = Vector3.ZERO

		body_2d_target = Vector3.ZERO

		body_2d_pose_timer = 0.0

		head_rot_offset = Vector3.ZERO

		head_rot_velocity = Vector3.ZERO

		root_2d_offset_x = 0.0

		root_2d_velocity_x = 0.0


# =============================================================
# SETTINGS
# =============================================================

func apply_settings(
	settings: CIGASettings
) -> void:

	if settings == null:

		return


	set_object_speed(
		settings.get_default_speed()
	)


	set_object_force(
		settings.get_default_force()
	)


	set_impact_movement(
		settings.get_impact_movement()
	)


# =============================================================
# VMC ROOT
# =============================================================

func get_character_displacement_for_vmc() -> Vector3:

	return Vector3.ZERO


# =============================================================
# VMC BODY
# =============================================================

func get_character_delta_rotation_for_vmc() -> Vector3:

	return body_rot_offset


# =============================================================
# VMC HEAD
# =============================================================

func get_head_delta_rotation_for_vmc() -> Vector3:

	return head_rot_offset


# =============================================================
# 2D ROOT OUTPUT
# =============================================================

func get_2d_root_x() -> float:

	return root_2d_offset_x


func get_2d_root_x_normalized() -> float:

	if ROOT_2D_MAX_OFFSET <= 0.0:

		return 0.0


	return clampf(
		root_2d_offset_x
		/
		ROOT_2D_MAX_OFFSET,
		-1.0,
		1.0
	)


# =============================================================
# OBJECT GETTERS
# =============================================================

func get_object_speed() -> float:

	return object_speed


func get_object_force() -> float:

	return object_force


func get_object_type() -> String:

	return object_type


func get_target_hit_point() -> String:

	return target_hit_point


# =============================================================
# STATE
# =============================================================

func set_character_state(
	new_state: CharacterState
) -> void:

	if character_state == new_state:

		return


	character_state = new_state


func get_character_state() -> CharacterState:

	return character_state


# =============================================================
# OBJECT SPEED
# =============================================================

func set_object_speed(
	new_speed: float
) -> void:

	object_speed = maxf(
		new_speed,
		0.01
	)


# =============================================================
# OBJECT FORCE
# =============================================================

func set_object_force(
	new_force: float
) -> void:

	object_force = clampf(
		new_force,
		MIN_IMPACT_FORCE,
		MAX_IMPACT_FORCE
	)


# =============================================================
# DIAGNOSTIC
# =============================================================

func get_diagnostic() -> Dictionary:

	return {

		"character":
			character != null,

		"realistic_mode":
			false,

		"solver":
			"NORMAL",

		"2d_mode":
			is_2d_mode,

		"impact_movement":
			impact_movement,

		"object_speed":
			object_speed,

		"object_force":
			object_force,

		"state":
			character_state,

		"body_rotation":
			body_rot_offset,

		"head_rotation":
			head_rot_offset,

		"body_2d_target":
			body_2d_target,

		"body_2d_pose_timer":
			body_2d_pose_timer,

		"root_2d_x":
			root_2d_offset_x,

		"root_2d_x_normalized":
			get_2d_root_x_normalized()
	}
