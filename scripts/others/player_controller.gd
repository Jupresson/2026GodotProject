@tool
extends CharacterBody3D

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

const SLIDE_SFX: AudioStream = preload("res://assets/sounds/sfx/general_slide/slide_1.ogg")
const SLIDE_SOUND_TAG: StringName = &"slide_sound"
const SLIDE_VOLUME_DB: float = -3
const SLIDE_PITCH_RANGE: Vector2 = Vector2(0.86, 1.34)

const LAND_SOUNDS_FOLDER: String = "res://assets/sounds/sfx/general_land/"
const LAND_VOLUME_DB: float = 0
const LAND_PITCH_RANGE: Vector2 = Vector2(0.86, 1.0)

@export_group("Character Speeds")
## Jump strength. Higher values make the player jump higher.
@export var jump_velocity : float = 4.35
## Walk speed. Higher values make normal movement faster.
@export var walk_speed : float = 3.0
## Sprint speed. Higher values make sprinting faster.
@export var sprint_speed : float = 4.6
## Crouch speed. Higher values make crouch movement faster.
@export var crouch_speed : float = 1.6
## Slide speed. Higher values make the slide cover more distance faster.
@export var slide_speed : float = 7.0

@export_group("Character Settings")
## Standing camera height. Higher values place the view higher.
@export var standing_height : float = 1.8
## Crouching camera height. Lower values bring the view closer to the ground.
@export var crouching_height : float = 1.3
## Slide duration in seconds. Higher values make slides last longer.
@export var sliding_length : float = 1.0
## Walking head bob speed. Higher values make the motion cycle faster.
@export var head_bob_walking_speed : float = 12.0
## Sprinting head bob speed. Higher values make the motion cycle faster.
@export var head_bob_sprinting_speed : float = 15.0
## Crouching head bob speed. Higher values make the motion cycle faster.
@export var head_bob_crouching_speed : float = 11.0
## Base head bob intensity. Higher values make the camera movement stronger.
@export var head_bob_intensity : float = 0.09

@export_group("Camera FOV")
## Default field of view. Higher values feel wider and faster.
@export var fov_low : float = 110.0
## Maximum field of view. Higher values feel more stretched and intense.
@export var fov_high : float = 140.0
## Extra FOV added while falling. Higher values make falling feel faster.
@export var fov_fall_boost : float = 70.0
## Speed cap used for the falling FOV effect. Lower values make the change smoother, higher values make it react faster.
@export var fov_fall_speed_max : float = 30.0
## FOV smoothing speed. Lower values make the camera change smoother, higher values make it respond faster.
@export var fov_smooth_speed : float = 6.0

@export_group("Audio")
## Slide sound fade-out time. Higher values make the sound linger longer.
@export var slide_sound_fade_out_seconds : float = 0.5
## General sound fade-out time. Higher values make sounds fade more slowly.
@export var sound_fade_out_seconds : float = 0.3

@export_group("Jump Feel")
## Coyote time in seconds. Higher values make jumping feel more forgiving after leaving a ledge.
@export var coyote_time : float = 0.3
## Landing sound cooldown in seconds. Higher values play landing sounds less often.
@export var landing_sound_limit_time : float = 0.5

@export_group("Controls")
## InputMap action used for moving left.
@export var LEFT : String = "move_left"
## InputMap action used for moving right.
@export var RIGHT : String = "move_right"
## InputMap action used for moving forward.
@export var FORWARD : String = "move_forward"
## InputMap action used for moving backward.
@export var BACKWARD : String = "move_backward"
## InputMap action used for sprinting.
@export var SPRINT : String = "action_sprint"
## InputMap action used for crouching.
@export var CROUCH : String = "action_crouch"
## InputMap action used for jumping.
@export var JUMP : String = "action_jump"
## Mouse look sensitivity. Higher values make turning faster.
@export var MOUSE_SENSITIVITY : float = 0.18

@export_group("Mouse")
## Enables mouse smoothing for a more natural, less jerky look feel.
@export var enable_mouse_smoothing : bool = true
## Mouse smoothing amount from 0 to 1. Lower values feel smoother; higher values feel snappier.
@export_range(0.0, 1.0, 0.01)
var mouse_smoothing_speed : float = 0.25

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
var landing_sound_limit_timer: float = 0.0
var was_on_ground : bool = false
var has_ground_state : bool = false
var is_input_enabled : bool = true

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var direction = Vector3.ZERO
var scene
var pending_mouse_relative := Vector2.ZERO
var smoothed_mouse_relative := Vector2.ZERO
var smoothed_mouse_prev := Vector2.ZERO

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
		InputManager.input_capture_changed.connect(_on_input_capture_changed)
		InputManager.mouse_look_input.connect(_on_mouse_look_input)
		_on_input_capture_changed(InputManager.is_input_enabled)
		step_requested.connect(_handle_head_bob_sound)
		
		pass


