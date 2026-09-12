class_name CIGAViewportRuntime
extends Node


# =============================================================
# CIGA VIEWPORT RUNTIME
# Godot 4.7.2
#
# RESPONSABILIDADES
#
# - gestão do viewport
# - gestão do avatar
# - object resource cache
# - object spawning
# - física / impactos
# - profiles
# - streamer mode
# - teclado do viewport
# - DISPLAY IMAGE
# - DISPLAY IMAGE LIVE
#
# =============================================================


# =============================================================
# PERFORMANCE
# =============================================================

const TARGET_FPS: int = 30

const DEFAULT_MAX_ACTIVE_PROJECTILES: int = 50

const SPACE_THROW_INTERVAL: float = 0.16

const EVENT_LAUNCH_INTERVAL: float = 0.055


# =============================================================
# CAMERA INPUT
# =============================================================

const CAMERA_MOVE_SPEED: float = 0.46

const CAMERA_ZOOM_SPEED: float = 0.075


# =============================================================
# SPAWN
# =============================================================

const SPAWN_MARGIN_PIXELS: float = 20.0

const SPAWN_FRONT_OFFSET: float = 0.20


# =============================================================
# EVENT IMAGE
# =============================================================

const EVENT_IMAGE_BASE_WIDTH: float = 0.35

const EVENT_IMAGE_MIN_SCALE: float = 0.05

const EVENT_IMAGE_MAX_SCALE: float = 10.0

const EVENT_IMAGE_MAX_DURATION: float = 3600.0

const EVENT_IMAGE_MIN_DURATION: float = 0.1


# =============================================================
# LIVE IMAGE
# =============================================================

const LIVE_IMAGE_TEMP_DIR: String = (
	"user://ciga/temp/live_images"
)

const LIVE_IMAGE_MAX_ACTIVE: int = 100

const LIVE_IMAGE_MIN_DURATION: float = 0.1


# =============================================================
# REFERENCES
# =============================================================

var viewport: CIGAViewport = null

var character_runtime: CIGACharacterRuntime = null

var character_manager: CIGACharacters = null

var interaction_manager: CIGAinteractionManager = null

var interaction_runtime: CIGAInteractionRuntime = null

var events_runtime: CIGAEventsRuntime = null

var object_manager: CIGAObjects = null

var profile_manager: CIGAProfiles = null

var settings_runtime: CIGASettings = null

var ciga_output: CIGAOutput = null

var vmc_runtime: CIGAVMCRuntime = null


# =============================================================
# CHARACTER
# =============================================================

var active_character: Node3D = null

var skeleton: Skeleton3D = null

var saved_avatar_position: Vector3 = Vector3.ZERO

var saved_avatar_rotation: Vector3 = Vector3.ZERO

var has_saved_avatar_transform: bool = false


# =============================================================
# STATE
# =============================================================

var initialized: bool = false

var initializing: bool = false

var streamer_mode_enabled: bool = false

var impact_orientation_flipped: bool = false

var vmc_tracking_flipped: bool = false


# =============================================================
# PROJECTILES
# =============================================================

var active_projectiles: Array[ThrowableObject] = []


# =============================================================
# EVENT QUEUE
# =============================================================

var event_launch_queue: Array[Dictionary] = []

var event_launch_timer: float = 0.0

var event_burst_processing: bool = false


# =============================================================
# LIVE IMAGE QUEUE
# =============================================================

var pending_live_image_actions: Array[Dictionary] = []

var active_live_image_sprites: Array[Sprite3D] = []

var active_event_image_sprites: Array[Sprite3D] = []


# =============================================================
# SPACE
# =============================================================

var space_throw_timer: float = 0.0

var space_was_pressed: bool = false


# =============================================================
# KEYBOARD
# =============================================================

var held_keyboard_keys: Dictionary = {}

var keyboard_input_connected: bool = false

var keyboard_window: Window = null


# =============================================================
# OBJECT STATE
# =============================================================

var object_names: Array[String] = []

var object_scales: Dictionary = {}


# =============================================================
# PRELOAD
# =============================================================

var preload_complete: bool = false


# =============================================================
# EDGE SETTINGS
# =============================================================

var edge_left_top_enabled: bool = true

var edge_left_bottom_enabled: bool = true

var edge_right_top_enabled: bool = true

var edge_right_bottom_enabled: bool = true

var edge_top_center_enabled: bool = true

var edge_bottom_center_enabled: bool = true


# =============================================================
# SPAWN POINTS
# =============================================================

var spawn_left_top: Marker3D = null

var spawn_left_bottom: Marker3D = null

var spawn_right_top: Marker3D = null

var spawn_right_bottom: Marker3D = null

var spawn_top_center: Marker3D = null

var spawn_bottom_center: Marker3D = null

var spawn_center: Marker3D = null


# =============================================================
# HIT POINTS
# =============================================================

const HIT_POINT_BONES: Dictionary = {
	"HeadHitPoint": "J_Bip_C_Head",
	"ChestHitPoint": "J_Bip_C_Chest",
	"LeftShoulderHitPoint": "J_Bip_L_Shoulder",
	"RightShoulderHitPoint": "J_Bip_R_Shoulder",
	"LeftArmHitPoint": "J_Bip_L_UpperArm",
	"RightArmHitPoint": "J_Bip_R_UpperArm",
	"LeftLegHitPoint": "J_Bip_L_UpperLeg",
	"RightLegHitPoint": "J_Bip_R_UpperLeg"
}


const HIT_POINTS: Array[String] = [
	"HeadHitPoint",
	"ChestHitPoint",
	"LeftShoulderHitPoint",
	"RightShoulderHitPoint",
	"LeftArmHitPoint",
	"RightArmHitPoint",
	"LeftLegHitPoint",
	"RightLegHitPoint"
]


# =============================================================
# PROFILE
# =============================================================

var loaded_profile_id: String = ""

var profile_check_timer: float = 0.0

const PROFILE_CHECK_INTERVAL: float = 0.5


# =============================================================
# READY
# =============================================================

func _ready() -> void:

	process_priority = 19000


# =============================================================
# SET VIEWPORT
# =============================================================

func set_viewport(
	new_viewport: CIGAViewport
) -> void:

	if keyboard_input_connected:

		_disconnect_keyboard_input()


	viewport = new_viewport


	if viewport == null:

		return


	_connect_keyboard_input()


# =============================================================
# KEYBOARD CONNECTION
# =============================================================

func _connect_keyboard_input() -> void:

	if viewport == null:

		return


	if viewport.root == null:

		return


	var window: Window = (
		viewport.root.get_window()
	)


	if window == null:

		return


	keyboard_window = window


	var callable := Callable(
		self,
		"_on_window_input"
	)


	if not window.window_input.is_connected(
		callable
	):

		window.window_input.connect(
			callable
		)


	keyboard_input_connected = true


# =============================================================
# KEYBOARD DISCONNECTION
# =============================================================

func _disconnect_keyboard_input() -> void:

	if not keyboard_input_connected:

		return


	if keyboard_window == null:

		keyboard_input_connected = false

		return


	var callable := Callable(
		self,
		"_on_window_input"
	)


	if keyboard_window.window_input.is_connected(
		callable
	):

		keyboard_window.window_input.disconnect(
			callable
		)


	keyboard_window = null

	keyboard_input_connected = false

	held_keyboard_keys.clear()


# =============================================================
# WINDOW INPUT
# =============================================================

func _on_window_input(
	event: InputEvent
) -> void:

	if viewport == null:

		return


	if viewport.root == null:

		return


	if not viewport.root.visible:

		return


	if not event is InputEventKey:

		return


	var key_event := (
		event
		as
		InputEventKey
	)


	if key_event.pressed:

		held_keyboard_keys[
			key_event.keycode
		] = true


		if key_event.physical_keycode != 0:

			held_keyboard_keys[
				key_event.physical_keycode
			] = true


		if not key_event.echo:

			_handle_key_pressed_once(
				key_event.keycode
			)

	else:

		held_keyboard_keys.erase(
			key_event.keycode
		)


		if key_event.physical_keycode != 0:

			held_keyboard_keys.erase(
				key_event.physical_keycode
			)


# =============================================================
# SINGLE KEY ACTION
# =============================================================

func _handle_key_pressed_once(
	key_code: int
) -> void:

	if viewport == null:

		return


	match key_code:

		KEY_R:

			rotate_avatar_180()

			viewport.show_notification(
				"CHARACTER ROTATED"
			)


		KEY_T:

			var flipped: bool = (
				toggle_impact_orientation()
			)


			if viewport.orientation_button != null:

				viewport.orientation_button.text = (
					"FLIPPED"
					if flipped
					else
					"FRONT"
				)


			viewport.show_notification(
				"TRACKING FLIPPED"
				if flipped
				else
				"TRACKING NORMAL"
			)


		KEY_TAB:

			toggle_streamer_mode()


		KEY_SPACE:

			if not streamer_mode_enabled:

				launch_test_object()


# =============================================================
# INITIALIZE
# =============================================================

func initialize_runtime() -> void:

	if initialized:

		return


	if initializing:

		return


	if viewport == null:

		return


	initializing = true


	# =========================================================
	# DEPENDENCIES
	# =========================================================

	auto_discover_dependencies()


	if interaction_runtime != null:

		set_interaction_runtime(
			interaction_runtime
		)


	if ciga_output != null:

		set_ciga_output(
			ciga_output
		)


	# =========================================================
	# CHARACTER MANAGER -> CHARACTER RUNTIME
	# =========================================================

	if (
		character_runtime != null
		and
		character_manager != null
	):

		character_runtime.set_character_manager(
			character_manager
		)


	# =========================================================
	# PROFILE
	# =========================================================

	load_profile_settings()


	# =========================================================
	# PRELOAD STATE
	# =========================================================

	preload_complete = false


	# =========================================================
	# CHARACTER
	# =========================================================

	if character_runtime != null:

		if character_runtime.has_method(
			"is_character_loaded"
		):

			if character_runtime.is_character_loaded():

				refresh_character()

		else:

			refresh_character()


	# =========================================================
	# SPAWNS
	# =========================================================

	create_spawn_points()


	# =========================================================
	# EVENT IMAGES
	# =========================================================

	preload_event_images()


	# =========================================================
	# OBJECT CACHE
	# =========================================================

	preload_object_library()


	# =========================================================
	# FINAL STATE
	# =========================================================

	initialized = true

	initializing = false


	update_viewport_status()

	refresh_viewport_ui()


	if streamer_mode_enabled:

		apply_streamer_mode()


# =============================================================
# REFRESH RESOURCE STATE
# =============================================================

func refresh_object_resource_state() -> void:

	object_names.clear()


	if object_manager == null:

		return


	for object_data: Dictionary in object_manager.objects:

		var object_id := str(
			object_data.get(
				"id",
				""
			)
		)


		if object_id.is_empty():

			continue


		var packed_scene: PackedScene = (
			object_manager.get_cached_packed_scene(
				object_id
			)
		)


		if packed_scene == null:

			continue


		object_names.append(
			object_id
		)


# =============================================================
# DEPENDENCY DISCOVERY
# =============================================================

func auto_discover_dependencies() -> void:

	var main_loop := (
		Engine.get_main_loop()
	)


	if main_loop == null:

		return


	if not main_loop is SceneTree:

		return


	var tree: SceneTree = (
		main_loop
		as
		SceneTree
	)


	var current_scene := tree.current_scene


	if current_scene == null:

		return


	# =========================================================
	# CIGA UI
	# =========================================================

	if (
		object_manager == null
		or
		profile_manager == null
		or
		character_manager == null
	):

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


			var ui: CIGAUI = (
				node
				as
				CIGAUI
			)


			if object_manager == null:

				object_manager = (
					ui.object_manager
				)


			if profile_manager == null:

				profile_manager = (
					ui.profile_manager
				)


			if character_manager == null:

				var manager_value: Variant = (
					ui.get(
						"character_manager"
					)
				)


				if manager_value is CIGACharacters:

					character_manager = (
						manager_value
						as
						CIGACharacters
					)


			if (
				object_manager != null
				and
				profile_manager != null
				and
				character_manager != null
			):

				break


	# =========================================================
	# CHARACTER RUNTIME
	# =========================================================

	if character_runtime == null:

		var character_nodes := (
			current_scene.find_children(
				"*",
				"CIGACharacterRuntime",
				true,
				false
			)
		)


		for node: Node in character_nodes:

			if node is CIGACharacterRuntime:

				character_runtime = (
					node
					as
					CIGACharacterRuntime
				)

				break


	# =========================================================
	# CHARACTER MANAGER -> CHARACTER RUNTIME
	# =========================================================

	if (
		character_runtime != null
		and
		character_manager != null
	):

		character_runtime.set_character_manager(
			character_manager
		)


	# =========================================================
	# INTERACTION MANAGER
	# =========================================================

	if interaction_manager == null:

		var managers: Array[CIGAinteractionManager] = []


		_collect_interaction_managers(
			current_scene,
			managers
		)


		for manager: CIGAinteractionManager in managers:

			if manager.name == "CIGAInteractionManager":

				interaction_manager = manager

				break


		if interaction_manager == null:

			for manager: CIGAinteractionManager in managers:

				if not manager.name.begins_with(
					"PreviewInteractionManager"
				):

					interaction_manager = manager

					break


		if interaction_manager == null:

			if not managers.is_empty():

				interaction_manager = managers[0]


	# =========================================================
	# INTERACTION RUNTIME
	# =========================================================

	if interaction_runtime == null:

		var interaction_nodes := (
			current_scene.find_children(
				"*",
				"CIGAInteractionRuntime",
				true,
				false
			)
		)


		for node: Node in interaction_nodes:

			if node is CIGAInteractionRuntime:

				interaction_runtime = (
					node
					as
					CIGAInteractionRuntime
				)

				break


	# =========================================================
	# EVENTS RUNTIME
	# =========================================================

	if events_runtime == null:

		var event_nodes := (
			current_scene.find_children(
				"*",
				"CIGAEventsRuntime",
				true,
				false
			)
		)


		for node: Node in event_nodes:

			if node is CIGAEventsRuntime:

				events_runtime = (
					node
					as
					CIGAEventsRuntime
				)

				break


	# =========================================================
	# CIGA OUTPUT
	# =========================================================

	if ciga_output == null:

		var output_nodes := (
			current_scene.find_children(
				"*",
				"CIGAOutput",
				true,
				false
			)
		)


		for node: Node in output_nodes:

			if node is CIGAOutput:

				ciga_output = (
					node
					as
					CIGAOutput
				)

				break


	# =========================================================
	# VMC RUNTIME
	# =========================================================

	if vmc_runtime == null:

		var vmc_nodes := (
			current_scene.find_children(
				"*",
				"CIGAVMCRuntime",
				true,
				false
			)
		)


		for node: Node in vmc_nodes:

			if node is CIGAVMCRuntime:

				vmc_runtime = (
					node
					as
					CIGAVMCRuntime
				)

				break


