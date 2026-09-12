class_name CIGAVMCRuntime
extends Node


# ============================================================
# CIGA VMC / OUTPUT RUNTIME
# Godot 4.7.2
#
# OUTPUT ARCHITECTURE
#
#                         CIGA Character
#                              |
#                 +------------+------------+
#                 |                         |
#          Imported 3D                  Native 3D
#         VRM / GLB / GLTF          CIGACalibrationAvatar
#                 |                         |
#             Skeleton3D                HitPoints
#                 |                         |
#                 +------------+------------+
#                              |
#                         OUTPUT RUNTIME
#                              |
#                 +------------+------------+
#                 |                         |
#             3D OUTPUT                  2D OUTPUT
#              VMC/OSC                 Future bridge
#             VSeeFace             VTube Studio/etc.
#
#
# VMC SENDER
#
# CIGA
#   |
#   | UDP / VMC
#   v
# VSeeFace / Warudo / other VMC receivers
#
#
# IMPORTANT
#
# - Sender port is configurable.
# - Default sender port remains 39539.
# - Receiver can later use another independent port.
# - The sender does not reserve the future receiver port.
#
# ============================================================


# ============================================================
# SIGNALS
# ============================================================

signal connection_status_changed(
	status: String,
	message: String
)

signal vmc_log(
	level: String,
	message: String
)

signal output_frame_ready(
	output_type: String,
	frame_data: Dictionary
)

signal output_target_changed(
	output_type: String
)


# ============================================================
# OUTPUT TYPES
# ============================================================

const OUTPUT_NONE: String = "NONE"

const OUTPUT_3D_VMC: String = "VMC_3D"

const OUTPUT_2D: String = "2D"


var output_mode: String = OUTPUT_3D_VMC


# ============================================================
# VMC CONFIG
# ============================================================

const DEFAULT_VMC_HOST: String = "127.0.0.1"

const DEFAULT_VMC_PORT: int = 39539

const MIN_VMC_PORT: int = 1

const MAX_VMC_PORT: int = 65535

const VMC_FPS: float = 60.0

const VMC_INTERVAL: float = (
	1.0
	/
	VMC_FPS
)

const VMC_PROCESS_PRIORITY: int = -10000


var vmc_host: String = DEFAULT_VMC_HOST

var vmc_port: int = DEFAULT_VMC_PORT

# ============================================================
# VMC RECEIVER CONFIG
# ============================================================

const DEFAULT_VMC_RECEIVER_BIND_HOST: String = "127.0.0.1"

const DEFAULT_VMC_RECEIVER_PORT: int = 39541

var vmc_receiver_bind_host: String = (
	DEFAULT_VMC_RECEIVER_BIND_HOST
)

var vmc_receiver_port: int = (
	DEFAULT_VMC_RECEIVER_PORT
)

# ============================================================
# 2D OUTPUT CONFIG
# ============================================================

const DEFAULT_2D_PARAMETER_VALUES: Dictionary = {

	"FaceEyeLeft":
		1.0,

	"FaceEyeRight":
		1.0,

	"FaceMouthOpen":
		0.0,

	"HeadYaw":
		0.0,

	"HeadPitch":
		0.0,

	"HeadRoll":
		0.0,

	"BodyYaw":
		0.0,

	"BodyPitch":
		0.0,

	"BodyRoll":
		0.0,

	"LeftArm":
		0.0,

	"RightArm":
		0.0,

	"CIGARootX":
		0.0
}


var output_2d_parameters: Dictionary = (
	DEFAULT_2D_PARAMETER_VALUES.duplicate(
		true
	)
)


# ============================================================
# 2D BODY SAFETY LIMITS
# ============================================================

const BODY_2D_MAX_X: float = 1.20

const BODY_2D_MAX_Y: float = 1.50

const BODY_2D_MAX_Z: float = 1.50


# ============================================================
# 2D ROOT SAFETY LIMIT
# ============================================================

const ROOT_2D_OUTPUT_MIN: float = -1.0

const ROOT_2D_OUTPUT_MAX: float = 1.0


# ============================================================
# 2D IMPACT MEMORY
# ============================================================

const IMPACT_OUTPUT_MEMORY_MS: int = 350


var last_2d_impact_hit_point: String = ""

var last_2d_impact_time_ms: int = 0


# ============================================================
# VMC BONE MAP
# ============================================================

const VMC_BONE_MAP: Dictionary = {

	"Hips":
		"J_Bip_C_Hips",

	"Spine":
		"J_Bip_C_Spine",

	"Chest":
		"J_Bip_C_Chest",

	"UpperChest":
		"J_Bip_C_UpperChest",

	"Neck":
		"J_Bip_C_Neck",

	"Head":
		"J_Bip_C_Head",

	"LeftShoulder":
		"J_Bip_L_Shoulder",

	"LeftUpperArm":
		"J_Bip_L_UpperArm",

	"LeftLowerArm":
		"J_Bip_L_LowerArm",

	"LeftHand":
		"J_Bip_L_Hand",

	"RightShoulder":
		"J_Bip_R_Shoulder",

	"RightUpperArm":
		"J_Bip_R_UpperArm",

	"RightLowerArm":
		"J_Bip_R_LowerArm",

	"RightHand":
		"J_Bip_R_Hand",

	"LeftUpperLeg":
		"J_Bip_L_UpperLeg",

	"LeftLowerLeg":
		"J_Bip_L_LowerLeg",

	"LeftFoot":
		"J_Bip_L_Foot",

	"RightUpperLeg":
		"J_Bip_R_UpperLeg",

	"RightLowerLeg":
		"J_Bip_R_LowerLeg",

	"RightFoot":
		"J_Bip_R_Foot"
}


# ============================================================
# UDP
# ============================================================

var udp: PacketPeerUDP = PacketPeerUDP.new()


var connected: bool = false

var enabled: bool = true

# ============================================================
# VMC RECEIVER UDP
# ============================================================

var vmc_receiver_udp: PacketPeerUDP = (
	PacketPeerUDP.new()
)

var vmc_receiver_connected: bool = false
# ============================================================
# RECEIVED TRACKING STATE
# ============================================================

