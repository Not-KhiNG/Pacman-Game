extends Area2D
class_name Ghost

signal direction_change(direction: String)
signal run_away_timeout

enum GhostState {
	SCATTER,
	CHASE,
	RUN_AWAY,
	EATEN,
	STARTING_AT_HOME
}

@export var speed := 120.0
@export var frightened_speed := 70.0
@export var eaten_speed := 240.0

@export var tile_map: TileMap
@export var chasing_target: Node2D
@export var scatter_targets: Array[Node2D]
@export var at_home_targets: Array[Node2D]
@export var start_at_home := false
@export var scatter_time := 8.0
@export var run_away_time := 8.0
@export var color: Color

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var scatter_timer: Timer = $ScatterTimer
@onready var run_away_timer: Timer = $RunAwayTimer
@onready var chase_update_timer: Timer = $UpdateChasingTargetPositionTimer
@onready var at_home_timer: Timer = $AtHomeTimer

@onready var body_sprite: BodySprite = $BodySprite
@onready var eye_sprite: EyeSprite = $EyeSprite

var current_state := GhostState.SCATTER
var current_scatter_index := 0
var current_home_index := 0
var direction: String
var is_blinking := false

func _ready():
	navigation_agent.path_desired_distance = 4
	navigation_agent.target_desired_distance = 4
	navigation_agent.target_reached.connect(_on_target_reached)

	scatter_timer.wait_time = scatter_time
	run_away_timer.wait_time = run_away_time

	scatter_timer.timeout.connect(start_chase)
	run_away_timer.timeout.connect(_on_run_away_timeout)
	at_home_timer.timeout.connect(_scatter)

	call_deferred("setup")

func setup():
	position = at_home_targets[0].position
	navigation_agent.set_navigation_map(tile_map.get_navigation_map(0))
	NavigationServer2D.agent_set_map(navigation_agent.get_rid(), tile_map.get_navigation_map(0))

	body_sprite.normal()
	eye_sprite.hide_eyes()

	if start_at_home:
		start_home()
	else:
		_scatter()

func _process(delta):
	if current_state == GhostState.RUN_AWAY \
	and !is_blinking \
	and run_away_timer.time_left < run_away_timer.wait_time / 2 :
		is_blinking = true
		body_sprite.start_blinking()

	var next_pos = navigation_agent.get_next_path_position()
	var velocity = (next_pos - global_position).normalized() * get_speed() * delta
	update_direction(velocity)
	global_position += velocity

func get_speed():
	match current_state:
		GhostState.RUN_AWAY:
			return frightened_speed
		GhostState.EATEN:
			return eaten_speed
		_:
			return speed

func update_direction(v: Vector2):
	var new_dir := direction
	if abs(v.x) > abs(v.y):
		new_dir = "right" if v.x > 0 else "left"
	else:
		new_dir = "down" if v.y > 0 else "up"

	if new_dir != direction:
		direction = new_dir
		direction_change.emit(direction)

# -----------------------------
# PAC-MAN EATS GHOST
# -----------------------------
func get_eaten():
	if current_state == GhostState.EATEN:
		return

	current_state = GhostState.EATEN
	body_sprite.visible = false
	eye_sprite.visible = true
	navigation_agent.target_position = at_home_targets[current_home_index].position

# -----------------------------
# MOVEMENT STATES
# -----------------------------
func _scatter():
	current_state = GhostState.SCATTER
	is_blinking = false
	scatter_timer.start()
	body_sprite.normal()
	eye_sprite.hide_eyes()
	navigation_agent.target_position = scatter_targets[current_scatter_index].position

func start_chase():
	current_state = GhostState.CHASE
	is_blinking = false
	chase_update_timer.start()
	body_sprite.normal()
	eye_sprite.hide_eyes()
	navigation_agent.target_position = chasing_target.position

func run_away_from_pacman():
	if current_state != GhostState.RUN_AWAY:
		current_state = GhostState.RUN_AWAY
		is_blinking = false
		chase_update_timer.stop()
		scatter_timer.stop()
		body_sprite.run_away()
		eye_sprite.hide_eyes()
		run_away_timer.start()
	navigation_agent.target_position = tile_map.get_random_empty_cell_position()

func _on_run_away_timeout():
	current_state = GhostState.CHASE
	is_blinking = false
	body_sprite.normal()
	eye_sprite.hide_eyes()
	run_away_timeout.emit()
	start_chase()

func start_home():
	current_state = GhostState.STARTING_AT_HOME
	at_home_timer.start()
	body_sprite.visible = true
	eye_sprite.hide_eyes()
	navigation_agent.target_position = at_home_targets[current_home_index].position

func _on_target_reached():
	match current_state:
		GhostState.SCATTER:
			current_scatter_index = (current_scatter_index + 1) % scatter_targets.size()
			navigation_agent.target_position = scatter_targets[current_scatter_index].position

		GhostState.RUN_AWAY:
			run_away_from_pacman()

		GhostState.EATEN:
			# Reached home, restore ghost
			body_sprite.visible = true
			eye_sprite.hide_eyes()
			start_home()

		GhostState.STARTING_AT_HOME:
			current_home_index = (current_home_index + 1) % at_home_targets.size()
			_scatter()
