class_name CIGAOutput
extends Node


# =============================================================
# CIGA OUTPUT
# Godot 4.7.2
#
# OUTPUTS
#
#   - STREAM ELEMENTS
#   - VMC / 3D
#   - VTube Studio / 2D
#   - CIGAIS WORKER
#
# VMC:
#   CIGA -> VMC/OSC -> VSeeFace / compatible receivers
#
# VTube Studio:
#   CIGA -> WebSocket JSON API -> VTube Studio -> Live2D
#
# CIGAIS WORKER:
#   CIGA -> WebSocket -> Cloudflare Durable Object
#        -> Discord Bot
#
# INCOMING CIGAIS IMAGE:
#
#   Discord Bot
#        ->
#   Cloudflare Worker
#        ->
#   CIGAOutput
#        ->
#   HTTP DOWNLOAD
#        ->
#   LOCAL TEMP IMAGE
#        ->
#   live_image_received
#
# IMPORTANT:
#
# VMC, VTube Studio, StreamElements and CIGAIS Worker
# are independent output paths.
#
# =============================================================


# =============================================================
# SIGNALS
# =============================================================

signal connection_status_changed(
	source_id: String,
	status: String,
	message: String
)

signal log_message(
	source_id: String,
	level: String,
	message: String
)

signal stream_event_received(
	source_id: String,
	event_name: String,
	payload: Dictionary
)

signal event_forwarded(
	source_id: String,
	event_name: String,
	payload: Dictionary
)

signal event_received(
	source_id: String,
	event_name: String,
	payload: Dictionary
)

signal live_image_received(
	payload: Dictionary
)


# =============================================================
# SOURCE IDS
# =============================================================

const SOURCE_STREAMELEMENTS: String = "STREAMELEMENTS"

const SOURCE_VMC: String = "VMC"

const SOURCE_VTUBESTUDIO: String = "VTUBESTUDIO"

const SOURCE_CIGAIS_WORKER: String = "CIGAIS_WORKER"


# =============================================================
# STREAMELEMENTS
# =============================================================

const STREAMELEMENTS_URL: String = (
	"wss://astro.streamelements.com"
)

const STREAMELEMENTS_ACTIVITIES_TOPIC: String = (
	"channel.activities"
)


# =============================================================
# CIGAIS WORKER
# =============================================================

const CIGAIS_WORKER_URL: String = (
	"wss://cigais.cigasystems-contact.workers.dev"
)


# =============================================================
# CIGAIS LIVE IMAGE
# =============================================================

const CIGAIS_LIVE_IMAGE_TEMP_DIR: String = (
	"user://ciga/temp/live_images"
)

const CIGAIS_LIVE_IMAGE_MAX_BYTES: int = (
	10
	*
	1024
	*
	1024
)

const CIGAIS_LIVE_IMAGE_MAX_DIMENSION: int = 1080

const CIGAIS_LIVE_IMAGE_MAX_REDIRECTS: int = 5

const CIGAIS_LIVE_IMAGE_REQUEST_TIMEOUT: float = 20.0


# =============================================================
# VTUBE STUDIO
# =============================================================

const VTUBE_STUDIO_URL: String = (
	"ws://127.0.0.1:8001"
)

const VTUBE_STUDIO_API_NAME: String = (
	"VTubeStudioPublicAPI"
)

const VTUBE_STUDIO_API_VERSION: String = (
	"1.0"
)

const VTUBE_STUDIO_DEFAULT_PLUGIN_NAME: String = (
	"CIGA Systems"
)

const VTUBE_STUDIO_DEFAULT_PLUGIN_DEVELOPER: String = (
	"CIGA Systems"
)


# =============================================================
# CUSTOM CIGA PARAMETERS
# =============================================================

const VTS_PARAM_BODY_YAW: String = (
	"CIGABodyYaw"
)

const VTS_PARAM_BODY_PITCH: String = (
	"CIGABodyPitch"
)

const VTS_PARAM_BODY_ROLL: String = (
	"CIGABodyRoll"
)

const VTS_PARAM_LEFT_ARM: String = (
	"CIGALeftArm"
)

const VTS_PARAM_RIGHT_ARM: String = (
	"CIGARightArm"
)

const VTS_PARAM_ROOT_X: String = (
	"CIGARootX"
)


# =============================================================
# RECONNECT
# =============================================================

const RECONNECT_BASE_DELAY: float = 2.0

const RECONNECT_MAX_DELAY: float = 30.0


# =============================================================
# STABILITY
# =============================================================

const STABILITY_LOG_INTERVAL: float = 600.0


# =============================================================
# DEDUP
# =============================================================

const DEDUP_WINDOW_SECONDS: float = 8.0

const MAX_DEDUP_ENTRIES: int = 300


# =============================================================
# REFERENCES
# =============================================================

var object_manager: CIGAObjects = null

var profile_manager: CIGAProfiles = null

var vmc_runtime: CIGAVMCRuntime = null

var events_runtime: CIGAEventsRuntime = null


# =============================================================
# STREAMELEMENTS STATE
# =============================================================

var streamelements_socket: WebSocketPeer = null

var streamelements_config: Dictionary = {}

var streamelements_connected: bool = false

var streamelements_authenticated: bool = false

var streamelements_subscribed: bool = false

var streamelements_manual_disconnect: bool = false

var streamelements_reconnect_timer: float = 0.0

var streamelements_reconnect_attempts: int = 0

var streamelements_stability_timer: float = 0.0


# =============================================================
# CIGAIS WORKER STATE
# =============================================================

var cigais_worker_socket: WebSocketPeer = null

var cigais_worker_connected: bool = false

var cigais_worker_reconnect_timer: float = 0.0

var cigais_worker_reconnect_attempts: int = 0

var cigais_worker_guild_id: String = ""

var cigais_live_image_counter: int = 0


# =============================================================
# VTUBE STUDIO STATE
# =============================================================

var vtube_studio_socket: WebSocketPeer = null

var vtube_studio_config: Dictionary = {}

var vtube_studio_connected: bool = false

var vtube_studio_authenticated: bool = false

var vtube_studio_manual_disconnect: bool = false

var vtube_studio_reconnect_timer: float = 0.0

var vtube_studio_reconnect_attempts: int = 0

var vtube_studio_request_counter: int = 0

var vtube_studio_parameters_ready: bool = false

var vtube_studio_plugin_name: String = (
	VTUBE_STUDIO_DEFAULT_PLUGIN_NAME
)

var vtube_studio_plugin_developer: String = (
	VTUBE_STUDIO_DEFAULT_PLUGIN_DEVELOPER
)

var vtube_studio_token: String = ""


# =============================================================
# MODEL INSPECTION
# =============================================================

var vtube_studio_model_inspection_requested: bool = false

var vtube_studio_parameter_inspection_requested: bool = false

var vtube_studio_input_parameter_inspection_requested: bool = false

var vtube_studio_available_input_names: Array[String] = []


# =============================================================
# VTUBE STUDIO OUTPUT
# =============================================================

var vtube_studio_send_timer: float = 0.0

const VTUBE_STUDIO_SEND_INTERVAL: float = (
	1.0
	/
	60.0
)


# =============================================================
# VTUBE STUDIO PENDING REQUESTS
# =============================================================

var vtube_studio_pending_requests: Dictionary = {}


# =============================================================
# DEDUP CACHE
# =============================================================

var dedup_cache: Dictionary = {}


# =============================================================
# READY
# =============================================================

func _ready() -> void:

	set_process(true)

	call_deferred(
		"_connect_events_runtime"
	)


# =============================================================
# SETUP
# =============================================================

func setup(
	objects: CIGAObjects = null,
	profiles: CIGAProfiles = null
) -> void:

	object_manager = objects

	profile_manager = profiles

	log_info(
		"OUTPUT",
		"CIGA Output manager initialized."
	)


# =============================================================
# SET VMC RUNTIME
# =============================================================

func set_vmc_runtime(
	new_runtime: CIGAVMCRuntime
) -> void:

	vmc_runtime = new_runtime

	if vmc_runtime != null:

		log_info(
			SOURCE_VMC,
			"VMC runtime linked to Output manager."
		)

	else:

		log_warning(
			SOURCE_VMC,
			"VMC runtime link cleared."
		)


# =============================================================
# PROCESS
# =============================================================

func _process(
	delta: float
) -> void:

	_poll_streamelements(
		delta
	)

	_poll_cigais_worker(
		delta
	)

	_poll_vtube_studio(
		delta
	)

	_cleanup_dedup_cache()

	_update_vtube_studio_output(
		delta
	)


# =============================================================
# POLL STREAM ELEMENTS
# =============================================================

func _poll_streamelements(
	delta: float
) -> void:

	if streamelements_socket == null:

		if streamelements_reconnect_timer > 0.0:

			streamelements_reconnect_timer -= delta

			if streamelements_reconnect_timer <= 0.0:

				_attempt_streamelements_reconnect()

		return


	streamelements_socket.poll()


	var state: WebSocketPeer.State = (
		streamelements_socket.get_ready_state()
	)


	match state:

		WebSocketPeer.STATE_CONNECTING:

			return


		WebSocketPeer.STATE_OPEN:

			streamelements_stability_timer += delta

			if (
				streamelements_connected
				and
				streamelements_stability_timer
				>=
				STABILITY_LOG_INTERVAL
			):

				streamelements_stability_timer = 0.0

				log_info(
					SOURCE_STREAMELEMENTS,
					"Connection stable."
				)


			while (
				streamelements_socket
				.get_available_packet_count()
				>
				0
			):

				var packet: PackedByteArray = (
					streamelements_socket.get_packet()
				)

				if not streamelements_socket.was_string_packet():

					continue


				var text: String = (
					packet.get_string_from_utf8()
				)


				_handle_streamelements_message(
					text
				)


		WebSocketPeer.STATE_CLOSING:

			return


		WebSocketPeer.STATE_CLOSED:

			_handle_streamelements_closed()


# =============================================================
# CONNECT CIGAIS WORKER
# =============================================================

func _connect_cigais_worker() -> bool:

	if CIGAIS_WORKER_URL.is_empty():

		return false


	var guild_id := _get_cigais_worker_guild_id()


	if guild_id.is_empty():

		log_warning(
			SOURCE_CIGAIS_WORKER,
			"Discord Guild ID is not configured."
		)

		return false


	cigais_worker_guild_id = guild_id


	if cigais_worker_socket != null:

		var current_state: WebSocketPeer.State = (
			cigais_worker_socket.get_ready_state()
		)


		if (
			current_state == WebSocketPeer.STATE_OPEN
			or
			current_state == WebSocketPeer.STATE_CONNECTING
		):

			return true


		cigais_worker_socket = null


	cigais_worker_socket = WebSocketPeer.new()


	log_info(
		SOURCE_CIGAIS_WORKER,
		"Connecting to CIGAIS Worker..."
	)


	emit_status(
		SOURCE_CIGAIS_WORKER,
		"CONNECTING",
		"Connecting to CIGAIS Worker..."
	)


	var error: Error = (
		cigais_worker_socket.connect_to_url(
			CIGAIS_WORKER_URL
		)
	)


	if error != OK:

		log_error(
			SOURCE_CIGAIS_WORKER,
			"Worker connection failed: "
			+
			error_string(
				error
			)
		)


		cigais_worker_socket = null

		_schedule_cigais_worker_reconnect()

		return false


	return true


# =============================================================
# GET CIGAIS WORKER GUILD ID
# =============================================================

func _get_cigais_worker_guild_id() -> String:

	var config: Dictionary = (
		get_saved_source_config(
			SOURCE_CIGAIS_WORKER
		)
	)


	return str(
		config.get(
			"guild_id",
			""
		)
	).strip_edges()


# =============================================================
# REGISTER CIGAIS
# =============================================================

func _register_cigais_worker() -> void:

	if cigais_worker_socket == null:

		return


	if (
		cigais_worker_socket.get_ready_state()
		!=
		WebSocketPeer.STATE_OPEN
	):

		return


	if cigais_worker_guild_id.is_empty():

		return


	var request := {

		"type":
			"register_cigais",

		"guild_id":
			cigais_worker_guild_id
	}


	var error: Error = (
		cigais_worker_socket.send_text(
			JSON.stringify(
				request
			)
		)
	)


	if error != OK:

		log_error(
			SOURCE_CIGAIS_WORKER,
			"Worker registration failed: "
			+
			error_string(
				error
			)
		)

		return


	log_info(
		SOURCE_CIGAIS_WORKER,
		"Registered CIGAIS with Worker | GUILD="
		+
		cigais_worker_guild_id
	)


# =============================================================
# SEND CIGAIS WORKER EVENT
# =============================================================

func send_cigais_worker_event(
	event_data: Dictionary
) -> bool:

	if event_data.is_empty():

		return false


	if cigais_worker_socket == null:

		return false


	if (
		cigais_worker_socket.get_ready_state()
		!=
		WebSocketPeer.STATE_OPEN
	):

		return false


	var error: Error = (
		cigais_worker_socket.send_text(
			JSON.stringify(
				event_data
			)
		)
	)


	if error != OK:

		log_error(
			SOURCE_CIGAIS_WORKER,
			"Worker event send failed: "
			+
			error_string(
				error
			)
		)

		return false


	log_info(
		SOURCE_CIGAIS_WORKER,
		"EVENT SENT | "
		+
		str(
			event_data.get(
				"event",
				"UNKNOWN"
			)
		)
		+
		" | REQUEST="
		+
		str(
			event_data.get(
				"request_id",
				""
			)
		)
	)


	return true


# =============================================================
# HANDLE CIGAIS WORKER MESSAGE
# =============================================================