var received_vmc_root_rotation: Quaternion = (
	Quaternion.IDENTITY
)

var received_vmc_hips_rotation: Quaternion = (
	Quaternion.IDENTITY
)

var received_vmc_spine_rotation: Quaternion = (
	Quaternion.IDENTITY
)

var received_vmc_chest_rotation: Quaternion = (
	Quaternion.IDENTITY
)

var received_vmc_upper_chest_rotation: Quaternion = (
	Quaternion.IDENTITY
)

var received_vmc_neck_rotation: Quaternion = (
	Quaternion.IDENTITY
)

var received_vmc_head_rotation: Quaternion = (
	Quaternion.IDENTITY
)


var received_vmc_root_position: Vector3 = (
	Vector3.ZERO
)

var received_vmc_tracking_valid: bool = false

var received_vmc_last_packet_time_ms: int = 0


# ============================================================
# STATE
# ============================================================

var send_timer: float = 0.0

var frame_count: int = 0

var packet_count: int = 0

var bones_sent_last_frame: int = 0

var last_send_error: String = ""

var last_send_timestamp: float = 0.0


# ============================================================
# CHARACTER STATE
# ============================================================

var character_runtime: CIGACharacterRuntime = null

var interaction_manager: CIGAinteractionManager = null

var character: Node3D = null

var skeleton: Skeleton3D = null

var native_character: CIGACalibrationAvatar = null

var is_native_character: bool = false

var native_output_logged: bool = false


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	process_priority = (
		VMC_PROCESS_PRIORITY
	)


	log_info(
		"VMC/output runtime initialized."
	)


	# ========================================================
	# IMPORTANT
	#
	# VMC DOES NOT CONNECT AUTOMATICALLY.
	#
	# Connection is controlled by CIGAOutputUI.
	#
	# The user must explicitly press:
	#
	#     CONNECT VMC OUTPUT
	#
	# ========================================================

	connected = false

	send_timer = 0.0
# ============================================================
# VMC HOST
# ============================================================

func set_vmc_host(
	host: String
) -> bool:

	host = host.strip_edges()


	if host.is_empty():

		log_error(
			"INVALID VMC HOST | HOST IS EMPTY."
		)

		return false


	if vmc_host == host:

		return true


	var was_connected: bool = connected


	if was_connected:

		disconnect_vmc()


	vmc_host = host


	log_info(
		"VMC HOST | "
		+
		vmc_host
	)


	if was_connected:

		return connect_vmc()


	return true


func get_vmc_host() -> String:

	return vmc_host


# ============================================================
# VMC PORT
# ============================================================

func set_vmc_port(
	port: int
) -> bool:

	port = clampi(
		port,
		MIN_VMC_PORT,
		MAX_VMC_PORT
	)


	if port < MIN_VMC_PORT:

		log_error(
			"INVALID VMC PORT."
		)

		return false


	if port > MAX_VMC_PORT:

		log_error(
			"INVALID VMC PORT."
		)

		return false


	if vmc_port == port:

		return true


	var was_connected: bool = connected


	if was_connected:

		disconnect_vmc()


	vmc_port = port


	print(
		"[CIGA VMC] SENDER PORT SET | ",
		vmc_port
	)


	log_info(
		"VMC SENDER PORT | "
		+
		str(
			vmc_port
		)
	)


	if was_connected:

		return connect_vmc()


	return true


func get_vmc_port() -> int:

	return vmc_port


# ============================================================
# VMC ENDPOINT
# ============================================================

func set_vmc_endpoint(
	host: String,
	port: int
) -> bool:

	host = host.strip_edges()


	if host.is_empty():

		log_error(
			"INVALID VMC HOST | HOST IS EMPTY."
		)

		return false


	if port < MIN_VMC_PORT:

		log_error(
			"INVALID VMC PORT."
		)

		return false


	if port > MAX_VMC_PORT:

		log_error(
			"INVALID VMC PORT."
		)

		return false


	var was_connected: bool = connected


	if was_connected:

		disconnect_vmc()


	vmc_host = host

	vmc_port = port


	log_info(
		"VMC ENDPOINT | "
		+
		vmc_host
		+
		":"
		+
		str(
			vmc_port
		)
	)


	if was_connected:

		return connect_vmc()


	return true


# ============================================================
# CONNECT
# ============================================================

func connect_vmc() -> bool:

	if connected:

		return true


	udp = PacketPeerUDP.new()


	var result: Error = (
		udp.connect_to_host(
			vmc_host,
			vmc_port
		)
	)


	if result != OK:

		connected = false

		last_send_error = (
			error_string(
				result
			)
		)


		log_error(
			"UDP CONNECTION FAILED | "
			+
			last_send_error
		)


		connection_status_changed.emit(
			"ERROR",
			last_send_error
		)


		return false


	connected = true

	send_timer = 0.0


	print(
		"[CIGA VMC] UDP SOCKET READY | ",
		vmc_host,
		":",
		vmc_port
	)


	connection_status_changed.emit(
		"CONNECTED",
		"VMC UDP output ready."
	)


	send_ok()


	return true

# ============================================================
# CONNECT VMC RECEIVER
# ============================================================

func connect_vmc_receiver() -> bool:

	if vmc_receiver_connected:

		return true


	if vmc_receiver_udp != null:

		vmc_receiver_udp.close()


	vmc_receiver_udp = PacketPeerUDP.new()


	var result: Error = (
		vmc_receiver_udp.bind(
			vmc_receiver_port,
			vmc_receiver_bind_host
		)
	)


	if result != OK:

		vmc_receiver_connected = false


		log_error(
			"VMC RECEIVER BIND FAILED | "
			+
			vmc_receiver_bind_host
			+
			":"
			+
			str(
				vmc_receiver_port
			)
			+
			" | "
			+
			error_string(
				result
			)
		)


		return false


	vmc_receiver_connected = true


	print(
		"[CIGA VMC] RECEIVER READY | ",
		vmc_receiver_bind_host,
		":",
		vmc_receiver_port
	)


	log_info(
		"VMC receiver ready."
	)


	return true
