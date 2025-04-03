extends CharacterBody3D

# Wall running variables
@export var WALL_RUN_SPEED = 50.0
@export var WALL_RUN_TIME = 1000.0  # Time before wall running stops automatically
var is_wall_running = false
var wall_normal = Vector3()
var wall_run_timer = 0.0

# Player movement variables
@export var WALK_SPEED = 5.0
@export var CROUCH_SPEED = 3.0
@export var SPRINT_SPEED = 8.0 
@export var JUMP_VELOCITY = 4.8
@export var acceleration := 7.0
@export var air_acceleration := 3.0
var speed = WALK_SPEED

# Bob variables
@export var BOB_FREQ = 2.4
@export var BOB_AMP = 0.08
@export var t_bob = 0.0

# FOV variables
@export var BASE_FOV = 75.0
@export var FOV_CHANGE = 1.5

# Camera shake variables
@export var SHAKE_INTENSITY_WALK = 0.0005
@export var SHAKE_INTENSITY_SPRINT = 0.01
@export var shake_amount = 0.0
@export var shake_target = Vector3.ZERO
@export var shake_offset = Vector3.ZERO
var rng = RandomNumberGenerator.new()

var gravity = 9.8

# Gun variables
@onready var shot_counter = $ShotCounter
@export var is_reloading = false

# Camera settings
var is_first_person: bool = true
@onready var third_person_camera: Camera3D = $"3rdPersonCamera"
@onready var head: Node3D = $Head
@onready var Camera: Camera3D = $Head/Camera3D
@export var sensitivity: float = 0.1  # Mouse sensitivity
@export var invert_y: bool = false   # Invert Y axis if needed

var rotation_x: float = 0.0  # Vertical rotation limit

# FOV settings
@export var normal_fov: float = 70.0  # Default FOV
@export var sprint_fov: float = 85.0  # FOV when sprinting

# Wall check distance
@export var wall_check_distance = 1.5  # Adjust as needed




func _input(event):
	
	
	if event is InputEventKey and event.pressed:
		if Input.is_action_just_pressed("SwitchCamera"):
			toggle_camera()
	
# Handle mouse motion input for camera rotation
	if event is InputEventMouseMotion:
		rotate_camera(event.relative)


func rotate_camera(relative_motion: Vector2):
	var mouse_x = -relative_motion.x * sensitivity
	var mouse_y = relative_motion.y * sensitivity * (1 if invert_y else -1)  # Fixed inversion logic

	# Rotate horizontally (yaw) on the Y axis
	rotate_y(deg_to_rad(mouse_x))

	# Rotate vertically (pitch) on X axis, clamp to avoid flipping
	rotation_x = clamp(rotation_x + mouse_y, -90, 90)
	Camera.rotation_degrees.x = rotation_x


# Movement and shooting
func _ready():
	 # Initially set to first-person
	Camera.visible = true
	third_person_camera.visible = false

	