# =============================================================
# SET VMC RUNTIME
# =============================================================

func set_vmc_runtime(
	new_runtime: CIGAVMCRuntime
) -> void:

	vmc_runtime = new_runtime


	# =========================================================
	# SIGNALS
	# =========================================================

	if character_runtime != null:

		var loaded_callable := Callable(
			self,
			"_on_character_loaded"
		)


		if not character_runtime.character_loaded.is_connected(
			loaded_callable
		):

			character_runtime.character_loaded.connect(
				loaded_callable
			)


		var unloaded_callable := Callable(
			self,
			"_on_character_unloaded"
		)


		if not character_runtime.character_unloaded.is_connected(
			unloaded_callable
		):

			character_runtime.character_unloaded.connect(
				unloaded_callable
			)


	if interaction_runtime != null:

		set_interaction_runtime(
			interaction_runtime
		)


	if ciga_output != null:

		set_ciga_output(
			ciga_output
		)


# =============================================================
# COLLECT MANAGERS
# =============================================================

func _collect_interaction_managers(
	node: Node,
	result: Array[CIGAinteractionManager]
) -> void:

	if node is CIGAinteractionManager:

		var manager := (
			node
			as
			CIGAinteractionManager
		)


		if not result.has(manager):

			result.append(
				manager
			)


	for child: Node in node.get_children():

		_collect_interaction_managers(
			child,
			result
		)


# =============================================================
# CHARACTER MANAGER
# =============================================================

func set_character_manager(
	new_manager: CIGACharacters
) -> void:

	character_manager = new_manager


	if character_runtime == null:

		return


	character_runtime.set_character_manager(
		character_manager
	)


# =============================================================
# CHARACTER RUNTIME
# =============================================================

func set_character_runtime(
	new_runtime: CIGACharacterRuntime
) -> void:

	character_runtime = new_runtime


	if character_runtime == null:

		return


	if character_manager != null:

		character_runtime.set_character_manager(
			character_manager
		)


	var loaded_callable := Callable(
		self,
		"_on_character_loaded"
	)


	if not character_runtime.character_loaded.is_connected(
		loaded_callable
	):

		character_runtime.character_loaded.connect(
			loaded_callable
	)


	var unloaded_callable := Callable(
		self,
		"_on_character_unloaded"
	)


	if not character_runtime.character_unloaded.is_connected(
		unloaded_callable
	):

		character_runtime.character_unloaded.connect(
			unloaded_callable
		)


	var current: Node3D = (
		character_runtime.get_active_character()
	)


	if current != null:

		_on_character_loaded(
			current
		)


# =============================================================
# INTERACTION MANAGER
# =============================================================

func set_interaction_manager(
	new_manager: CIGAinteractionManager
) -> void:

	interaction_manager = new_manager


# =============================================================
# INTERACTION RUNTIME
# =============================================================

func set_interaction_runtime(
	new_runtime: CIGAInteractionRuntime
) -> void:

	if interaction_runtime != null:

		var old_callable := Callable(
			self,
			"_on_interaction_burst_started"
		)


		if interaction_runtime.interaction_burst_started.is_connected(
			old_callable
		):

			interaction_runtime.interaction_burst_started.disconnect(
				old_callable
			)


	interaction_runtime = new_runtime


	if interaction_runtime == null:

		return


	var callable := Callable(
		self,
		"_on_interaction_burst_started"
	)


	if not interaction_runtime.interaction_burst_started.is_connected(
		callable
	):

		interaction_runtime.interaction_burst_started.connect(
			callable
		)


	print(
		"[CIGA VIEWPORT] INTERACTION RUNTIME CONNECTED"
	)


# =============================================================
# EVENTS RUNTIME
# =============================================================

func set_events_runtime(
	new_runtime: CIGAEventsRuntime
) -> void:

	events_runtime = new_runtime


# =============================================================
# OBJECT MANAGER
# =============================================================

func set_object_manager(
	new_manager: CIGAObjects
) -> void:

	object_manager = new_manager


	if object_manager == null:

		return


	var imported_callable := Callable(
		self,
		"_on_object_library_changed"
	)


	if not object_manager.object_imported.is_connected(
		imported_callable
	):

		object_manager.object_imported.connect(
			imported_callable
		)


	var removed_callable := Callable(
		self,
		"_on_object_library_changed"
	)


	if not object_manager.object_removed.is_connected(
		removed_callable
	):

		object_manager.object_removed.connect(
			removed_callable
		)


	var active_callable := Callable(
		self,
		"_on_object_library_changed"
	)


	if not object_manager.active_object_changed.is_connected(
		active_callable
	):

		object_manager.active_object_changed.connect(
			active_callable
		)


	if initialized:

		refresh_object_cache()


# =============================================================
# PROFILE MANAGER
# =============================================================

func set_profile_manager(
	new_manager: CIGAProfiles
) -> void:

	profile_manager = new_manager


	if profile_manager != null:

		load_profile_settings()


# =============================================================
# SETTINGS RUNTIME
# =============================================================

func set_settings_runtime(
	new_settings_runtime: CIGASettings
) -> void:

	settings_runtime = new_settings_runtime


# =============================================================
# CIGA OUTPUT
# =============================================================

func set_ciga_output(
	new_output: CIGAOutput
) -> void:

	if ciga_output != null:

		var old_callable := Callable(
			self,
			"_on_live_image_received"
		)


		if ciga_output.live_image_received.is_connected(
			old_callable
		):

			ciga_output.live_image_received.disconnect(
				old_callable
			)


	ciga_output = new_output


	if ciga_output == null:

		return


	var callable := Callable(
		self,
		"_on_live_image_received"
	)


	if not ciga_output.live_image_received.is_connected(
		callable
	):

		ciga_output.live_image_received.connect(
			callable
		)


# =============================================================
# CHARACTER
# =============================================================

func refresh_character() -> void:

	if character_runtime == null:

		auto_discover_dependencies()


	if character_runtime == null:

		return


	var current: Node3D = (
		character_runtime.get_active_character()
	)


	if current != null:

		_on_character_loaded(
			current
		)


# =============================================================
# CHARACTER LOADED
# =============================================================

func _on_character_loaded(
	new_character: Node3D
) -> void:

	if new_character == null:

		return


	if active_character == new_character:

		if active_character is CIGACalibrationAvatar:

			skeleton = null

		else:

			find_skeleton()


		update_spawn_points()


		if viewport != null:

			viewport.set_visual_character_visible(
				not streamer_mode_enabled
			)

			viewport.refresh_native_avatar_controls()


		return


	active_character = new_character

	_apply_saved_avatar_transform()


	# =========================================================
	# CHARACTER TYPE
	# =========================================================

	if active_character is CIGACalibrationAvatar:

		skeleton = null

	else:

		find_skeleton()


	# =========================================================
	# INTERACTION MANAGER
	# =========================================================

	if interaction_manager != null:

		interaction_manager.set_character(
			active_character
		)


	# =========================================================
	# SPAWN
	# =========================================================

	create_spawn_points()


	# =========================================================
	# VISIBILITY
	# =========================================================

	set_avatar_visible(
		not streamer_mode_enabled
	)


	# =========================================================
	# VIEWPORT
	# =========================================================

	if viewport != null:

		viewport.set_character(
			active_character
		)

		viewport.refresh_native_avatar_controls()


# =============================================================
# CHARACTER UNLOADED
# =============================================================

func _on_character_unloaded() -> void:

	active_character = null

	skeleton = null


	if viewport != null:

		viewport.clear_character()


# =============================================================
# FIND SKELETON
# =============================================================

func find_skeleton() -> void:

	skeleton = null


	if active_character == null:

		return


	if active_character is CIGACalibrationAvatar:

		return


	var found := (
		active_character.find_children(
			"*",
			"Skeleton3D",
			true,
			false
		)
	)


	for node: Node in found:

		if node is Skeleton3D:

			skeleton = (
				node
				as
				Skeleton3D
			)

			break


# =============================================================
# OBJECT PRELOAD
# =============================================================

func preload_object_library() -> void:

	if object_manager == null:

		auto_discover_dependencies()


	if object_manager == null:

		preload_complete = false

		return


	object_names.clear()


	for object_data: Dictionary in object_manager.objects:

		var object_id := str(
			object_data.get(
				"id",
				""
			)
		)


		if object_id.is_empty():

			continue


		var packed_scene: PackedScene = (
			object_manager.get_cached_packed_scene(
				object_id
			)
		)


		if packed_scene == null:

			continue


		object_names.append(
			object_id
		)


	object_names = (
		object_names.duplicate()
	)


	preload_complete = (
		object_manager.objects.size() == object_names.size()
		or
		not object_names.is_empty()
	)


# =============================================================
# UPDATE OBJECT SCALE
# =============================================================

func _update_object_scale(
	object_id: String,
	object_data: Dictionary
) -> void:

	if object_id.is_empty():

		return


	if object_manager == null:

		return


	var base_scale: float = (
		CIGAObjects.DEFAULT_OBJECT_SCALE
	)


	if object_manager.has_method(
		"get_object_base_scale"
	):

		base_scale = float(
			object_manager.get_object_base_scale(
				object_id
			)
		)

	else:

		base_scale = float(
			object_data.get(
				"base_scale",
				object_data.get(
					"scale",
					CIGAObjects.DEFAULT_OBJECT_SCALE
				)
			)
		)


	if not is_finite(
		base_scale
	):

		base_scale = (
			CIGAObjects.DEFAULT_OBJECT_SCALE
		)


	base_scale = clampf(
		base_scale,
		CIGAObjects.MIN_OBJECT_SCALE,
		CIGAObjects.MAX_OBJECT_SCALE
	)


	var multiplier: float = (
		CIGAObjects.DEFAULT_SCALE_MULTIPLIER
	)


	if object_manager.has_method(
		"get_object_scale_multiplier"
	):

		multiplier = float(
			object_manager.get_object_scale_multiplier(
				object_id
			)
		)

	else:

		multiplier = float(
			object_data.get(
				"scale_multiplier",
				CIGAObjects.DEFAULT_SCALE_MULTIPLIER
			)
		)


	if not is_finite(
		multiplier
	):

		multiplier = (
			CIGAObjects.DEFAULT_SCALE_MULTIPLIER
		)


	multiplier = clampf(
		multiplier,
		CIGAObjects.MIN_SCALE_MULTIPLIER,
		CIGAObjects.MAX_SCALE_MULTIPLIER
	)


	var effective_scale: float = (
		base_scale
		*
		multiplier
	)


	if not is_finite(
		effective_scale
	):

		effective_scale = (
			base_scale
		)


	effective_scale = clampf(
		effective_scale,
		CIGAObjects.MIN_OBJECT_SCALE,
		CIGAObjects.MAX_OBJECT_SCALE
	)


	object_scales[object_id] = (
		effective_scale
	)


# =============================================================
# TEST OBJECT
# =============================================================

func launch_test_object() -> bool:

	if viewport == null:

		return false


	if not initialized:

		return false


	if not preload_complete:

		return false


	if active_character == null:

		refresh_character()


	if active_character == null:

		return false


	if interaction_manager == null:

		auto_discover_dependencies()


	if interaction_manager == null:

		return false


	if object_names.is_empty():

		return false


	var object_id: String = (
		object_names.pick_random()
	)


	var target_name: String = (
		HIT_POINTS.pick_random()
	)


	var spawn: Marker3D = (
		get_spawn_point()
	)


	if spawn == null:

		return false


	return launch_object(
		object_id,
		target_name,
		spawn
	)


# =============================================================
# NORMAL LAUNCH
# =============================================================

func launch_object(
	object_id: String,
	target_name: String,
	spawn: Marker3D
) -> bool:

	if object_id.is_empty():

		return false


	if object_manager == null:

		return false


	var packed_scene: PackedScene = (
		object_manager.get_cached_packed_scene(
			object_id
		)
	)


	if packed_scene == null:

		return false


	target_name = (
		target_name_to_hit_point(
			target_name
		)
	)


	if spawn == null:

		spawn = get_spawn_point()


	if spawn == null:

		return false


	var speed: float = 5.4

	var force: float = 1.8


	if interaction_manager != null:

		speed = (
			interaction_manager.get_object_speed()
		)

		force = (
			interaction_manager.get_object_force()
		)


	var effective_scale: float = (
		get_current_object_scale(
			object_id
		)
	)


	return launch_object_with_parameters(
		object_id,
		target_name,
		spawn,
		speed,
		force,
		effective_scale
	)


# =============================================================
# LAUNCH OBJECT WITH PARAMETERS
# =============================================================