# ============================================================
# DISCONNECT VMC RECEIVER
# ============================================================

func disconnect_vmc_receiver() -> void:

	if not vmc_receiver_connected:

		return


	vmc_receiver_connected = false


	if vmc_receiver_udp != null:

		vmc_receiver_udp.close()


	print(
		"[CIGA VMC] RECEIVER DISCONNECTED"
	)


	log_info(
		"VMC receiver disconnected."
	)
# ============================================================
# VMC RECEIVER PORT
# ============================================================

func set_vmc_receiver_port(
	port: int
) -> bool:

	if (
		port < MIN_VMC_PORT
		or
		port > MAX_VMC_PORT
	):

		log_error(
			"INVALID VMC RECEIVER PORT."
		)

		return false


	var was_connected: bool = (
		vmc_receiver_connected
	)


	if was_connected:

		disconnect_vmc_receiver()


	vmc_receiver_port = port


	print(
		"[CIGA VMC] RECEIVER PORT SET | ",
		vmc_receiver_port
	)


	if was_connected:

		return connect_vmc_receiver()


	return true
# ============================================================
# GET VMC RECEIVER PORT
# ============================================================

func get_vmc_receiver_port() -> int:

	return vmc_receiver_port
# ============================================================
# VMC RECEIVER BIND HOST
# ============================================================

func set_vmc_receiver_bind_host(
	host: String
) -> bool:

	host = host.strip_edges()


	if host.is_empty():

		return false


	var was_connected: bool = (
		vmc_receiver_connected
	)


	if was_connected:

		disconnect_vmc_receiver()


	vmc_receiver_bind_host = host


	if was_connected:

		return connect_vmc_receiver()


	return true
# ============================================================
# PROCESS VMC RECEIVER PACKETS
# ============================================================

func _process_vmc_receiver() -> void:

	if not vmc_receiver_connected:

		return


	while (
		vmc_receiver_udp.get_available_packet_count()
		>
		0
	):

		var packet: PackedByteArray = (
			vmc_receiver_udp.get_packet()
		)


		if packet.is_empty():

			continue


		_parse_vmc_osc_packet(
			packet,
			0,
			packet.size()
		)
# ============================================================
# PARSE VMC OSC PACKET
# ============================================================

func _parse_vmc_osc_packet(
	packet: PackedByteArray,
	offset: int,
	packet_end: int
) -> void:

	if offset >= packet_end:

		return


	var address_data: Dictionary = (
		_read_osc_string(
			packet,
			offset,
			packet_end
		)
	)


	if address_data.is_empty():

		return


	var address: String = str(
		address_data.get(
			"value",
			""
		)
	)


	var next_offset: int = int(
		address_data.get(
			"next_offset",
			offset
		)
	)


	if address == "#bundle":

		if next_offset + 8 > packet_end:

			return


		# ====================================================
		# OSC BUNDLE TIMETAG
		# ====================================================

		next_offset += 8


		while next_offset + 4 <= packet_end:

			var element_size: int = (
				_read_osc_int32(
					packet,
					next_offset
				)
			)


			next_offset += 4


			if element_size <= 0:

				break


			if (
				next_offset + element_size
				>
				packet_end
			):

				break


			_parse_vmc_osc_packet(
				packet,
				next_offset,
				next_offset + element_size
			)


			next_offset += element_size


		return


	# ========================================================
	# NORMAL OSC MESSAGE
	# ========================================================

	var type_data: Dictionary = (
		_read_osc_string(
			packet,
			next_offset,
			packet_end
		)
	)


	if type_data.is_empty():

		return


	var type_tags: String = str(
		type_data.get(
			"value",
			""
		)
	)


	next_offset = int(
		type_data.get(
			"next_offset",
			next_offset
		)
	)


	if type_tags.is_empty():

		return


	if not type_tags.begins_with(","):

		return


	var arguments: Array = []


	for i in range(
		1,
		type_tags.length()
	):

		var type_tag: String = (
			type_tags[i]
		)


		var argument_data: Dictionary = (
			_read_osc_argument(
				packet,
				next_offset,
				packet_end,
				type_tag
			)
		)


		if argument_data.is_empty():

			return


		arguments.append(
			argument_data.get(
				"value"
			)
		)


		next_offset = int(
			argument_data.get(
				"next_offset",
				next_offset
			)
		)


	# ========================================================
	# VMC MESSAGE
	# ========================================================

	_handle_vmc_message(
		address,
		arguments
	)
# ============================================================
# READ OSC STRING
# ============================================================

func _read_osc_string(
	packet: PackedByteArray,
	offset: int,
	packet_end: int
) -> Dictionary:

	if offset < 0:

		return {}


	if offset >= packet_end:

		return {}


	var string_end: int = offset


	while string_end < packet_end:

		if packet[string_end] == 0:

			break


		string_end += 1


	if string_end >= packet_end:

		return {}


	var string_bytes: PackedByteArray = (
		packet.slice(
			offset,
			string_end
		)
	)


	var value: String = (
		string_bytes.get_string_from_utf8()
	)


	var next_offset: int = (
		string_end + 1
	)


	while (
		next_offset < packet_end
		and
		next_offset % 4 != 0
	):

		next_offset += 1


	return {

		"value":
			value,

		"next_offset":
			next_offset
	}
# ============================================================
# READ OSC ARGUMENT
# ============================================================

