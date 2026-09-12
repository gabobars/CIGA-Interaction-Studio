class_name ThrowableObject
extends Node3D


# =========================================================
# SIGNALS
# =========================================================

signal impacted(
	object_type: String,
	impact_direction: Vector3,
	impact_force: float,
	hit_point_name: String
)


# =========================================================
# OBJECT DATA
# =========================================================

var object_type: String = "OBJECT"

var object_speed: float = 5.4

var object_force: float = 1.8

var hit_point_name: String = "ChestHitPoint"

var object_lifetime: float = 5.0

var lifetime_timer: float = 0.0

var bounce_time: float = 0.30


# =========================================================
# PRE-LOADED / PRE-INSTANTIATED VISUAL
#
# O Viewport Runtime entrega aqui uma DUPLICATE do template
# já carregado.
#
# Nunca fazemos load() neste script.
# =========================================================

var pre_instantiated_model: Node3D = null


# =========================================================
# POSITIONS
# =========================================================

var start_position: Vector3 = Vector3.ZERO

var target_position: Vector3 = Vector3.ZERO

var movement_direction: Vector3 = Vector3.ZERO


# =========================================================
# TRAJECTORY
# =========================================================

var trajectory_control_point: Vector3 = Vector3.ZERO

var trajectory_progress: float = 0.0

var trajectory_distance: float = 1.0

var previous_trajectory_position: Vector3 = Vector3.ZERO


const TRAJECTORY_CURVE_MIN: float = 0.20

const TRAJECTORY_CURVE_MAX: float = 0.55

const TRAJECTORY_VERTICAL_MIN: float = -0.18

const TRAJECTORY_VERTICAL_MAX: float = 0.35


# =========================================================
# IMPACT / BOUNCE
# =========================================================

var has_impacted: bool = false

var is_bouncing: bool = false

var bounce_velocity: Vector3 = Vector3.ZERO

var bounce_timer: float = 0.0


# =========================================================
# SPIN
# =========================================================

var spin_axis: Vector3 = Vector3.ZERO

var spin_speed: float = 0.0


# =========================================================
# SIZE
# =========================================================

const DEFAULT_TARGET_SIZE: float = 0.40


# =========================================================
# VISUAL
# =========================================================

var visual_container: Node3D = null


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	if visual_container == null:

		visual_container = Node3D.new()

		visual_container.name = "VisualContainer"

		add_child(
			visual_container
		)


# =========================================================
# SETUP
# =========================================================

func setup(
	new_start_position: Vector3,
	new_target_position: Vector3,
	new_object_type: String,
	new_object_speed: float,
	new_object_force: float,
	new_hit_point_name: String,
	new_lifetime: float,
	new_bounce_time: float
) -> void:

	start_position = (
		new_start_position
	)

	target_position = (
		new_target_position
	)

	object_type = (
		new_object_type.to_upper()
	)

	object_speed = maxf(
		new_object_speed,
		0.01
	)

	object_force = (
		new_object_force
	)

	hit_point_name = (
		new_hit_point_name
	)

	object_lifetime = maxf(
		new_lifetime,
		0.1
	)

	bounce_time = maxf(
		new_bounce_time,
		0.0
	)


	lifetime_timer = 0.0

	bounce_timer = 0.0

	global_position = (
		start_position
	)

	has_impacted = false

	is_bouncing = false

	bounce_velocity = Vector3.ZERO


	# =====================================================
	# BASE DIRECTION
	# =====================================================

	movement_direction = (
		target_position
		-
		start_position
	)

	if movement_direction.length() > 0.001:

		movement_direction = (
			movement_direction.normalized()
		)

	else:

		movement_direction = Vector3.BACK


	# =====================================================
	# DISTANCE
	# =====================================================

	trajectory_distance = (
		start_position.distance_to(
			target_position
		)
	)

	if trajectory_distance < 0.001:

		trajectory_distance = 1.0


	trajectory_progress = 0.0

	previous_trajectory_position = (
		start_position
	)


	# =====================================================
	# CURVE
	# =====================================================

	_create_trajectory()


	# =====================================================
	# ORIENTATION
	# =====================================================

	var up_vec: Vector3 = (

		Vector3.UP

		if abs(movement_direction.y) < 0.99

		else

		Vector3.FORWARD
	)

	look_at(
		global_position + movement_direction,
		up_vec
	)


	# =====================================================
	# RANDOM SPIN
	# =====================================================

	var choice: int = randi_range(
		0,
		2
	)

	match choice:

		0:

			spin_axis = Vector3(
				1.0,
				0.0,
				0.0
			)

			spin_speed = randf_range(
				2.5,
				4.0
			)


		1:

			spin_axis = Vector3(
				0.0,
				0.0,
				1.0
			)

			spin_speed = randf_range(
				2.0,
				3.5
			)


		2:

			spin_axis = Vector3(
				0.0,
				1.0,
				0.0
			)

			spin_speed = randf_range(
				1.5,
				3.0
			)


	# =====================================================
	# VISUAL
	# =====================================================

	setup_visual()


# =========================================================
# CREATE TRAJECTORY
# =========================================================