func launch_object_with_parameters(
	object_id: String,
	target_name: String,
	spawn: Marker3D,
	speed: float,
	force: float,
	effective_scale: float
) -> bool:

	if object_id.is_empty():

		return false


	if object_manager == null:

		return false


	var packed_scene: PackedScene = (
		object_manager.get_cached_packed_scene(
			object_id
		)
	)


	if packed_scene == null:

		return false


	target_name = (
		target_name_to_hit_point(
			target_name
		)
	)


	if spawn == null:

		spawn = get_spawn_point()


	if spawn == null:

		return false


	var target_position: Vector3 = (
		get_target_world_position(
			target_name
		)
	)


	if not target_position.is_finite():

		return false


	if viewport == null:

		return false


	if viewport.workspace == null:

		return false


	_enforce_projectile_limit()


	var throwable := ThrowableObject.new()


	if throwable == null:

		return false


	viewport.workspace.add_child(
		throwable
	)


	throwable.scale = Vector3.ONE


	if throwable.visual_container != null:

		throwable.visual_container.scale = Vector3.ONE


	if not throwable.impacted.is_connected(
		_on_throwable_impact
	):

		throwable.impacted.connect(
			_on_throwable_impact
	)


	var visual_value: Variant = (
		packed_scene.instantiate()
	)


	if not visual_value is Node3D:

		throwable.queue_free()

		return false


	var visual_instance: Node3D = (
		visual_value
		as
		Node3D
	)


	effective_scale = clampf(
		effective_scale,
		CIGAObjects.MIN_OBJECT_SCALE,
		CIGAObjects.MAX_OBJECT_SCALE
	)


	throwable.scale = Vector3.ONE


	if throwable.visual_container != null:

		throwable.visual_container.scale = Vector3.ONE


	visual_instance.scale = (
		Vector3.ONE
		*
		effective_scale
	)


	visual_instance.visible = true

	visual_instance.process_mode = (
		Node.PROCESS_MODE_INHERIT
	)


	throwable.pre_instantiated_model = (
		visual_instance
	)


	throwable.setup(
		spawn.global_position,
		target_position,
		object_id,
		maxf(
			speed,
			0.1
		),
		maxf(
			force,
			0.0
		),
		target_name,
		get_object_lifetime(),
		get_bounce_time()
	)


	active_projectiles.append(
		throwable
	)


	return true


# =============================================================
# INTERACTION BURST
# =============================================================

func _on_interaction_burst_started(
	launches: Array
) -> void:

	if launches.is_empty():

		return


	var normal_launches: Array = []


	for launch_value: Variant in launches:

		if not launch_value is Dictionary:

			continue


		var launch_data: Dictionary = (
			launch_value
			as
			Dictionary
		)


		var action_type: String = str(
			launch_data.get(
				"action_type",
				""
			)
		).strip_edges().to_upper()


		if action_type == "DISPLAY_IMAGE":

			display_event_image(
				launch_data
			)

			continue


		if action_type == "DISPLAY_IMAGE_LIVE":

			queue_live_image_action(
				launch_data
			)

			continue


		normal_launches.append(
			launch_data
		)


	if not normal_launches.is_empty():

		launch_objects(
			normal_launches
		)


# =============================================================
# QUEUE LIVE IMAGE ACTION
# =============================================================

func queue_live_image_action(
	action: Dictionary
) -> void:

	if action.is_empty():

		return


	var stored_action: Dictionary = (
		action.duplicate(
			true
		)
	)


	var requested_duration: float = float(
		stored_action.get(
			"image_live_duration",
			10.0
		)
	)


	if not is_finite(
		requested_duration
	):

		requested_duration = 10.0


	requested_duration = clampf(
		requested_duration,
		LIVE_IMAGE_MIN_DURATION,
		EVENT_IMAGE_MAX_DURATION
	)


	stored_action["image_live_duration"] = (
		requested_duration
	)


	pending_live_image_actions.append(
		stored_action
	)


	print(
		"[CIGA VIEWPORT] LIVE IMAGE ACTION WAITING | "
		+
		"TARGET="
		+
		str(
			stored_action.get(
				"image_live_target",
				"HeadHitPoint"
			)
		)
		+
		" | DURATION="
		+
		str(
			requested_duration
		)
		+
		" | QUEUE="
		+
		str(
			pending_live_image_actions.size()
		)
	)


# =============================================================
# LIVE IMAGE RECEIVED
# =============================================================

func _on_live_image_received(
	payload: Dictionary
) -> void:

	if payload.is_empty():

		return


	print(
		"[CIGA VIEWPORT] LIVE IMAGE RECEIVED FROM OUTPUT"
	)


	if pending_live_image_actions.is_empty():

		print(
			"[CIGA VIEWPORT] LIVE IMAGE RECEIVED WITHOUT "
			+
			"PENDING ACTION | CLEANING FILE"
		)


		_cleanup_live_image_file_from_payload(
			payload
		)

		return


	var action: Dictionary = (
		pending_live_image_actions.pop_front()
	)


	display_live_event_image(
		payload,
		action
	)


# =============================================================
# DISPLAY LIVE EVENT IMAGE
# =============================================================

func display_live_event_image(
	payload: Dictionary,
	action: Dictionary
) -> void:

	if payload.is_empty():

		return


	if action.is_empty():

		_cleanup_live_image_file_from_payload(
			payload
		)

		return


	if viewport == null:

		print(
			"[CIGA VIEWPORT] LIVE IMAGE FAILED | VIEWPORT NULL"
		)

		_cleanup_live_image_file_from_payload(
			payload
		)

		return


	if viewport.workspace == null:

		print(
			"[CIGA VIEWPORT] LIVE IMAGE FAILED | WORKSPACE NULL"
		)

		_cleanup_live_image_file_from_payload(
			payload
		)

		return


	var temporary_path: String = str(
		payload.get(
			"local_path",
			""
		)
	).strip_edges()


	if temporary_path.is_empty():

		print(
			"[CIGA VIEWPORT] LIVE IMAGE FAILED | NO LOCAL PATH"
		)

		_cleanup_live_image_file_from_payload(
			payload
		)

		return


	if not temporary_path.begins_with(
		LIVE_IMAGE_TEMP_DIR
	):

		print(
			"[CIGA VIEWPORT] LIVE IMAGE FAILED | "
			+
			"INVALID TEMP PATH | "
			+
			temporary_path
		)

		return


	if not FileAccess.file_exists(
		temporary_path
	):

		print(
			"[CIGA VIEWPORT] LIVE IMAGE FAILED | FILE NOT FOUND | "
			+
			temporary_path
		)

		return


	var image: Image = Image.new()


	var image_error: Error = (
		image.load(
			temporary_path
		)
	)


	if image_error != OK:

		print(
			"[CIGA VIEWPORT] LIVE IMAGE FAILED | IMAGE LOAD ERROR="
			+
			error_string(
				image_error
			)
		)

		_cleanup_live_image_file(
			temporary_path
		)

		return


	if image.is_empty():

		print(
			"[CIGA VIEWPORT] LIVE IMAGE FAILED | EMPTY IMAGE"
		)

		_cleanup_live_image_file(
			temporary_path
		)

		return


	var texture: ImageTexture = (
		ImageTexture.create_from_image(
			image
		)
	)


	if texture == null:

		print(
			"[CIGA VIEWPORT] LIVE IMAGE FAILED | "
			+
			"TEXTURE CREATION FAILED"
		)

		_cleanup_live_image_file(
			temporary_path
		)

		return


	var texture_width: int = maxi(
		texture.get_width(),
		1
	)


	var texture_height: int = maxi(
		texture.get_height(),
		1
	)


	if active_character == null:

		refresh_character()


	if active_character == null:

		print(
			"[CIGA VIEWPORT] LIVE IMAGE FAILED | "
			+
			"ACTIVE CHARACTER NULL"
		)

		_cleanup_live_image_file(
			temporary_path
		)

		return


	var target_name: String = str(
		action.get(
			"image_live_target",
			"HeadHitPoint"
		)
	).strip_edges()


	if target_name.is_empty():

		target_name = "HeadHitPoint"


	target_name = (
		target_name_to_hit_point(
			target_name
		)
	)


	var target_node: Node3D = (
		get_event_image_target_node(
			target_name
		)
	)


	if target_node == null:

		print(
			"[CIGA VIEWPORT] LIVE IMAGE FAILED | "
			+
			"TARGET NOT FOUND | TARGET="
			+
			target_name
		)

		_cleanup_live_image_file(
			temporary_path
		)

		return


	var sprite: Sprite3D = Sprite3D.new()


	if sprite == null:

		print(
			"[CIGA VIEWPORT] LIVE IMAGE FAILED | "
			+
			"SPRITE CREATION FAILED"
		)

		_cleanup_live_image_file(
			temporary_path
		)

		return


	sprite.name = (
		"CIGALiveImage_"
		+
		str(
			Time.get_ticks_usec()
		)
	)


	sprite.texture = texture

	sprite.pixel_size = (
		EVENT_IMAGE_BASE_WIDTH
		/
		float(
			texture_width
		)
	)


	sprite.billboard = (
		BaseMaterial3D.BILLBOARD_DISABLED
	)

	sprite.no_depth_test = true

	sprite.render_priority = 100

	sprite.visible = true


	var image_scale: float = (
		_resolve_live_scale(
			action
		)
	)


	if not is_finite(
		image_scale
	):

		image_scale = 1.0


	image_scale = clampf(
		image_scale,
		EVENT_IMAGE_MIN_SCALE,
		EVENT_IMAGE_MAX_SCALE
	)


	var offset_x: float = (
		_resolve_live_parameter(
			action,
			"image_live_offset_x",
			0.0
		)
	)


	var offset_y: float = (
		_resolve_live_parameter(
			action,
			"image_live_offset_y",
			0.0
		)
	)


	var offset_z: float = (
		_resolve_live_parameter(
			action,
			"image_live_offset_z",
			0.0
		)
	)


	var rotation_x: float = (
		_resolve_live_parameter(
			action,
			"image_live_rotation_x",
			0.0
		)
	)


	var rotation_y: float = (
		_resolve_live_parameter(
			action,
			"image_live_rotation_y",
			0.0
		)
	)


	var rotation_z: float = (
		_resolve_live_parameter(
			action,
			"image_live_rotation_z",
			0.0
		)
	)


	var mirror_horizontal: bool = bool(
		action.get(
			"image_live_mirror_h",
			false
		)
	)


	var mirror_vertical: bool = bool(
		action.get(
			"image_live_mirror_v",
			false
		)
	)


	var scale_x: float = image_scale

	var scale_y: float = image_scale


	if mirror_horizontal:

		scale_x *= -1.0


	if mirror_vertical:

		scale_y *= -1.0


	sprite.position = Vector3(
		offset_x,
		offset_y,
		offset_z
	)


	sprite.rotation_degrees = Vector3(
		rotation_x,
		rotation_y,
		rotation_z
	)


	var configured_rotation: Quaternion = (
		Quaternion.from_euler(
			Vector3(
				deg_to_rad(
					rotation_x
				),
				deg_to_rad(
					rotation_y
				),
				deg_to_rad(
					rotation_z
				)
			)
		)
		.normalized()
	)


	sprite.set_meta(
		"ciga_live_follow_vmc",
		true
	)


	sprite.set_meta(
		"ciga_live_base_position",
		sprite.position
	)

	sprite.set_meta(
		"ciga_live_base_rotation",
		configured_rotation
	)


	sprite.scale = Vector3(
		scale_x,
		scale_y,
		1.0
	)


	target_node.add_child(
		sprite
	)


	if not sprite.is_inside_tree():

		print(
			"[CIGA VIEWPORT] LIVE IMAGE FAILED | "
			+
			"SPRITE NOT ADDED TO TREE"
		)

		sprite.queue_free()

		_cleanup_live_image_file(
			temporary_path
		)

		return


	# =========================================================
	# VMC REFERENCE
	#
	# Cada sprite guarda:
	#
	# 1. orientação VMC no instante em que nasceu
	# 2. rotação visual no instante em que nasceu
	#
	# Isto permite aplicar apenas o delta futuro.
	# =========================================================

	var current_tracking: Quaternion = (
		_get_current_vmc_tracking_rotation()
	)


	if current_tracking != Quaternion.IDENTITY:

		sprite.set_meta(
			"ciga_vmc_reference_tracking",
			current_tracking
		)

		sprite.set_meta(
			"ciga_vmc_reference_visual_rotation",
			sprite.quaternion
		)


	active_live_image_sprites.append(
		sprite
	)


	_enforce_live_image_limit()


	var duration: float = float(
		action.get(
			"image_live_duration",
			10.0
		)
	)


	if not is_finite(
		duration
	):

		duration = 10.0


	duration = clampf(
		duration,
		LIVE_IMAGE_MIN_DURATION,
		EVENT_IMAGE_MAX_DURATION
	)


	print(
		"[CIGA VIEWPORT] LIVE IMAGE CREATED | "
		+
		"FILE="
		+
		str(
			payload.get(
				"filename",
				"live_image"
			)
		)
		+
		" | PATH="
		+
		temporary_path
		+
		" | TEXTURE="
		+
		str(
			texture_width
		)
		+
		"x"
		+
		str(
			texture_height
		)
		+
		" | TARGET="
		+
		target_name
		+
		" | SCALE="
		+
		str(
			image_scale
		)
		+
		" | OFFSET=("
		+
		str(
			offset_x
		)
		+
		", "
		+
		str(
			offset_y
		)
		+
		", "
		+
		str(
			offset_z
		)
		+
		")"
		+
		" | ROTATION=("
		+
		str(
			rotation_x
		)
		+
		", "
		+
		str(
			rotation_y
		)
		+
		", "
		+
		str(
			rotation_z
		)
		+
		")"
		+
		" | MIRROR_H="
		+
		str(
			mirror_horizontal
		)
		+
		" | MIRROR_V="
		+
		str(
			mirror_vertical
		)
		+
		" | DURATION="
		+
		str(
			duration
		)
	)


	_remove_live_image_after_duration(
		sprite,
		duration,
		temporary_path
	)


# =============================================================
# VMC CURRENT ROTATION
# =============================================================

func _get_current_vmc_tracking_rotation() -> Quaternion:

	if vmc_runtime == null:

		return Quaternion.IDENTITY


	if not is_instance_valid(
		vmc_runtime
	):

		return Quaternion.IDENTITY


	if not vmc_runtime.is_vmc_tracking_available():

		return Quaternion.IDENTITY


	var rotation: Quaternion = (
		vmc_runtime
		.get_vmc_global_tracking_rotation()
	)


	if rotation.length_squared() <= 0.000001:

		return Quaternion.IDENTITY


	return rotation.normalized()
	
	

func _get_vmc_tracking_delta_euler(
	reference_tracking: Quaternion,
	current_tracking: Quaternion
) -> Vector3:

	var delta_rotation: Quaternion = (
		reference_tracking.inverse()
		*
		current_tracking
	).normalized()


	return delta_rotation.get_euler()

# =============================================================
# VMC REBASE
# =============================================================