func _read_osc_argument(
	packet: PackedByteArray,
	offset: int,
	packet_end: int,
	type_tag: String
) -> Dictionary:

	match type_tag:

		"s":

			return _read_osc_string(
				packet,
				offset,
				packet_end
			)


		"f":

			if offset + 4 > packet_end:

				return {}


			var float_buffer := (
				StreamPeerBuffer.new()
			)


			float_buffer.big_endian = true


			float_buffer.data_array = (
				packet.slice(
					offset,
					offset + 4
				)
			)


			var value: float = (
				float_buffer.get_float()
			)


			return {

				"value":
					value,

				"next_offset":
					offset + 4
			}


		"i":

			if offset + 4 > packet_end:

				return {}


			var int_buffer := (
				StreamPeerBuffer.new()
			)


			int_buffer.big_endian = true


			int_buffer.data_array = (
				packet.slice(
					offset,
					offset + 4
				)
			)


			var int_value: int = (
				int_buffer.get_32()
			)


			return {

				"value":
					int_value,

				"next_offset":
					offset + 4
			}


		"b":

			if offset + 4 > packet_end:

				return {}


			var blob_buffer := (
				StreamPeerBuffer.new()
			)


			blob_buffer.big_endian = true


			blob_buffer.data_array = (
				packet.slice(
					offset,
					offset + 4
				)
			)


			var blob_size: int = (
				blob_buffer.get_32()
			)


			if blob_size < 0:

				return {}


			var blob_start: int = (
				offset + 4
			)


			var blob_end: int = (
				blob_start + blob_size
			)


			if blob_end > packet_end:

				return {}


			var padded_end: int = blob_end


			while (
				padded_end < packet_end
				and
				padded_end % 4 != 0
			):

				padded_end += 1


			return {

				"value":
					packet.slice(
						blob_start,
						blob_end
					),

				"next_offset":
					padded_end
			}


		"t":

			if offset + 8 > packet_end:

				return {}


			return {

				"value":
					null,

				"next_offset":
					offset + 8
			}


		"F", "T", "N", "I":

			return {

				"value":
					null,

				"next_offset":
					offset
			}


		_:

			return {}
# ============================================================
# READ OSC INT32
# ============================================================

func _read_osc_int32(
	packet: PackedByteArray,
	offset: int
) -> int:

	if offset < 0:

		return 0


	if offset + 4 > packet.size():

		return 0


	var buffer := (
		StreamPeerBuffer.new()
	)


	buffer.big_endian = true


	buffer.data_array = (
		packet.slice(
			offset,
			offset + 4
		)
	)


	return buffer.get_32()
# ============================================================
# HANDLE VMC MESSAGE
# ============================================================

func _handle_vmc_message(
	address: String,
	arguments: Array
) -> void:

	if address == "/VMC/Ext/Root/Pos":

		_handle_vmc_root_message(
			arguments
		)

		return


	if address == "/VMC/Ext/Bone/Pos":

		_handle_vmc_bone_message(
			arguments
		)

		return
# ============================================================
# HANDLE VMC ROOT
# ============================================================

func _handle_vmc_root_message(
	arguments: Array
) -> void:

	if arguments.size() < 8:

		return


	if not arguments[0] is String:

		return


	var position := Vector3(

		float(
			arguments[1]
		),

		float(
			arguments[2]
		),

		float(
			arguments[3]
		)
	)


	var rotation := Quaternion(

		float(
			arguments[4]
		),

		float(
			arguments[5]
		),

		float(
			arguments[6]
		),

		float(
			arguments[7]
		)
	)


	if rotation.length_squared() <= 0.000001:

		return


	rotation = (
		rotation.normalized()
	)


	received_vmc_root_position = (
		position
	)


	received_vmc_root_rotation = (
		rotation
	)


	received_vmc_last_packet_time_ms = (
		Time.get_ticks_msec()
	)


	received_vmc_tracking_valid = true
# ============================================================
# HANDLE VMC BONE
# ============================================================

func _handle_vmc_bone_message(
	arguments: Array
) -> void:

	if arguments.size() < 8:

		return


	if not arguments[0] is String:

		return


	var bone_name: String = (
		str(
			arguments[0]
		)
		.strip_edges()
	)


	var rotation := Quaternion(

		float(
			arguments[4]
		),

		float(
			arguments[5]
		),

		float(
			arguments[6]
		),

		float(
			arguments[7]
		)
	)


	if rotation.length_squared() <= 0.000001:

		return


	rotation = (
		rotation.normalized()
	)


	match bone_name:

		"Hips":

			received_vmc_hips_rotation = (
				rotation
			)


		"Spine":

			received_vmc_spine_rotation = (
				rotation
			)


		"Chest":

			received_vmc_chest_rotation = (
				rotation
			)


		"UpperChest":

			received_vmc_upper_chest_rotation = (
				rotation
			)


		"Neck":

			received_vmc_neck_rotation = (
				rotation
			)


		"Head":

			received_vmc_head_rotation = (
				rotation
			)


		_:

			return


	received_vmc_last_packet_time_ms = (
		Time.get_ticks_msec()
	)


	received_vmc_tracking_valid = true
# ============================================================
# GET VMC GLOBAL TRACKING ROTATION
# ============================================================

func get_vmc_global_tracking_rotation() -> Quaternion:

	if not received_vmc_tracking_valid:

		return Quaternion.IDENTITY


	var combined: Quaternion = (
		received_vmc_root_rotation
	)


	combined = (
		combined
		*
		received_vmc_hips_rotation
	).normalized()


	combined = (
		combined
		*
		received_vmc_spine_rotation
	).normalized()


	combined = (
		combined
		*
		received_vmc_chest_rotation
	).normalized()


	combined = (
		combined
		*
		received_vmc_upper_chest_rotation
	).normalized()


	combined = (
		combined
		*
		received_vmc_neck_rotation
	).normalized()


	combined = (
		combined
		*
		received_vmc_head_rotation
	).normalized()


	return combined
# ============================================================
# VMC TRACKING STATUS
# ============================================================

func is_vmc_tracking_available() -> bool:

	if not vmc_receiver_connected:

		return false


	if not received_vmc_tracking_valid:

		return false


	var age_ms: int = (
		Time.get_ticks_msec()
		-
		received_vmc_last_packet_time_ms
	)


	return age_ms <= 500
# ============================================================
# PROCESS
# ============================================================