func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		head.rotate_y(-event.relative.x * sensitivity)
		Camera.rotate_x(-event.relative.y * sensitivity)
		Camera.rotation.x = clamp(Camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func toggle_camera():
	if is_first_person:
		# Switch to third-person camera
		Camera.visible = false
		third_person_camera.visible = true
	else:
		# Switch to first-person camera
		Camera.visible = true
		third_person_camera.visible = false
	
	# Toggle the mode flag
	is_first_person = !is_first_person


func _physics_process(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

   # Handle wall run check
	wall_run_check()

	var input_dir = Input.get_vector("Move_Left", "Move_Right", "Move_Forward", "Move_Back")
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	
# Handle movement
	if Input.get_vector("Move_Left", "Move_Right", "Move_Forward", "Move_Back"):
		$Player/PlayerBodyAnimation.play("Walking")
	else:
		$Player/PlayerBodyAnimation.play("Stopped")
		

	# Get camera basis for proper movement direction
	var camera_basis = head.get_global_transform().basis
	var forward_dir = camera_basis.z.normalized()
	var right_dir = camera_basis.x.normalized()

	# Final movement direction relative to camera
	var final_dir = (right_dir * direction.x + forward_dir * direction.z).normalized()

	  # Wall running behavior
	if is_wall_running:
		# Apply wall running movement
		var wall_dir = wall_normal.cross(Vector3.UP).normalized()
		velocity.x = wall_dir.x * WALL_RUN_SPEED
		velocity.z = wall_dir.z * WALL_RUN_SPEED
		wall_run_timer -= delta
		if wall_run_timer <= 0:
			is_wall_running = false
	else:
		# Regular movement
		if is_on_floor():
			var target_speed = SPRINT_SPEED if Input.is_action_pressed("Sprint") else WALK_SPEED
			speed = lerp(speed, target_speed, delta * acceleration)
			if direction != Vector3.ZERO:
				velocity.x = final_dir.x * speed
				velocity.z = final_dir.z * speed
			else:
				velocity.x = lerp(velocity.x, 0.0, delta * acceleration)
				velocity.z = lerp(velocity.z, 0.0, delta * acceleration)
		else:
			velocity.x = lerp(velocity.x, final_dir.x * speed, delta * air_acceleration)
			velocity.z = lerp(velocity.z, final_dir.z * speed, delta * air_acceleration)


# Handle FOV change while sprinting
	adjust_fov(delta)


func adjust_fov(delta):
	var target_fov = sprint_fov if Input.is_action_pressed("Sprint") else normal_fov
	Camera.fov = lerp(Camera.fov, target_fov, delta * 5.0)

	# FOV adjustment
	var _velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	Camera.fov = lerp(Camera.fov, target_fov, delta * 8.0)


	# Handle Jump
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

# Handle Sprint
	if Input.is_action_just_pressed("Sprint") and Input.is_action_pressed("Move_Forward"):
		speed = SPRINT_SPEED
		shake_amount = SHAKE_INTENSITY_SPRINT
		$Head/Camera3D/PlayerAnimation.play("Running")
	elif Input.is_action_just_released("Sprint"):
		$Head/Camera3D/PlayerAnimation.play("UnRunning")
		if $Head/Camera3D/PlayerAnimation.current_animation == "UnRunning" and $Head/Camera3D/PlayerAnimation.animation_finished:
			$Head/Camera3D/PlayerAnimation.play("Idle")
			speed = WALK_SPEED
			shake_amount = SHAKE_INTENSITY_WALK
			
			

	
	

	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	Camera.transform.origin = _headbob(t_bob) + _bodycam_shake(delta)








	# Shooting logic
	if Input.is_action_just_pressed("Shoot") and not is_reloading:
		$Head/Camera3D/Gun/AnimationPlayer.play("Shoot")
		
		# Increment shot counter and check for reload
		if shot_counter.increment_shot():
			start_reload()


	if Input.is_action_just_pressed("Zoom"):
			$Head/Camera3D/PlayerAnimation.play("Zoom")
	elif Input.is_action_just_released("Zoom"):
			$Head/Camera3D/PlayerAnimation.play("UnZoom") 
	if $Head/Camera3D/PlayerAnimation.current_animation == "UnZoom":
		await $Head/Camera3D/PlayerAnimation.animation_finished
		$Head/Camera3D/PlayerAnimation.play("Idle")


	move_and_slide()



# Wall run detection (raycast)
func wall_run_check():
	var wall_ray_start = global_transform.origin
	var wall_ray_end = wall_ray_start + velocity.normalized() * wall_check_distance
	var space_state = get_world_3d().direct_space_state

	var query = PhysicsRayQueryParameters3D.new()
	query.from = wall_ray_start
	query.to = wall_ray_end
	query.exclude = [self]  # Exclude the character itself

	var result = space_state.intersect_ray(query)

	if result:
		# Wall detected, start wall running
		if !is_wall_running and Input.is_action_pressed("Move_Forward"):
			is_wall_running = true
			wall_normal = result.normal
			wall_run_timer = WALL_RUN_TIME
	else:
		# No wall, stop wall running
		is_wall_running = false



# Start reloading and prevent shooting
func start_reload():
	is_reloading = true
	$Head/Camera3D/Gun/AnimationPlayer.play("Reload")
	
	# Wait for reload animation to finish before allowing shooting again
	var reload_duration = $Head/Camera3D/Gun/AnimationPlayer.get_animation("Reload").length
	await get_tree().create_timer(reload_duration).timeout
	
	# Reload complete, allow shooting again
	is_reloading = false

# Head bobbing effect
func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

# Body camera shake effect
func _bodycam_shake(delta: float) -> Vector3:
	if velocity.length() > 0 and is_on_floor():  # Shake only when moving and grounded
		shake_target.x = rng.randf_range(-shake_amount, shake_amount)
		shake_target.y = rng.randf_range(-shake_amount, shake_amount)
		shake_offset = lerp(shake_offset, shake_target, delta * 5.0)
	else:
		shake_offset = lerp(shake_offset, Vector3.ZERO, delta * 5.0)
	return shake_offset