func _rebase_vmc_tracking() -> void:

	var current_tracking: Quaternion = (
		_get_current_vmc_tracking_rotation()
	)


	if current_tracking == Quaternion.IDENTITY:

		return


	# =========================================================
	# NORMAL DISPLAY IMAGE
	# =========================================================

	for sprite in active_event_image_sprites:

		if sprite == null:

			continue


		if not is_instance_valid(
			sprite
		):

			continue


		if not bool(
			sprite.get_meta(
				"ciga_follow_vmc",
				false
			)
		):

			continue


		var base_position_value: Variant = (
			sprite.get_meta(
				"ciga_base_position",
				sprite.position
			)
		)


		var base_rotation_value: Variant = (
			sprite.get_meta(
				"ciga_base_rotation",
				sprite.quaternion
			)
		)


		if base_position_value is Vector3:

			sprite.position = (
				base_position_value
				as
				Vector3
			)


		if base_rotation_value is Quaternion:

			sprite.quaternion = (
				(base_rotation_value as Quaternion)
				.normalized()
			)


		sprite.set_meta(
			"ciga_vmc_reference_tracking",
			current_tracking
		)


	# =========================================================
	# LIVE DISPLAY IMAGE
	# =========================================================

	for sprite in active_live_image_sprites:

		if sprite == null:

			continue


		if not is_instance_valid(
			sprite
		):

			continue


		if not bool(
			sprite.get_meta(
				"ciga_live_follow_vmc",
				false
			)
		):

			continue


		var base_position_value: Variant = (
			sprite.get_meta(
				"ciga_live_base_position",
				sprite.position
			)
		)


		var base_rotation_value: Variant = (
			sprite.get_meta(
				"ciga_live_base_rotation",
				sprite.quaternion
			)
		)


		if base_position_value is Vector3:

			sprite.position = (
				base_position_value
				as
				Vector3
			)


		if base_rotation_value is Quaternion:

			sprite.quaternion = (
				(base_rotation_value as Quaternion)
				.normalized()
			)


		sprite.set_meta(
			"ciga_vmc_reference_tracking",
			current_tracking
		)

# =============================================================
# VMC IMAGE TRACKING
# =============================================================

func _update_event_image_vmc_tracking() -> void:

	var current_tracking: Quaternion = (
		_get_current_vmc_tracking_rotation()
	)


	if current_tracking == Quaternion.IDENTITY:

		return


	# =========================================================
	# NORMAL EVENT IMAGES
	# =========================================================

	for sprite in active_event_image_sprites:

		if sprite == null:

			continue


		if not is_instance_valid(
			sprite
		):

			continue


		if not bool(
			sprite.get_meta(
				"ciga_follow_vmc",
				false
			)
		):

			continue


		var reference_value: Variant = (
			sprite.get_meta(
				"ciga_vmc_reference_tracking",
				Quaternion.IDENTITY
			)
		)


		if not reference_value is Quaternion:

			sprite.set_meta(
				"ciga_vmc_reference_tracking",
				current_tracking
			)

			sprite.set_meta(
				"ciga_base_position",
				sprite.position
			)

			sprite.set_meta(
				"ciga_base_rotation",
				sprite.quaternion
			)

			continue


		var reference_tracking: Quaternion = (
			reference_value
			as
			Quaternion
		).normalized()


		var base_position_value: Variant = (
			sprite.get_meta(
				"ciga_base_position",
				sprite.position
			)
		)


		var base_rotation_value: Variant = (
			sprite.get_meta(
				"ciga_base_rotation",
				sprite.quaternion
			)
		)


		if not base_position_value is Vector3:

			base_position_value = sprite.position


		if not base_rotation_value is Quaternion:

			base_rotation_value = sprite.quaternion


		var base_position: Vector3 = (
			base_position_value
			as
			Vector3
		)


		var base_rotation: Quaternion = (
			base_rotation_value
			as
			Quaternion
		).normalized()


		# =====================================================
		# DELTA DE ORIENTAÇÃO
		# =====================================================

		var delta_rotation: Quaternion = (
			reference_tracking.inverse()
			*
			current_tracking
		).normalized()


		# =====================================================
		# T = INVERTER TRACKING
		# =====================================================

		if vmc_tracking_flipped:

			delta_rotation = (
				delta_rotation.inverse()
			).normalized()


		# =====================================================
		# POSIÇÃO
		#
		# A posição da imagem é o offset ORIGINAL rodado
		# pela rotação do avatar.
		#
		# Isto faz a imagem comportar-se como a ponta
		# de uma vara presa ao ponto de origem.
		# =====================================================

		sprite.quaternion = (
			base_rotation
			*
			delta_rotation.inverse()
		).normalized()
		# =====================================================
		# ORIENTAÇÃO
		#
		# A frente da imagem acompanha a direção real
		# do avatar.
		# =====================================================

		sprite.quaternion = (
			base_rotation
			*
			delta_rotation.inverse()
		).normalized()


	# =========================================================
	# LIVE EVENT IMAGES
	# =========================================================

	for sprite in active_live_image_sprites:

		if sprite == null:

			continue


		if not is_instance_valid(
			sprite
		):

			continue


		if not bool(
			sprite.get_meta(
				"ciga_live_follow_vmc",
				false
			)
		):

			continue


		var reference_value: Variant = (
			sprite.get_meta(
				"ciga_vmc_reference_tracking",
				Quaternion.IDENTITY
			)
		)


		if not reference_value is Quaternion:

			sprite.set_meta(
				"ciga_vmc_reference_tracking",
				current_tracking
			)

			sprite.set_meta(
				"ciga_live_base_position",
				sprite.position
			)

			sprite.set_meta(
				"ciga_live_base_rotation",
				sprite.quaternion
			)

			continue


		var reference_tracking: Quaternion = (
			reference_value
			as
			Quaternion
		).normalized()


		var base_position_value: Variant = (
			sprite.get_meta(
				"ciga_live_base_position",
				sprite.position
			)
		)


		var base_rotation_value: Variant = (
			sprite.get_meta(
				"ciga_live_base_rotation",
				sprite.quaternion
			)
		)


		if not base_position_value is Vector3:

			base_position_value = sprite.position


		if not base_rotation_value is Quaternion:

			base_rotation_value = sprite.quaternion


		var base_position: Vector3 = (
			base_position_value
			as
			Vector3
		)


		var base_rotation: Quaternion = (
			base_rotation_value
			as
			Quaternion
		).normalized()


		# =====================================================
		# DELTA DE ORIENTAÇÃO
		# =====================================================

		var delta_rotation: Quaternion = (
			reference_tracking.inverse()
			*
			current_tracking
		).normalized()


		# =====================================================
		# T = INVERTER TRACKING
		# =====================================================

		if vmc_tracking_flipped:

			delta_rotation = (
				delta_rotation.inverse()
			).normalized()


		# =====================================================
		# POSIÇÃO
		# =====================================================

		sprite.position = (
			delta_rotation
			*
			base_position
		)


		# =====================================================
		# ORIENTAÇÃO
		# =====================================================

		sprite.quaternion = (
			base_rotation
			*
			delta_rotation
		).normalized()

# =============================================================
# RESOLVE LIVE SCALE
# =============================================================

func _resolve_live_scale(
	action_data: Dictionary
) -> float:

	var mode: String = str(
		action_data.get(
			"image_live_scale_mode",
			"FIXED"
		)
	).to_upper().strip_edges()


	if mode == "RANDOM":

		var minimum: float = float(
			action_data.get(
				"image_live_scale_min",
				0.8
			)
		)


		var maximum: float = float(
			action_data.get(
				"image_live_scale_max",
				1.2
			)
		)


		if not is_finite(
			minimum
		):

			minimum = 0.8


		if not is_finite(
			maximum
		):

			maximum = 1.2


		minimum = clampf(
			minimum,
			EVENT_IMAGE_MIN_SCALE,
			EVENT_IMAGE_MAX_SCALE
		)


		maximum = clampf(
			maximum,
			EVENT_IMAGE_MIN_SCALE,
			EVENT_IMAGE_MAX_SCALE
		)


		if minimum > maximum:

			var temp: float = minimum

			minimum = maximum

			maximum = temp


		return randf_range(
			minimum,
			maximum
		)


	var fixed_scale: float = float(
		action_data.get(
			"image_live_scale",
			1.0
		)
	)


	if not is_finite(
		fixed_scale
	):

		fixed_scale = 1.0


	return clampf(
		fixed_scale,
		EVENT_IMAGE_MIN_SCALE,
		EVENT_IMAGE_MAX_SCALE
	)


# =============================================================
# RESOLVE LIVE PARAMETER
# =============================================================

func _resolve_live_parameter(
	action_data: Dictionary,
	parameter_name: String,
	default_value: float = 0.0
) -> float:

	var mode_key: String = (
		parameter_name
		+
		"_mode"
	)


	var minimum_key: String = (
		parameter_name
		+
		"_min"
	)


	var maximum_key: String = (
		parameter_name
		+
		"_max"
	)


	var mode: String = str(
		action_data.get(
			mode_key,
			"FIXED"
		)
	).to_upper().strip_edges()


	if mode == "RANDOM":

		var minimum: float = float(
			action_data.get(
				minimum_key,
				default_value
			)
		)


		var maximum: float = float(
			action_data.get(
				maximum_key,
				default_value
			)
		)


		if not is_finite(
			minimum
		):

			minimum = default_value


		if not is_finite(
			maximum
		):

			maximum = default_value


		if minimum > maximum:

			var temp: float = minimum

			minimum = maximum

			maximum = temp


		return randf_range(
			minimum,
			maximum
		)


	var fixed_value: float = float(
		action_data.get(
			parameter_name,
			default_value
		)
	)


	if not is_finite(
		fixed_value
	):

		fixed_value = default_value


	return fixed_value


# =============================================================
# REMOVE LIVE IMAGE
# =============================================================

func _remove_live_image_after_duration(
	image: Sprite3D,
	duration: float,
	image_path: String
) -> void:

	if image == null:

		_cleanup_live_image_file(
			image_path
		)

		return


	var safe_duration: float = clampf(
		duration,
		LIVE_IMAGE_MIN_DURATION,
		EVENT_IMAGE_MAX_DURATION
	)


	var timer: SceneTreeTimer = (
		get_tree().create_timer(
			safe_duration
		)
	)


	timer.timeout.connect(
		func() -> void:

			if is_instance_valid(
				image
			):

				active_live_image_sprites.erase(
					image
				)

				image.queue_free()


			_cleanup_live_image_file(
				image_path
			)


			print(
				"[CIGA VIEWPORT] LIVE IMAGE REMOVED | "
				+
				"DURATION_FINISHED | PATH="
				+
				image_path
			)
	)


# =============================================================
# LIVE IMAGE LIMIT
# =============================================================

func _enforce_live_image_limit() -> void:

	for i in range(
		active_live_image_sprites.size() - 1,
		-1,
		-1
	):

		var sprite: Sprite3D = (
			active_live_image_sprites[i]
		)


		if (
			sprite == null
			or
			not is_instance_valid(
				sprite
			)
		):

			active_live_image_sprites.remove_at(
				i
			)


	while (
		active_live_image_sprites.size()
		>
		LIVE_IMAGE_MAX_ACTIVE
	):

		var oldest: Sprite3D = (
			active_live_image_sprites.pop_front()
		)


		if oldest == null:

			continue


		if is_instance_valid(
			oldest
		):

			oldest.queue_free()


# =============================================================
# CLEAN LIVE IMAGE FILE
# =============================================================

func _cleanup_live_image_file(
	path: String
) -> void:

	if path.is_empty():

		return


	var normalized_path: String = (
		path
		.replace(
			"\\",
			"/"
		)
	)


	var normalized_temp_dir: String = (
		LIVE_IMAGE_TEMP_DIR
		.replace(
			"\\",
			"/"
		)
	)


	if not normalized_path.begins_with(
		normalized_temp_dir
	):

		return


	if not FileAccess.file_exists(
		normalized_path
	):

		return


	var absolute_path: String = (
		ProjectSettings.globalize_path(
			normalized_path
		)
	)


	var temp_directory_absolute: String = (
		ProjectSettings.globalize_path(
			normalized_temp_dir
		)
	)


	if not absolute_path.begins_with(
		temp_directory_absolute
	):

		return


	var file_name: String = (
		absolute_path.get_file()
	)


	var dir: DirAccess = (
		DirAccess.open(
			temp_directory_absolute
		)
	)


	if dir == null:

		push_warning(
			"[CIGA VIEWPORT] LIVE IMAGE CLEANUP FAILED | "
			+
			"TEMP DIR UNAVAILABLE"
		)

		return


	var remove_error: Error = (
		dir.remove(
			file_name
		)
	)


	if remove_error == OK:

		print(
			"[CIGA VIEWPORT] LIVE IMAGE TEMP FILE DELETED | "
			+
			normalized_path
		)

	else:

		push_warning(
			"[CIGA VIEWPORT] FAILED TO DELETE LIVE IMAGE | "
			+
			normalized_path
			+
			" | "
			+
			error_string(
				remove_error
			)
		)


# =============================================================
# CLEAN LIVE IMAGE FROM PAYLOAD
# =============================================================

func _cleanup_live_image_file_from_payload(
	payload: Dictionary
) -> void:

	if payload.is_empty():

		return


	var path: String = str(
		payload.get(
			"local_path",
			""
		)
	).strip_edges()


	if path.is_empty():

		return


	_cleanup_live_image_file(
		path
	)


# =============================================================
# CLEAN PENDING LIVE IMAGES
# =============================================================

func _try_cleanup_pending_live_images() -> void:

	if pending_live_image_actions.is_empty():

		return


	return


# =============================================================
# DISPLAY EVENT IMAGE
# =============================================================