func _process(
	delta: float
) -> void:

	if is_queued_for_deletion():

		return


	# ========================================================
	# CHARACTER REFERENCE
	# ========================================================

	_update_character_reference()


	# ========================================================
	# VMC RECEIVER
	# ========================================================
	#
	# O receiver deve continuar a funcionar mesmo quando:
	#
	# - não existe Skeleton3D
	# - estamos em 2D
	# - estamos a usar o avatar de calibração
	#
	# ========================================================

	if vmc_receiver_connected:

		_process_vmc_receiver()
		


	# ========================================================
	# ENABLE
	# ========================================================

	if not enabled:

		return


	# ========================================================
	# NATIVE CHARACTER
	# ========================================================

	if is_native_character:

		_update_native_output_state()

		return


	# ========================================================
	# SENDER
	# ========================================================

	if not connected:

		return


	if skeleton == null:

		return


	send_timer += delta


	if send_timer >= VMC_INTERVAL:

		send_timer -= VMC_INTERVAL

		send_vmc_frame()


# ============================================================
# CHARACTER REFERENCE
# ============================================================

func _update_character_reference() -> void:

	if character_runtime == null:

		return


	if not is_instance_valid(
		character_runtime
	):

		character_runtime = null

		return


	var active_character: Node3D = (
		character_runtime
		.get_active_character()
	)


	if active_character == null:

		return


	if active_character != character:

		set_character(
			active_character
		)


# ============================================================
# SEND FRAME
# ============================================================

func send_vmc_frame() -> void:

	if not connected:

		return


	if skeleton == null:

		return


	if is_native_character:

		return


	bones_sent_last_frame = 0


	var root_rotation: Quaternion = (
		Quaternion.IDENTITY
	)


	if interaction_manager != null:

		if is_instance_valid(
			interaction_manager
		):

			var body_rotation: Vector3 = (
				interaction_manager
				.get_character_delta_rotation_for_vmc()
			)


			body_rotation.x = (
				-body_rotation.x
			)


			root_rotation = (
				Quaternion
				.from_euler(
					body_rotation
				)
				.normalized()
			)


	send_root(
		Vector3.ZERO,
		root_rotation
	)


	send_skeleton_bones()


	send_timestamp()


	send_ok()


	frame_count += 1


	last_send_timestamp = (
		Time.get_ticks_msec()
		/
		1000.0
	)


	output_frame_ready.emit(
		OUTPUT_3D_VMC,
		_build_3d_output_state(
			root_rotation
		)
	)


# ============================================================
# 3D OUTPUT STATE
# ============================================================

func _build_3d_output_state(
	root_rotation: Quaternion
) -> Dictionary:

	return {

		"type":
			OUTPUT_3D_VMC,

		"character":
			character,

		"character_name":
			(
				character.name
				if character != null
				else
				""
			),

		"root_position":
			Vector3.ZERO,

		"root_rotation":
			root_rotation,

		"skeleton":
			skeleton,

		"bones_sent":
			bones_sent_last_frame,

		"vmc_host":
			vmc_host,

		"vmc_port":
			vmc_port
	}


# ============================================================
# NATIVE OUTPUT STATE
# ============================================================

func _update_native_output_state() -> void:

	if native_character == null:

		return


	if not is_instance_valid(
		native_character
	):

		native_character = null

		return


	var frame_data: Dictionary = (
		_build_native_output_state()
	)


	output_frame_ready.emit(
		OUTPUT_2D,
		frame_data
	)


# ============================================================
# NATIVE OUTPUT STATE BUILD
# ============================================================

func _build_native_output_state() -> Dictionary:

	var head_rotation: Vector3 = Vector3.ZERO

	var body_rotation: Vector3 = Vector3.ZERO

	var root_x: float = 0.0

	var left_arm_value: float = 0.0

	var right_arm_value: float = 0.0

	var left_eye_open: bool = true

	var right_eye_open: bool = true

	var mouth_open: bool = false


	if native_character != null:

		if is_instance_valid(
			native_character
		):

			var definition: Dictionary = (
				native_character
				.get_definition()
			)


			if definition.has(
				"pose"
			):

				var pose_data: Variant = (
					definition[
						"pose"
					]
				)


				if pose_data is Dictionary:

					var pose: Dictionary = (
						pose_data
						as
						Dictionary
					)


					if pose.has(
						"head_rotation"
					):

						var head_data: Variant = (
							pose[
								"head_rotation"
							]
						)


						if head_data is Dictionary:

							var head_dict: Dictionary = (
								head_data
								as
								Dictionary
							)


							head_rotation = Vector3(

								float(
									head_dict.get(
										"x",
										0.0
									)
								),

								float(
									head_dict.get(
										"y",
										0.0
									)
								),

								float(
									head_dict.get(
										"z",
										0.0
									)
								)
							)


					left_arm_value = float(
						pose.get(
							"left_arm",
							0.0
						)
					)


					right_arm_value = float(
						pose.get(
							"right_arm",
							0.0
						)
					)


					left_eye_open = bool(
						pose.get(
							"left_eye",
							true
						)
					)


					right_eye_open = bool(
						pose.get(
							"right_eye",
							true
						)
					)


					mouth_open = bool(
						pose.get(
							"mouth",
							false
						)
					)


	if interaction_manager != null:

		if is_instance_valid(
			interaction_manager
		):

			var interaction_head_rotation: Vector3 = (
				interaction_manager
				.get_head_delta_rotation_for_vmc()
			)


			head_rotation += (
				interaction_head_rotation
			)


			body_rotation = (
				interaction_manager
				.get_character_delta_rotation_for_vmc()
			)


			body_rotation.x = clampf(
				body_rotation.x,
				-BODY_2D_MAX_X,
				BODY_2D_MAX_X
			)


			body_rotation.y = clampf(
				body_rotation.y,
				-BODY_2D_MAX_Y,
				BODY_2D_MAX_Y
			)


			body_rotation.z = clampf(
				body_rotation.z,
				-BODY_2D_MAX_Z,
				BODY_2D_MAX_Z
			)


			root_x = (
				interaction_manager
				.get_2d_root_x_normalized()
			)


			root_x = clampf(
				root_x,
				ROOT_2D_OUTPUT_MIN,
				ROOT_2D_OUTPUT_MAX
			)


	var now_ms: int = (
		Time.get_ticks_msec()
	)


	var impact_recent: bool = (
		last_2d_impact_time_ms > 0
		and
		(
			now_ms
			-
			last_2d_impact_time_ms
		)
		<=
		IMPACT_OUTPUT_MEMORY_MS
	)


	return {

		"type":
			OUTPUT_2D,

		"output_type":
			OUTPUT_2D,

		"character":
			character,

		"character_name":
			(
				character.name
				if character != null
				else
				""
			),

		"native":
			true,

		"native_character":
			is_native_character,

		"head_rotation":
			head_rotation,

		"body_rotation":
			body_rotation,

		"root_x":
			root_x,

		"left_arm":
			left_arm_value,

		"right_arm":
			right_arm_value,

		"left_eye_open":
			left_eye_open,

		"right_eye_open":
			right_eye_open,

		"mouth_open":
			mouth_open,

		"impact_hit_point":
			last_2d_impact_hit_point,

		"impact_recent":
			impact_recent,

		"parameters":
			output_2d_parameters.duplicate(
				true
			)
	}