func _create_trajectory() -> void:

	var direction: Vector3 = (
		target_position
		-
		start_position
	)

	if direction.length() <= 0.001:

		trajectory_control_point = (
			start_position
		)

		return


	direction = (
		direction.normalized()
	)


	# =====================================================
	# SIDE VECTOR
	# =====================================================

	var side_vector: Vector3 = (
		direction.cross(
			Vector3.UP
		)
	)

	if side_vector.length() < 0.001:

		side_vector = (
			direction.cross(
				Vector3.RIGHT
			)
		)


	if side_vector.length() > 0.001:

		side_vector = (
			side_vector.normalized()
		)

	else:

		side_vector = Vector3.RIGHT


	# =====================================================
	# RANDOM CURVE
	# =====================================================

	var side_sign: float = (

		-1.0

		if randf() < 0.5

		else

		1.0
	)


	var curve_amount: float = (
		randf_range(
			TRAJECTORY_CURVE_MIN,
			TRAJECTORY_CURVE_MAX
		)
	)


	var vertical_amount: float = (
		randf_range(
			TRAJECTORY_VERTICAL_MIN,
			TRAJECTORY_VERTICAL_MAX
		)
	)


	# =====================================================
	# CONTROL POINT
	# =====================================================

	var middle_point: Vector3 = (
		start_position.lerp(
			target_position,
			0.5
		)
	)

	middle_point += (
		side_vector
		*
		curve_amount
		*
		side_sign
	)

	middle_point.y += (
		vertical_amount
	)

	trajectory_control_point = (
		middle_point
	)


# =========================================================
# BEZIER
# =========================================================

func _get_trajectory_position(
	progress: float
) -> Vector3:

	var t: float = clampf(
		progress,
		0.0,
		1.0
	)

	var one_minus_t: float = (
		1.0 - t
	)

	return (

		(
			one_minus_t
			*
			one_minus_t
		)
		*
		start_position

		+

		(
			2.0
			*
			one_minus_t
			*
			t
		)
		*
		trajectory_control_point

		+

		(
			t
			*
			t
		)
		*
		target_position
	)


# =========================================================
# VISUAL SETUP
# =========================================================

func setup_visual() -> void:

	if visual_container == null:

		visual_container = Node3D.new()

		visual_container.name = "VisualContainer"

		add_child(
			visual_container
		)


	# =====================================================
	# VISUAL CONTAINER
	# =====================================================

	visual_container.scale = Vector3.ONE


	# =====================================================
	# CLEAR OLD VISUAL
	# =====================================================

	for child: Node in visual_container.get_children():

		child.queue_free()


	# =====================================================
	# ATTACH PRE-INSTANTIATED MODEL
	# =====================================================

	if pre_instantiated_model != null:

		visual_container.add_child(
			pre_instantiated_model
		)

		pre_instantiated_model.visible = true


# =========================================================
# PROCESS
# =========================================================

func _process(
	delta: float
) -> void:

	lifetime_timer += delta


	# =====================================================
	# TOTAL LIFETIME
	# =====================================================

	if lifetime_timer >= object_lifetime:

		queue_free()

		return


	# =====================================================
	# BOUNCE
	# =====================================================

	if is_bouncing:

		global_position += (
			bounce_velocity
			*
			delta
		)


		bounce_velocity.y -= (
			9.8
			*
			delta
		)


		if visual_container != null:

			visual_container.rotate_object_local(

				spin_axis,

				spin_speed
				*
				delta
				*
				2.0
			)


		bounce_timer += delta


		if bounce_timer >= bounce_time:

			queue_free()

			return


		return


	# =====================================================
	# FLIGHT
	# =====================================================

	var travel_distance: float = (
		object_speed
		*
		delta
	)


	var progress_step: float = (
		travel_distance
		/
		trajectory_distance
	)


	trajectory_progress += (
		progress_step
	)


	trajectory_progress = clampf(
		trajectory_progress,
		0.0,
		1.0
	)


	# =====================================================
	# NEW POSITION
	# =====================================================

	var new_position: Vector3 = (
		_get_trajectory_position(
			trajectory_progress
		)
	)


	# =====================================================
	# ACTUAL FRAME DIRECTION
	# =====================================================

	var frame_direction: Vector3 = (
		new_position
		-
		previous_trajectory_position
	)


	if frame_direction.length() > 0.0001:

		movement_direction = (
			frame_direction.normalized()
		)


	# =====================================================
	# MOVE
	# =====================================================

	global_position = (
		new_position
	)

	previous_trajectory_position = (
		new_position
	)


	# =====================================================
	# ORIENTATION
	# =====================================================

	if movement_direction.length() > 0.001:

		var up_vec: Vector3 = (

			Vector3.UP

			if abs(movement_direction.y) < 0.99

			else

			Vector3.FORWARD
		)

		look_at(
			global_position + movement_direction,
			up_vec
		)


	# =====================================================
	# SPIN
	# =====================================================

	if visual_container != null:

		visual_container.rotate_object_local(

			spin_axis,

			spin_speed
			*
			delta
		)


	# =====================================================
	# IMPACT
	# =====================================================

	if trajectory_progress >= 1.0:

		trigger_impact()


# =========================================================
# IMPACT
# =========================================================

func trigger_impact() -> void:

	if has_impacted:

		return


	has_impacted = true

	is_bouncing = true

	bounce_timer = 0.0


	# =====================================================
	# RECOIL
	# =====================================================

	var recoil_back: Vector3 = (
		-movement_direction
	)


	bounce_velocity = Vector3(

		recoil_back.x
		*
		randf_range(
			1.8,
			2.8
		),

		randf_range(
			2.0,
			3.5
		),

		recoil_back.z
		*
		randf_range(
			1.8,
			2.8
		)
	)





	# =====================================================
	# REAL IMPACT DIRECTION
	# =====================================================

	impacted.emit(

		object_type,

		movement_direction,

		object_force,

		hit_point_name
	)