func display_event_image(
	image_data: Dictionary
) -> bool:

	print(
		"[CIGA VIEWPORT] DISPLAY IMAGE HANDLER ENTERED"
	)


	if image_data.is_empty():

		push_warning(
			"[CIGA VIEWPORT] DISPLAY IMAGE FAILED | IMAGE DATA EMPTY"
		)

		return false


	print(
		"[CIGA VIEWPORT] DISPLAY IMAGE DATA | ",
		image_data
	)


	if viewport == null:

		push_warning(
			"[CIGA VIEWPORT] DISPLAY IMAGE FAILED | VIEWPORT NULL"
		)

		return false


	if viewport.workspace == null:

		push_warning(
			"[CIGA VIEWPORT] DISPLAY IMAGE FAILED | WORKSPACE NULL"
		)

		return false


	var image_path: String = str(
		image_data.get(
			"image_path",
			""
		)
	).strip_edges()


	if image_path.is_empty():

		push_warning(
			"[CIGA VIEWPORT] DISPLAY IMAGE FAILED | IMAGE PATH EMPTY"
		)

		return false


	print(
		"[CIGA VIEWPORT] DISPLAY IMAGE PATH | ",
		image_path
	)


	# =========================================================
	# CACHE
	# =========================================================

	var texture: Texture2D = (
		get_cached_event_image(
			image_path
		)
	)


	print(
		"[CIGA VIEWPORT] DISPLAY IMAGE CACHE | ",
		texture
	)


	# =========================================================
	# FALLBACK LOAD
	# =========================================================

	if texture == null:

		var image := Image.new()

		var load_error := image.load(
			image_path
		)


		if load_error != OK:

			push_warning(
				"[CIGA VIEWPORT] DISPLAY IMAGE FAILED | "
				+
				"IMAGE LOAD ERROR | "
				+
				image_path
				+
				" | ERROR="
				+
				error_string(
					load_error
				)
			)

			return false


		if image.is_empty():

			push_warning(
				"[CIGA VIEWPORT] DISPLAY IMAGE FAILED | "
				+
				"EMPTY IMAGE | "
				+
				image_path
			)

			return false


		texture = (
			ImageTexture.create_from_image(
				image
			)
		)


		if texture == null:

			push_warning(
				"[CIGA VIEWPORT] DISPLAY IMAGE FAILED | "
				+
				"TEXTURE CREATION FAILED | "
				+
				image_path
			)

			return false


		var cache_value: Variant = (
			viewport.workspace.get_meta(
				"ciga_event_image_cache",
				{}
			)
		)


		if cache_value is Dictionary:

			var cache: Dictionary = (
				cache_value
				as
				Dictionary
			)


			cache[image_path] = texture


			viewport.workspace.set_meta(
				"ciga_event_image_cache",
				cache
			)


	print(
		"[CIGA VIEWPORT] DISPLAY IMAGE TEXTURE READY | ",
		texture.get_width(),
		"x",
		texture.get_height()
	)


	# =========================================================
	# CHARACTER
	# =========================================================

	if active_character == null:

		refresh_character()


	if active_character == null:

		push_warning(
			"[CIGA VIEWPORT] DISPLAY IMAGE FAILED | "
			+
			"ACTIVE CHARACTER NULL"
		)

		return false


	# =========================================================
	# TARGET
	# =========================================================

	var target_name: String = str(
		image_data.get(
			"image_target",
			"HeadHitPoint"
		)
	).strip_edges()


	if target_name.is_empty():

		target_name = "HeadHitPoint"


	target_name = (
		target_name_to_hit_point(
			target_name
		)
	)


	var target_node: Node3D = (
		get_event_image_target_node(
			target_name
		)
	)


	if target_node == null:

		push_warning(
			"[CIGA VIEWPORT] DISPLAY IMAGE FAILED | "
			+
			"TARGET NOT FOUND | "
			+
			target_name
		)

		return false


	print(
		"[CIGA VIEWPORT] DISPLAY IMAGE TARGET | ",
		target_node.get_path()
	)


	# =========================================================
	# CREATE SPRITE
	# =========================================================

	var sprite: Sprite3D = Sprite3D.new()


	if sprite == null:

		push_warning(
			"[CIGA VIEWPORT] DISPLAY IMAGE FAILED | "
			+
			"SPRITE CREATION FAILED"
		)

		return false


	sprite.name = (
		"CIGAEventImage_"
		+
		str(
			Time.get_ticks_usec()
		)
	)


	sprite.texture = texture

	sprite.visible = true

	sprite.billboard = (
		BaseMaterial3D.BILLBOARD_DISABLED
	)

	sprite.no_depth_test = true

	sprite.render_priority = 100


	# =========================================================
	# SIZE
	# =========================================================

	var texture_width: int = maxi(
		texture.get_width(),
		1
	)


	sprite.pixel_size = (
		EVENT_IMAGE_BASE_WIDTH
		/
		float(texture_width)
	)


	# =========================================================
	# SCALE
	# =========================================================

	var image_scale: float = float(
		image_data.get(
			"image_scale",
			1.0
		)
	)


	if not is_finite(
		image_scale
	):

		image_scale = 1.0


	image_scale = clampf(
		image_scale,
		EVENT_IMAGE_MIN_SCALE,
		EVENT_IMAGE_MAX_SCALE
	)


	# =========================================================
	# OFFSET
	# =========================================================

	var offset: Vector3 = Vector3.ZERO

	var offset_value: Variant = (
		image_data.get(
			"image_offset",
			Vector3.ZERO
		)
	)


	if offset_value is Vector3:

		offset = (
			offset_value
			as
			Vector3
		)


	elif offset_value is Dictionary:

		offset = Vector3(
			float(
				offset_value.get(
					"x",
					0.0
				)
			),
			float(
				offset_value.get(
					"y",
					0.0
				)
			),
			float(
				offset_value.get(
					"z",
					0.0
				)
			)
		)


	offset.x = clampf(
		offset.x,
		-2.0,
		2.0
	)


	offset.y = clampf(
		offset.y,
		-2.0,
		2.0
	)


	offset.z = clampf(
		offset.z,
		-2.0,
		2.0
	)


	# =========================================================
	# IMPORTANT
	#
	# Restore the configured event position.
	# This was accidentally missing from the previous version.
	# =========================================================

	sprite.position = offset


	# =========================================================
	# ROTATION
	# =========================================================

	sprite.rotation_degrees = Vector3(
		float(
			image_data.get(
				"image_rotation_x",
				0.0
			)
		),
		float(
			image_data.get(
				"image_rotation_y",
				0.0
			)
		),
		float(
			image_data.get(
				"image_rotation_z",
				0.0
			)
		)
	)


	# =========================================================
	# MIRROR
	# =========================================================

	var mirror_h: bool = bool(
		image_data.get(
			"image_mirror_h",
			false
		)
	)


	var mirror_v: bool = bool(
		image_data.get(
			"image_mirror_v",
			false
		)
	)


	var scale_x: float = image_scale

	var scale_y: float = image_scale


	if mirror_h:

		scale_x *= -1.0


	if mirror_v:

		scale_y *= -1.0


	sprite.scale = Vector3(
		scale_x,
		scale_y,
		1.0
	)


	# =========================================================
	# ATTACH
	# =========================================================

	_attach_event_image_to_target(
		sprite,
		target_node
	)


	if not sprite.is_inside_tree():

		push_warning(
			"[CIGA VIEWPORT] DISPLAY IMAGE FAILED | "
			+
			"SPRITE NOT ADDED TO TREE"
		)

		sprite.queue_free()

		return false


	# =========================================================
	# VMC FOLLOW REGISTRATION
	# =========================================================

	sprite.set_meta(
		"ciga_follow_vmc",
		true
	)


	sprite.set_meta(
		"ciga_base_position",
		sprite.position
	)

	sprite.set_meta(
		"ciga_base_rotation",
		sprite.quaternion
	)


	var current_tracking: Quaternion = (
		_get_current_vmc_tracking_rotation()
	)


	if current_tracking != Quaternion.IDENTITY:

		sprite.set_meta(
			"ciga_vmc_reference_tracking",
			current_tracking
		)


		sprite.set_meta(
			"ciga_vmc_reference_visual_rotation",
			sprite.quaternion
		)


	if not active_event_image_sprites.has(
		sprite
	):

		active_event_image_sprites.append(
			sprite
		)


	print(
		"[CIGA VIEWPORT] DISPLAY IMAGE CREATED | "
		+
		"PATH="
		+
		image_path
		+
		" | TARGET="
		+
		target_name
		+
		" | TARGET_NODE="
		+
		str(
			target_node.get_path()
		)
		+
		" | POSITION="
		+
		str(
			sprite.position
		)
		+
		" | GLOBAL_POSITION="
		+
		str(
			sprite.global_position
		)
		+
		" | SCALE="
		+
		str(
			sprite.scale
		)
	)


	# =========================================================
	# DURATION
	# =========================================================

	var duration: float = float(
		image_data.get(
			"image_duration",
			3.0
		)
	)


	if not is_finite(
		duration
	):

		duration = 3.0


	duration = clampf(
		duration,
		EVENT_IMAGE_MIN_DURATION,
		60.0
	)


	_remove_event_image_after_duration(
		sprite,
		duration
	)


	return true

# =============================================================
# EVENT IMAGE CONTAINER
# =============================================================

func get_or_create_event_image_container() -> Node3D:

	if viewport == null:

		return null


	if viewport.workspace == null:

		return null


	var existing: Node = (
		viewport.workspace.get_node_or_null(
			"CIGAEventImages"
		)
	)


	if existing is Node3D:

		return (
			existing
			as
			Node3D
		)


	var container: Node3D = Node3D.new()


	container.name = (
		"CIGAEventImages"
	)


	container.process_mode = (
		Node.PROCESS_MODE_INHERIT
	)


	container.visible = true


	viewport.workspace.add_child(
		container
	)


	return container


# =============================================================
# EVENT IMAGE TARGET
# =============================================================

func get_event_image_target_node(
	target_name: String
) -> Node3D:

	if active_character == null:

		return null


	var resolved_name: String = (
		target_name_to_hit_point(
			target_name
		)
	)


	var direct_hit_point: Node = (
		active_character.find_child(
			resolved_name,
			true,
			false
		)
	)


	if direct_hit_point is Node3D:

		return (
			direct_hit_point
			as
			Node3D
		)


	if skeleton == null:

		find_skeleton()


	if skeleton == null:

		return null


	var bone_name: String = str(
		HIT_POINT_BONES.get(
			resolved_name,
			""
		)
	)


	if bone_name.is_empty():

		return null


	var bone_index: int = (
		skeleton.find_bone(
			bone_name
		)
	)


	if bone_index == -1:

		return null


	return (
		get_or_create_event_image_bone_attachment(
			bone_index,
			bone_name
		)
	)


# =============================================================
# EVENT IMAGE BONE ATTACHMENT
# =============================================================

func get_or_create_event_image_bone_attachment(
	bone_index: int,
	bone_name: String
) -> Node3D:

	if skeleton == null:

		return null


	var attachment_name: String = (
		"CIGAEventImageBone_"
		+
		bone_name
	)


	var existing: Node = (
		skeleton.get_node_or_null(
			attachment_name
		)
	)


	if existing is BoneAttachment3D:

		return (
			existing
			as
			BoneAttachment3D
		)


	var attachment: BoneAttachment3D = (
		BoneAttachment3D.new()
	)


	attachment.name = (
		attachment_name
	)


	attachment.bone_idx = (
		bone_index
	)


	skeleton.add_child(
		attachment
	)


	return attachment


# =============================================================
# ATTACH EVENT IMAGE
# =============================================================

func _attach_event_image_to_target(
	image: Sprite3D,
	target_node: Node3D
) -> void:

	if image == null:

		return


	if target_node == null:

		return


	var current_parent: Node = (
		image.get_parent()
	)


	if current_parent == target_node:

		return


	if current_parent != null:

		current_parent.remove_child(
			image
		)


	target_node.add_child(
		image
	)


# =============================================================
# REMOVE EVENT IMAGE
# =============================================================

func _remove_event_image_after_duration(
	image: Sprite3D,
	duration: float
) -> void:

	if image == null:

		return


	var safe_duration: float = clampf(
		duration,
		EVENT_IMAGE_MIN_DURATION,
		60.0
	)


	var timer: SceneTreeTimer = (
		get_tree().create_timer(
			safe_duration
		)
	)


	timer.timeout.connect(
		func() -> void:

			if is_instance_valid(
				image
			):

				active_event_image_sprites.erase(
					image
				)

				image.queue_free()
	)


# =============================================================
# PRELOAD EVENT IMAGES
# =============================================================

func preload_event_images() -> void:

	if viewport == null:

		push_warning(
			"[CIGA VIEWPORT] PRELOAD EVENT IMAGES FAILED | VIEWPORT NULL"
		)

		return


	if viewport.workspace == null:

		push_warning(
			"[CIGA VIEWPORT] PRELOAD EVENT IMAGES FAILED | WORKSPACE NULL"
		)

		return


	var directory: String = (
		"user://ciga/assets/images"
	)


	var cache: Dictionary = {}


	var dir: DirAccess = (
		DirAccess.open(
			directory
		)
	)


	if dir == null:

		viewport.workspace.set_meta(
			"ciga_event_image_cache",
			cache
		)

		return


	dir.list_dir_begin()


	while true:

		var file_name: String = (
			dir.get_next()
		)


		if file_name.is_empty():

			break


		if dir.current_is_dir():

			continue


		var extension: String = (
			file_name
			.get_extension()
			.to_lower()
		)


		if extension not in [
			"png",
			"jpg",
			"jpeg",
			"webp",
			"bmp"
		]:

			continue


		var path: String = (
			directory
			+
			"/"
			+
			file_name
		)


		if not FileAccess.file_exists(
			path
		):

			continue


		var image: Image = (
			Image.load_from_file(
				path
			)
		)


		if image == null:

			push_warning(
				"[CIGA VIEWPORT] EVENT IMAGE PRELOAD FAILED | "
				+
				path
			)

			continue


		var texture: ImageTexture = (
			ImageTexture.create_from_image(
				image
			)
		)


		if texture == null:

			push_warning(
				"[CIGA VIEWPORT] EVENT IMAGE TEXTURE CREATE FAILED | "
				+
				path
			)

			continue


		cache[path] = texture


		print(
			"[CIGA VIEWPORT] EVENT IMAGE PRELOADED | ",
			file_name
		)


	dir.list_dir_end()


	viewport.workspace.set_meta(
		"ciga_event_image_cache",
		cache
	)


	print(
		"[CIGA VIEWPORT] EVENT IMAGE PRELOAD COMPLETE | COUNT=",
		cache.size()
	)


# =============================================================
# GET CACHED EVENT IMAGE
# =============================================================