func _handle_cigais_worker_message(
	raw_text: String
) -> void:

	if raw_text.is_empty():

		return


	var parsed: Variant = (
		JSON.parse_string(
			raw_text
		)
	)


	if not parsed is Dictionary:

		return


	var message: Dictionary = (
		parsed as Dictionary
	)


	var message_type := str(
		message.get(
			"type",
			""
		)
	)


	match message_type:

		"hello_ack":

			log_info(
				SOURCE_CIGAIS_WORKER,
				"HELLO ACK RECEIVED."
			)


		"register_cigais_ack":

			if bool(
				message.get(
					"registered",
					false
				)
			):

				log_info(
					SOURCE_CIGAIS_WORKER,
					"CIGAIS REGISTERED | GUILD="
					+
					str(
						message.get(
							"guild_id",
							""
						)
					)
				)

				emit_status(
					SOURCE_CIGAIS_WORKER,
					"CONNECTED",
					"CIGAIS registered with Worker."
				)


		"cigais_event_ack":

			log_info(
				SOURCE_CIGAIS_WORKER,
				"EVENT ACK | REQUEST="
				+
				str(
					message.get(
						"request_id",
						""
					)
				)
				+
				" | DELIVERED="
				+
				str(
					message.get(
						"delivered",
						false
					)
				)
			)


		"cigais_image_ack":

			log_info(
				SOURCE_CIGAIS_WORKER,
				"IMAGE ACK | MESSAGE="
				+
				str(
					message.get(
						"message_id",
						""
					)
				)
				+
				" | DELIVERED="
				+
				str(
					message.get(
						"delivered",
						false
					)
				)
			)


		"bot_event_ack":

			log_info(
				SOURCE_CIGAIS_WORKER,
				"BOT ACK | REQUEST="
				+
				str(
					message.get(
						"request_id",
						""
					)
				)
				+
				" | STATUS="
				+
				str(
					message.get(
						"status",
						""
					)
				)
			)


		"bot_test":

			log_info(
				SOURCE_CIGAIS_WORKER,
				"BOT TEST RECEIVED | "
				+
				str(
					message.get(
						"message",
						""
					)
				)
			)


		"cigais_image":

			_handle_cigais_image_message(
				message
			)


		_:

			log_info(
				SOURCE_CIGAIS_WORKER,
				"WORKER MESSAGE | TYPE="
				+
				message_type
			)


# =============================================================
# HANDLE LIVE IMAGE MESSAGE
# =============================================================

func _handle_cigais_image_message(
	message: Dictionary
) -> void:

	if message.is_empty():

		return


	var image_url := str(
		message.get(
			"image_url",
			""
		)
	).strip_edges()


	var image_proxy_url := str(
		message.get(
			"image_proxy_url",
			""
		)
	).strip_edges()


	if image_url.is_empty():

		image_url = image_proxy_url


	if image_url.is_empty():

		log_error(
			SOURCE_CIGAIS_WORKER,
			"Live image received without image URL."
		)

		return


	var normalized_url := image_url.to_lower()


	if (
		not normalized_url.begins_with("https://")
		and
		not normalized_url.begins_with("http://")
	):

		log_error(
			SOURCE_CIGAIS_WORKER,
			"Live image URL is invalid."
		)

		return


	var content_type := str(
		message.get(
			"content_type",
			""
		)
	).to_lower().strip_edges()


	if (
		not content_type.is_empty()
		and
		not _is_supported_live_image_content_type(
			content_type
		)
	):

		log_error(
			SOURCE_CIGAIS_WORKER,
			"Unsupported live image content type: "
			+
			content_type
		)

		return


	var declared_size := int(
		message.get(
			"size_bytes",
			0
		)
	)


	if declared_size > CIGAIS_LIVE_IMAGE_MAX_BYTES:

		log_error(
			SOURCE_CIGAIS_WORKER,
			"Live image exceeds 10 MB limit."
		)

		return


	log_info(
		SOURCE_CIGAIS_WORKER,
		"LIVE IMAGE RECEIVED | "
		+
		str(
			message.get(
				"filename",
				"image"
			)
		)
		+
		" | MESSAGE="
		+
		str(
			message.get(
				"message_id",
				""
			)
		)
	)


	_download_cigais_live_image(
		image_url,
		message
	)


# =============================================================
# SUPPORTED LIVE IMAGE TYPES
# =============================================================

func _is_supported_live_image_content_type(
	content_type: String
) -> bool:

	var normalized := (
		content_type
		.to_lower()
		.strip_edges()
	)


	return (
		normalized == "image/png"
		or
		normalized == "image/jpeg"
		or
		normalized == "image/jpg"
		or
		normalized == "image/webp"
	)


# =============================================================
# DOWNLOAD LIVE IMAGE
# =============================================================

func _download_cigais_live_image(
	url: String,
	payload: Dictionary
) -> void:

	if url.is_empty():

		return


	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(
			CIGAIS_LIVE_IMAGE_TEMP_DIR
		)
	)


	var request := HTTPRequest.new()

	request.name = (
		"CIGALiveImageDownload"
	)


	request.timeout = (
		CIGAIS_LIVE_IMAGE_REQUEST_TIMEOUT
	)


	request.max_redirects = (
		CIGAIS_LIVE_IMAGE_MAX_REDIRECTS
	)


	# IMPORTANT:
	# The callback uses this EXACT same metadata key.
	request.set_meta(
		"cigais_live_image_meta",
		payload.duplicate(true)
	)


	add_child(
		request
	)


	request.request_completed.connect(
		_on_cigais_live_image_request_completed.bind(
			request
		)
	)


	log_info(
		SOURCE_CIGAIS_WORKER,
		"Downloading live image..."
	)


	var error: Error = (
		request.request(
			url
		)
	)


	if error != OK:

		log_error(
			SOURCE_CIGAIS_WORKER,
			"Live image download request failed: "
			+
			error_string(
				error
			)
		)


		request.queue_free()


# =============================================================
# LIVE IMAGE DOWNLOAD COMPLETED
# =============================================================
#
# IMPORTANT:
#
# This function ONLY:
#
#   1. receives the downloaded bytes
#   2. decodes the image
#   3. validates it
#   4. adds transparent padding to make it square
#   5. resizes to max 1080
#   6. saves the temporary PNG
#   7. emits live_image_received
#
# The DISPLAY_IMAGE_LIVE duration is NOT handled here.
#
# The duration starts later in CIGAViewportRuntime, only after
# the Sprite3D has actually been created and displayed.
#
# =============================================================

func _on_cigais_live_image_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	request: HTTPRequest
) -> void:

	# =============================================================
	# REQUEST VALIDATION
	# =============================================================

	if request == null:

		print(
			"[CIGA OUTPUT] LIVE IMAGE FAILED | REQUEST=NULL"
		)

		return


	var meta_variant: Variant = request.get_meta(
		"cigais_live_image_meta",
		{}
	)


	var meta: Dictionary = {}


	if meta_variant is Dictionary:

		meta = (
			meta_variant as Dictionary
		)


	# =============================================================
	# REQUEST CAN NOW BE FREED
	# =============================================================

	request.queue_free()


	# =============================================================
	# HTTP RESULT
	# =============================================================

	if result != HTTPRequest.RESULT_SUCCESS:

		print(
			"[CIGA OUTPUT] LIVE IMAGE DOWNLOAD FAILED | RESULT=%s"
			%
			str(
				result
			)
		)

		return


	if response_code < 200 or response_code >= 300:

		print(
			"[CIGA OUTPUT] LIVE IMAGE DOWNLOAD FAILED | HTTP=%d"
			%
			response_code
		)

		return


	if body.is_empty():

		print(
			"[CIGA OUTPUT] LIVE IMAGE DOWNLOAD FAILED | EMPTY BODY"
		)

		return


	# =============================================================
	# SIZE VALIDATION
	# =============================================================

	if body.size() > CIGAIS_LIVE_IMAGE_MAX_BYTES:

		print(
			"[CIGA OUTPUT] LIVE IMAGE REJECTED | SIZE=%d | MAX=%d"
			%
			[
				body.size(),
				CIGAIS_LIVE_IMAGE_MAX_BYTES
			]
		)

		return


	# =============================================================
	# IMAGE INFORMATION
	# =============================================================

	var content_type: String = str(
		meta.get(
			"content_type",
			""
		)
	).to_lower().strip_edges()


	var image_url: String = str(
		meta.get(
			"image_url",
			""
		)
	).to_lower()


	# =============================================================
	# IMAGE DECODER
	# =============================================================

	var image: Image = Image.new()

	var load_error: Error = ERR_UNAVAILABLE


	# =============================================================
	# TRY CONTENT TYPE
	# =============================================================

	if content_type.find("png") != -1:

		load_error = image.load_png_from_buffer(
			body
		)

	elif (
		content_type.find("jpeg") != -1
		or
		content_type.find("jpg") != -1
	):

		load_error = image.load_jpg_from_buffer(
			body
		)

	elif content_type.find("webp") != -1:

		load_error = image.load_webp_from_buffer(
			body
		)


	# =============================================================
	# FALLBACK TO URL EXTENSION
	# =============================================================

	if load_error != OK:

		if image_url.find(".png") != -1:

			load_error = image.load_png_from_buffer(
				body
			)

		elif (
			image_url.find(".jpg") != -1
			or
			image_url.find(".jpeg") != -1
		):

			load_error = image.load_jpg_from_buffer(
				body
			)

		elif image_url.find(".webp") != -1:

			load_error = image.load_webp_from_buffer(
				body
			)


	# =============================================================
	# FALLBACK TO FILE SIGNATURE
	# =============================================================

	if (
		load_error != OK
		and
		body.size() >= 8
	):

		# PNG
		var is_png: bool = (
			body[0] == 0x89
			and
			body[1] == 0x50
			and
			body[2] == 0x4E
			and
			body[3] == 0x47
			and
			body[4] == 0x0D
			and
			body[5] == 0x0A
			and
			body[6] == 0x1A
			and
			body[7] == 0x0A
		)


		if is_png:

			load_error = image.load_png_from_buffer(
				body
			)


	# =============================================================
	# JPEG SIGNATURE
	# =============================================================

	if (
		load_error != OK
		and
		body.size() >= 3
	):

		var is_jpeg: bool = (
			body[0] == 0xFF
			and
			body[1] == 0xD8
			and
			body[2] == 0xFF
		)


		if is_jpeg:

			load_error = image.load_jpg_from_buffer(
				body
			)


	# =============================================================
	# WEBP SIGNATURE
	#
	# RIFF....WEBP
	# =============================================================

	if (
		load_error != OK
		and
		body.size() >= 12
	):

		var is_webp: bool = (
			body[0] == 0x52
			and
			body[1] == 0x49
			and
			body[2] == 0x46
			and
			body[3] == 0x46
			and
			body[8] == 0x57
			and
			body[9] == 0x45
			and
			body[10] == 0x42
			and
			body[11] == 0x50
		)


		if is_webp:

			load_error = image.load_webp_from_buffer(
				body
			)


	# =============================================================
	# DECODE FAILED
	# =============================================================

	if load_error != OK:

		print(
			"[CIGA OUTPUT] LIVE IMAGE DECODE FAILED | ERROR=%s"
			%
			str(
				load_error
			)
		)

		return


	# =============================================================
	# ORIGINAL DIMENSIONS
	# =============================================================

	var original_width: int = image.get_width()

	var original_height: int = image.get_height()


	if (
		original_width <= 0
		or
		original_height <= 0
	):

		print(
			"[CIGA OUTPUT] LIVE IMAGE REJECTED | INVALID SIZE=%dx%d"
			%
			[
				original_width,
				original_height
			]
		)

		return


	# =============================================================
	# CONVERT TO RGBA8
	# =============================================================
	#
	# We always normalize the working image to RGBA8.
	#
	# This guarantees that:
	#
	#   - PNG transparency works
	#   - transparent canvas works
	#   - JPEG/WebP become compatible
	#   - saved output is always PNG
	#
	# =============================================================

	if image.get_format() != Image.FORMAT_RGBA8:

		image.convert(
			Image.FORMAT_RGBA8
		)


	# =============================================================
	# CREATE SQUARE TRANSPARENT CANVAS
	# =============================================================
	#
	# VERY IMPORTANT:
	#
	# We DO NOT crop transparent pixels from the original image.
	#
	# We preserve the complete original canvas and only add
	# transparent padding where required to make the canvas square.
	#
	# Example:
	#
	# Original = 800 x 500
	#
	# Result:
	# 800 x 800
	#
	# The original 800 x 500 image stays intact in the center.
	#
	# This keeps the scale based on the full image canvas rather
	# than changing the scale because of transparent margins.
	#
	# =============================================================

	var square_size: int = maxi(
		original_width,
		original_height
	)


	var normalized_image: Image = Image.create(
		square_size,
		square_size,
		false,
		Image.FORMAT_RGBA8
	)


	if normalized_image == null:

		print(
			"[CIGA OUTPUT] LIVE IMAGE FAILED | COULD NOT CREATE CANVAS"
		)

		return


	# Completely transparent background.
	normalized_image.fill(
		Color(
			1.0,
			1.0,
			1.0,
			0.0
		)
	)


	# =============================================================
	# CENTER ORIGINAL IMAGE
	# =============================================================

	var offset_x: int = (
		square_size
		-
		original_width
	) / 2


	var offset_y: int = (
		square_size
		-
		original_height
	) / 2


	normalized_image.blit_rect(
		image,
		Rect2i(
			0,
			0,
			original_width,
			original_height
		),
		Vector2i(
			offset_x,
			offset_y
		)
	)


	image = normalized_image


	# =============================================================
	# MAXIMUM DIMENSION 1080
	# =============================================================

	var processed_width: int = image.get_width()

	var processed_height: int = image.get_height()


	if (
		processed_width > CIGAIS_LIVE_IMAGE_MAX_DIMENSION
		or
		processed_height > CIGAIS_LIVE_IMAGE_MAX_DIMENSION
	):

		var resize_ratio: float = min(
			float(
				CIGAIS_LIVE_IMAGE_MAX_DIMENSION
			)
			/
			float(
				processed_width
			),
			float(
				CIGAIS_LIVE_IMAGE_MAX_DIMENSION
			)
			/
			float(
				processed_height
			)
		)


		var resized_width: int = maxi(
			1,
			int(
				round(
					float(
						processed_width
					)
					*
					resize_ratio
				)
			)
		)


		var resized_height: int = maxi(
			1,
			int(
				round(
					float(
						processed_height
					)
					*
					resize_ratio
				)
			)
		)


		image.resize(
			resized_width,
			resized_height,
			Image.INTERPOLATE_LANCZOS
		)


		processed_width = image.get_width()

		processed_height = image.get_height()


	# =============================================================
	# FINAL IMAGE SAFETY
	# =============================================================

	if image.is_empty():

		print(
			"[CIGA OUTPUT] LIVE IMAGE FAILED | IMAGE EMPTY AFTER PROCESSING"
		)

		return


	if (
		processed_width <= 0
		or
		processed_height <= 0
	):

		print(
			"[CIGA OUTPUT] LIVE IMAGE FAILED | INVALID PROCESSED SIZE"
		)

		return


	# =============================================================
	# CREATE TEMP DIRECTORY
	# =============================================================

	var temp_directory: String = (
		CIGAIS_LIVE_IMAGE_TEMP_DIR
	)


	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(
			temp_directory
		)
	)


	# =============================================================
	# UNIQUE FILE NAME
	# =============================================================

	cigais_live_image_counter += 1


	var timestamp: int = (
		Time.get_ticks_msec()
	)


	var temporary_path: String = (
		temp_directory
		+
		"/live_"
		+
		str(
			timestamp
		)
		+
		"_"
		+
		str(
			cigais_live_image_counter
		)
		+
		".png"
	)


	# =============================================================
	# SAVE LOCAL PNG
	# =============================================================

	var save_error: Error = (
		image.save_png(
			temporary_path
		)
	)


	if save_error != OK:

		log_error(
			SOURCE_CIGAIS_WORKER,
			"Failed to save live image locally: "
			+
			error_string(
				save_error
			)
		)

		return


	# =============================================================
	# BUILD LOCAL PAYLOAD
	# =============================================================

	var payload: Dictionary = (
		meta.duplicate(
			true
		)
	)


	payload["local_path"] = (
		temporary_path
	)


	payload["temporary"] = true


	payload["content_type"] = (
		"image/png"
	)


	payload["processed_width"] = (
		processed_width
	)


	payload["processed_height"] = (
		processed_height
	)


	payload["original_width"] = (
		original_width
	)


	payload["original_height"] = (
		original_height
	)


	payload["canvas_width"] = (
		processed_width
	)


	payload["canvas_height"] = (
		processed_height
	)


	payload["downloaded_size_bytes"] = (
		body.size()
	)


	payload["processed_format"] = (
		"PNG"
	)


	# =============================================================
	# LIVE IMAGE READY
	# =============================================================

	log_info(
		SOURCE_CIGAIS_WORKER,
		"LIVE IMAGE READY | "
		+
		str(
			payload.get(
				"filename",
				"live_image"
			)
		)
		+
		" | ORIGINAL="
		+
		str(
			original_width
		)
		+
		"x"
		+
		str(
			original_height
		)
		+
		" | PROCESSED="
		+
		str(
			processed_width
		)
		+
		"x"
		+
		str(
			processed_height
		)
	)


	log_info(
		SOURCE_CIGAIS_WORKER,
		"LIVE IMAGE TEMP CREATED | "
		+
		temporary_path
	)


	# =============================================================
	# EMIT
	# =============================================================
	#
	# IMPORTANT:
	#
	# No DISPLAY_IMAGE_LIVE timer starts here.
	#
	# This only means:
	#
	# "The image has finished loading and is ready to display."
	#
	# CIGAViewportRuntime is responsible for:
	#
	#   image received
	#        ->
	#   Sprite3D created
	#        ->
	#   Sprite3D added to viewport
	#        ->
	#   duration timer starts
	#
	# =============================================================

	live_image_received.emit(
		payload
	)