# ============================================================
# SEND SKELETON
# ============================================================

func send_skeleton_bones() -> void:

	if skeleton == null:

		return


	for vmc_name: String in VMC_BONE_MAP.keys():

		var vrm_name: String = str(
			VMC_BONE_MAP[
				vmc_name
			]
		)


		var bone_index: int = (
			skeleton.find_bone(
				vrm_name
			)
		)


		if bone_index == -1:

			continue


		var local_pose: Transform3D = (
			skeleton.get_bone_pose(
				bone_index
			)
		)


		var local_position: Vector3 = (
			local_pose.origin
		)


		var local_rotation: Quaternion = (
			local_pose.basis
			.get_rotation_quaternion()
			.normalized()
		)


		if (
			vmc_name == "Head"
			and
			interaction_manager != null
		):

			if is_instance_valid(
				interaction_manager
			):

				var head_offset: Vector3 = (
					interaction_manager
					.get_head_delta_rotation_for_vmc()
				)


				head_offset.x = (
					-head_offset.x
				)


				if head_offset.length() > 0.000001:

					var head_rotation: Quaternion = (
						Quaternion
						.from_euler(
							head_offset
						)
						.normalized()
					)


					local_rotation = (
						local_rotation
						*
						head_rotation
					)


					local_rotation = (
						local_rotation
						.normalized()
					)


		send_bone(
			vmc_name,
			local_position,
			local_rotation
		)


		bones_sent_last_frame += 1


# ============================================================
# ROOT
# ============================================================

func send_root(
	position: Vector3,
	rotation: Quaternion
) -> void:

	var normalized_rotation: Quaternion = (
		rotation.normalized()
	)


	var packet: PackedByteArray = (
		create_osc_message(
			"/VMC/Ext/Root/Pos",
			[
				"root",

				float(position.x),
				float(position.y),
				float(position.z),

				float(normalized_rotation.x),
				float(normalized_rotation.y),
				float(normalized_rotation.z),
				float(normalized_rotation.w)
			]
		)
	)


	_send_packet(
		packet
	)


# ============================================================
# BONE
# ============================================================

func send_bone(
	bone_name: String,
	position: Vector3,
	rotation: Quaternion
) -> void:

	var normalized_rotation: Quaternion = (
		rotation.normalized()
	)


	var packet: PackedByteArray = (
		create_osc_message(
			"/VMC/Ext/Bone/Pos",
			[
				bone_name,

				float(position.x),
				float(position.y),
				float(position.z),

				float(normalized_rotation.x),
				float(normalized_rotation.y),
				float(normalized_rotation.z),
				float(normalized_rotation.w)
			]
		)
	)


	_send_packet(
		packet
	)


# ============================================================
# TIMESTAMP
# ============================================================

func send_timestamp() -> void:

	var timestamp: float = (
		Time.get_ticks_msec()
		/
		1000.0
	)


	var packet: PackedByteArray = (
		create_osc_message(
			"/VMC/Ext/T",
			[
				timestamp
			]
		)
	)


	_send_packet(
		packet
	)


# ============================================================
# OK
# ============================================================

func send_ok() -> void:

	var packet: PackedByteArray = (
		create_osc_message(
			"/VMC/Ext/OK",
			[
				1
			]
		)
	)


	_send_packet(
		packet
	)


# ============================================================
# UDP SEND
# ============================================================

func _send_packet(
	packet: PackedByteArray
) -> void:

	if not connected:

		return


	if packet.is_empty():

		last_send_error = (
			"EMPTY OSC PACKET"
		)

		return


	var result: Error = (
		udp.put_packet(
			packet
		)
	)


	if result != OK:

		last_send_error = (
			error_string(
				result
			)
		)

		return


	packet_count += 1


# ============================================================
# CHARACTER RUNTIME
# ============================================================

func set_character_runtime(
	runtime: CIGACharacterRuntime
) -> void:

	if character_runtime != null:

		if is_instance_valid(
			character_runtime
		):

			var loaded_callable := Callable(
				self,
				"_on_character_loaded"
			)


			if character_runtime.character_loaded.is_connected(
				loaded_callable
			):

				character_runtime.character_loaded.disconnect(
					loaded_callable
				)


			var unloaded_callable := Callable(
				self,
				"_on_character_unloaded"
			)


			if character_runtime.character_unloaded.is_connected(
				unloaded_callable
			):

				character_runtime.character_unloaded.disconnect(
					unloaded_callable
				)


	character_runtime = runtime


	if character_runtime == null:

		character = null

		skeleton = null

		native_character = null

		is_native_character = false

		return


	log_info(
		"Character runtime connected."
	)


	var loaded_callable := Callable(
		self,
		"_on_character_loaded"
	)


	if not character_runtime.character_loaded.is_connected(
		loaded_callable
	):

		character_runtime.character_loaded.connect(
			_on_character_loaded
		)


	var unloaded_callable := Callable(
		self,
		"_on_character_unloaded"
	)


	if not character_runtime.character_unloaded.is_connected(
		unloaded_callable
	):

		character_runtime.character_unloaded.connect(
			_on_character_unloaded
		)


	var current_character: Node3D = (
		character_runtime.get_active_character()
	)


	if current_character != null:

		set_character(
			current_character
		)


# ============================================================
# CHARACTER LOADED
# ============================================================