func get_cached_event_image(
	image_path: String
) -> Texture2D:

	if viewport == null:

		return null


	if viewport.workspace == null:

		return null


	var cache_value: Variant = (
		viewport.workspace.get_meta(
			"ciga_event_image_cache",
			{}
		)
	)


	if not cache_value is Dictionary:

		return null


	var cache: Dictionary = (
		cache_value
		as
		Dictionary
	)


	var texture_value: Variant = (
		cache.get(
			image_path,
			null
		)
	)


	if texture_value is Texture2D:

		return (
			texture_value
			as
			Texture2D
		)


	return null


# =============================================================
# LAUNCH OBJECTS
# =============================================================

func launch_objects(
	launches: Array
) -> void:

	if launches.is_empty():

		return


	for launch_value: Variant in launches:

		if not launch_value is Dictionary:

			continue


		var launch_data: Dictionary = (
			launch_value
			as
			Dictionary
		)


		if launch_data.is_empty():

			continue


		var action_type: String = str(
			launch_data.get(
				"action_type",
				"INTERACTION"
			)
		).to_upper().strip_edges()


		if action_type == "DISPLAY_IMAGE":

			display_event_image(
				launch_data
			)

			continue


		if action_type == "DISPLAY_IMAGE_LIVE":

			queue_live_image_action(
				launch_data
			)

			continue


		event_launch_queue.append(
			launch_data.duplicate(
				true
			)
		)


	event_burst_processing = (
		not event_launch_queue.is_empty()
	)


	if event_launch_timer <= 0.0:

		event_launch_timer = 0.0


# =============================================================
# EVENT QUEUE
# =============================================================

func _process_event_launch_queue(
	delta: float
) -> void:

	if event_launch_queue.is_empty():

		event_burst_processing = false

		return


	if not preload_complete:

		return


	event_launch_timer -= delta


	if event_launch_timer > 0.0:

		return


	event_launch_timer = (
		EVENT_LAUNCH_INTERVAL
	)


	event_burst_processing = true


	var launch_data: Dictionary = (
		event_launch_queue.pop_front()
	)


	launch_event_projectile(
		launch_data
	)


# =============================================================
# EVENT PROJECTILE
# =============================================================

func launch_event_projectile(
	launch_data: Dictionary
) -> bool:

	if launch_data.is_empty():

		return false


	var object_value: Variant = (
		launch_data.get(
			"object_data",
			{}
		)
	)


	if not object_value is Dictionary:

		return false


	var object_data: Dictionary = (
		object_value
		as
		Dictionary
	)


	var object_id: String = str(
		object_data.get(
			"id",
			""
		)
	)


	if object_id.is_empty():

		return false


	var target_name: String = (
		target_name_to_hit_point(
			str(
				launch_data.get(
					"target",
					"ChestHitPoint"
				)
			)
		)
	)


	var spawn_name: String = str(
		launch_data.get(
			"spawn",
			"RANDOM"
		)
	)


	var spawn: Marker3D = (
		get_event_spawn_point(
			spawn_name
		)
	)


	if spawn == null:

		return false


	var speed: float = float(
		launch_data.get(
			"speed",
			5.4
		)
	)


	var force: float = float(
		launch_data.get(
			"force",
			1.8
		)
	)


	var scale_value: float = (
		get_current_object_scale(
			object_id
		)
	)


	return launch_object_with_parameters(
		object_id,
		target_name,
		spawn,
		speed,
		force,
		scale_value
	)


func toggle_impact_orientation() -> bool:

	impact_orientation_flipped = (
		not impact_orientation_flipped
	)

	vmc_tracking_flipped = (
		not vmc_tracking_flipped
	)



	# ========================================================
	# RESET TRACKED IMAGES TO THEIR CONFIGURED ROTATION
	# ========================================================

	for sprite in active_event_image_sprites:

		if sprite == null:

			continue


		if not is_instance_valid(
			sprite
		):

			continue


		if not bool(
			sprite.get_meta(
				"ciga_follow_vmc",
				false
			)
		):

			continue


		var base_value: Variant = (
			sprite.get_meta(
				"ciga_base_rotation",
				Quaternion.IDENTITY
			)
		)


		if base_value is Quaternion:

			sprite.quaternion = (
				(base_value as Quaternion)
				.normalized()
			)


	for sprite in active_live_image_sprites:

		if sprite == null:

			continue


		if not is_instance_valid(
			sprite
		):

			continue


		if not bool(
			sprite.get_meta(
				"ciga_live_follow_vmc",
				false
			)
		):

			continue


		var base_value: Variant = (
			sprite.get_meta(
				"ciga_live_base_rotation",
				Quaternion.IDENTITY
			)
		)


		if base_value is Quaternion:

			sprite.quaternion = (
				(base_value as Quaternion)
				.normalized()
			)


	_rebase_vmc_tracking()

	save_profile_settings()

	return impact_orientation_flipped

# =============================================================
# ROTATE AVATAR
# =============================================================

func rotate_avatar_180() -> void:

	if active_character == null:

		refresh_character()


	if active_character == null:

		return


	if interaction_manager != null:

		if interaction_manager.has_method(
			"rotate_avatar_y"
		):

			interaction_manager.rotate_avatar_y(
				PI
			)

		else:

			active_character.rotation.y += PI

	else:

		active_character.rotation.y += PI


# =============================================================
# STREAMER MODE
# =============================================================

func toggle_streamer_mode() -> bool:

	streamer_mode_enabled = (
		not streamer_mode_enabled
	)


	apply_streamer_mode()

	save_profile_settings()


	return streamer_mode_enabled


func apply_streamer_mode() -> void:

	if viewport == null:

		return


	var scene_viewport: SubViewport = (
		viewport.scene_viewport
	)


	var main_loop := (
		Engine.get_main_loop()
	)


	var scene_tree: SceneTree = null


	if (
		main_loop != null
		and
		main_loop is SceneTree
	):

		scene_tree = (
			main_loop
			as
			SceneTree
		)


	if streamer_mode_enabled:

		if scene_viewport != null:

			scene_viewport.transparent_bg = true


		if scene_tree != null:

			scene_tree.root.transparent_bg = true


		DisplayServer.window_set_flag(
			DisplayServer.WINDOW_FLAG_TRANSPARENT,
			true
		)


		set_avatar_visible(
			false
		)


		viewport.set_visual_character_visible(
			false
		)

	else:

		if scene_viewport != null:

			scene_viewport.transparent_bg = false


		if scene_tree != null:

			scene_tree.root.transparent_bg = false


		DisplayServer.window_set_flag(
			DisplayServer.WINDOW_FLAG_TRANSPARENT,
			false
		)


		set_avatar_visible(
			true
		)


		viewport.set_visual_character_visible(
			true
		)


	viewport.apply_streamer_mode_ui(
		streamer_mode_enabled
	)


# =============================================================
# AVATAR VISIBILITY
# =============================================================

func set_avatar_visible(
	visible_state: bool
) -> void:

	if active_character == null:

		return


	_set_node_mesh_visibility(
		active_character,
		visible_state
	)


func _set_node_mesh_visibility(
	node: Node,
	visible_state: bool
) -> void:

	if node == null:

		return


	if node is ThrowableObject:

		return


	if (
		node.get_parent() != null
		and
		node.get_parent() is ThrowableObject
	):

		return


	if node is MeshInstance3D:

		var mesh: MeshInstance3D = (
			node
			as
			MeshInstance3D
		)


		mesh.visible = visible_state


	elif node is CSGShape3D:

		var csg: CSGShape3D = (
			node
			as
			CSGShape3D
		)


		csg.visible = visible_state


	for child: Node in node.get_children():

		_set_node_mesh_visibility(
			child,
			visible_state
		)


# =============================================================
# PROFILE
# =============================================================

func get_active_profile_id() -> String:

	if profile_manager == null:

		return "default"


	var profile: Dictionary = (
		profile_manager.get_active_profile()
	)


	if profile.is_empty():

		return "default"


	var profile_id: String = str(
		profile.get(
			"id",
			"default"
		)
	)


	if profile_id.is_empty():

		return "default"


	return profile_id


func check_profile_change() -> void:

	if profile_manager == null:

		return


	var current_id: String = (
		get_active_profile_id()
	)


	if loaded_profile_id.is_empty():

		loaded_profile_id = current_id

		return


	if current_id == loaded_profile_id:

		return


	load_profile_settings()

	refresh_object_cache()


	if viewport != null:

		viewport.update_camera()


# =============================================================
# LOAD PROFILE
# =============================================================

func load_profile_settings() -> void:

	if profile_manager == null:

		return


	var profile: Dictionary = (
		profile_manager.get_active_profile()
	)


	if profile.is_empty():

		apply_default_profile_settings()

		return


	var profile_id: String = str(
		profile.get(
			"id",
			"default"
		)
	)


	var camera_value: Variant = (
		profile.get(
			"camera",
			{}
		)
	)


	var camera_section: Dictionary = {}


	if camera_value is Dictionary:

		camera_section = (
			camera_value
			as
			Dictionary
		)


	if viewport != null:

		if viewport.camera_x != null:

			viewport.camera_x.set_value_no_signal(
				clampf(
					float(
						camera_section.get(
							"x",
							0.0
						)
					),
					viewport.camera_x.min_value,
					viewport.camera_x.max_value
				)
			)


		if viewport.camera_y != null:

			viewport.camera_y.set_value_no_signal(
				clampf(
					float(
						camera_section.get(
							"y",
							1.4
						)
					),
					viewport.camera_y.min_value,
					viewport.camera_y.max_value
				)
			)


		if viewport.camera_z != null:

			viewport.camera_z.set_value_no_signal(
				clampf(
					float(
						camera_section.get(
							"z",
							4.0
						)
					),
					viewport.camera_z.min_value,
					viewport.camera_z.max_value
				)
			)


		if viewport.camera_fov != null:

			viewport.camera_fov.set_value_no_signal(
				clampf(
					float(
						camera_section.get(
							"fov",
							40.0
						)
					),
					viewport.camera_fov.min_value,
					viewport.camera_fov.max_value
				)
			)


		viewport.camera_flipped = bool(
			camera_section.get(
				"flipped",
				false
			)
		)


	var viewport_value: Variant = (
		profile.get(
			"viewport",
			{}
		)
	)


	var viewport_section: Dictionary = {}


	if viewport_value is Dictionary:

		viewport_section = (
			viewport_value
			as
			Dictionary
		)


	edge_left_top_enabled = bool(
		viewport_section.get(
			"edge_left_top",
			true
		)
	)


	edge_left_bottom_enabled = bool(
		viewport_section.get(
			"edge_left_bottom",
			true
		)
	)


	edge_right_top_enabled = bool(
		viewport_section.get(
			"edge_right_top",
			true
		)
	)


	edge_right_bottom_enabled = bool(
		viewport_section.get(
			"edge_right_bottom",
			true
		)
	)


	edge_top_center_enabled = bool(
		viewport_section.get(
			"edge_top_center",
			true
		)
	)


	edge_bottom_center_enabled = bool(
		viewport_section.get(
			"edge_bottom_center",
			true
		)
	)


	impact_orientation_flipped = bool(
		viewport_section.get(
			"impact_orientation_flipped",
			false
		)
	)


	vmc_tracking_flipped = (
		impact_orientation_flipped
	)


	streamer_mode_enabled = bool(
		viewport_section.get(
			"streamer_mode",
			false
		)
	)


	# =========================================================
	# AVATAR TRANSFORM
	# =========================================================

	var avatar_value: Variant = (
		profile.get(
			"avatar",
			{}
		)
	)


	var avatar_section: Dictionary = {}


	if avatar_value is Dictionary:

		avatar_section = (
			avatar_value
			as
			Dictionary
		)


	var position_value: Variant = (
		avatar_section.get(
			"position",
			{}
		)
	)


	if position_value is Dictionary:

		saved_avatar_position = Vector3(
			float(
				position_value.get(
					"x",
					0.0
				)
			),
			float(
				position_value.get(
					"y",
					0.0
				)
			),
			float(
				position_value.get(
					"z",
					0.0
				)
			)
		)


	var rotation_value: Variant = (
		avatar_section.get(
			"rotation",
			{}
		)
	)


	if rotation_value is Dictionary:

		saved_avatar_rotation = Vector3(
			float(
				rotation_value.get(
					"x",
					0.0
				)
			),
			float(
				rotation_value.get(
					"y",
					0.0
				)
			),
			float(
				rotation_value.get(
					"z",
					0.0
				)
			)
		)


	has_saved_avatar_transform = (
		avatar_section.has("position")
		or
		avatar_section.has("rotation")
	)


	loaded_profile_id = profile_id


	_update_cached_object_scales()


	refresh_viewport_ui()


	if viewport != null:

		viewport.update_camera()


# =============================================================
# APPLY SAVED AVATAR TRANSFORM
# =============================================================

func _apply_saved_avatar_transform() -> void:

	if not has_saved_avatar_transform:

		return


	if active_character == null:

		return


	if not is_instance_valid(
		active_character
	):

		return


	active_character.position = (
		saved_avatar_position
	)


	active_character.rotation = (
		saved_avatar_rotation
	)


	print(
		"[CIGA VIEWPORT] AVATAR TRANSFORM RESTORED | "
		+
		"POSITION="
		+
		str(
			active_character.position
		)
		+
		" | ROTATION="
		+
		str(
			active_character.rotation
		)
	)


# =============================================================
# UPDATE CACHED SCALES
# =============================================================

func _update_cached_object_scales() -> void:

	object_scales.clear()


	if object_manager == null:

		return


	for object_data: Dictionary in object_manager.objects:

		var object_id: String = str(
			object_data.get(
				"id",
				""
			)
		)


		if object_id.is_empty():

			continue


		_update_object_scale(
			object_id,
			object_data
		)


# =============================================================
# DEFAULT PROFILE
# =============================================================