# =============================================================
# WORKER RECONNECT
# =============================================================

func _schedule_cigais_worker_reconnect() -> void:

	var guild_id := _get_cigais_worker_guild_id()


	if guild_id.is_empty():

		return


	var exponent: float = float(
		cigais_worker_reconnect_attempts
	)


	var delay: float = min(
		RECONNECT_BASE_DELAY
		*
		pow(
			2.0,
			exponent
		),
		RECONNECT_MAX_DELAY
	)


	cigais_worker_reconnect_attempts += 1

	cigais_worker_reconnect_timer = delay


	log_info(
		SOURCE_CIGAIS_WORKER,
		"Reconnect scheduled in %.1f seconds."
		%
		delay
	)


# =============================================================
# WORKER CLOSED
# =============================================================

func _handle_cigais_worker_closed() -> void:

	var close_code := -1

	var close_reason := ""


	if cigais_worker_socket != null:

		close_code = (
			cigais_worker_socket.get_close_code()
		)

		close_reason = (
			cigais_worker_socket.get_close_reason()
		)


	cigais_worker_socket = null

	cigais_worker_connected = false


	log_warning(
		SOURCE_CIGAIS_WORKER,
		"Worker connection lost. Code=%d Reason=%s"
		%
		[
			close_code,
			close_reason
		]
	)


	emit_status(
		SOURCE_CIGAIS_WORKER,
		"DISCONNECTED",
		"Worker connection lost."
	)


	_schedule_cigais_worker_reconnect()


# =============================================================
# DISCONNECT CIGAIS WORKER
# =============================================================

func disconnect_cigais_worker(
	disable_auto_connect: bool = false
) -> void:

	cigais_worker_reconnect_timer = 0.0

	cigais_worker_reconnect_attempts = 0

	cigais_worker_connected = false


	if disable_auto_connect:

		var config: Dictionary = (
			get_saved_source_config(
				SOURCE_CIGAIS_WORKER
			)
		)


		if not config.is_empty():

			config["guild_id"] = ""

			save_source_config(
				SOURCE_CIGAIS_WORKER,
				config
			)

			cigais_worker_guild_id = ""


	if cigais_worker_socket != null:

		var socket: WebSocketPeer = (
			cigais_worker_socket
		)


		cigais_worker_socket = null


		if (
			socket.get_ready_state()
			!=
			WebSocketPeer.STATE_CLOSED
		):

			socket.close(
				1000,
				"CIGA disconnect"
			)


	log_info(
		SOURCE_CIGAIS_WORKER,
		"Worker output stopped."
	)


	emit_status(
		SOURCE_CIGAIS_WORKER,
		"DISCONNECTED",
		"Worker output stopped."
	)


# =============================================================
# POLL CIGAIS WORKER
# =============================================================

func _poll_cigais_worker(
	delta: float
) -> void:

	if cigais_worker_socket == null:

		if cigais_worker_reconnect_timer > 0.0:

			cigais_worker_reconnect_timer -= delta


			if cigais_worker_reconnect_timer <= 0.0:

				_connect_cigais_worker()

		return


	cigais_worker_socket.poll()


	var state: WebSocketPeer.State = (
		cigais_worker_socket.get_ready_state()
	)


	match state:

		WebSocketPeer.STATE_CONNECTING:

			return


		WebSocketPeer.STATE_OPEN:

			if not cigais_worker_connected:

				cigais_worker_connected = true

				cigais_worker_reconnect_attempts = 0

				log_info(
					SOURCE_CIGAIS_WORKER,
					"Worker WebSocket connected."
				)


				emit_status(
					SOURCE_CIGAIS_WORKER,
					"CONNECTING",
					"Worker WebSocket connected. Registering..."
				)


				_register_cigais_worker()


			while (
				cigais_worker_socket
				.get_available_packet_count()
				>
				0
			):

				var packet: PackedByteArray = (
					cigais_worker_socket.get_packet()
				)


				if not cigais_worker_socket.was_string_packet():

					continue


				var text: String = (
					packet.get_string_from_utf8()
				)


				_handle_cigais_worker_message(
					text
				)


		WebSocketPeer.STATE_CLOSING:

			return


		WebSocketPeer.STATE_CLOSED:

			_handle_cigais_worker_closed()


# =============================================================
# POLL VTUBE STUDIO
# =============================================================

func _poll_vtube_studio(
	delta: float
) -> void:

	if vtube_studio_socket == null:

		if vtube_studio_reconnect_timer > 0.0:

			vtube_studio_reconnect_timer -= delta

			if vtube_studio_reconnect_timer <= 0.0:

				_attempt_vtube_studio_reconnect()

		return


	vtube_studio_socket.poll()


	var state: WebSocketPeer.State = (
		vtube_studio_socket.get_ready_state()
	)


	match state:

		WebSocketPeer.STATE_CONNECTING:

			return


		WebSocketPeer.STATE_OPEN:

			if not vtube_studio_connected:

				vtube_studio_connected = true

				vtube_studio_reconnect_attempts = 0

				log_info(
					SOURCE_VTUBESTUDIO,
					"WebSocket connection established."
				)


				emit_status(
					SOURCE_VTUBESTUDIO,
					"CONNECTING",
					"WebSocket connected. Starting authentication..."
				)


				if vtube_studio_token.is_empty():

					_request_vtube_studio_token()

				else:

					_authenticate_vtube_studio()


			while (
				vtube_studio_socket
				.get_available_packet_count()
				>
				0
			):

				var packet: PackedByteArray = (
					vtube_studio_socket.get_packet()
				)


				if not vtube_studio_socket.was_string_packet():

					continue


				var text: String = (
					packet.get_string_from_utf8()
				)


				_handle_vtube_studio_message(
					text
				)


		WebSocketPeer.STATE_CLOSING:

			return


		WebSocketPeer.STATE_CLOSED:

			_handle_vtube_studio_closed()


# =============================================================
# CONNECT ALL
# =============================================================

func connect_all_available() -> void:

	var connected_any: bool = false


	# =========================================================
	# CIGAIS WORKER
	# =========================================================

	if not _get_cigais_worker_guild_id().is_empty():

		connected_any = true

		_connect_cigais_worker()

	else:

		log_info(
			SOURCE_CIGAIS_WORKER,
			"No Discord Guild ID configured."
		)


	# =========================================================
	# STREAM ELEMENTS
	# =========================================================

	var se_config: Dictionary = (
		get_saved_source_config(
			SOURCE_STREAMELEMENTS
		)
	)


	var se_token: String = str(
		se_config.get(
			"token",
			""
		)
	)


	if not se_token.is_empty():

		connected_any = true

		log_info(
			SOURCE_STREAMELEMENTS,
			"Configured credentials found."
		)


		connect_streamelements(
			true
		)

	else:

		log_info(
			SOURCE_STREAMELEMENTS,
			"No credentials configured."
		)


	# =========================================================
	# VMC
	# =========================================================

	if vmc_runtime != null:

		connected_any = true

		log_info(
			SOURCE_VMC,
			"Starting VMC output..."
		)


		var vmc_status: String = (
		vmc_runtime.get_connection_status()
		)


		if vmc_status == "CONNECTED":

			log_info(
				SOURCE_VMC,
				"VMC output already active."
			)


			emit_status(
				SOURCE_VMC,
				"CONNECTED",
				"VMC output already active."
			)

		else:

			var started: bool = (
				vmc_runtime.connect_vmc()
			)


			if started:

				log_info(
					SOURCE_VMC,
					"VMC output started on UDP 127.0.0.1:39539."
				)


				emit_status(
					SOURCE_VMC,
					"CONNECTED",
					"VMC output active on UDP 127.0.0.1:39539."
				)

			else:

				log_error(
					SOURCE_VMC,
					"VMC output failed to start."
				)


				emit_status(
					SOURCE_VMC,
					"ERROR",
					"VMC output failed to start."
				)

	else:

		log_error(
			SOURCE_VMC,
			"VMC runtime unavailable."
		)


		emit_status(
			SOURCE_VMC,
			"ERROR",
			"VMC runtime unavailable."
		)


	# =========================================================
	# VTUBE STUDIO
	# =========================================================

	var vts_config: Dictionary = (
		get_saved_source_config(
			SOURCE_VTUBESTUDIO
		)
	)


	var vts_enabled: bool = bool(
		vts_config.get(
			"enabled",
			false
		)
	)


	if vts_enabled:

		connected_any = true

		log_info(
			SOURCE_VTUBESTUDIO,
			"VTube Studio output is enabled."
		)


		connect_vtube_studio(
			true
		)

	else:

		log_info(
			SOURCE_VTUBESTUDIO,
			"VTube Studio output not enabled."
		)


	if not connected_any:

		log_info(
			"OUTPUT",
			"No configured output connections available."
		)


# =============================================================
# CONNECT SOURCE
# =============================================================

func connect_source(
	source_id: String,
	save_auto_connect: bool = true
) -> void:

	match source_id:

		SOURCE_STREAMELEMENTS:

			connect_streamelements(
				save_auto_connect
			)


		SOURCE_VMC:

			connect_vmc()


		SOURCE_VTUBESTUDIO:

			connect_vtube_studio(
				save_auto_connect
			)


		SOURCE_CIGAIS_WORKER:

			_connect_cigais_worker()


		_:

			log_error(
				source_id,
				"Unknown output source."
			)


