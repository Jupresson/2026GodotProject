@tool
extends CharacterBody3D
class_name UCharacterBody3D

## A 3D physics body using a revamped template script.

signal step_requested(intensity: float, is_sprinting: bool, is_crouching: bool)

const STEP_SOUNDS_FOLDER: String = "res://assets/sounds/sfx/general_step/"
const STEP_VOLUME_DB: float = 5.0
const STEP_PITCH_RANGE: Vector2 = Vector2(0.96, 1.04)

const JUMP_SOUNDS_FOLDER: String = "res://assets/sounds/sfx/general_jump/"
const JUMP_VOLUME_DB: float = -5.0
const JUMP_PITCH_RANGE: Vector2 = Vector2(0.86, 0.9)

const DASH_SOUNDS_FOLDER: String = "res://assets/sounds/sfx/general_dash/"
const DASH_VOLUME_DB: float = -3
const DASH_PITCH_RANGE: Vector2 = Vector2(0.96, 1.04)

const LAND_SOUNDS_FOLDER: String = "res://assets/sounds/sfx/general_land/"
const LAND_VOLUME_DB: float = 0
const LAND_PITCH_RANGE: Vector2 = Vector2(0.86, 1.34)

const SLIDE_LOOP_KEY_PREFIX: String = "ucharacter_slide_loop_"

@export_group("Character Speeds")
@export var jump_velocity : float = 4.35
@export var walk_speed : float = 3.0
@export var sprint_speed : float = 4.6
@export var crouch_speed : float = 1.6
@export var slide_speed : float = 7.0

@export_group("Character Settings")
## Where the camera will be positioned, default of 1.8 is based off of a character height of 2.0
@export var standing_height : float = 1.8
## Where the camera will be positioned, default of 1.3 is based off of a character height of 2.0
@export var crouching_height : float = 1.3
## The slide length in seconds for how far the player can slide
@export var sliding_length : float = 1.0
@export var head_bob_walking_speed : float = 12.0
@export var head_bob_sprinting_speed : float = 15.0
@export var head_bob_crouching_speed : float = 11.0
## The head bob intensity is for crouching, where walking is multiplied by 2, and sprinting is multiplied by 4
@export var head_bob_intensity : float = 0.09

@export_group("Camera FOV")
@export var fov_low : float = 125.8
@export var fov_high : float = 145.8
@export var fov_fall_boost : float = 8.0
@export var fov_fall_speed_max : float = 30.0
@export var fov_smooth_speed : float = 6.0

@export_group("Jump Feel")
## Grace period after stepping off a ledge where jumping is still allowed.
@export var coyote_time : float = 0.3

@export_group("Slide Audio")
@export var slide_loop_stream: AudioStream
@export var slide_loop_base_volume_db: float = -14.0
@export var slide_loop_max_volume_db: float = -4.0
@export var slide_loop_min_speed: float = 2.0
@export var slide_loop_max_speed: float = 9.0
@export var slide_loop_pitch_range: Vector2 = Vector2(0.92, 1.08)
@export var slide_loop_fade_out_speed: float = 18.0

@export_group("Controls")
## The InputMap action string to be used for LEFT movement
@export var LEFT : String = "move_left"
## The InputMap action string to be used for RIGHT movement
@export var RIGHT : String = "move_right"
## The InputMap action string to be used for FORWARD movement
@export var FORWARD : String = "move_forward"
## The InputMap action string to be used for BACKWARD movement
@export var BACKWARD : String = "move_backward"
## The InputMap action string to be used for sprinting
@export var SPRINT : String = "action_sprint"
## The InputMap action string to be used for crouching
@export var CROUCH : String = "action_crouch"
## The InputMap action string to be used for jumping
@export var JUMP : String = "action_jump"
## A default value of 0.4 is a good starting point, stay between 0.01 and 1.0
@export var MOUSE_SENSITIVITY : float = 0.4

var is_walking = false
var is_sprinting = false
var is_crouching = false
var is_sliding = false

var collision_shape_normal : CollisionShape3D
var collision_shape_crouch : CollisionShape3D
var head_node : Node3D
var camera_node : Camera3D
var raycast_node : RayCast3D

var shader_node : ColorRect