func _on_character_loaded(
	new_character: Node3D
) -> void:

	set_character(
		new_character
	)


# ============================================================
# CHARACTER UNLOADED
# ============================================================

func _on_character_unloaded() -> void:

	character = null

	skeleton = null

	native_character = null

	is_native_character = false

	native_output_logged = false


	output_target_changed.emit(
		OUTPUT_NONE
	)


# ============================================================
# SET CHARACTER
# ============================================================

func set_character(
	new_character: Node3D
) -> void:

	character = new_character

	skeleton = null

	native_character = null

	is_native_character = false

	native_output_logged = false


	if character == null:

		if interaction_manager != null:

			if is_instance_valid(
				interaction_manager
			):

				interaction_manager.set_2d_mode(
					false
				)


		output_target_changed.emit(
			OUTPUT_NONE
		)


		return


	if character is CIGACalibrationAvatar:

		native_character = (
			character
			as
			CIGACalibrationAvatar
		)


		is_native_character = true


		if interaction_manager != null:

			if is_instance_valid(
				interaction_manager
			):

				interaction_manager.set_2d_mode(
					true
				)


		output_target_changed.emit(
			OUTPUT_2D
		)


		log_info(
			"Native calibration avatar detected."
		)


		log_info(
			"2D impact reaction mode enabled."
		)


		log_info(
			"VMC skeleton output bypassed."
		)


		return


	if interaction_manager != null:

		if is_instance_valid(
			interaction_manager
		):

			interaction_manager.set_2d_mode(
				false
			)


	output_target_changed.emit(
		OUTPUT_3D_VMC
	)


	var skeleton_nodes: Array[Node] = (
		character.find_children(
			"*",
			"Skeleton3D",
			true,
			false
		)
	)


	for candidate: Node in skeleton_nodes:

		if candidate is Skeleton3D:

			skeleton = (
				candidate
				as
				Skeleton3D
			)

			break


	if skeleton == null:

		log_error(
			"NO SKELETON FOUND FOR IMPORTED 3D CHARACTER."
		)

		return


	print(
		"[CIGA VMC] SKELETON FOUND | ",
		skeleton.name,
		" | BONES=",
		skeleton.get_bone_count()
	)


	var valid_map_count: int = 0


	for vmc_name: String in VMC_BONE_MAP.keys():

		var vrm_name: String = str(
			VMC_BONE_MAP[
				vmc_name
			]
		)


		if skeleton.find_bone(
			vrm_name
		) != -1:

			valid_map_count += 1


	print(
		"[CIGA VMC] VMC BONES AVAILABLE | ",
		valid_map_count,
		"/",
		VMC_BONE_MAP.size()
	)


	if valid_map_count == 0:

		log_error(
			"NO VMC BONES MATCHED IN IMPORTED CHARACTER."
		)

	else:

		log_info(
			"3D VMC output ready."
		)


# ============================================================
# INTERACTION MANAGER
# ============================================================

func set_interaction_manager(
	manager: CIGAinteractionManager
) -> void:

	if interaction_manager != null:

		if is_instance_valid(
			interaction_manager
		):

			var old_callable := Callable(
				self,
				"_on_2d_impact_received"
			)


			if interaction_manager.impact_received.is_connected(
				old_callable
			):

				interaction_manager.impact_received.disconnect(
					old_callable
				)


	interaction_manager = manager


	if interaction_manager == null:

		last_2d_impact_hit_point = ""

		last_2d_impact_time_ms = 0

		return


	var impact_callable := Callable(
		self,
		"_on_2d_impact_received"
	)


	if not interaction_manager.impact_received.is_connected(
		impact_callable
	):

		interaction_manager.impact_received.connect(
			impact_callable
		)


# ============================================================
# 2D IMPACT RECEIVED
# ============================================================

func _on_2d_impact_received(
	hit_point_name: String,
	_force: float,
	_impact_direction: Vector3
) -> void:

	last_2d_impact_hit_point = (
		hit_point_name
	)


	last_2d_impact_time_ms = (
		Time.get_ticks_msec()
	)


# ============================================================
# OUTPUT MODE
# ============================================================

func set_output_mode(
	mode: String
) -> void:

	if (
		mode != OUTPUT_NONE
		and
		mode != OUTPUT_3D_VMC
		and
		mode != OUTPUT_2D
	):

		log_error(
			"INVALID OUTPUT MODE | "
			+
			mode
		)

		return


	output_mode = mode


	output_target_changed.emit(
		output_mode
	)


	log_info(
		"OUTPUT MODE | "
		+
		output_mode
	)


func get_output_mode() -> String:

	return output_mode


func get_available_output_modes() -> Array[String]:

	return [
		OUTPUT_NONE,
		OUTPUT_3D_VMC,
		OUTPUT_2D
	]


# ============================================================
# 2D PARAMETER API
# ============================================================

func set_2d_parameter(
	parameter_name: String,
	value: float
) -> void:

	output_2d_parameters[
		parameter_name
	] = value


func set_2d_parameters(
	parameters: Dictionary
) -> void:

	for parameter_name: Variant in parameters.keys():

		output_2d_parameters[
			str(
				parameter_name
			)
		] = float(
			parameters[
				parameter_name
			]
		)


func get_2d_parameter(
	parameter_name: String,
	default_value: float = 0.0
) -> float:

	if not output_2d_parameters.has(
		parameter_name
	):

		return default_value


	return float(
		output_2d_parameters[
			parameter_name
		]
	)


func get_2d_output_state() -> Dictionary:

	if is_native_character:

		return (
			_build_native_output_state()
		)


	return {

		"output_type":
			OUTPUT_2D,

		"character":
			character,

		"character_name":
			(
				character.name
				if character != null
				else
				""
			),

		"native_character":
			is_native_character,

		"head_rotation":
			Vector3.ZERO,

		"body_rotation":
			Vector3.ZERO,

		"root_x":
			0.0,

		"left_arm":
			0.0,

		"right_arm":
			0.0,

		"left_eye_open":
			true,

		"right_eye_open":
			true,

		"mouth_open":
			false,

		"impact_hit_point":
			last_2d_impact_hit_point,

		"impact_recent":
			(
				last_2d_impact_time_ms > 0
				and
				(
					Time.get_ticks_msec()
					-
					last_2d_impact_time_ms
				)
				<=
				IMPACT_OUTPUT_MEMORY_MS
			),

		"parameters":
			output_2d_parameters.duplicate(
				true
			)
	}