# =============================================================
# CONNECT VMC
# =============================================================

func connect_vmc() -> bool:

	if vmc_runtime == null:

		log_error(
			SOURCE_VMC,
			"VMC runtime unavailable."
		)


		emit_status(
			SOURCE_VMC,
			"ERROR",
			"VMC runtime unavailable."
		)


		return false


	var current_status: String = (
		vmc_runtime.get_connection_status()
	)


	if current_status == "CONNECTED":

		log_info(
			SOURCE_VMC,
			"VMC output already connected."
		)


		emit_status(
			SOURCE_VMC,
			"CONNECTED",
			"VMC output already active."
		)


		return true


	log_info(
		SOURCE_VMC,
		"Starting VMC output..."
	)


	var started: bool = (
		vmc_runtime.connect_vmc()
	)


	if started:

		log_info(
			SOURCE_VMC,
			"VMC output active on UDP 127.0.0.1:39539."
		)


		emit_status(
			SOURCE_VMC,
			"CONNECTED",
			"VMC output active on UDP 127.0.0.1:39539."
		)

	else:

		log_error(
			SOURCE_VMC,
			"VMC output failed to start."
		)


		emit_status(
			SOURCE_VMC,
			"ERROR",
			"VMC output failed to start."
		)


	return started


# =============================================================
# CONNECT VTUBE STUDIO
# =============================================================

func connect_vtube_studio(
	save_configuration: bool = true
) -> bool:

	var config: Dictionary = (
		get_saved_source_config(
			SOURCE_VTUBESTUDIO
		)
	)


	vtube_studio_plugin_name = str(
		config.get(
			"plugin_name",
			VTUBE_STUDIO_DEFAULT_PLUGIN_NAME
		)
	)


	vtube_studio_plugin_developer = str(
		config.get(
			"plugin_developer",
			VTUBE_STUDIO_DEFAULT_PLUGIN_DEVELOPER
		)
	)


	vtube_studio_token = str(
		config.get(
			"authentication_token",
			""
		)
	)


	if vtube_studio_plugin_name.length() < 3:

		vtube_studio_plugin_name = (
			VTUBE_STUDIO_DEFAULT_PLUGIN_NAME
		)


	if vtube_studio_plugin_developer.length() < 3:

		vtube_studio_plugin_developer = (
			VTUBE_STUDIO_DEFAULT_PLUGIN_DEVELOPER
		)


	if save_configuration:

		config["enabled"] = true

		config["plugin_name"] = (
			vtube_studio_plugin_name
		)

		config["plugin_developer"] = (
			vtube_studio_plugin_developer
		)

		config["authentication_token"] = (
			vtube_studio_token
		)


		save_source_config(
			SOURCE_VTUBESTUDIO,
			config
		)


	vtube_studio_manual_disconnect = false

	vtube_studio_reconnect_timer = 0.0

	vtube_studio_reconnect_attempts = 0

	vtube_studio_connected = false

	vtube_studio_authenticated = false

	vtube_studio_parameters_ready = false

	vtube_studio_send_timer = 0.0

	vtube_studio_model_inspection_requested = false

	vtube_studio_parameter_inspection_requested = false

	vtube_studio_input_parameter_inspection_requested = false

	vtube_studio_available_input_names.clear()


	if vtube_studio_socket != null:

		var current_state: WebSocketPeer.State = (
			vtube_studio_socket.get_ready_state()
		)


		if (
			current_state == WebSocketPeer.STATE_OPEN
			or
			current_state == WebSocketPeer.STATE_CONNECTING
		):

			log_info(
				SOURCE_VTUBESTUDIO,
				"Connection already active."
			)


			return true


		vtube_studio_socket = null


	vtube_studio_socket = WebSocketPeer.new()


	log_info(
		SOURCE_VTUBESTUDIO,
		"Connecting to VTube Studio..."
	)


	emit_status(
		SOURCE_VTUBESTUDIO,
		"CONNECTING",
		"Connecting to VTube Studio..."
	)


	var error: Error = (
		vtube_studio_socket.connect_to_url(
			VTUBE_STUDIO_URL
		)
	)


	if error != OK:

		log_error(
			SOURCE_VTUBESTUDIO,
			"WebSocket connection failed: "
			+
			error_string(
				error
			)
		)


		emit_status(
			SOURCE_VTUBESTUDIO,
			"ERROR",
			error_string(
				error
			)
		)


		vtube_studio_socket = null

		_schedule_vtube_studio_reconnect()

		return false


	return true


# =============================================================
# VTUBE STUDIO CLOSED
# =============================================================

func _handle_vtube_studio_closed() -> void:

	vtube_studio_connected = false

	vtube_studio_authenticated = false

	vtube_studio_parameters_ready = false

	vtube_studio_send_timer = 0.0

	vtube_studio_model_inspection_requested = false

	vtube_studio_parameter_inspection_requested = false

	vtube_studio_input_parameter_inspection_requested = false

	vtube_studio_pending_requests.clear()

	vtube_studio_available_input_names.clear()


	var close_code: int = -1

	var close_reason: String = ""


	if vtube_studio_socket != null:

		close_code = (
			vtube_studio_socket.get_close_code()
		)

		close_reason = (
			vtube_studio_socket.get_close_reason()
		)


	vtube_studio_socket = null


	if vtube_studio_manual_disconnect:

		return


	log_warning(
		SOURCE_VTUBESTUDIO,
		"VTube Studio connection lost. Code=%d Reason=%s"
		%
		[
			close_code,
			close_reason
		]
	)


	emit_status(
		SOURCE_VTUBESTUDIO,
		"DISCONNECTED",
		"Connection lost."
	)


	_schedule_vtube_studio_reconnect()


# =============================================================
# VTUBE STUDIO RECONNECT
# =============================================================

func _schedule_vtube_studio_reconnect() -> void:

	if vtube_studio_manual_disconnect:

		return


	var config: Dictionary = (
		get_saved_source_config(
			SOURCE_VTUBESTUDIO
		)
	)


	if config.is_empty():

		return


	if not bool(
		config.get(
			"enabled",
			false
		)
	):

		return


	var exponent: float = float(
		vtube_studio_reconnect_attempts
	)


	var delay: float = min(
		RECONNECT_BASE_DELAY
		*
		pow(
			2.0,
			exponent
		),
		RECONNECT_MAX_DELAY
	)


	vtube_studio_reconnect_attempts += 1

	vtube_studio_reconnect_timer = delay


	log_info(
		SOURCE_VTUBESTUDIO,
		"Reconnect scheduled in %.1f seconds."
		%
		delay
	)


# =============================================================
# VTUBE STUDIO RECONNECT ATTEMPT
# =============================================================

func _attempt_vtube_studio_reconnect() -> void:

	if vtube_studio_manual_disconnect:

		return


	log_info(
		SOURCE_VTUBESTUDIO,
		"Attempting VTube Studio reconnect..."
	)


	connect_vtube_studio(
		true
	)


# =============================================================
# VTUBE STUDIO MESSAGE
# =============================================================

func _handle_vtube_studio_message(
	raw_text: String
) -> void:

	if raw_text.is_empty():

		return


	var parsed: Variant = (
		JSON.parse_string(
			raw_text
		)
	)


	if not parsed is Dictionary:

		return


	var message: Dictionary = (
		parsed as Dictionary
	)


	var message_type: String = str(
		message.get(
			"messageType",
			""
		)
	)


	var request_id: String = str(
		message.get(
			"requestID",
			""
		)
	)


	match message_type:

		"AuthenticationTokenResponse":

			_handle_vtube_studio_token_response(
				message
			)


		"AuthenticationResponse":

			_handle_vtube_studio_auth_response(
				message
			)


		"APIStateResponse":

			log_info(
				SOURCE_VTUBESTUDIO,
				"VTube Studio API state received."
			)


		"ParameterCreationResponse":

			pass


		"CurrentModelResponse":

			_handle_vtube_studio_current_model_response(
				message
			)


		"Live2DParameterListResponse":

			_handle_vtube_studio_live2d_parameter_list_response(
				message
			)


		"InputParameterListResponse":

			_handle_vtube_studio_input_parameter_list_response(
				message
			)


		"InjectParameterDataResponse":

			pass


		"APIError":

			_handle_vtube_studio_error(
				message
			)


	if not request_id.is_empty():

		vtube_studio_pending_requests.erase(
			request_id
		)


# =============================================================
# TOKEN RESPONSE
# =============================================================

func _handle_vtube_studio_token_response(
	message: Dictionary
) -> void:

	var data_value: Variant = (
		message.get(
			"data",
			{}
		)
	)


	if not data_value is Dictionary:

		return


	var data: Dictionary = (
		data_value as Dictionary
	)


	var token: String = str(
		data.get(
			"authenticationToken",
			""
		)
	)


	if token.is_empty():

		log_error(
			SOURCE_VTUBESTUDIO,
			"VTube Studio did not return an authentication token."
		)


		emit_status(
			SOURCE_VTUBESTUDIO,
			"ERROR",
			"Authentication token was not returned."
		)


		return


	vtube_studio_token = token


	var config: Dictionary = (
		get_saved_source_config(
			SOURCE_VTUBESTUDIO
		)
	)


	config["enabled"] = true

	config["plugin_name"] = (
		vtube_studio_plugin_name
	)

	config["plugin_developer"] = (
		vtube_studio_plugin_developer
	)

	config["authentication_token"] = token


	save_source_config(
		SOURCE_VTUBESTUDIO,
		config
	)


	log_info(
		SOURCE_VTUBESTUDIO,
		"Authentication token received and saved."
	)


	_authenticate_vtube_studio()


# =============================================================
# AUTH RESPONSE
# =============================================================

func _handle_vtube_studio_auth_response(
	message: Dictionary
) -> void:

	var data_value: Variant = (
		message.get(
			"data",
			{}
		)
	)


	if not data_value is Dictionary:

		return


	var data: Dictionary = (
		data_value as Dictionary
	)


	var authenticated: bool = bool(
		data.get(
			"authenticated",
			false
		)
	)


	if not authenticated:

		vtube_studio_authenticated = false

		vtube_studio_parameters_ready = false


		log_error(
			SOURCE_VTUBESTUDIO,
			"VTube Studio authentication failed."
		)


		emit_status(
			SOURCE_VTUBESTUDIO,
			"ERROR",
			"Authentication failed."
		)


		return


	vtube_studio_authenticated = true

	vtube_studio_reconnect_attempts = 0


	log_info(
		SOURCE_VTUBESTUDIO,
		"VTube Studio authenticated."
	)


	emit_status(
		SOURCE_VTUBESTUDIO,
		"CONNECTED",
		"VTube Studio authenticated."
	)


	_create_vtube_studio_custom_parameters()

	_request_vtube_studio_model_inspection()


# =============================================================
# REQUEST MODEL INSPECTION
# =============================================================

func _request_vtube_studio_model_inspection() -> void:

	if not vtube_studio_authenticated:

		return


	if vtube_studio_model_inspection_requested:

		return


	vtube_studio_model_inspection_requested = true


	var current_model_request: Dictionary = {

		"apiName":
			VTUBE_STUDIO_API_NAME,

		"apiVersion":
			VTUBE_STUDIO_API_VERSION,

		"requestID":
			_make_vts_request_id(),

		"messageType":
			"CurrentModelRequest",

		"data":
			{}
	}


	var live2d_parameter_request: Dictionary = {

		"apiName":
			VTUBE_STUDIO_API_NAME,

		"apiVersion":
			VTUBE_STUDIO_API_VERSION,

		"requestID":
			_make_vts_request_id(),

		"messageType":
			"Live2DParameterListRequest",

		"data":
			{}
	}


	var input_parameter_request: Dictionary = {

		"apiName":
			VTUBE_STUDIO_API_NAME,

		"apiVersion":
			VTUBE_STUDIO_API_VERSION,

		"requestID":
			_make_vts_request_id(),

		"messageType":
			"InputParameterListRequest",

		"data":
			{}
	}


	_send_vtube_studio_request(
		current_model_request
	)


	_send_vtube_studio_request(
		live2d_parameter_request
	)


	_send_vtube_studio_request(
		input_parameter_request
	)


	vtube_studio_input_parameter_inspection_requested = true


# =============================================================
# CURRENT MODEL RESPONSE
# =============================================================

func _handle_vtube_studio_current_model_response(
	message: Dictionary
) -> void:

	var data_value: Variant = (
		message.get(
			"data",
			{}
		)
	)


	if not data_value is Dictionary:

		return


	var data: Dictionary = (
		data_value as Dictionary
	)


	var model_loaded: bool = bool(
		data.get(
			"modelLoaded",
			false
		)
	)


	var model_name: String = str(
		data.get(
			"modelName",
			""
		)
	)


	var model_id: String = str(
		data.get(
			"modelID",
			""
		)
	)


	var vts_model_name: String = str(
		data.get(
			"vtsModelName",
			""
		)
	)


	var live2d_model_name: String = str(
		data.get(
			"live2DModelName",
			""
		)
	)


# =============================================================
# LIVE2D PARAMETER RESPONSE
# =============================================================

func _handle_vtube_studio_live2d_parameter_list_response(
	message: Dictionary
) -> void:

	var data_value: Variant = (
		message.get(
			"data",
			{}
		)
	)


	if not data_value is Dictionary:

		return


	var data: Dictionary = (
		data_value as Dictionary
	)


	var model_loaded: bool = bool(
		data.get(
			"modelLoaded",
			false
		)
	)


	var model_name: String = str(
		data.get(
			"modelName",
			""
		)
	)


	var parameters_value: Variant = (
		data.get(
			"parameters",
			[]
		)
	)


	if not parameters_value is Array:

		return


	var parameters: Array = (
		parameters_value as Array
	)


	# A lista é recebida apenas para inspeção interna.
	# Não imprimimos os 200+ parâmetros no Output.