var current_speed = walk_speed
var slide_timer = 0.0
var slide_vector = Vector2.ZERO
var head_bob_current_intensity = 0.0
var head_bob_vector = Vector2.ZERO
var head_bob_index = 0.0
var last_velocity = Vector3.ZERO
var coyote_timer = 0.3
var was_on_ground : bool = false
var has_ground_state : bool = false
var slide_loop_player: AudioStreamPlayer
var slide_loop_key: StringName = StringName()

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var direction = Vector3.ZERO
var scene

func _enter_tree():
	if Engine.is_editor_hint():
		# Obtain the current scene root
		scene = get_tree().edited_scene_root
		if scene == null:
			printerr("Failed to obtain scene tree in editor")
			return
	
	if !Engine.is_editor_hint():
		collision_shape_normal = $CollisionShapeNormal
		collision_shape_crouch = $CollisionShapeCrouch
		head_node = $Head
		camera_node = $Head/Camera
		raycast_node = $RayCast3D
		shader_node = $BodyCamShader/ColorRect
		camera_node.fov = fov_low
		
func _ready():
	# Only editor: Create child nodes
	if Engine.is_editor_hint():
		# TODO: Find a better way to implement this. A workaround to not adding duplicate nodes
		# Need to figure out how to lo	
		var nodes = get_children()
		if nodes.size() > 0:
			collision_shape_normal = get_node("CollisionShapeNormal")
			collision_shape_crouch = get_node("CollisionShapeCrouch")
			head_node = get_node("Head")
			camera_node = head_node.get_node("Camera")
			raycast_node = get_node("RayCast3D")
		
		# Create the collision shapes
		if collision_shape_normal == null:
			collision_shape_normal = CollisionShape3D.new()
			collision_shape_normal.name = "CollisionShapeNormal"
			collision_shape_normal.shape = CapsuleShape3D.new()
			collision_shape_normal.position.y = 1.0
			self.add_child(collision_shape_normal)
			collision_shape_normal.owner = scene
		
		if collision_shape_crouch == null:
			collision_shape_crouch = CollisionShape3D.new()
			collision_shape_crouch.name = "CollisionShapeCrouch"
			collision_shape_crouch.shape = CapsuleShape3D.new()
			collision_shape_crouch.shape.height = crouching_height
			collision_shape_crouch.position.y = crouching_height/2
			collision_shape_crouch.disabled = true
			self.add_child(collision_shape_crouch)
			collision_shape_crouch.owner = scene
		
		# Create the head node
		if head_node == null:
			head_node = Node3D.new()
			head_node.name = "Head"
			head_node.position.y = standing_height
			self.add_child(head_node)
			head_node.owner = scene
		
		# Create the camera node
		if camera_node == null:
			camera_node = Camera3D.new()
			camera_node.name = "Camera"
			head_node.add_child(camera_node)
			camera_node.owner = scene
		
		# Create the raycast node
		if raycast_node == null:
			raycast_node = RayCast3D.new()
			raycast_node.name = "RayCast3D"
			raycast_node.target_position = Vector3(0, 2, 0)
			self.add_child(raycast_node)
			raycast_node.owner = scene
	
	# Only game: Run normal ready logic
	if !Engine.is_editor_hint():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		step_requested.connect(_handle_head_bob_sound)
		slide_loop_key = StringName("%s%s" % [SLIDE_LOOP_KEY_PREFIX, str(get_instance_id())])
		
		pass

