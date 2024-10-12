extends CharacterBody3D
class_name Enemy

@export var speed : float = 5.0

@export var max_hitpoints : int = 100
@export var attack_range : float = 1.5
@export var attack_damage : int = 20

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]

var player
var provoked : bool = false
var aggro_range : float = 12.0

var hitpoints : int = max_hitpoints:
	set(value):
		hitpoints = value
		if hitpoints <= 0:
			queue_free()
		provoked = true

func _ready() -> void:
	
	player = get_tree().get_first_node_in_group("Player")

func _process(_delta: float) -> void:
	
	if provoked == true:
		navigation_agent_3d.target_position = player.global_position

func _physics_process(delta: float) -> void:
	
	var next_position = navigation_agent_3d.get_next_path_position()
	
	if not is_on_floor():
		if velocity.y >= 0:
			velocity.y -= gravity * delta
		else:
			velocity.y -= gravity * delta
	
	var direction = global_position.direction_to(next_position)
	var distance = global_position.distance_to(player.global_position)
	
	if distance <= aggro_range:
		provoked = true
	
	if provoked == true:
		if distance <= attack_range:
			playback.travel("Attack")
	
	if direction:
		if distance > 0.001:
			look_at_target(direction)
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	move_and_slide()

func look_at_target(direction: Vector3) -> void:
	
	var adjusted_direction = direction
	adjusted_direction.y = 0
	if snappedf(direction.x, 0.0001) != 0.0:
		look_at(global_position + adjusted_direction, Vector3.UP, true)

func attack() -> void:
	
	player.hitpoints -= attack_damage