# =============================================================
# INPUT PARAMETER RESPONSE
#
# INSPECTION ONLY.
#
# Não tentamos inferir Body / Left / Right pelos nomes.
# =============================================================

func _handle_vtube_studio_input_parameter_list_response(
	message: Dictionary
) -> void:

	var data_value: Variant = (
		message.get(
			"data",
			{}
		)
	)


	if not data_value is Dictionary:

		return


	var data: Dictionary = (
		data_value as Dictionary
	)


	var default_parameters_value: Variant = (
		data.get(
			"defaultParameters",
			[]
		)
	)


	var custom_parameters_value: Variant = (
		data.get(
			"customParameters",
			[]
		)
	)


	var default_parameters: Array = (
		default_parameters_value as Array
		if default_parameters_value is Array
		else
		[]
	)


	var custom_parameters: Array = (
		custom_parameters_value as Array
		if custom_parameters_value is Array
		else
		[]


	)


	vtube_studio_available_input_names.clear()


	for parameter_value: Variant in default_parameters:

		if not parameter_value is Dictionary:

			continue


		var parameter: Dictionary = (
			parameter_value as Dictionary
		)


		var parameter_name: String = str(
			parameter.get(
				"name",
				""
			)
		)


		if parameter_name.is_empty():

			continue


		if not vtube_studio_available_input_names.has(
			parameter_name
		):

			vtube_studio_available_input_names.append(
				parameter_name
			)


	for parameter_value: Variant in custom_parameters:

		if not parameter_value is Dictionary:

			continue


		var parameter: Dictionary = (
			parameter_value as Dictionary
		)


		var parameter_name: String = str(
			parameter.get(
				"name",
				""
			)
		)


		if parameter_name.is_empty():

			continue


		if not vtube_studio_available_input_names.has(
			parameter_name
		):

			vtube_studio_available_input_names.append(
				parameter_name
			)


	# Não imprimimos a lista completa de inputs.


# =============================================================
# VTS ERROR
# =============================================================

func _handle_vtube_studio_error(
	message: Dictionary
) -> void:

	var data_value: Variant = (
		message.get(
			"data",
			{}
		)
	)


	var error_message: String = (
		"Unknown VTube Studio API error."
	)


	if data_value is Dictionary:

		var data: Dictionary = (
			data_value as Dictionary
		)


		error_message = str(
			data.get(
				"message",
				error_message
			)
		)


	log_error(
		SOURCE_VTUBESTUDIO,
		error_message
	)


	emit_status(
		SOURCE_VTUBESTUDIO,
		"ERROR",
		error_message
	)


# =============================================================
# AUTHENTICATE
# =============================================================

func _authenticate_vtube_studio() -> void:

	if vtube_studio_socket == null:

		return


	if (
		vtube_studio_socket.get_ready_state()
		!=
		WebSocketPeer.STATE_OPEN
	):

		return


	if vtube_studio_token.is_empty():

		_request_vtube_studio_token()

		return


	var request: Dictionary = {

		"apiName":
			VTUBE_STUDIO_API_NAME,

		"apiVersion":
			VTUBE_STUDIO_API_VERSION,

		"requestID":
			_make_vts_request_id(),

		"messageType":
			"AuthenticationRequest",

		"data":
			{
				"pluginName":
					vtube_studio_plugin_name,

				"pluginDeveloper":
					vtube_studio_plugin_developer,

				"authenticationToken":
					vtube_studio_token
			}
	}


	_send_vtube_studio_request(
		request
	)


# =============================================================
# REQUEST TOKEN
# =============================================================

func _request_vtube_studio_token() -> void:

	if vtube_studio_socket == null:

		return


	var request: Dictionary = {

		"apiName":
			VTUBE_STUDIO_API_NAME,

		"apiVersion":
			VTUBE_STUDIO_API_VERSION,

		"requestID":
			_make_vts_request_id(),

		"messageType":
			"AuthenticationTokenRequest",

		"data":
			{
				"pluginName":
					vtube_studio_plugin_name,

				"pluginDeveloper":
					vtube_studio_plugin_developer
			}
	}


	log_info(
		SOURCE_VTUBESTUDIO,
		"Requesting VTube Studio plugin permission."
	)


	_send_vtube_studio_request(
		request
	)


# =============================================================
# CUSTOM PARAMETERS
# =============================================================

func _create_vtube_studio_custom_parameters() -> void:

	if not vtube_studio_authenticated:

		return


	var parameters: Array[String] = [

		VTS_PARAM_BODY_YAW,

		VTS_PARAM_BODY_PITCH,

		VTS_PARAM_BODY_ROLL,

		VTS_PARAM_LEFT_ARM,

		VTS_PARAM_RIGHT_ARM,

		VTS_PARAM_ROOT_X
	]


	for parameter_name: String in parameters:

		var request: Dictionary = {

			"apiName":
				VTUBE_STUDIO_API_NAME,

			"apiVersion":
				VTUBE_STUDIO_API_VERSION,

			"requestID":
				_make_vts_request_id(),

			"messageType":
				"ParameterCreationRequest",

			"data":
				{
					"parameterName":
						parameter_name,

					"explanation":
						(
							"CIGA output parameter: "
							+
							parameter_name
						),

					"min":
						-1.0,

					"max":
						1.0,

					"defaultValue":
						0.0
				}
		}


		_send_vtube_studio_request(
			request
		)


	vtube_studio_parameters_ready = true


	log_info(
		SOURCE_VTUBESTUDIO,
		"VTube Studio output parameters ready."
	)


# =============================================================
# UPDATE VTS OUTPUT
# =============================================================

func _update_vtube_studio_output(
	delta: float
) -> void:

	if not vtube_studio_authenticated:

		return


	if not vtube_studio_parameters_ready:

		return


	vtube_studio_send_timer += delta


	if vtube_studio_send_timer < VTUBE_STUDIO_SEND_INTERVAL:

		return


	vtube_studio_send_timer = 0.0


	var state: Dictionary = (
		_get_vtube_studio_state()
	)


	if state.is_empty():

		return


	_send_vtube_studio_parameters(
		state
	)


# =============================================================
# GET VTS STATE
# =============================================================

func _get_vtube_studio_state() -> Dictionary:

	if vmc_runtime == null:

		return {}


	if not vmc_runtime.has_method(
		"get_2d_output_state"
	):

		return {}


	var value: Variant = (
		vmc_runtime.call(
			"get_2d_output_state"
		)
	)


	if not value is Dictionary:

		return {}


	return (
		value as Dictionary
	)


# =============================================================
# STATE VECTOR3 HELPER
# =============================================================

func _get_state_vector3(
	state: Dictionary,
	key: String
) -> Vector3:

	var value: Variant = (
		state.get(
			key,
			Vector3.ZERO
		)
	)


	if value is Vector3:

		return value as Vector3


	return Vector3.ZERO


# =============================================================
# VTS OUTPUT
# =============================================================

func _send_vtube_studio_parameters(
	state: Dictionary
) -> void:

	if not vtube_studio_connected:

		return


	if not vtube_studio_authenticated:

		return


	if state.is_empty():

		return


	# ============================================================
	# STATE
	# ============================================================

	var head_rotation: Vector3 = (
		state.get(
			"head_rotation",
			Vector3.ZERO
		)
	)


	var body_rotation: Vector3 = (
		state.get(
			"body_rotation",
			Vector3.ZERO
		)
	)


	var root_x: float = float(
		state.get(
			"root_x",
			0.0
		)
	)


	var left_arm: float = float(
		state.get(
			"left_arm",
			0.0
		)
	)


	var right_arm: float = float(
		state.get(
			"right_arm",
			0.0
		)
	)


	var impact_hit_point: String = str(
		state.get(
			"impact_hit_point",
			""
		)
	)


	var impact_recent: bool = bool(
		state.get(
			"impact_recent",
			false
		)
	)


	# ============================================================
	# BODY ROTATION
	# ============================================================

	var body_pitch_degrees: float = rad_to_deg(
		body_rotation.x
	)


	var body_yaw_degrees: float = rad_to_deg(
		body_rotation.y
	)


	var body_roll_degrees: float = rad_to_deg(
		body_rotation.z
	)


	# ============================================================
	# ADAPTIVE IMPACT GAIN
	# ============================================================

	var body_strength: float = max(
		absf(
			body_pitch_degrees
		),
		max(
			absf(
				body_yaw_degrees
			),
			absf(
				body_roll_degrees
			)
		)
	)


	var impact_gain: float = 1.0


	if body_strength < 1.0:

		impact_gain = 24.0

	elif body_strength < 2.0:

		impact_gain = 18.0

	elif body_strength < 3.5:

		impact_gain = 13.5

	elif body_strength < 5.0:

		impact_gain = 10.5

	else:

		impact_gain = 7.5


	if impact_recent:

		body_pitch_degrees *= impact_gain

		body_yaw_degrees *= impact_gain

		body_roll_degrees *= impact_gain


	# ============================================================
	# BODY LIMITS
	# ============================================================

	body_pitch_degrees = clampf(
		body_pitch_degrees,
		-20.0,
		20.0
	)


	body_yaw_degrees = clampf(
		body_yaw_degrees,
		-20.0,
		20.0
	)


	body_roll_degrees = clampf(
		body_roll_degrees,
		-20.0,
		20.0
	)


	# ============================================================
	# CIGA NORMALIZED BODY
	# ============================================================

	var ciga_body_pitch: float = clampf(
		body_pitch_degrees / 20.0,
		-1.0,
		1.0
	)


	var ciga_body_yaw: float = clampf(
		body_yaw_degrees / 20.0,
		-1.0,
		1.0
	)


	var ciga_body_roll: float = clampf(
		body_roll_degrees / 20.0,
		-1.0,
		1.0
	)


	# ============================================================
	# OTHER VALUES
	# ============================================================

	root_x = clampf(
		root_x,
		-1.0,
		1.0
	)


	left_arm = clampf(
		left_arm,
		-1.0,
		1.0
	)


	right_arm = clampf(
		right_arm,
		-1.0,
		1.0
	)


	# ============================================================
	# BODY -> HEAD MIX
	# ============================================================

	var body_to_head_mix: float = 0.0


	if impact_recent:

		if impact_hit_point == "HeadHitPoint":

			body_to_head_mix = 0.25

		elif impact_hit_point == "ChestHitPoint":

			body_to_head_mix = 0.80

		elif (
			impact_hit_point.contains(
				"Shoulder"
			)
			or
			impact_hit_point.contains(
				"Arm"
			)
		):

			body_to_head_mix = 0.70

		elif impact_hit_point.contains(
			"Leg"
		):

			body_to_head_mix = 0.50

		else:

			body_to_head_mix = 0.60


	# ============================================================
	# VISUAL HEAD ROTATION
	# ============================================================

	var visual_head_rotation: Vector3 = (
		head_rotation
	)


	if body_to_head_mix > 0.0:

		visual_head_rotation += (
			Vector3(
				deg_to_rad(
					body_pitch_degrees
				),

				deg_to_rad(
					body_yaw_degrees
				),

				deg_to_rad(
					body_roll_degrees
				)
			)
			*
			body_to_head_mix
		)


	# ============================================================
	# HEAD -> DEGREES
	# ============================================================

	var head_pitch_degrees: float = rad_to_deg(
		visual_head_rotation.x
	)


	var head_yaw_degrees: float = rad_to_deg(
		visual_head_rotation.y
	)


	var head_roll_degrees: float = rad_to_deg(
		visual_head_rotation.z
	)


	# ============================================================
	# HEAD LIMITS
	# ============================================================

	head_pitch_degrees = clampf(
		head_pitch_degrees,
		-30.0,
		30.0
	)


	head_yaw_degrees = clampf(
		head_yaw_degrees,
		-30.0,
		30.0
	)


	head_roll_degrees = clampf(
		head_roll_degrees,
		-90.0,
		90.0
	)


	# ============================================================
	# SET PARAMETERS
	# ============================================================

	var set_parameter_values: Array[Dictionary] = []


	# ------------------------------------------------------------
	# CIGA BODY PARAMETERS
	# ------------------------------------------------------------

	set_parameter_values.append(
		{
			"id":
				VTS_PARAM_BODY_YAW,

			"value":
				ciga_body_yaw,

			"weight":
				1.0
		}
	)


	set_parameter_values.append(
		{
			"id":
				VTS_PARAM_BODY_PITCH,

			"value":
				ciga_body_pitch,

			"weight":
				1.0
		}
	)


	set_parameter_values.append(
		{
			"id":
				VTS_PARAM_BODY_ROLL,

			"value":
				ciga_body_roll,

			"weight":
				1.0
		}
	)


	# ------------------------------------------------------------
	# ARMS
	# ------------------------------------------------------------

	set_parameter_values.append(
		{
			"id":
				VTS_PARAM_LEFT_ARM,

			"value":
				left_arm,

			"weight":
				1.0
		}
	)


	set_parameter_values.append(
		{
			"id":
				VTS_PARAM_RIGHT_ARM,

			"value":
				right_arm,

			"weight":
				1.0
		}
	)


	# ------------------------------------------------------------
	# ROOT
	# ------------------------------------------------------------

	set_parameter_values.append(
		{
			"id":
				VTS_PARAM_ROOT_X,

			"value":
				root_x,

			"weight":
				1.0
		}
	)


	# ------------------------------------------------------------
	# VTS BODY INPUTS
	# ------------------------------------------------------------

	set_parameter_values.append(
		{
			"id":
				"MocopiBodyAngleX",

			"value":
				body_pitch_degrees,

			"weight":
				1.0
		}
	)


	set_parameter_values.append(
		{
			"id":
				"MocopiBodyAngleY",

			"value":
				body_yaw_degrees,

			"weight":
				1.0
		}
	)


	set_parameter_values.append(
		{
			"id":
				"MocopiBodyAngleZ",

			"value":
				body_roll_degrees,

			"weight":
				1.0
		}
	)


	# ============================================================
	# SET REQUEST
	# ============================================================

	var set_request: Dictionary = {

		"apiName":
			VTUBE_STUDIO_API_NAME,

		"apiVersion":
			VTUBE_STUDIO_API_VERSION,

		"requestID":
			_make_vts_request_id(),

		"messageType":
			"InjectParameterDataRequest",

		"data":
			{
				"faceFound":
					true,

				"mode":
					"set",

				"parameterValues":
					set_parameter_values
			}
	}


	_send_vtube_studio_request(
		set_request
	)


	# ============================================================
	# ADD FACE TRACKING REQUEST
	# ============================================================

	var add_parameter_values: Array[Dictionary] = []


	add_parameter_values.append(
		{
			"id":
				"FaceAngleX",

			"value":
				head_pitch_degrees
		}
	)


	add_parameter_values.append(
		{
			"id":
				"FaceAngleY",

			"value":
				head_yaw_degrees
		}
	)


	add_parameter_values.append(
		{
			"id":
				"FaceAngleZ",

			"value":
				head_roll_degrees
		}
	)


	var add_request: Dictionary = {

		"apiName":
			VTUBE_STUDIO_API_NAME,

		"apiVersion":
			VTUBE_STUDIO_API_VERSION,

		"requestID":
			_make_vts_request_id(),

		"messageType":
			"InjectParameterDataRequest",

		"data":
			{
				"faceFound":
					true,

				"mode":
					"add",

				"parameterValues":
					add_parameter_values
			}
	}


	_send_vtube_studio_request(
		add_request
	)