func _input(event):
	if !Engine.is_editor_hint():
		if event is InputEventMouseMotion and !is_sliding:
			rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENSITIVITY))
			head_node.rotate_x(deg_to_rad(-event.relative.y * MOUSE_SENSITIVITY))
			head_node.rotation.x = clampf(head_node.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta):
	if !Engine.is_editor_hint():
		# Get input direction
		var input_dir = Input.get_vector(LEFT, RIGHT, FORWARD, BACKWARD)
		
		# Handle crouch, sprint, walk speed.
		if Input.is_action_pressed(CROUCH) or is_sliding:
			current_speed = lerpf(current_speed, crouch_speed, delta * 10.0)
			head_node.position.y = lerpf(head_node.position.y, crouching_height, delta * 10.0)
			collision_shape_normal.disabled = true
			collision_shape_crouch.disabled = false
			
			# Handle sliding
			if is_sprinting and input_dir != Vector2.ZERO:
				is_sliding = true
				slide_timer = sliding_length
				slide_vector = input_dir
				_handle_dash_sound()
			
			is_walking = false
			is_sprinting = false
			is_crouching = true
			
		elif !raycast_node.is_colliding():
			head_node.position.y = lerpf(head_node.position.y, standing_height, delta * 10.0)
			collision_shape_normal.disabled = false
			collision_shape_crouch.disabled = true
			
			if Input.is_action_pressed(SPRINT):
				current_speed = lerpf(current_speed, sprint_speed, delta * 10.0)
				
				is_walking = false
				is_sprinting = true
				is_crouching = false
				
			else:
				current_speed = lerpf(current_speed, walk_speed, delta * 10.0)
				
				is_walking = true
				is_sprinting = false
				is_crouching = false
		
		if is_sliding:
			slide_timer -= delta
			if slide_timer <= 0:
				is_sliding = false

		_update_slide_audio(delta)
		
		# Handle head bob.
		if is_sprinting:
			head_bob_current_intensity = head_bob_intensity * 4
			head_bob_index += head_bob_sprinting_speed * delta
		elif is_walking:
			head_bob_current_intensity = head_bob_intensity * 2
			head_bob_index += head_bob_walking_speed * delta
		elif is_crouching:
			head_bob_current_intensity = head_bob_intensity
			head_bob_index += head_bob_crouching_speed * delta
		
		if is_on_floor() and !is_sliding and input_dir != Vector2.ZERO:
			var previous_bob_y = head_bob_vector.y
			head_bob_vector.y = sin(head_bob_index)
			head_bob_vector.x = sin(head_bob_index/2)+0.5
			if previous_bob_y > 0.0 and head_bob_vector.y <= 0.0:
				var step_intensity := clampf(absf(velocity.length()) / maxf(sprint_speed, 0.001), 0.0, 1.0)
				step_requested.emit(step_intensity, is_sprinting, is_crouching)
			camera_node.position.y = lerp(camera_node.position.y, head_bob_vector.y * (head_bob_current_intensity/2.0), delta * 10.0)
			camera_node.position.x = lerp(camera_node.position.x, head_bob_vector.x * head_bob_current_intensity, delta * 10.0)
		else:
			camera_node.position.y = lerp(camera_node.position.y, 0.0, delta * 10.0)
			camera_node.position.x = lerp(camera_node.position.x, 0.0, delta * 10.0)
		
		# Add the gravity.
		if !is_on_floor():
			velocity.y -= gravity * delta
			coyote_timer = maxf(coyote_timer - delta, 0.0)
			was_on_ground = false
		else:
			coyote_timer = coyote_time

		# handle jump sound
		if has_ground_state and is_on_floor():
			if !was_on_ground:
				was_on_ground = _handle_land_sound()
		
		# Handle jump.
		if Input.is_action_just_pressed(JUMP) and (is_on_floor() or coyote_timer > 0.0):
			velocity.y = jump_velocity
			is_sliding = false
			coyote_timer = 0.0
			_handle_jump_sound()

		# Handle the movement/deceleration.
		if is_on_floor():
			if last_velocity.y < -8.5:
				# TODO: Handle player hard landing
				pass
			elif last_velocity.y < 0.0:
				# TODO: Handle player soft landing
				pass
			direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * 10.0)
		else:
			if input_dir != Vector2.ZERO:
				direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * 3.0)
		
		if is_sliding:
			direction = (transform.basis * Vector3(slide_vector.x, 0, slide_vector.y)).normalized()
			current_speed = (slide_timer + 0.1) * slide_speed
		
		if direction:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
		else:
			velocity.x = move_toward(velocity.x, 0, current_speed)
			velocity.z = move_toward(velocity.z, 0, current_speed)

		_update_dynamic_fov(delta)
		
		last_velocity = velocity
		
		move_and_slide()
		
		if !has_ground_state:
			was_on_ground = is_on_floor()
			has_ground_state = true

func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	_stop_slide_loop_immediately()

func _update_dynamic_fov(delta : float):
	if camera_node == null:
		return

	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var speed_ratio := clampf(horizontal_speed / maxf(sprint_speed, 0.001), 0.0, 1.0)
	var target_fov := lerpf(fov_low, fov_high, speed_ratio)

	var fall_speed := maxf(-velocity.y, 0.0)
	var fall_ratio := clampf(fall_speed / maxf(fov_fall_speed_max, 0.001), 0.0, 1.0)
	target_fov += fall_ratio * fov_fall_boost

	var max_fov := fov_high + fov_fall_boost
	target_fov = clampf(target_fov, fov_low, max_fov)
	camera_node.fov = lerpf(camera_node.fov, target_fov, delta * fov_smooth_speed)