func _exit_tree() -> void:
	if !Engine.is_editor_hint():
		pass


func _physics_process(delta):
	if !Engine.is_editor_hint() and is_input_enabled:
		# Apply smoothed mouse look each physics frame
		_process_mouse_look(delta)
		# Get input direction
		var input_dir := InputManager.get_move_vector(LEFT, RIGHT, FORWARD, BACKWARD)
		landing_sound_limit_timer = maxf(landing_sound_limit_timer - delta, 0.0)
		
		# Handle crouch, sprint, walk speed.
		if InputManager.is_action_pressed(CROUCH) or is_sliding:
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
				if is_on_floor():
					_play_slide_sound()
			
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
		
		# Handle head bob.
		if is_sprinting:
			head_bob_current_intensity = head_bob_intensity * 2
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
			# Reset head bob when not actively moving
			head_bob_index = 0.0
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
				if is_sliding:
					_play_slide_sound()
				was_on_ground = _handle_land_sound()
		
		# Handle jump.
		if InputManager.is_action_just_pressed(JUMP) and (is_on_floor() or coyote_timer > 0.0):
			AudioManager.stop_by_unique_tag(SLIDE_SOUND_TAG)
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


func _on_input_capture_changed(enabled: bool) -> void:
	is_input_enabled = enabled


func _on_mouse_look_input(relative: Vector2) -> void:
	if !is_input_enabled or is_sliding:
		return

	# Queue the raw mouse delta; actual rotation is applied in _physics_process
	# accumulate deltas so smoothing can interpolate across frames
	pending_mouse_relative += relative

	# If smoothing is disabled, also apply immediately so input feels responsive
	if not enable_mouse_smoothing:
		if head_node != null:
			rotate_y(deg_to_rad(-pending_mouse_relative.x * MOUSE_SENSITIVITY))
			head_node.rotate_x(deg_to_rad(-pending_mouse_relative.y * MOUSE_SENSITIVITY))
			head_node.rotation.x = clampf(head_node.rotation.x, deg_to_rad(-80), deg_to_rad(80))
		# clear pending so we don't reapply in _process
		pending_mouse_relative = Vector2.ZERO
		smoothed_mouse_relative = Vector2.ZERO
		smoothed_mouse_prev = Vector2.ZERO


func _process_mouse_look(delta: float) -> void:
	if head_node == null or camera_node == null:
		return

	if not enable_mouse_smoothing:
		return

	# Smooth towards the latest pending mouse delta using lerp
	var smoothing_speed := lerpf(1.0, 30.0, mouse_smoothing_speed)
	var t := clampf(delta * smoothing_speed, 0.0, 1.0)
	# Interpolate the smoothed target towards the pending delta
	smoothed_mouse_relative = smoothed_mouse_relative.lerp(pending_mouse_relative, t)

	# Apply only the change since last frame to avoid repeatedly reapplying the same delta
	var delta_apply := smoothed_mouse_relative - smoothed_mouse_prev
	if delta_apply != Vector2.ZERO:
		rotate_y(deg_to_rad(-delta_apply.x * MOUSE_SENSITIVITY))
		head_node.rotate_x(deg_to_rad(-delta_apply.y * MOUSE_SENSITIVITY))
		head_node.rotation.x = clampf(head_node.rotation.x, deg_to_rad(-80), deg_to_rad(80))

	# Consume the applied portion from the pending target so smoothing continues across frames
	pending_mouse_relative -= delta_apply

	# Move previous smoothed tracker
	smoothed_mouse_prev = smoothed_mouse_relative

	# If the remaining pending is tiny, clear to avoid residual micro-rotations
	if pending_mouse_relative.length() < 0.001:
		pending_mouse_relative = Vector2.ZERO
		smoothed_mouse_relative = Vector2.ZERO
		smoothed_mouse_prev = Vector2.ZERO

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

	max_fov = clampf(max_fov, 0.1, 179.0) # limit fov always be 0.1 - 179.0

	target_fov = clampf(target_fov, fov_low, max_fov)
	camera_node.fov = lerpf(camera_node.fov, target_fov, delta * fov_smooth_speed)
	
func _handle_head_bob_sound(intensity: float, _is_sprinting: bool, _is_crouching: bool) -> void:
	var volume_db: float = STEP_VOLUME_DB
	if _is_sprinting:
		volume_db += 2.0
	elif _is_crouching:
		volume_db -= 1.5
	volume_db += lerpf(-1.5, 1.5, intensity)

	# Vary pitch based on movement state and step intensity:
	var pitch_range: Vector2 = STEP_PITCH_RANGE
	if _is_sprinting:
		# Slightly higher pitch and wider range when sprinting
		pitch_range = Vector2(STEP_PITCH_RANGE.x * 1.06, STEP_PITCH_RANGE.y * 1.12)
	elif _is_crouching:
		# Slightly lower pitch when crouching
		pitch_range = Vector2(STEP_PITCH_RANGE.x * 0.92, STEP_PITCH_RANGE.y * 0.98)
	else:
		# Walking: subtle pitch variation based on step intensity
		var sway := lerpf(0.98, 1.02, intensity)
		pitch_range = Vector2(STEP_PITCH_RANGE.x * sway, STEP_PITCH_RANGE.y * sway)

	_play_spatial_folder_sound(STEP_SOUNDS_FOLDER, volume_db, pitch_range, sound_fade_out_seconds)
		
