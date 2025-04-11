# ================= PLAYER SCRIPT =================
extends CharacterBody3D
# ================= NODES =================
@onready var head: Node3D = $Head
@onready var Camera: Camera3D = $Head/Camera3D
# ================= PLAYER SETTINGS =================
@onready var animationPlayer = $AuxScene/AnimationPlayer
@export var WALK_SPEED = 3.0
@export var CROUCH_SPEED = 1.5
@export var SPRINT_SPEED = 4.5 
@export var JUMP_VELOCITY = 4.8
@export var acceleration := 7.0
@export var air_acceleration := 3.0
var speed = WALK_SPEED
# ================= CAMERA SETTINGS =================
@export var sensitivity: float = 0.07
@export var invert_y: bool = false
var rotation_x: float = 0.0
# ================= CAMERA BOB & SHAKE =================
@export var BOB_FREQ = 2.4
@export var BOB_AMP = 0.08
@export var SHAKE_INTENSITY_WALK = 0.0005
@export var SHAKE_INTENSITY_SPRINT = 0.01
@export var shake_amount = 0.0
@export var shake_target = Vector3.ZERO
@export var shake_offset = Vector3.ZERO
var rng = RandomNumberGenerator.new()
var t_bob = 0.0
# ================= FOV SETTINGS =================
@export var normal_fov: float = 70.0
@export var sprint_fov: float = 85.0
@export var BASE_FOV = 75.0
@export var FOV_CHANGE = 1.5
# ================= CAMERA SWITCH =================
var firstperson = true
var thirdperson = false
# ================= GRAVITY =================
var gravity = 9.8
# ================= INPUT =================
func _input(event):
	if event is InputEventMouseMotion:
		rotate_camera(event.relative)

func rotate_camera(relative_motion: Vector2):
	var mouse_x = -relative_motion.x * sensitivity
	var mouse_y = relative_motion.y * sensitivity * (1 if invert_y else -1)
	
	# Yaw - rotate player left/right
	rotate_y(deg_to_rad(mouse_x))
	
	# Pitch - clamp camera up/down
	rotation_x = clamp(rotation_x + mouse_y, -90, 90)
	Camera.rotation_degrees.x = rotation_x

# ================= PHYSICS =================
func _physics_process(delta):
# ================= ANIMATIONS =================
	var move_input := Input.get_vector("Move_Left", "Move_Right", "Move_Forward", "Move_Back")
	var is_moving := move_input.length() > 0
	var is_sprinting := Input.is_action_pressed("Sprint") and Input.is_action_pressed("Move_Forward")

	if is_sprinting:
		animationPlayer.play("Running")
	elif is_moving:
		animationPlayer.play("Walking(1)")
	else:
		animationPlayer.play("Idle")

# ================= CAMERA SWITCH =================
	if Input.is_action_just_pressed("Switch") and not thirdperson:
		firstperson = false
		thirdperson = true
		animationPlayer.play("CameraSwitch")

	if Input.is_action_just_pressed("SwitchBack") and not firstperson:
		thirdperson = false
		firstperson = true
		animationPlayer.play("CameraSwitchBack")



# ================= GRAVITY =================
	if not is_on_floor():
		velocity.y -= gravity * delta
# ================= VARIABLES =================
	var input_dir = Input.get_vector("Move_Left", "Move_Right", "Move_Forward", "Move_Back")
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()

	# Convert to camera-relative direction
	var camera_basis = head.get_global_transform().basis
	var forward_dir = camera_basis.z.normalized()
	var right_dir = camera_basis.x.normalized()
	var final_dir = (right_dir * direction.x + forward_dir * direction.z).normalized()
# ================= SPRINT & WALKING =================
	if Input.is_action_just_pressed("Sprint") and Input.is_action_just_pressed("Move_Forward"):
		speed = SPRINT_SPEED
		shake_amount = SHAKE_INTENSITY_SPRINT
	elif Input.is_action_just_released("Sprint"):
		speed = WALK_SPEED
		shake_amount = SHAKE_INTENSITY_WALK
		
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
# ================= JUMP =================
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	move_and_slide()
# ================= FOV =================
	# FOV
	adjust_fov(delta)

func adjust_fov(delta):
	var target_fov = sprint_fov if Input.is_action_pressed("Sprint") else normal_fov
	Camera.fov = lerp(Camera.fov, target_fov, delta * 8.0)
# ================= CAMERA EFFECTS =================
	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	Camera.transform.origin = _headbob(t_bob) + _bodycam_shake(delta)
	
func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos
	
func _bodycam_shake(delta: float) -> Vector3:
	if velocity.length() > 0 and is_on_floor():
		shake_target.x = rng.randf_range(-shake_amount, shake_amount)
		shake_target.y = rng.randf_range(-shake_amount, shake_amount)
		shake_offset = lerp(shake_offset, shake_target, delta * 5.0)
	else:
		shake_offset = lerp(shake_offset, Vector3.ZERO, delta * 5.0)
	return shake_offset




func _ready() -> void:
	firstperson = true
	animationPlayer.play("Idle")