func apply_default_profile_settings() -> void:

	edge_left_top_enabled = true

	edge_left_bottom_enabled = true

	edge_right_top_enabled = true

	edge_right_bottom_enabled = true

	edge_top_center_enabled = true

	edge_bottom_center_enabled = true

	impact_orientation_flipped = false

	vmc_tracking_flipped = false

	streamer_mode_enabled = false


	loaded_profile_id = (
		get_active_profile_id()
	)


	_update_cached_object_scales()


	if viewport != null:

		viewport.camera_flipped = false


		if viewport.camera_x != null:

			viewport.camera_x.set_value_no_signal(
				0.0
			)


		if viewport.camera_y != null:

			viewport.camera_y.set_value_no_signal(
				1.4
			)


		if viewport.camera_z != null:

			viewport.camera_z.set_value_no_signal(
				4.0
			)


		if viewport.camera_fov != null:

			viewport.camera_fov.set_value_no_signal(
				40.0
			)


		viewport.update_camera()

		refresh_viewport_ui()


# =============================================================
# SAVE PROFILE
# =============================================================

func save_profile_settings() -> void:

	if profile_manager == null:

		return


	var profile: Dictionary = (
		profile_manager.get_active_profile()
	)


	if profile.is_empty():

		return


	var camera_value: Variant = (
		profile.get(
			"camera",
			{}
		)
	)


	var camera_section: Dictionary = {}


	if camera_value is Dictionary:

		camera_section = (
			camera_value
			as
			Dictionary
		)


	if viewport != null:

		if viewport.camera_x != null:

			camera_section["x"] = (
				viewport.camera_x.value
			)


		if viewport.camera_y != null:

			camera_section["y"] = (
				viewport.camera_y.value
			)


		if viewport.camera_z != null:

			camera_section["z"] = (
				viewport.camera_z.value
			)


		if viewport.camera_fov != null:

			camera_section["fov"] = (
				viewport.camera_fov.value
			)


		camera_section["flipped"] = (
			viewport.camera_flipped
		)


	profile["camera"] = camera_section


	var viewport_value: Variant = (
		profile.get(
			"viewport",
			{}
		)
	)


	var viewport_section: Dictionary = {}


	if viewport_value is Dictionary:

		viewport_section = (
			viewport_value
			as
			Dictionary
		)


	viewport_section["edge_left_top"] = (
		edge_left_top_enabled
	)


	viewport_section["edge_left_bottom"] = (
		edge_left_bottom_enabled
	)


	viewport_section["edge_right_top"] = (
		edge_right_top_enabled
	)


	viewport_section["edge_right_bottom"] = (
		edge_right_bottom_enabled
	)


	viewport_section["edge_top_center"] = (
		edge_top_center_enabled
	)


	viewport_section["edge_bottom_center"] = (
		edge_bottom_center_enabled
	)


	viewport_section["impact_orientation_flipped"] = (
		impact_orientation_flipped
	)


	viewport_section["streamer_mode"] = (
		streamer_mode_enabled
	)


	if viewport != null:

		if viewport.scene_viewport != null:

			viewport_section["width"] = (
				viewport.scene_viewport.size.x
			)


			viewport_section["height"] = (
				viewport.scene_viewport.size.y
			)


	var avatar_value: Variant = (
		profile.get(
			"avatar",
			{}
		)
	)


	var avatar_section: Dictionary = {}


	if avatar_value is Dictionary:

		avatar_section = (
			avatar_value
			as
			Dictionary
		)


	if (
		active_character != null
		and
		is_instance_valid(
			active_character
		)
	):

		avatar_section["position"] = {
			"x": active_character.position.x,
			"y": active_character.position.y,
			"z": active_character.position.z
		}


		avatar_section["rotation"] = {
			"x": active_character.rotation.x,
			"y": active_character.rotation.y,
			"z": active_character.rotation.z
		}


	profile["avatar"] = avatar_section

	profile["viewport"] = viewport_section


	var saved: bool = (
		profile_manager.save_profiles()
	)


	if not saved:

		return


# =============================================================
# UI
# =============================================================

func refresh_viewport_ui() -> void:

	if viewport == null:

		return


	viewport.refresh_edge_checkboxes()

	viewport.update_runtime_status()


# =============================================================
# STATUS
# =============================================================

func get_status() -> String:

	if viewport == null:

		return "NO VIEWPORT"


	if initializing:

		return "INITIALIZING"


	if active_character == null:

		return "NO CHARACTER"


	if interaction_manager == null:

		return "NO INTERACTION MANAGER"


	if object_names.is_empty():

		return "NO OBJECTS"


	if not preload_complete:

		return "PRELOADING"


	return "READY"


func update_viewport_status() -> void:

	if viewport == null:

		return


	if viewport.runtime_status == null:

		return


	viewport.runtime_status.text = (
		"VIEWPORT RUNTIME: "
		+
		get_status()
	)


# =============================================================
# THROWABLE IMPACT
# =============================================================

func _on_throwable_impact(
	_obj_type: String,
	impact_direction: Vector3,
	force: float,
	hit_point_name: String
) -> void:

	if interaction_manager == null:

		auto_discover_dependencies()


	if interaction_manager == null:

		push_error(
			"[CIGA IMPACT ERROR] Interaction Manager unavailable | "
			+
			"HIT="
			+
			hit_point_name
		)

		return


	var final_direction: Vector3 = (
		impact_direction
	)


	if final_direction.length() <= 0.001:

		final_direction = Vector3(
			0.0,
			0.0,
			1.0
		)


	final_direction = (
		final_direction.normalized()
	)


	if impact_orientation_flipped:

		final_direction.x = (
			-final_direction.x
		)

		final_direction = (
			final_direction.normalized()
		)


	interaction_manager.receive_impact(
		hit_point_name,
		force,
		null,
		final_direction
	)


# =============================================================
# CLEANUP PROJECTILES
# =============================================================

func _cleanup_projectiles() -> void:

	for i in range(
		active_projectiles.size() - 1,
		-1,
		-1
	):

		var projectile: ThrowableObject = (
			active_projectiles[i]
		)


		if projectile == null:

			active_projectiles.remove_at(
				i
			)

			continue


		if not is_instance_valid(
			projectile
		):

			active_projectiles.remove_at(
				i
			)


# =============================================================
# PROJECTILE LIMIT
# =============================================================

func _enforce_projectile_limit() -> void:

	_cleanup_projectiles()


	var max_projectiles: int = (
		get_max_active_projectiles()
	)


	while (
		active_projectiles.size()
		>=
		max_projectiles
	):

		var oldest: ThrowableObject = (
			active_projectiles.pop_front()
		)


		if oldest == null:

			continue


		if is_instance_valid(
			oldest
		):

			oldest.queue_free()


# =============================================================
# CLEAR KEYBOARD
# =============================================================

func _clear_keyboard_state() -> void:

	held_keyboard_keys.clear()

	space_was_pressed = false

	space_throw_timer = 0.0


# =============================================================
# SAVE DISPLAY ON EXIT
# =============================================================

func save_display_settings_on_exit() -> void:

	if viewport == null:

		return


	if viewport.has_method(
		"save_display_settings"
	):

		viewport.save_display_settings()


# =============================================================
# SHUTDOWN
# =============================================================

func _exit_tree() -> void:

	_disconnect_keyboard_input()

	_clear_keyboard_state()

	save_display_settings_on_exit()


	if profile_manager != null:

		save_profile_settings()


	event_launch_queue.clear()

	pending_live_image_actions.clear()


	for sprite: Sprite3D in active_live_image_sprites:

		if sprite == null:

			continue


		if is_instance_valid(
			sprite
		):

			sprite.queue_free()


	active_live_image_sprites.clear()


	for sprite: Sprite3D in active_event_image_sprites:

		if sprite == null:

			continue


		if is_instance_valid(
			sprite
		):

			sprite.queue_free()


	active_event_image_sprites.clear()


	for projectile: ThrowableObject in active_projectiles:

		if projectile == null:

			continue


		if is_instance_valid(
			projectile
		):

			projectile.queue_free()


	active_projectiles.clear()


	object_scales.clear()

	object_names.clear()

	active_character = null

	skeleton = null


# =============================================================
# MAX ACTIVE PROJECTILES
# =============================================================

func get_max_active_projectiles() -> int:

	if settings_runtime != null:

		return clampi(
			settings_runtime.get_max_objects(),
			1,
			500
		)


	if profile_manager != null:

		var settings_value: Variant = (
			profile_manager.get_active_value(
				"settings",
				CIGASettings.KEY_MAX_OBJECTS,
				DEFAULT_MAX_ACTIVE_PROJECTILES
			)
		)


		return clampi(
			int(settings_value),
			1,
			500
		)


	return DEFAULT_MAX_ACTIVE_PROJECTILES


# =============================================================
# OBJECT LIFETIME
# =============================================================

func get_object_lifetime() -> float:

	if settings_runtime != null:

		return clampf(
			settings_runtime.get_object_lifetime(),
			0.1,
			60.0
		)


	if profile_manager != null:

		var value: Variant = (
			profile_manager.get_active_value(
				"settings",
				CIGASettings.KEY_OBJECT_LIFETIME,
				CIGASettings.DEFAULT_OBJECT_LIFETIME
			)
		)


		return clampf(
			float(value),
			0.1,
			60.0
		)


	return CIGASettings.DEFAULT_OBJECT_LIFETIME


# =============================================================
# BOUNCE TIME
# =============================================================

func get_bounce_time() -> float:

	if settings_runtime != null:

		return clampf(
			settings_runtime.get_bounce_time(),
			0.0,
			10.0
		)


	if profile_manager != null:

		var value: Variant = (
			profile_manager.get_active_value(
				"settings",
				CIGASettings.KEY_BOUNCE_TIME,
				CIGASettings.DEFAULT_BOUNCE_TIME
			)
		)


		return clampf(
			float(value),
			0.0,
			10.0
		)


	return CIGASettings.DEFAULT_BOUNCE_TIME


# =============================================================
# OBJECT LIBRARY CHANGED
# =============================================================

func _on_object_library_changed(
	_data: Dictionary = {}
) -> void:

	if object_manager == null:

		return


	if not initialized:

		return


	refresh_object_cache()


# =============================================================
# GET CURRENT OBJECT SCALE
# =============================================================