# =============================================================
# SEND VTS REQUEST
# =============================================================

func _send_vtube_studio_request(
	request: Dictionary
) -> bool:

	if vtube_studio_socket == null:

		return false


	if (
		vtube_studio_socket.get_ready_state()
		!=
		WebSocketPeer.STATE_OPEN
	):

		return false


	var request_id: String = str(
		request.get(
			"requestID",
			""
		)
	)


	if not request_id.is_empty():

		vtube_studio_pending_requests[
			request_id
		] = (
			request.get(
				"messageType",
				""
			)
		)


	var error: Error = (
		vtube_studio_socket.send_text(
			JSON.stringify(
				request
			)
		)
	)


	if error != OK:

		log_error(
			SOURCE_VTUBESTUDIO,
			"VTube Studio request failed: "
			+
			error_string(
				error
			)
		)


		if not request_id.is_empty():

			vtube_studio_pending_requests.erase(
				request_id
			)


		return false


	return true


# =============================================================
# VTS REQUEST ID
# =============================================================

func _make_vts_request_id() -> String:

	vtube_studio_request_counter += 1


	return (
		"ciga-vts-"
		+
		str(
			Time.get_ticks_usec()
		)
		+
		"-"
		+
		str(
			vtube_studio_request_counter
		)
	)


# =============================================================
# DISCONNECT SOURCE
# =============================================================

func disconnect_source(
	source_id: String
) -> void:

	match source_id:

		SOURCE_STREAMELEMENTS:

			disconnect_streamelements(
				true
			)


		SOURCE_VMC:

			disconnect_vmc_source()


		SOURCE_VTUBESTUDIO:

			disconnect_vtube_studio(
				true
			)


		SOURCE_CIGAIS_WORKER:

			disconnect_cigais_worker(
				false
			)


		_:

			log_warning(
				source_id,
				"No active runtime connection."
			)


# =============================================================
# DISCONNECT VMC
# =============================================================

func disconnect_vmc_source() -> void:

	if vmc_runtime == null:

		return


	if vmc_runtime.has_method(
		"disconnect_vmc"
	):

		vmc_runtime.call(
			"disconnect_vmc"
		)


	log_info(
		SOURCE_VMC,
		"VMC output stopped."
	)


	emit_status(
		SOURCE_VMC,
		"DISCONNECTED",
		"VMC output stopped."
	)


# =============================================================
# DISCONNECT VTUBE STUDIO
# =============================================================

func disconnect_vtube_studio(
	disable_auto_connect: bool = true
) -> void:

	vtube_studio_manual_disconnect = true

	vtube_studio_reconnect_timer = 0.0

	vtube_studio_reconnect_attempts = 0

	vtube_studio_connected = false

	vtube_studio_authenticated = false

	vtube_studio_parameters_ready = false

	vtube_studio_send_timer = 0.0

	vtube_studio_model_inspection_requested = false

	vtube_studio_parameter_inspection_requested = false

	vtube_studio_input_parameter_inspection_requested = false

	vtube_studio_available_input_names.clear()


	if disable_auto_connect:

		var config: Dictionary = (
			get_saved_source_config(
				SOURCE_VTUBESTUDIO
			)
		)


		if not config.is_empty():

			config["enabled"] = false


			save_source_config(
				SOURCE_VTUBESTUDIO,
				config
			)


	if vtube_studio_socket != null:

		var socket: WebSocketPeer = (
			vtube_studio_socket
		)


		vtube_studio_socket = null


		if (
			socket.get_ready_state()
			!=
			WebSocketPeer.STATE_CLOSED
		):

			socket.close(
				1000,
				"CIGA disconnect"
			)


	log_info(
		SOURCE_VTUBESTUDIO,
		"VTube Studio output stopped."
	)


	emit_status(
		SOURCE_VTUBESTUDIO,
		"DISCONNECTED",
		"VTube Studio output stopped."
	)


# =============================================================
# STREAM ELEMENTS
# =============================================================

func connect_streamelements(
	save_auto_connect: bool = true
) -> void:

	var config: Dictionary = (
		get_saved_source_config(
			SOURCE_STREAMELEMENTS
		)
	)


	if config.is_empty():

		log_error(
			SOURCE_STREAMELEMENTS,
			"No StreamElements configuration found."
		)


		emit_status(
			SOURCE_STREAMELEMENTS,
			"ERROR",
			"No configuration found."
		)


		return


	var token: String = str(
		config.get(
			"token",
			""
		)
	)


	if token.is_empty():

		log_error(
			SOURCE_STREAMELEMENTS,
			"No StreamElements token configured."
		)


		emit_status(
			SOURCE_STREAMELEMENTS,
			"ERROR",
			"Token is empty."
		)


		return


	var token_type: String = str(
		config.get(
			"token_type",
			"apikey"
		)
	)


	if (
		token_type != "apikey"
		and
		token_type != "jwt"
		and
		token_type != "oauth2"
	):

		token_type = "apikey"


	if save_auto_connect:

		config["auto_connect"] = true


		save_source_config(
			SOURCE_STREAMELEMENTS,
			config
		)


	streamelements_config = (
		config.duplicate(
			true
		)
	)


	streamelements_manual_disconnect = false

	streamelements_reconnect_timer = 0.0

	streamelements_reconnect_attempts = 0

	streamelements_connected = false

	streamelements_authenticated = false

	streamelements_subscribed = false

	streamelements_stability_timer = 0.0


	if streamelements_socket != null:

		var current_state: WebSocketPeer.State = (
			streamelements_socket.get_ready_state()
		)


		if (
			current_state == WebSocketPeer.STATE_OPEN
			or
			current_state == WebSocketPeer.STATE_CONNECTING
		):

			log_info(
				SOURCE_STREAMELEMENTS,
				"Connection already active."
			)


			return


		streamelements_socket = null


	streamelements_socket = WebSocketPeer.new()


	log_info(
		SOURCE_STREAMELEMENTS,
		"Connecting to StreamElements Astro..."
	)


	emit_status(
		SOURCE_STREAMELEMENTS,
		"CONNECTING",
		"Connecting to StreamElements Astro..."
	)


	var url: String = (
		STREAMELEMENTS_URL
	)


	var reconnect_token: String = str(
		config.get(
			"reconnect_token",
			""
		)
	)


	if not reconnect_token.is_empty():

		url += (
			"?reconnect_token="
			+
			reconnect_token.uri_encode()
		)


	var error: Error = (
		streamelements_socket.connect_to_url(
			url
		)
	)


	if error != OK:

		log_error(
			SOURCE_STREAMELEMENTS,
			"WebSocket connection failed: "
			+
			error_string(
				error
			)
		)


		emit_status(
			SOURCE_STREAMELEMENTS,
			"ERROR",
			error_string(
				error
			)
		)


		streamelements_socket = null

		_schedule_reconnect()

		return


	log_info(
		SOURCE_STREAMELEMENTS,
		"WebSocket connection request accepted."
	)


# =============================================================
# DISCONNECT STREAM ELEMENTS
# =============================================================

func disconnect_streamelements(
	disable_auto_connect: bool = true
) -> void:

	streamelements_manual_disconnect = true

	streamelements_reconnect_timer = 0.0

	streamelements_reconnect_attempts = 0

	streamelements_connected = false

	streamelements_authenticated = false

	streamelements_subscribed = false

	streamelements_stability_timer = 0.0


	if disable_auto_connect:

		var config: Dictionary = (
			get_saved_source_config(
				SOURCE_STREAMELEMENTS
			)
		)


		if not config.is_empty():

			config["auto_connect"] = false

			config.erase(
				"reconnect_token"
			)


			save_source_config(
				SOURCE_STREAMELEMENTS,
				config
			)


	if streamelements_socket != null:

		var socket: WebSocketPeer = (
			streamelements_socket
		)


		streamelements_socket = null


		if (
			socket.get_ready_state()
			!=
			WebSocketPeer.STATE_CLOSED
		):

			socket.close(
				1000,
				"CIGA disconnect"
			)


	log_info(
		SOURCE_STREAMELEMENTS,
		"Disconnected."
	)


	emit_status(
		SOURCE_STREAMELEMENTS,
		"DISCONNECTED",
		"Disconnected."
	)


# =============================================================
# HANDLE STREAM ELEMENTS CLOSED
# =============================================================

func _handle_streamelements_closed() -> void:

	var close_code: int = -1

	var close_reason: String = ""


	if streamelements_socket != null:

		close_code = (
			streamelements_socket.get_close_code()
		)

		close_reason = (
			streamelements_socket.get_close_reason()
		)


	streamelements_socket = null

	streamelements_connected = false

	streamelements_authenticated = false

	streamelements_subscribed = false

	streamelements_stability_timer = 0.0


	if streamelements_manual_disconnect:

		return


	log_warning(
		SOURCE_STREAMELEMENTS,
		"Connection lost. Code=%d Reason=%s"
		%
		[
			close_code,
			close_reason
		]
	)


	emit_status(
		SOURCE_STREAMELEMENTS,
		"DISCONNECTED",
		"Connection lost."
	)


	_schedule_reconnect()


# =============================================================
# STREAM ELEMENTS RECONNECT
# =============================================================

func _schedule_reconnect() -> void:

	if streamelements_manual_disconnect:

		return


	var config: Dictionary = (
		get_saved_source_config(
			SOURCE_STREAMELEMENTS
		)
	)


	if config.is_empty():

		return


	var auto_connect: bool = bool(
		config.get(
			"auto_connect",
			false
		)
	)


	if not auto_connect:

		return


	var exponent: float = float(
		streamelements_reconnect_attempts
	)


	var delay: float = min(
		RECONNECT_BASE_DELAY
		*
		pow(
			2.0,
			exponent
		),
		RECONNECT_MAX_DELAY
	)


	streamelements_reconnect_attempts += 1

	streamelements_reconnect_timer = delay


	log_info(
		SOURCE_STREAMELEMENTS,
		"Reconnect scheduled in %.1f seconds."
		%
		delay
	)


# =============================================================
# STREAM ELEMENTS RECONNECT ATTEMPT
# =============================================================

func _attempt_streamelements_reconnect() -> void:

	connect_streamelements(
		true
	)


# =============================================================
# STREAM ELEMENTS MESSAGE
# =============================================================

func _handle_streamelements_message(
	raw_text: String
) -> void:

	if raw_text.is_empty():

		return


	var parsed: Variant = JSON.parse_string(
		raw_text
	)


	if not parsed is Dictionary:

		return


	var message: Dictionary = (
		parsed as Dictionary
	)


	match str(
		message.get(
			"type",
			""
		)
	):

		"welcome":

			_handle_streamelements_welcome(
				message
			)


		"response":

			_handle_streamelements_response(
				message
			)


		"message":

			_handle_streamelements_event_message(
				message
			)


		"reconnect":

			_handle_streamelements_reconnect(
				message
			)


		"error":

			log_error(
				SOURCE_STREAMELEMENTS,
				str(
					message
				)
			)


# =============================================================
# WELCOME
# =============================================================

