extends CharacterBody3D

@export var speed : float = 5.0
@export var jump_height : float = 1.0
@export var fall_multiplier : float = 2.5
@export var aim_multiplier : float = 0.7

@export var max_hitpoints : int = 100
var hitpoints : int = max_hitpoints:
	set(value):
		if value < hitpoints:
			damage_animation_player.stop(false)
			damage_animation_player.play("TakeDamage")
		hitpoints = value
		#print(hitpoints)
		if hitpoints <= 0:
			game_over_menu.game_over()

@onready var camera_pivot: Node3D = $CameraPivot
@onready var damage_animation_player: AnimationPlayer = $DamageTexture/DamageAnimationPlayer
@onready var game_over_menu: Control = $GameOverMenu
@onready var ammo_handler: AmmoHandler = %AmmoHandler

@onready var smooth_camera: Camera3D = %SmoothCamera
@onready var smooth_camera_fov := smooth_camera.fov

@onready var weapon_camera: Camera3D = %WeaponCamera
@onready var weapon_camera_fov := weapon_camera.fov

var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")
var mouse_motion := Vector2.ZERO

var controller = null
var controller_look_input = Vector2.ZERO

func _ready() -> void:
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if Input.get_connected_joypads().size() > 0:
		controller = Input.get_connected_joypads()[0]
	if controller == null:
		print("No joypads connected, using keyboard and mouse")
	else:
		printt("Using controller: ", controller)

func _process(delta: float) -> void:
	
	if Input.is_action_pressed("aim"):
		smooth_camera.fov = lerp(smooth_camera.fov, smooth_camera_fov * aim_multiplier, delta * 20.0)
		weapon_camera.fov = lerp(weapon_camera.fov, weapon_camera_fov * aim_multiplier, delta * 20.0)
	else:
		smooth_camera.fov = lerp(smooth_camera.fov, smooth_camera_fov, delta * 30.0)
		weapon_camera.fov = lerp(weapon_camera.fov, weapon_camera_fov, delta * 30.0)

func _physics_process(delta: float) -> void:
	
	handle_camera_rotation()
	
	if not is_on_floor():
		if velocity.y >= 0:
			velocity.y -= gravity * delta
		else:
			velocity.y -= gravity * delta * fall_multiplier

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = sqrt(jump_height * 2.0 * gravity)

	var input_dir = Vector2.ZERO
	
	if controller != null:
		
		var deadzone = 0.1
		
		var move_axis_x = Input.get_joy_axis(controller, JOY_AXIS_LEFT_X)
		if absf(move_axis_x) <= deadzone:
			move_axis_x = 0
		
		var move_axis_y = Input.get_joy_axis(controller, JOY_AXIS_LEFT_Y)
		if absf(move_axis_y) <= deadzone:
			move_axis_y = 0
		
		input_dir = Vector2(move_axis_x, move_axis_y)
	
	else:
		
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		if Input.is_action_pressed("aim"):
			velocity.x *= aim_multiplier
			velocity.z *= aim_multiplier
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

func _input(event: InputEvent) -> void:
	
	if controller != null:
		
		controller_look_input = Vector2(
			Input.get_joy_axis(controller, JOY_AXIS_RIGHT_X),
			Input.get_joy_axis(controller, JOY_AXIS_RIGHT_Y)
			) * 0.01
			
		#printt("controller_look_input: ", controller_look_input)
		
		if Input.is_action_pressed("aim"):
			controller_look_input *= aim_multiplier
	
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			mouse_motion = -event.relative * 0.001
			if Input.is_action_pressed("aim"):
				mouse_motion *= aim_multiplier
	
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
func handle_camera_rotation() -> void:
	
	if controller != null:
		rotate_y(-controller_look_input.x * 3)
		camera_pivot.rotate_x(-controller_look_input.y * 3)
	
	else:
		rotate_y(mouse_motion.x)
		camera_pivot.rotate_x(mouse_motion.y)
	
	camera_pivot.rotation_degrees.x = clampf(
		camera_pivot.rotation_degrees.x, -90.0, 90.0
	)
	mouse_motion = Vector2.ZERO