func get_current_object_scale(
	object_id: String
) -> float:

	if object_id.is_empty():

		return CIGAObjects.DEFAULT_OBJECT_SCALE


	if object_manager == null:

		return CIGAObjects.DEFAULT_OBJECT_SCALE


	var object_data: Dictionary = (
		object_manager.get_object(
			object_id
		)
	)


	if object_data.is_empty():

		return CIGAObjects.DEFAULT_OBJECT_SCALE


	var base_scale: float = (
		CIGAObjects.DEFAULT_OBJECT_SCALE
	)


	if object_manager.has_method(
		"get_object_base_scale"
	):

		base_scale = float(
			object_manager.get_object_base_scale(
				object_id
			)
		)

	else:

		base_scale = float(
			object_data.get(
				"base_scale",
				object_data.get(
					"scale",
					CIGAObjects.DEFAULT_OBJECT_SCALE
				)
			)
		)


	if not is_finite(
		base_scale
	):

		base_scale = (
			CIGAObjects.DEFAULT_OBJECT_SCALE
		)


	base_scale = clampf(
		base_scale,
		CIGAObjects.MIN_OBJECT_SCALE,
		CIGAObjects.MAX_OBJECT_SCALE
	)


	var multiplier: float = (
		CIGAObjects.DEFAULT_SCALE_MULTIPLIER
	)


	if object_manager.has_method(
		"get_object_scale_multiplier"
	):

		multiplier = float(
			object_manager.get_object_scale_multiplier(
				object_id
			)
		)

	else:

		multiplier = float(
			object_data.get(
				"scale_multiplier",
				CIGAObjects.DEFAULT_SCALE_MULTIPLIER
			)
		)


	if not is_finite(
		multiplier
	):

		multiplier = (
			CIGAObjects.DEFAULT_SCALE_MULTIPLIER
		)


	multiplier = clampf(
		multiplier,
		CIGAObjects.MIN_SCALE_MULTIPLIER,
		CIGAObjects.MAX_SCALE_MULTIPLIER
	)


	var final_scale: float = (
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


	final_scale = clampf(
		final_scale,
		CIGAObjects.MIN_OBJECT_SCALE,
		CIGAObjects.MAX_OBJECT_SCALE
	)


	object_scales[object_id] = (
		final_scale
	)


	return final_scale


# =============================================================
# REFRESH CACHE
# =============================================================

func refresh_object_cache() -> void:

	if not is_inside_tree():

		return


	if object_manager == null:

		auto_discover_dependencies()


	if object_manager == null:

		return


	refresh_object_resource_state()

	_update_cached_object_scales()

	refresh_viewport_ui()

	update_viewport_status()


# =============================================================
# EDGE SETTINGS
# =============================================================

func set_edge_enabled(
	edge_name: String,
	enabled: bool
) -> void:

	match edge_name:

		"LEFT_TOP":

			edge_left_top_enabled = enabled


		"LEFT_BOTTOM":

			edge_left_bottom_enabled = enabled


		"RIGHT_TOP":

			edge_right_top_enabled = enabled


		"RIGHT_BOTTOM":

			edge_right_bottom_enabled = enabled


		"TOP_CENTER":

			edge_top_center_enabled = enabled


		"BOTTOM_CENTER":

			edge_bottom_center_enabled = enabled


		_:

			return


	save_profile_settings()


	if viewport != null:

		viewport.refresh_edge_checkboxes()


# =============================================================
# EDGE CHECK
# =============================================================

func is_edge_enabled(
	edge_name: String
) -> bool:

	match edge_name:

		"LEFT_TOP":

			return edge_left_top_enabled


		"LEFT_BOTTOM":

			return edge_left_bottom_enabled


		"RIGHT_TOP":

			return edge_right_top_enabled


		"RIGHT_BOTTOM":

			return edge_right_bottom_enabled


		"TOP_CENTER":

			return edge_top_center_enabled


		"BOTTOM_CENTER":

			return edge_bottom_center_enabled


	return false


# =============================================================
# EDGE COUNT
# =============================================================

func get_enabled_edge_count() -> int:

	var count: int = 0


	if edge_left_top_enabled:

		count += 1


	if edge_left_bottom_enabled:

		count += 1


	if edge_right_top_enabled:

		count += 1


	if edge_right_bottom_enabled:

		count += 1


	if edge_top_center_enabled:

		count += 1


	if edge_bottom_center_enabled:

		count += 1


	return count


# =============================================================
# RANDOM SPAWN
# =============================================================

func get_spawn_point() -> Marker3D:

	var valid: Array[Marker3D] = []


	if (
		edge_left_top_enabled
		and
		spawn_left_top != null
	):

		valid.append(
			spawn_left_top
		)


	if (
		edge_left_bottom_enabled
		and
		spawn_left_bottom != null
	):

		valid.append(
			spawn_left_bottom
		)


	if (
		edge_right_top_enabled
		and
		spawn_right_top != null
	):

		valid.append(
			spawn_right_top
		)


	if (
		edge_right_bottom_enabled
		and
		spawn_right_bottom != null
	):

		valid.append(
			spawn_right_bottom
		)


	if (
		edge_top_center_enabled
		and
		spawn_top_center != null
	):

		valid.append(
			spawn_top_center
		)


	if (
		edge_bottom_center_enabled
		and
		spawn_bottom_center != null
	):

		valid.append(
			spawn_bottom_center
		)


	if valid.is_empty():

		return spawn_center


	return valid.pick_random()


# =============================================================
# EVENT SPAWN RESOLUTION
# =============================================================

func get_event_spawn_point(
	spawn_name: String
) -> Marker3D:

	var normalized: String = (
		spawn_name
		.strip_edges()
		.to_upper()
		.replace(
			"_",
			""
		)
		.replace(
			" ",
			""
		)
	)


	if (
		normalized == "RANDOM"
		or
		normalized == "RANDOMSPAWN"
		or
		normalized == "RANDOMFROMALL"
	):

		return get_spawn_point()


	if (
		normalized == "CENTER"
		or
		normalized == "OBJECTSPAWNCENTER"
		or
		normalized == "SPAWNCENTER"
	):

		return spawn_center


	if (
		normalized == "LEFT"
		or
		normalized == "OBJECTSPAWNLEFT"
		or
		normalized == "SPAWNLEFT"
	):

		return spawn_left_top


	if (
		normalized == "RIGHT"
		or
		normalized == "OBJECTSPAWNRIGHT"
		or
		normalized == "SPAWNRIGHT"
	):

		return spawn_right_top


	if (
		normalized == "TOP"
		or
		normalized == "NORTH"
		or
		normalized == "OBJECTSPAWNTOP"
		or
		normalized == "SPAWNTOP"
	):

		return spawn_top_center


	if (
		normalized == "BOTTOM"
		or
		normalized == "SOUTH"
		or
		normalized == "OBJECTSPAWNBOTTOM"
		or
		normalized == "SPAWNBOTTOM"
	):

		return spawn_bottom_center


	if normalized == "LEFTTOP":

		return spawn_left_top


	if normalized == "LEFTBOTTOM":

		return spawn_left_bottom


	if normalized == "RIGHTTOP":

		return spawn_right_top


	if normalized == "RIGHTBOTTOM":

		return spawn_right_bottom


	if normalized == "TOPCENTER":

		return spawn_top_center


	if normalized == "BOTTOMCENTER":

		return spawn_bottom_center


	return get_spawn_point()


# =============================================================
# TARGET NORMALIZATION
# =============================================================

func target_name_to_hit_point(
	target_name: String
) -> String:

	var normalized: String = (
		target_name
		.strip_edges()
		.to_upper()
		.replace(
			"_",
			""
		)
		.replace(
			" ",
			""
		)
	)


	match normalized:

		"HEAD", "HEADHITPOINT":

			return "HeadHitPoint"


		"CHEST", "CHESTHITPOINT":

			return "ChestHitPoint"


		"LEFTSHOULDER", "LEFTSHOULDERHITPOINT":

			return "LeftShoulderHitPoint"


		"RIGHTSHOULDER", "RIGHTSHOULDERHITPOINT":

			return "RightShoulderHitPoint"


		"LEFTARM", "LEFTARMHITPOINT":

			return "LeftArmHitPoint"


		"RIGHTARM", "RIGHTARMHITPOINT":

			return "RightArmHitPoint"


		"LEFTLEG", "LEFTLEGHITPOINT":

			return "LeftLegHitPoint"


		"RIGHTLEG", "RIGHTLEGHITPOINT":

			return "RightLegHitPoint"


		_:

			return "ChestHitPoint"


# =============================================================
# TARGET WORLD POSITION
# =============================================================

func get_target_world_position(
	hit_point_name: String
) -> Vector3:

	if active_character == null:

		return Vector3.INF


	var resolved_name: String = (
		target_name_to_hit_point(
			hit_point_name
		)
	)


	var direct_hit_point: Node = (
		active_character.find_child(
			resolved_name,
			true,
			false
		)
	)


	if direct_hit_point is Node3D:

		return (
			(direct_hit_point as Node3D)
			.global_position
		)


	if skeleton == null:

		find_skeleton()


	if skeleton == null:

		return Vector3.INF


	var bone_name: String = str(
		HIT_POINT_BONES.get(
			resolved_name,
			""
		)
	)


	if bone_name.is_empty():

		return Vector3.INF


	var bone_index: int = (
		skeleton.find_bone(
			bone_name
		)
	)


	if bone_index == -1:

		return Vector3.INF


	var bone_pose: Transform3D = (
		skeleton.get_bone_global_pose(
			bone_index
		)
	)


	var world_pose: Transform3D = (
		skeleton.global_transform
		*
		bone_pose
	)


	return world_pose.origin


# =============================================================
# SPAWN CREATION
# =============================================================

func create_spawn_points() -> void:

	if viewport == null:

		return


	if viewport.workspace == null:

		return


	_delete_old_spawns()


	spawn_left_top = _create_spawn(
		"SpawnLeftTop"
	)


	spawn_left_bottom = _create_spawn(
		"SpawnLeftBottom"
	)


	spawn_right_top = _create_spawn(
		"SpawnRightTop"
	)


	spawn_right_bottom = _create_spawn(
		"SpawnRightBottom"
	)


	spawn_top_center = _create_spawn(
		"SpawnTopCenter"
	)


	spawn_bottom_center = _create_spawn(
		"SpawnBottomCenter"
	)


	spawn_center = _create_spawn(
		"SpawnCenter"
	)


	viewport.workspace.add_child(
		spawn_left_top
	)


	viewport.workspace.add_child(
		spawn_left_bottom
	)


	viewport.workspace.add_child(
		spawn_right_top
	)


	viewport.workspace.add_child(
		spawn_right_bottom
	)


	viewport.workspace.add_child(
		spawn_top_center
	)


	viewport.workspace.add_child(
		spawn_bottom_center
	)


	viewport.workspace.add_child(
		spawn_center
	)


	update_spawn_points()


func _create_spawn(
	spawn_name: String
) -> Marker3D:

	var marker: Marker3D = Marker3D.new()

	marker.name = spawn_name

	return marker


func _delete_old_spawns() -> void:

	if viewport == null:

		return


	if viewport.workspace == null:

		return


	for child: Node in viewport.workspace.get_children():

		if child is Marker3D:

			if child.name.begins_with(
				"Spawn"
			):

				child.queue_free()


# =============================================================
# UPDATE SPAWN POINTS
# =============================================================

func update_spawn_points() -> void:

	if viewport == null:

		return


	if viewport.camera == null:

		return


	if viewport.scene_viewport == null:

		return


	if spawn_left_top == null:

		return


	var camera: Camera3D = (
		viewport.camera
	)


	var viewport_size: Vector2i = (
		viewport.scene_viewport.size
	)


	if viewport_size.x <= 0:

		return


	if viewport_size.y <= 0:

		return


	var spawn_depth: float = 3.0


	if active_character != null:

		var camera_to_avatar: float = (
			camera.global_position.distance_to(
				active_character.global_position
			)
		)


		spawn_depth = (
			camera_to_avatar
			-
			SPAWN_FRONT_OFFSET
		)


	spawn_depth = maxf(
		spawn_depth,
		0.1
	)


	var margin: float = (
		SPAWN_MARGIN_PIXELS
	)


	var left_x: float = -margin

	var right_x: float = (
		float(viewport_size.x)
		+
		margin
	)


	var top_y: float = -margin

	var bottom_y: float = (
		float(viewport_size.y)
		+
		margin
	)


	var center_x: float = (
		float(viewport_size.x)
		*
		0.5
	)


	var center_y: float = (
		float(viewport_size.y)
		*
		0.5
	)


	spawn_left_top.global_position = (
		camera.project_position(
			Vector2(
				left_x,
				top_y
			),
			spawn_depth
		)
	)


	spawn_left_bottom.global_position = (
		camera.project_position(
			Vector2(
				left_x,
				bottom_y
			),
			spawn_depth
		)
	)


	spawn_right_top.global_position = (
		camera.project_position(
			Vector2(
				right_x,
				top_y
			),
			spawn_depth
		)
	)


	spawn_right_bottom.global_position = (
		camera.project_position(
			Vector2(
				right_x,
				bottom_y
			),
			spawn_depth
		)
	)


	spawn_top_center.global_position = (
		camera.project_position(
			Vector2(
				center_x,
				top_y
			),
			spawn_depth
		)
	)


	spawn_bottom_center.global_position = (
		camera.project_position(
			Vector2(
				center_x,
				bottom_y
			),
			spawn_depth
		)
	)


	spawn_center.global_position = (
		camera.project_position(
			Vector2(
				center_x,
				center_y
			),
			spawn_depth
		)
	)


# =============================================================
# PROCESS
# =============================================================

func _process(
	delta: float
) -> void:

	update_spawn_points()

	_update_event_image_vmc_tracking()

	_cleanup_projectiles()

	_process_keyboard(
		delta
	)

	_process_space_test_throw(
		delta
	)

	_process_event_launch_queue(
		delta
	)


	if not initialized:

		return


	profile_check_timer += delta


	if profile_check_timer >= PROFILE_CHECK_INTERVAL:

		profile_check_timer = 0.0

		check_profile_change()


# =============================================================
# PROCESS KEYBOARD
# =============================================================

func _process_keyboard(
	_delta: float
) -> void:

	if viewport == null:

		_clear_keyboard_state()

		return


	if viewport.root == null:

		_clear_keyboard_state()

		return


	if not viewport.root.visible:

		_clear_keyboard_state()

		return


	var window: Window = (
		viewport.root.get_window()
	)


	if window == null:

		_clear_keyboard_state()

		return


	if not window.has_focus():

		_clear_keyboard_state()


		if viewport.ui_camera_active:

			viewport.ui_camera_active = false

			viewport._update_ui_visibility_state()


		return


	if streamer_mode_enabled:

		if viewport.ui_camera_active:

			viewport.ui_camera_active = false

			viewport._update_ui_visibility_state()


		return


	var camera_active: bool = false


	if _is_key_held(
		KEY_LEFT
	):

		_move_camera_direct(
			1.0,
			0.0,
			_delta
	)

		camera_active = true


	if _is_key_held(
		KEY_RIGHT
	):

		_move_camera_direct(
			-1.0,
			0.0,
			_delta
	)

		camera_active = true


	if _is_key_held(
		KEY_UP
	):

		_move_camera_direct(
			0.0,
			-1.0,
			_delta
	)

		camera_active = true


	if _is_key_held(
		KEY_DOWN
	):

		_move_camera_direct(
			0.0,
			1.0,
			_delta
	)

		camera_active = true


	if (
		_is_key_held(KEY_EQUAL)
		or
		_is_key_held(KEY_KP_ADD)
		or
		_is_key_held(KEY_PAGEUP)
	):

		viewport.camera_zoom(
			-1.0,
			_delta * 6.0
		)

		camera_active = true


	if (
		_is_key_held(KEY_MINUS)
		or
		_is_key_held(KEY_KP_SUBTRACT)
		or
		_is_key_held(KEY_PAGEDOWN)
	):

		viewport.camera_zoom(
			1.0,
			_delta * 6.0
		)

		camera_active = true


	if camera_active:

		viewport._mark_camera_interaction()

	else:

		if viewport.ui_camera_active:

			viewport.ui_camera_active = false

			viewport._update_ui_visibility_state()


# =============================================================
# DIRECT CAMERA MOVEMENT
# =============================================================

func _move_camera_direct(
	x_direction: float,
	y_direction: float,
	delta: float
) -> void:

	if viewport == null:

		return


	if viewport.camera == null:

		return


	var step: float = (
		CAMERA_MOVE_SPEED
		*
		delta
		*
		6.0
	)


	var new_x: float = (
		viewport.camera.position.x
		+
		x_direction * step
	)


	var new_y: float = (
		viewport.camera.position.y
		+
		y_direction * step
	)


	new_x = clampf(
		new_x,
		-20.0,
		20.0
	)


	new_y = clampf(
		new_y,
		-20.0,
		20.0
	)


	viewport.camera.position.x = new_x

	viewport.camera.position.y = new_y


	if viewport.camera_x != null:

		viewport.camera_x.set_value_no_signal(
			new_x
		)


	if viewport.camera_y != null:

		viewport.camera_y.set_value_no_signal(
			new_y
		)


	update_spawn_points()


# =============================================================
# IS KEY HELD
# =============================================================

func _is_key_held(
	key_code: int
) -> bool:

	return bool(
		held_keyboard_keys.get(
			key_code,
			false
		)
	)


# =============================================================
# SPACE
# =============================================================

func _process_space_test_throw(
	delta: float
) -> void:

	if viewport == null:

		space_was_pressed = false

		space_throw_timer = 0.0

		return


	if viewport.root == null:

		space_was_pressed = false

		space_throw_timer = 0.0

		return


	if not viewport.root.visible:

		space_was_pressed = false

		space_throw_timer = 0.0

		return


	var window: Window = (
		viewport.root.get_window()
	)


	if window == null:

		space_was_pressed = false

		space_throw_timer = 0.0

		return


	if not window.has_focus():

		space_was_pressed = false

		space_throw_timer = 0.0

		return


	var pressed: bool = (
		_is_key_held(
			KEY_SPACE
		)
	)


	if pressed and not space_was_pressed:

		space_throw_timer = 0.0

		launch_test_object()


	elif pressed:

		space_throw_timer += delta


		if space_throw_timer >= SPACE_THROW_INTERVAL:

			space_throw_timer = 0.0

			launch_test_object()


	else:

		space_throw_timer = 0.0


	space_was_pressed = pressed


# =============================================================
# PHYSICS PROCESS
# =============================================================

func _physics_process(
	_delta: float
) -> void:

	update_spawn_points()