func clear_2d_parameters() -> void:

	output_2d_parameters = (
		DEFAULT_2D_PARAMETER_VALUES.duplicate(
			true
		)
	)


# ============================================================
# LEGACY MODE COMPATIBILITY
# ============================================================

func set_realistic_mode(
	value: bool
) -> void:

	if value:

		log_info(
			"REALISTIC MODE REQUESTED | IGNORED | NORMAL ONLY"
		)


func get_realistic_mode() -> bool:

	return false


# ============================================================
# ENABLE
# ============================================================

func set_enabled(
	value: bool
) -> void:

	enabled = value


func is_vmc_connected() -> bool:

	return connected


func is_vmc_enabled() -> bool:

	return enabled


func get_connection_status() -> String:

	if not enabled:

		return "DISABLED"


	if not connected:

		return "DISCONNECTED"


	return "CONNECTED"


# ============================================================
# IMPACT DIAGNOSTIC
# ============================================================

func register_impact(
	_hit_point_name: String,
	_force: float
) -> void:

	pass


# ============================================================
# MODE
# ============================================================

func _get_mode_name() -> String:

	return "NORMAL"


# ============================================================
# DIAGNOSTIC API
# ============================================================

func get_diagnostic() -> Dictionary:

	return {

		"socket_ready":
			connected,

		"host":
			vmc_host,

		"port":
			vmc_port,

		"fps":
			VMC_FPS,

		"process_priority":
			process_priority,

		"packets":
			packet_count,

		"frames":
			frame_count,

		"bones_sent":
			bones_sent_last_frame,

		"realistic_mode":
			false,

		"mode":
			"NORMAL",

		"output_mode":
			output_mode,

		"character":
			character != null,

		"native_character":
			is_native_character,

		"skeleton":
			skeleton != null,

		"2d_parameters":
			output_2d_parameters.size(),

		"last_2d_impact":
			last_2d_impact_hit_point,

		"last_2d_impact_age_ms":
			(
				Time.get_ticks_msec()
				-
				last_2d_impact_time_ms
				if last_2d_impact_time_ms > 0
				else
				-1
			),

		"last_error":
			last_send_error,

		"last_send_timestamp":
			last_send_timestamp
	}


# ============================================================
# OSC
# ============================================================

func create_osc_message(
	address: String,
	arguments: Array
) -> PackedByteArray:

	var packet := PackedByteArray()


	packet.append_array(
		pad_osc_string(
			address
		)
	)


	var type_tags: String = ","


	for argument in arguments:

		if argument is String:

			type_tags += "s"

		elif argument is float:

			type_tags += "f"

		elif argument is int:

			type_tags += "i"

		elif argument is Vector3:

			type_tags += "fff"

		elif argument is Quaternion:

			type_tags += "ffff"


	packet.append_array(
		pad_osc_string(
			type_tags
		)
	)


	for argument in arguments:

		if argument is String:

			packet.append_array(
				pad_osc_string(
					str(
						argument
					)
				)
			)


		elif argument is float:

			packet.append_array(
				float_to_big_endian_bytes(
					float(
						argument
					)
				)
			)


		elif argument is int:

			packet.append_array(
				int_to_big_endian_bytes(
					int(
						argument
					)
				)
			)


		elif argument is Vector3:

			packet.append_array(
				float_to_big_endian_bytes(
					argument.x
				)
			)


			packet.append_array(
				float_to_big_endian_bytes(
					argument.y
				)
			)


			packet.append_array(
				float_to_big_endian_bytes(
					argument.z
				)
			)


		elif argument is Quaternion:

			packet.append_array(
				float_to_big_endian_bytes(
					argument.x
				)
			)


			packet.append_array(
				float_to_big_endian_bytes(
					argument.y
				)
			)


			packet.append_array(
				float_to_big_endian_bytes(
					argument.z
				)
			)


			packet.append_array(
				float_to_big_endian_bytes(
					argument.w
				)


			)


	return packet


# ============================================================
# OSC STRING
# ============================================================

func pad_osc_string(
	value: String
) -> PackedByteArray:

	var source: PackedByteArray = (
		value.to_utf8_buffer()
	)


	var result := PackedByteArray()


	result.append_array(
		source
	)


	result.append(
		0
	)


	while result.size() % 4 != 0:

		result.append(
			0
		)


	return result


# ============================================================
# FLOAT BIG ENDIAN
# ============================================================

func float_to_big_endian_bytes(
	value: float
) -> PackedByteArray:

	var buffer := (
		StreamPeerBuffer.new()
	)


	buffer.big_endian = true


	buffer.put_float(
		value
	)


	return buffer.data_array


# ============================================================
# INTEGER BIG ENDIAN
# ============================================================

func int_to_big_endian_bytes(
	value: int
) -> PackedByteArray:

	var buffer := (
		StreamPeerBuffer.new()
	)


	buffer.big_endian = true


	buffer.put_32(
		value
	)


	return buffer.data_array


# ============================================================
# LOG
# ============================================================

func log_info(
	message: String
) -> void:

	vmc_log.emit(
		"INFO",
		message
	)


func log_error(
	message: String
) -> void:

	push_error(
		"[CIGA VMC] "
		+
		message
	)


	vmc_log.emit(
		"ERROR",
		message
	)


# ============================================================
# DISCONNECT
# ============================================================

func disconnect_vmc() -> void:

	if not connected:

		return


	connected = false


	if udp != null:

		udp.close()


	print(
		"[CIGA VMC] UDP DISCONNECTED"
	)


	connection_status_changed.emit(
		"DISCONNECTED",
		"VMC UDP output disconnected."
	)


# ============================================================
# EXIT
# ============================================================

func _exit_tree() -> void:

	connected = false


	if udp != null:

		udp.close()