func _handle_jump_sound():
	# Vary jump pitch depending on movement state
	var pitch_range: Vector2 = JUMP_PITCH_RANGE
	if is_sprinting:
		pitch_range = Vector2(JUMP_PITCH_RANGE.x * 1.03, JUMP_PITCH_RANGE.y * 1.08)
	elif is_crouching:
		pitch_range = Vector2(JUMP_PITCH_RANGE.x * 0.96, JUMP_PITCH_RANGE.y * 0.98)

	_play_spatial_folder_sound(JUMP_SOUNDS_FOLDER, JUMP_VOLUME_DB, pitch_range, sound_fade_out_seconds)


func _handle_dash_sound():
	_play_spatial_folder_sound(DASH_SOUNDS_FOLDER, DASH_VOLUME_DB, DASH_PITCH_RANGE, sound_fade_out_seconds)



func _play_slide_sound() -> void:
	# Slide pitch varies with remaining slide time and whether sprinting
	var slide_ratio := 0.0
	if sliding_length > 0.0:
		slide_ratio = clampf((slide_timer + 0.1) / maxf(sliding_length, 0.0001), 0.0, 1.0)
	var sway := lerpf(1.0, 1.15, slide_ratio)
	var pitch_range := Vector2(SLIDE_PITCH_RANGE.x * sway, SLIDE_PITCH_RANGE.y * sway)
	if is_sprinting:
		pitch_range = Vector2(pitch_range.x * 1.04, pitch_range.y * 1.06)
	elif is_crouching:
		pitch_range = Vector2(pitch_range.x * 0.96, pitch_range.y * 0.98)

	_play_spatial_stream_sound(SLIDE_SFX, SLIDE_VOLUME_DB, SLIDE_SOUND_TAG, slide_sound_fade_out_seconds, pitch_range)

func _handle_land_sound():
	if landing_sound_limit_timer > 0.0:
		return true

	# Vary landing pitch by fall intensity
	var pitch_range: Vector2 = LAND_PITCH_RANGE
	# Use last frame vertical velocity to judge landing severity
	var fall_v = last_velocity.y
	if fall_v < -12.0:
		# Hard landing: raise pitch/range slightly
		pitch_range = Vector2(LAND_PITCH_RANGE.x * 1.12, LAND_PITCH_RANGE.y * 1.18)
	elif fall_v < -6.0:
		# Medium landing
		pitch_range = Vector2(LAND_PITCH_RANGE.x * 1.04, LAND_PITCH_RANGE.y * 1.06)
	elif is_crouching:
		# Crouched landing tends to be quieter/lower
		pitch_range = Vector2(LAND_PITCH_RANGE.x * 0.96, LAND_PITCH_RANGE.y * 0.98)

	_play_spatial_folder_sound(LAND_SOUNDS_FOLDER, LAND_VOLUME_DB, pitch_range, sound_fade_out_seconds)
	landing_sound_limit_timer = landing_sound_limit_time

	return true


func _play_spatial_folder_sound(folder_path: String, volume_db: float, pitch_range: Vector2, fade_out_seconds: float = 0.15) -> void:
	var request := AudioManager.SoundRequest.new()
	request.folder_path = folder_path
	request.playback_kind = AudioManager.PlaybackKind.SPATIAL_3D
	request.global_position = camera_node.global_position
	request.bus_category = AudioManager.BusCategory.SFX
	request.volume_db = volume_db
	request.pitch_range = pitch_range
	request.search_recursively = true
	request.fade_out_seconds = fade_out_seconds
	AudioManager.play_sound(request)


func _play_spatial_stream_sound(stream: AudioStream, volume_db: float = 0.0, unique_tag: StringName = &"", fade_out_seconds: float = 0.15, pitch_range: Vector2 = SLIDE_PITCH_RANGE) -> void:
	var request := AudioManager.SoundRequest.new()
	request.stream = stream
	request.playback_kind = AudioManager.PlaybackKind.SPATIAL_3D
	request.global_position = camera_node.global_position
	request.bus_category = AudioManager.BusCategory.SFX
	request.volume_db = volume_db
	request.pitch_range = pitch_range
	request.unique_tag = unique_tag
	request.fade_out_seconds = fade_out_seconds
	AudioManager.play_sound(request)

