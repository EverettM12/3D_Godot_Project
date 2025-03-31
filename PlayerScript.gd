extends CharacterBody3D

var speed = WALK_SPEED 
@export var WALK_SPEED = 2.0
@export var SPRINT_SPEED = 5.0
@export var JUMP_VELOCITY = 4.8
@export var SENSITIVITY = 0.004

# Bob variables
@export var BOB_FREQ = 2.4
@export var BOB_AMP = 0.08
@export var t_bob = 0.0

# FOV variables
@export var BASE_FOV = 75.0
@export var FOV_CHANGE = 1.5

# Body cam shake variables
@export var SHAKE_INTENSITY_WALK = 0.05
@export var SHAKE_INTENSITY_SPRINT = 0.01
@export var shake_amount = 0.0
@export var shake_target = Vector3.ZERO
@export var shake_offset = Vector3.ZERO
var rng = RandomNumberGenerator.new()


var gravity = 9.8

#Gun Variables
@onready var shot_counter = $ShotCounter
@export var is_reloading = false



@onready var head: Node3D = $Head
@onready var Camera: Camera3D = $Head/Camera3D  
@export var sensitivity: float = 0.1  # Mouse sensitivity
@export var invert_y: bool = false   # Invert Y axis if needed

var rotation_x: float = 0.0  # Vertical rotation limit

# FOV settings
@export var normal_fov: float = 70.0  # Default FOV
@export var sprint_fov: float = 85.0  # FOV when sprinting




func _input(event):
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
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	
func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		head.rotate_y(-event.relative.x * sensitivity)
		Camera.rotate_x(-event.relative.y * sensitivity)
		Camera.rotation.x = clamp(Camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func _physics_process(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta


# Handle movement
	var input_dir = Input.get_vector("Move_Left", "Move_Right", "Move_Forward", "Move_Back")
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()

	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)


	# Handle Jump
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

# Handle Sprint
	if Input.is_action_just_pressed("Sprint"):
		speed = SPRINT_SPEED
		shake_amount = SHAKE_INTENSITY_SPRINT
		$Head/Camera3D/PlayerAnimation.play("Running")
	elif Input.is_action_just_released("Sprint"):
		speed = WALK_SPEED
		shake_amount = SHAKE_INTENSITY_WALK
		$Head/Camera3D/PlayerAnimation.play("UnRunning")
		if $Head/Camera3D/PlayerAnimation.current_animation == "UnRunning" and $Head/Camera3D/PlayerAnimation.animation_finished:
			$Head/Camera3D/PlayerAnimation.play("Idle")


	

	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	Camera.transform.origin = _headbob(t_bob) + _bodycam_shake(delta)

	# FOV adjustment
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	Camera.fov = lerp(Camera.fov, target_fov, delta * 8.0)






	# Shooting logic
	if Input.is_action_just_pressed("Shoot") and not is_reloading:
		$Head/Camera3D/Sketchfab_Scene/AnimationPlayer.play("Shoot")
		
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

# Start reloading and prevent shooting
func start_reload():
	is_reloading = true
	$Head/Camera3D/Sketchfab_Scene/AnimationPlayer.play("Reload")
	
	# Wait for reload animation to finish before allowing shooting again
	var reload_duration = $Head/Camera3D/Sketchfab_Scene/AnimationPlayer.get_animation("Reload").length
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

# 