func _handle_streamelements_welcome(
	_message: Dictionary
) -> void:

	streamelements_connected = true

	streamelements_reconnect_attempts = 0

	streamelements_stability_timer = 0.0


	emit_status(
		SOURCE_STREAMELEMENTS,
		"CONNECTED",
		"Welcome received. Subscribing..."
	)


	var subscription_data: Dictionary = {

		"topic":
			STREAMELEMENTS_ACTIVITIES_TOPIC,

		"token":
			str(
				streamelements_config.get(
					"token",
					""
				)
			),

		"token_type":
			str(
				streamelements_config.get(
					"token_type",
					"apikey"
				)
			)
	}


	var room: String = str(
		streamelements_config.get(
			"room",
			""
		)
	)


	if not room.is_empty():

		subscription_data["room"] = room


	var request: Dictionary = {

		"type":
			"subscribe",

		"nonce":
			_make_nonce(),

		"data":
			subscription_data
	}


	if streamelements_socket == null:

		return


	var error: Error = (
		streamelements_socket.send_text(
			JSON.stringify(
				request
			)
		)
	)


	if error != OK:

		log_error(
			SOURCE_STREAMELEMENTS,
			"Subscription request failed: "
			+
			error_string(
				error
			)
		)


		return


	log_info(
		SOURCE_STREAMELEMENTS,
		"Subscription request sent for channel.activities."
	)


# =============================================================
# RESPONSE
# =============================================================

func _handle_streamelements_response(
	message: Dictionary
) -> void:

	var error_value: Variant = (
		message.get(
			"error",
			null
		)
	)


	if error_value != null:

		log_error(
			SOURCE_STREAMELEMENTS,
			"StreamElements response error: "
			+
			str(
				error_value
			)
		)


		emit_status(
			SOURCE_STREAMELEMENTS,
			"ERROR",
			str(
				error_value
			)
		)


		return


	var data_value: Variant = (
		message.get(
			"data",
			{}
		)
	)


	if not data_value is Dictionary:

		return


	var data: Dictionary = (
		data_value as Dictionary
	)


	var message_text: String = str(
		data.get(
			"message",
			""
		)
	)


	if not message_text.is_empty():

		log_info(
			SOURCE_STREAMELEMENTS,
			message_text
		)


	if (
		message_text
		.to_lower()
		.find(
			"successfully subscribed"
		)
		>=
		0
	):

		streamelements_authenticated = true

		streamelements_subscribed = true


		emit_status(
			SOURCE_STREAMELEMENTS,
			"CONNECTED",
			"Connected and subscribed to channel.activities."
		)


# =============================================================
# EVENT MESSAGE
# =============================================================

func _handle_streamelements_event_message(
	message: Dictionary
) -> void:

	var topic: String = str(
		message.get(
			"topic",
			""
		)
	)


	if topic != STREAMELEMENTS_ACTIVITIES_TOPIC:

		return


	var data_value: Variant = (
		message.get(
			"data",
			{}
		)
	)


	if not data_value is Dictionary:

		return


	var activity: Dictionary = (
		data_value as Dictionary
	)


	var event_name: String = str(
		activity.get(
			"type",
			""
		)
	).to_upper()


	if event_name.is_empty():

		return


	var is_mock: bool = (
		_detect_mock_event(
			activity
		)
	)


	var payload: Dictionary = (
		activity.duplicate(
			true
		)
	)


	payload["_ciga_source"] = (
		SOURCE_STREAMELEMENTS
	)


	payload["_ciga_mock"] = is_mock

	payload["_ciga_received_time"] = (
		Time.get_ticks_msec()
	)


	stream_event_received.emit(
		SOURCE_STREAMELEMENTS,
		event_name,
		payload
	)


	log_info(
		SOURCE_STREAMELEMENTS,
		"EVENT RECEIVED: "
		+
		event_name
		+
		(
			" [MOCK]"
			if is_mock
			else
			""
		)
	)


	if is_duplicate_event(
		event_name,
		payload
	):

		return


	if (
		is_mock
		and
		not get_accept_mock_events()
	):

		return


	event_forwarded.emit(
		SOURCE_STREAMELEMENTS,
		event_name,
		payload
	)


	event_received.emit(
		SOURCE_STREAMELEMENTS,
		event_name,
		payload
	)


	log_info(
		SOURCE_STREAMELEMENTS,
		"EVENT FORWARDED TO CIGA EVENTS: "
		+
		event_name
	)


# =============================================================
# MOCK DETECTION
# =============================================================

func _detect_mock_event(
	activity: Dictionary
) -> bool:

	var candidates: Array[String] = [

		"mock",
		"isMock",
		"test",
		"isTest",
		"simulated",
		"isSimulated"
	]


	for key: String in candidates:

		if not activity.has(
			key
		):

			continue


		var value: Variant = (
			activity.get(
				key
			)
		)


		if value is bool:

			if bool(
				value
			):

				return true

		else:

			var text: String = str(
				value
			).to_lower()


			if text in [
				"true",
				"mock",
				"test",
				"simulated"
			]:

				return true


	var provider_value: String = str(
		activity.get(
			"provider",
			""
		)
	).to_lower()


	return (
		provider_value == "mock"
		or
		provider_value == "test"
	)


# =============================================================
# MOCK EVENT
# =============================================================

func emit_mock_event(
	event_name: String,
	username: String,
	provider: String = "twitch"
) -> void:

	var normalized_event: String = (
		event_name.to_upper()
	)


	var clean_username: String = (
		username.strip_edges()
	)


	if clean_username.is_empty():

		clean_username = "test_user"


	var event_data: Dictionary = {

		"type":
			normalized_event.to_lower(),

		"provider":
			provider,

		"data":
			{
				"username":
					clean_username,

				"displayName":
					clean_username,

				"providerId":
					"mock_"
					+
					clean_username.to_lower()
			},

		"_ciga_source":
			SOURCE_STREAMELEMENTS,

		"_ciga_mock":
			true,

		"_ciga_mock_id":
			str(
				Time.get_ticks_usec()
			)
	}


	stream_event_received.emit(
		SOURCE_STREAMELEMENTS,
		normalized_event,
		event_data
	)


	if not get_accept_mock_events():

		return


	event_forwarded.emit(
		SOURCE_STREAMELEMENTS,
		normalized_event,
		event_data
	)


	event_received.emit(
		SOURCE_STREAMELEMENTS,
		normalized_event,
		event_data
	)


# =============================================================
# DEDUP
# =============================================================

func is_duplicate_event(
	event_name: String,
	payload: Dictionary
) -> bool:

	if bool(
		payload.get(
			"_ciga_mock",
			false
		)
	):

		return false


	var normalized_event: String = (
		event_name
		.strip_edges()
		.to_upper()
	)


	if (
		normalized_event == "CHANNEL_POINTS_REDEEM"
		or
		normalized_event == "CHANNEL_POINT_REDEEM"
		or
		normalized_event == "CHANNEL_POINTS_REDEMPTION"
		or
		normalized_event == "CHANNEL_POINT_REDEMPTION"
		or
		normalized_event == "CHANNEL_POINTS_CUSTOM_REWARD_REDEMPTION"
		or
		normalized_event == "CHANNEL_POINTS_CUSTOM_REWARD_REDEMPTION_ADD"
		or
		normalized_event == "CHANNEL_CHANNEL_POINTS_CUSTOM_REWARD_REDEMPTION_ADD"
		or
		normalized_event == "CHANNELPOINTSREDEMPTION"
	):

		var redemption_id: String = (
			get_unique_event_id_from_payload(
				payload
			)
		)


		if redemption_id.is_empty():

			return false


		var redemption_signature: String = (
			"REDEMPTION|"
			+
			redemption_id
		)


		var now_ms: int = (
			Time.get_ticks_msec()
		)


		if dedup_cache.has(
			redemption_signature
		):

			var previous_value: Variant = (
				dedup_cache.get(
					redemption_signature
				)
			)


			if previous_value is int:

				var elapsed: float = (
					float(
						now_ms
						-
						int(
							previous_value
						)
					)
					/
					1000.0
				)


				if elapsed <= DEDUP_WINDOW_SECONDS:

					return true


		dedup_cache[
			redemption_signature
		] = now_ms


		_trim_dedup_cache()

		return false


	var signature: String = (
		build_event_signature(
			event_name,
			payload
		)
	)


	if signature.is_empty():

		return false


	var now_ms: int = (
		Time.get_ticks_msec()
	)


	if dedup_cache.has(
		signature
	):

		var previous_value: Variant = (
			dedup_cache.get(
				signature
			)
		)


		if previous_value is int:

			var elapsed: float = (
				float(
					now_ms
					-
					int(
						previous_value
					)
				)
				/
				1000.0
			)


			if elapsed <= DEDUP_WINDOW_SECONDS:

				return true


	dedup_cache[
		signature
	] = now_ms


	_trim_dedup_cache()


	return false


# =============================================================
# GET UNIQUE EVENT ID
# =============================================================

func get_unique_event_id_from_payload(
	payload: Dictionary
) -> String:

	if payload.is_empty():

		return ""


	var direct_keys: Array[String] = [

		"id",
		"eventId",
		"event_id",
		"activityId",
		"activity_id",
		"redemptionId",
		"redemption_id",
		"uuid"
	]


	for key: String in direct_keys:

		if not payload.has(
			key
		):

			continue


		var value: Variant = (
			payload.get(
				key,
				""
			)
		)


		if value == null:

			continue


		var result: String = (
			str(
				value
			)
			.strip_edges()
		)


		if not result.is_empty():

			return result


	var data_value: Variant = (
		payload.get(
			"data",
			null
		)
	)


	if data_value is Dictionary:

		var data: Dictionary = (
			data_value as Dictionary
		)


		for key: String in direct_keys:

			if not data.has(
				key
			):

				continue


			var value: Variant = (
				data.get(
					key,
					""
				)
			)


			if value == null:

				continue


			var result: String = (
				str(
					value
				)
				.strip_edges()
			)


			if not result.is_empty():

				return result


		var redemption_value: Variant = (
			data.get(
				"redemption",
				null
			)
		)


		if redemption_value is Dictionary:

			var redemption: Dictionary = (
				redemption_value as Dictionary
			)


			for key: String in direct_keys:

				if not redemption.has(
					key
				):

					continue


				var value: Variant = (
					redemption.get(
						key,
						""
					)
				)


				if value == null:

					continue


				var result: String = (
					str(
						value
					)
					.strip_edges()
				)


				if not result.is_empty():

					return result


	var event_value: Variant = (
		payload.get(
			"event",
			null
		)
	)


	if event_value is Dictionary:

		var event_data: Dictionary = (
			event_value as Dictionary
		)


		for key: String in direct_keys:

			if not event_data.has(
				key
			):

				continue


			var value: Variant = (
				event_data.get(
					key,
					""
				)
			)


			if value == null:

				continue


			var result: String = (
				str(
					value
				)
				.strip_edges()
			)


			if not result.is_empty():

				return result


		var event_redemption_value: Variant = (
			event_data.get(
				"redemption",
				null
			)
		)


		if event_redemption_value is Dictionary:

			var event_redemption: Dictionary = (
				event_redemption_value as Dictionary
			)


			for key: String in direct_keys:

				if not event_redemption.has(
					key
				):

					continue


				var value: Variant = (
					event_redemption.get(
						key,
						""
					)
				)


				if value == null:

					continue


				var result: String = (
					str(
						value
					)
					.strip_edges()
				)


				if not result.is_empty():

					return result


	return ""


# =============================================================
# BUILD EVENT SIGNATURE
# =============================================================

func build_event_signature(
	event_name: String,
	payload: Dictionary
) -> String:

	var normalized_event: String = (
		event_name
		.strip_edges()
		.to_lower()
	)


	var data_value: Variant = (
		payload.get(
			"data",
			{}
		)
	)


	var username: String = ""

	var display_name: String = ""

	var provider_id: String = ""


	if data_value is Dictionary:

		var data: Dictionary = (
			data_value as Dictionary
		)


		username = str(
			data.get(
				"username",
				""
			)
		).strip_edges().to_lower()


		display_name = str(
			data.get(
				"displayName",
				""
			)
		).strip_edges().to_lower()


		provider_id = str(
			data.get(
				"providerId",
				""
			)
		).strip_edges().to_lower()


	if username.is_empty():

		username = str(
			payload.get(
				"username",
				""
			)
		).strip_edges().to_lower()


	if display_name.is_empty():

		display_name = str(
			payload.get(
				"displayName",
				""
			)
		).strip_edges().to_lower()


	if provider_id.is_empty():

		provider_id = str(
			payload.get(
				"providerId",
				""
			)
		).strip_edges().to_lower()


	var identity: String = ""


	if not provider_id.is_empty():

		identity = (
			"id:"
			+
			provider_id
		)

	elif not username.is_empty():

		identity = (
			"user:"
			+
			username
		)

	elif not display_name.is_empty():

		identity = (
			"name:"
			+
			display_name
		)


	if identity.is_empty():

		return ""


	var amount: String = str(
		payload.get(
			"amount",
			payload.get(
				"value",
				""
			)
		)
	).strip_edges().to_lower()


	var message: String = str(
		payload.get(
			"message",
			""
		)
	).strip_edges().to_lower()


	return (
		normalized_event
		+
		"|"
		+
		identity
		+
		"|"
		+
		amount
		+
		"|"
		+
		message
	)


# =============================================================
# CLEAN DEDUP
# =============================================================

func _cleanup_dedup_cache() -> void:

	if dedup_cache.is_empty():

		return


	var now_ms: int = (
		Time.get_ticks_msec()
	)


	var remove_keys: Array[String] = []


	for key_value: Variant in dedup_cache.keys():

		var key: String = str(
			key_value
		)


		var value: Variant = (
			dedup_cache.get(
				key
			)
		)


		if not value is int:

			remove_keys.append(
				key
			)

			continue


		var age: float = (
			float(
				now_ms
				-
				int(
					value
				)
			)
			/
			1000.0
		)


		if age > DEDUP_WINDOW_SECONDS:

			remove_keys.append(
				key
			)


	for key: String in remove_keys:

		dedup_cache.erase(
			key
		)


# =============================================================
# TRIM
# =============================================================