func _handle_head_bob_sound(intensity: float, is_sprinting: bool, is_crouching: bool) -> void:
	var volume_db: float = STEP_VOLUME_DB
	if is_sprinting:
		volume_db += 2.0
	elif is_crouching:
		volume_db -= 1.5
	volume_db += lerpf(-1.5, 1.5, intensity)

	AudioManager.play_random_global_from_folder(
		STEP_SOUNDS_FOLDER,
		&"SFX",
		volume_db,
		AudioManager.PitchMode.CUSTOM_RANGE,
		AudioManager.PitchPreset.NORMAL,
		STEP_PITCH_RANGE,
		1.0,
		true
	)
		
func _handle_jump_sound():
	AudioManager.play_random_global_from_folder(
		JUMP_SOUNDS_FOLDER,
		&"SFX",
		JUMP_VOLUME_DB,
		AudioManager.PitchMode.CUSTOM_RANGE,
		AudioManager.PitchPreset.NORMAL,
		JUMP_PITCH_RANGE,
		1.0,
		true
	)	

func _handle_dash_sound():
	AudioManager.play_random_global_from_folder(
		DASH_SOUNDS_FOLDER,
		&"SFX",
		DASH_VOLUME_DB,
		AudioManager.PitchMode.CUSTOM_RANGE,
		AudioManager.PitchPreset.NORMAL,
		DASH_PITCH_RANGE,
		1.0,
		true
	)	

func _handle_land_sound():
	AudioManager.play_random_global_from_folder(
		LAND_SOUNDS_FOLDER,
		&"SFX",
		LAND_VOLUME_DB,
		AudioManager.PitchMode.CUSTOM_RANGE,
		AudioManager.PitchPreset.NORMAL,
		LAND_PITCH_RANGE,
		1.0,
		true
	)

	return true

func _update_slide_audio(delta: float) -> void:
	if slide_loop_stream == null:
		_stop_slide_loop_immediately()
		return

	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var should_play := is_sliding and is_on_floor() and horizontal_speed > slide_loop_min_speed

	if should_play:
		if slide_loop_player == null or !is_instance_valid(slide_loop_player):
			_ensure_slide_stream_loops()
			slide_loop_player = AudioManager.play_global_loop(
				slide_loop_key,
				slide_loop_stream,
				&"SFX",
				slide_loop_base_volume_db,
				AudioManager.PitchMode.CUSTOM_VALUE,
				AudioManager.PitchPreset.NORMAL,
				slide_loop_pitch_range,
				1.0
			)

		if slide_loop_player != null and is_instance_valid(slide_loop_player):
			var speed_ratio := clampf(
				(horizontal_speed - slide_loop_min_speed) / maxf(slide_loop_max_speed - slide_loop_min_speed, 0.001),
				0.0,
				1.0
			)
			slide_loop_player.volume_db = lerpf(slide_loop_base_volume_db, slide_loop_max_volume_db, speed_ratio)
			slide_loop_player.pitch_scale = lerpf(slide_loop_pitch_range.x, slide_loop_pitch_range.y, speed_ratio)
	else:
		if slide_loop_player != null and is_instance_valid(slide_loop_player):
			slide_loop_player.volume_db = move_toward(slide_loop_player.volume_db, -80.0, slide_loop_fade_out_speed * delta)
			if slide_loop_player.volume_db <= -70.0:
				_stop_slide_loop_immediately()
		else:
			_stop_slide_loop_immediately()

func _stop_slide_loop_immediately() -> void:
	AudioManager.stop_global_loop(slide_loop_key)
	slide_loop_player = null

func _ensure_slide_stream_loops() -> void:
	if slide_loop_stream is AudioStreamWAV:
		var wav_stream := slide_loop_stream as AudioStreamWAV
		if wav_stream.loop_mode == AudioStreamWAV.LOOP_DISABLED:
			wav_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif slide_loop_stream is AudioStreamOggVorbis:
		var ogg_stream := slide_loop_stream as AudioStreamOggVorbis
		ogg_stream.loop = true
	elif slide_loop_stream is AudioStreamMP3:
		var mp3_stream := slide_loop_stream as AudioStreamMP3
		mp3_stream.loop = true
