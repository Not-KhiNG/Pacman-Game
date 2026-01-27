extends CharacterBody2D

@export var speed := 120.0
@export var pacman: Node2D  # Drag your Pac-Man node here in the editor

@onready var agent: NavigationAgent2D = $NavigationAgent2D

func _ready():
	# Optional: smooth turning
	agent.path_desired_distance = 4
	agent.target_desired_distance = 4
	agent.avoidance_enabled = false

func _physics_process(delta):
	if not pacman:
		return
	
	# Set Pac-Man as the target
	agent.target_position = pacman.global_position

	# Get the next point along the path
	var next_pos = agent.get_next_path_position()
	if next_pos == null:
		return
	var direction = (next_pos - global_position).normalized()

	# Move the ghost
	velocity = direction * speed
	move_and_slide()