func _trim_dedup_cache() -> void:

	while dedup_cache.size() > MAX_DEDUP_ENTRIES:

		var oldest_key: String = ""

		var oldest_value: int = 9223372036854775807


		for key_value: Variant in dedup_cache.keys():

			var key: String = str(
				key_value
			)


			var value: Variant = (
				dedup_cache.get(
					key
				)
			)


			if not value is int:

				continue


			var timestamp: int = int(
				value
			)


			if timestamp < oldest_value:

				oldest_value = timestamp

				oldest_key = key


		if oldest_key.is_empty():

			break


		dedup_cache.erase(
			oldest_key
		)


# =============================================================
# MOCK SETTING
# =============================================================

func get_accept_mock_events() -> bool:

	var config: Dictionary = (
		get_saved_source_config(
			SOURCE_STREAMELEMENTS
		)
	)


	return bool(
		config.get(
			"accept_mock_events",
			false
		)
	)


func set_accept_mock_events(
	enabled: bool
) -> void:

	var config: Dictionary = (
		get_saved_source_config(
			SOURCE_STREAMELEMENTS
		)
	)


	config["accept_mock_events"] = enabled


	save_source_config(
		SOURCE_STREAMELEMENTS,
		config
	)


# =============================================================
# STATUS
# =============================================================

func emit_status(
	source_id: String,
	status: String,
	message: String
) -> void:

	connection_status_changed.emit(
		source_id,
		status,
		message
	)


# =============================================================
# LOG
# =============================================================

func log_info(
	source_id: String,
	message: String
) -> void:

	log_message.emit(
		source_id,
		"INFO",
		message
	)


func log_warning(
	source_id: String,
	message: String
) -> void:

	log_message.emit(
		source_id,
		"WARNING",
		message
	)


func log_error(
	source_id: String,
	message: String
) -> void:

	log_message.emit(
		source_id,
		"ERROR",
		message
	)


# =============================================================
# NONCE
# =============================================================

func _make_nonce() -> String:

	return (
		"ciga-"
		+
		str(
			Time.get_ticks_usec()
		)
	)


# =============================================================
# OUTPUT ROOT
# =============================================================

func get_output_root() -> Dictionary:

	if profile_manager == null:

		return {}


	var profile_value: Variant = (
		profile_manager.get_active_profile()
	)


	if not profile_value is Dictionary:

		return {}


	var profile: Dictionary = (
		profile_value as Dictionary
	)


	var output_value: Variant = (
		profile.get(
			"output",
			{}
		)
	)


	if not output_value is Dictionary:

		return {}


	return (
		(output_value as Dictionary)
		.duplicate(
			true
		)
	)


# =============================================================
# GET SOURCE CONFIG
# =============================================================

func get_saved_source_config(
	source_id: String
) -> Dictionary:

	var output: Dictionary = (
		get_output_root()
	)


	var sources_value: Variant = (
		output.get(
			"sources",
			{}
		)
	)


	if not sources_value is Dictionary:

		return {}


	var sources: Dictionary = (
		sources_value as Dictionary
	)


	var config_value: Variant = (
		sources.get(
			source_id,
			{}
		)
	)


	if not config_value is Dictionary:

		return {}


	return (
		(config_value as Dictionary)
		.duplicate(
			true
		)
	)


# =============================================================
# SAVE SOURCE CONFIG
# =============================================================

func save_source_config(
	source_id: String,
	config: Dictionary
) -> void:

	if profile_manager == null:

		return


	var profile: Dictionary = (
		profile_manager.get_active_profile()
	)


	if profile.is_empty():

		return


	var output_value: Variant = (
		profile.get(
			"output",
			{}
		)
	)


	var output: Dictionary = (
		output_value as Dictionary
		if output_value is Dictionary
		else
		{}
	)


	var sources_value: Variant = (
		output.get(
			"sources",
			{}
		)
	)


	var sources: Dictionary = (
		sources_value as Dictionary
		if sources_value is Dictionary
		else
		{}
	)


	sources[source_id] = (
		config.duplicate(
			true
		)
	)


	output["sources"] = sources

	profile["output"] = output


	profile_manager.save_profiles()


# =============================================================
# AUTO CONNECT
# =============================================================

func auto_connect_saved_sources() -> void:

	# =========================================================
	# CIGAIS WORKER
	# =========================================================

	if not _get_cigais_worker_guild_id().is_empty():

		_connect_cigais_worker()


	# =========================================================
	# STREAM ELEMENTS
	# =========================================================

	var se_config: Dictionary = (
		get_saved_source_config(
			SOURCE_STREAMELEMENTS
		)
	)


	var se_token: String = str(
		se_config.get(
			"token",
			""
		)
	)


	var se_auto_connect: bool = bool(
		se_config.get(
			"auto_connect",
			false
		)
	)


	if (
		se_auto_connect
		and
		not se_token.is_empty()
	):

		connect_streamelements(
			true
		)


	# =========================================================
	# VTUBE STUDIO
	# =========================================================

	var vts_config: Dictionary = (
		get_saved_source_config(
			SOURCE_VTUBESTUDIO
		)
	)


	if bool(
		vts_config.get(
			"enabled",
			false
		)
	):

		connect_vtube_studio(
			true
		)


# =============================================================
# CIGAIS WORKER CONFIG
# =============================================================

func set_cigais_worker_guild_id(
	guild_id: String
) -> void:

	var clean_id := (
		guild_id
		.strip_edges()
	)


	var config := (
		get_saved_source_config(
			SOURCE_CIGAIS_WORKER
		)
	)


	config["guild_id"] = clean_id


	save_source_config(
		SOURCE_CIGAIS_WORKER,
		config
	)


	cigais_worker_guild_id = clean_id


func get_cigais_worker_guild_id() -> String:

	return _get_cigais_worker_guild_id()


# =============================================================
# CONNECTION STATUS
# =============================================================

func get_connection_status(
	source_id: String
) -> String:

	match source_id:

		SOURCE_STREAMELEMENTS:

			if streamelements_socket != null:

				var state: WebSocketPeer.State = (
					streamelements_socket.get_ready_state()
				)


				if state == WebSocketPeer.STATE_OPEN:

					if streamelements_subscribed:

						return "CONNECTED"


					return "CONNECTING"


			if streamelements_reconnect_timer > 0.0:

				return "RECONNECTING"


			return "DISCONNECTED"


		SOURCE_VMC:

			if vmc_runtime == null:

				return "UNAVAILABLE"


			return vmc_runtime.get_connection_status()


		SOURCE_CIGAIS_WORKER:

			if cigais_worker_socket != null:

				var worker_state: WebSocketPeer.State = (
					cigais_worker_socket.get_ready_state()
				)


				if worker_state == WebSocketPeer.STATE_OPEN:

					if cigais_worker_connected:

						return "CONNECTED"


					return "CONNECTING"


				if worker_state == WebSocketPeer.STATE_CONNECTING:

					return "CONNECTING"


			if cigais_worker_reconnect_timer > 0.0:

				return "RECONNECTING"


			return "DISCONNECTED"


		SOURCE_VTUBESTUDIO:

			if vtube_studio_socket != null:

				var vts_state: WebSocketPeer.State = (
					vtube_studio_socket.get_ready_state()
				)


				if vts_state == WebSocketPeer.STATE_OPEN:

					if vtube_studio_authenticated:

						return "CONNECTED"


					return "CONNECTING"


			if vtube_studio_reconnect_timer > 0.0:

				return "RECONNECTING"


			return "DISCONNECTED"


	return "UNKNOWN"


# =============================================================
# VTUBE STUDIO CONFIG API
# =============================================================

func set_vtube_studio_enabled(
	enabled: bool
) -> void:

	var config: Dictionary = (
		get_saved_source_config(
			SOURCE_VTUBESTUDIO
		)
	)


	config["enabled"] = enabled


	save_source_config(
		SOURCE_VTUBESTUDIO,
		config
	)


	if not enabled:

		disconnect_vtube_studio(
			false
		)


func is_vtube_studio_enabled() -> bool:

	var config: Dictionary = (
		get_saved_source_config(
			SOURCE_VTUBESTUDIO
		)
	)


	return bool(
		config.get(
			"enabled",
			false
		)
	)


func get_vtube_studio_config() -> Dictionary:

	return (
		get_saved_source_config(
			SOURCE_VTUBESTUDIO
		)
	)


func clear_vtube_studio_token() -> void:

	var config: Dictionary = (
		get_saved_source_config(
			SOURCE_VTUBESTUDIO
		)
	)


	config.erase(
		"authentication_token"
	)


	save_source_config(
		SOURCE_VTUBESTUDIO,
		config
	)


	vtube_studio_token = ""

	vtube_studio_authenticated = false

	vtube_studio_parameters_ready = false


# =============================================================
# RECONNECT MESSAGE
# =============================================================

func _handle_streamelements_reconnect(
	message: Dictionary
) -> void:

	log_warning(
		SOURCE_STREAMELEMENTS,
		"StreamElements requested a reconnect."
	)


	var data_value: Variant = (
		message.get(
			"data",
			{}
		)
	)


	if data_value is Dictionary:

		var data: Dictionary = (
			data_value as Dictionary
		)


		var reconnect_token: String = str(
			data.get(
				"reconnect_token",
				""
			)
		)


		if not reconnect_token.is_empty():

			streamelements_config["reconnect_token"] = (
				reconnect_token
			)


			save_source_config(
				SOURCE_STREAMELEMENTS,
				streamelements_config
			)


	if streamelements_socket != null:

		var socket: WebSocketPeer = (
			streamelements_socket
		)


		streamelements_socket = null

		streamelements_connected = false

		streamelements_authenticated = false

		streamelements_subscribed = false


		if (
			socket.get_ready_state()
			!=
			WebSocketPeer.STATE_CLOSED
		):

			socket.close(
				1000,
				"StreamElements reconnect requested"
			)


	emit_status(
		SOURCE_STREAMELEMENTS,
		"RECONNECTING",
		"StreamElements requested a reconnect."
	)


	_schedule_reconnect()


# =============================================================
# EVENTS RUNTIME
# =============================================================

func _connect_events_runtime() -> void:

	if events_runtime == null:

		var main_loop := Engine.get_main_loop()


		if main_loop == null:

			return


		if not main_loop is SceneTree:

			return


		var tree: SceneTree = (
			main_loop as SceneTree
		)


		var current_scene := tree.current_scene


		if current_scene == null:

			return


		var found := (
			current_scene.find_children(
				"*",
				"CIGAEventsRuntime",
				true,
				false
			)
		)


		for node: Node in found:

			if node is CIGAEventsRuntime:

				events_runtime = (
					node as CIGAEventsRuntime
				)

				break


	if events_runtime == null:

		return


	# =========================================================
	# NORMAL EVENT FLOW
	# =========================================================

	if not event_forwarded.is_connected(
		_on_event_forwarded
	):

		event_forwarded.connect(
			_on_event_forwarded
		)


	# =========================================================
	# WORKER EVENT FLOW
	# =========================================================

	if not events_runtime.worker_event_requested.is_connected(
		send_cigais_worker_event
	):

		events_runtime.worker_event_requested.connect(
			send_cigais_worker_event
		)


# =============================================================
# FORWARD EVENT
# =============================================================

func _on_event_forwarded(
	_source_id: String,
	event_name: String,
	payload: Dictionary
) -> void:

	if events_runtime == null:

		_connect_events_runtime()


	if events_runtime == null:

		return


	events_runtime.receive_event(
		event_name,
		payload
	)


# =============================================================
# EXIT
# =============================================================

func _exit_tree() -> void:

	streamelements_manual_disconnect = true

	vtube_studio_manual_disconnect = true


	# =========================================================
	# STREAM ELEMENTS
	# =========================================================

	if streamelements_socket != null:

		var se_socket: WebSocketPeer = (
			streamelements_socket
		)


		if (
			se_socket.get_ready_state()
			!=
			WebSocketPeer.STATE_CLOSED
		):

			se_socket.close(
				1000,
				"CIGA application shutdown"
			)


		streamelements_socket = null


	# =========================================================
	# CIGAIS WORKER
	# =========================================================

	cigais_worker_reconnect_timer = 0.0

	cigais_worker_connected = false


	if cigais_worker_socket != null:

		var worker_socket: WebSocketPeer = (
			cigais_worker_socket
		)


		if (
			worker_socket.get_ready_state()
			!=
			WebSocketPeer.STATE_CLOSED
		):

			worker_socket.close(
				1000,
				"CIGA application shutdown"
			)


		cigais_worker_socket = null


	# =========================================================
	# VTUBE STUDIO
	# =========================================================

	if vtube_studio_socket != null:

		var vts_socket: WebSocketPeer = (
			vtube_studio_socket
		)


		if (
			vts_socket.get_ready_state()
			!=
			WebSocketPeer.STATE_CLOSED
		):

			vts_socket.close(
				1000,
				"CIGA application shutdown"
			)


		vtube_studio_socket = null


# =============================================================
# EVENTS RUNTIME DIRECT LINK
# =============================================================

func set_events_runtime(
	new_runtime: CIGAEventsRuntime
) -> void:

	events_runtime = new_runtime


	if events_runtime == null:

		return


	# =========================================================
	# NORMAL EVENT FLOW
	# =========================================================

	if not event_forwarded.is_connected(
		_on_event_forwarded
	):

		event_forwarded.connect(
			_on_event_forwarded
		)


	# =========================================================
	# WORKER EVENT FLOW
	# =========================================================

	if not events_runtime.worker_event_requested.is_connected(
		send_cigais_worker_event
	):

		events_runtime.worker_event_requested.connect(
			send_cigais_worker_event
		)
