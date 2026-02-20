extends Area2D
class_name Ghost

# ============================
# STATES & TYPES
# ============================
enum GhostState { 
	SCATTER, 
	CHASE, 
	RUN_AWAY, 
	RETURNING_HOME 
	}
enum GhostType { 
	BLINKY, 
	PINKY, 
	INKY, 
	CLYDE 
	}

signal direction_change(direction: String)
signal run_away_timeout

const TILE_SIZE := 24

@export var ghost_type: GhostType
@export var blinky_ref: Node2D
@export var home_positions: Array[Node2D] = []


@export var speed := 120.0
@export var eaten_speed := 240.0
@export var scatter_wait_time := 8.0
@export var frightened_time := 6.0
@export var blink_time := 2.0

@export var tile_map: TileMap
@export var chasing_target: Player
@export var movement_targets: Resource
@export var starting_position: Node2D
@export var is_starting_at_home := false
@export var color: Color
@export var starting_texture: Texture2D

@onready var scatter_timer: Timer = $ScatterTimer
@onready var run_away_timer: Timer = $RunAwayTimer
@onready var blink_timer: Timer = $BlinkTimer
@onready var chase_timer: Timer = $UpdateChasingTargetPositionTimer

@onready var body_sprite: BodySprite = $BodySprite
@onready var eye_sprite: EyeSprite = $EyeSprite
@onready var points_label: Label = $PointsLabel
@onready var nav: NavigationAgent2D = $NavigationAgent2D

var current_state := GhostState.SCATTER
var scatter_index := 0
var direction := ""
var last_velocity := Vector2.ZERO

# ============================
# READY
# ============================
func _ready():
	body_entered.connect(_on_body_entered)
	body_sprite.starting_texture = starting_texture
	body_sprite.move()
	eye_sprite.show_eyes()

	scatter_timer.timeout.connect(_on_scatter_timeout)
	run_away_timer.timeout.connect(_on_run_away_timeout)
	blink_timer.timeout.connect(_on_blink_timeout)
	chase_timer.timeout.connect(_update_chase_target)
	nav.target_reached.connect(_on_target_reached)

	if starting_position:
		global_position = starting_position.global_position

	if is_starting_at_home:
		_return_home()
	else:
		_enter_scatter()

	blink_timer.one_shot = true
	run_away_timer.one_shot = true

# ============================
# MOVEMENT
# ============================
func _physics_process(delta):


	# --- RETURN HOME (EYES) — DIRECT MOVEMENT ---
	#if current_state == GhostState.RETURNING_HOME and home_positions.size() > 0:
		#var home := home_positions[0]
		#var dir: Vector2 = home.global_position - global_position

		# reached home
		#if dir.length() < 4:
			#_revive_from_home()
			#return

		#global_position += dir.normalized() * eaten_speed * delta
		#_update_direction(dir)
		#return


	# --- NORMAL NAVIGATION ---

	# never stop thinking when navigation finishes
	if nav.is_navigation_finished():
		_choose_new_target()

	var next := nav.get_next_path_position()
	var vel := (next - global_position).normalized()
	last_velocity = vel

	var spd := speed

	if current_state == GhostState.RUN_AWAY:
		spd = speed * 0.6
	elif current_state == GhostState.RETURNING_HOME:
		spd = eaten_speed

	global_position += vel * spd * delta
	_update_direction(vel)

func _update_direction(v: Vector2):
	var new_dir := direction
	if abs(v.x) > abs(v.y):
		new_dir = "right" if v.x > 0 else "left"
	else:
		new_dir = "down" if v.y > 0 else "up"

	if new_dir != direction:
		direction = new_dir
		direction_change.emit(direction)

func _reverse_direction():
	if last_velocity == Vector2.ZERO:
		return

	var reverse_target = global_position - last_velocity * TILE_SIZE
	nav.target_position = reverse_target

# ============================
# TARGET SELECTION
# ============================
func _choose_new_target():
	match current_state:
		GhostState.RUN_AWAY:
			_run_away_from_player()

		GhostState.RETURNING_HOME:
			if home_positions.size() > 0:
				nav.target_position = home_positions[0].global_position
			#if current_state == GhostState.RETURNING_HOME and home_positions.size() > 0:
				#var home := home_positions[0]
				#var dir: Vector2 = home.global_position - global_position


		GhostState.SCATTER:
			_set_target(movement_targets.scatter_targets[scatter_index])

		GhostState.CHASE:
			_update_chase_target()

func _run_away_from_player():
	if not chasing_target:
		return

	var dir := (global_position - chasing_target.global_position).normalized()
	var target := global_position + dir * TILE_SIZE * 10
	nav.target_position = target

# ============================
# STATES
# ============================
func _enter_scatter():
	current_state = GhostState.SCATTER
	scatter_timer.start(scatter_wait_time)
	_set_target(movement_targets.scatter_targets[scatter_index])

func _enter_chase():
	current_state = GhostState.CHASE
	chase_timer.start()
	_update_chase_target()

func enter_frightened():
	if current_state == GhostState.RETURNING_HOME:
		return

	current_state = GhostState.RUN_AWAY

	chase_timer.stop()
	scatter_timer.stop()

	_reverse_direction()

	body_sprite.run_away()
	eye_sprite.hide_eyes()

	run_away_timer.start(frightened_time)
	blink_timer.start(frightened_time - blink_time)

	_run_away_from_player()

func get_eaten():
	if current_state != GhostState.RUN_AWAY:
		return

	SoundManager.play_sfx("eatghost")
	GameManager.ghost_eaten()

	run_away_timer.stop()
	blink_timer.stop()

	body_sprite.hide()
	eye_sprite.show_eyes()

	points_label.text = str(GameManager.points_for_ghost_eaten)
	points_label.show()
	await GameManager.pause_on_ghost_eaten()
	points_label.hide()

	_return_home()

func _return_home():
	current_state = GhostState.RETURNING_HOME

	chase_timer.stop()
	scatter_timer.stop()
	run_away_timer.stop()
	blink_timer.stop()

	body_sprite.hide()
	eye_sprite.show_eyes()

	if home_positions.size() > 0:
		nav.target_position = home_positions[0].global_position
	#if current_state == GhostState.RETURNING_HOME and home_positions.size() > 0:
		#var home := home_positions[0]
		#var dir: Vector2 = home.global_position - global_position

# ============================
# CHASE TARGETING
# ============================
func _update_chase_target():
	if not chasing_target:
		return

	match ghost_type:
		GhostType.BLINKY:
			nav.target_position = chasing_target.global_position

		GhostType.PINKY:
			nav.target_position = chasing_target.global_position + chasing_target.direction * TILE_SIZE * 4

		GhostType.INKY:
			if blinky_ref:
				var mid = chasing_target.global_position + chasing_target.direction * TILE_SIZE * 2
				nav.target_position = blinky_ref.global_position + (mid - blinky_ref.global_position) * 2

		GhostType.CLYDE:
			if global_position.distance_to(chasing_target.global_position) < TILE_SIZE * 8:
				_set_target(movement_targets.scatter_targets[0])
			else:
				nav.target_position = chasing_target.global_position

func _set_target(target: Variant):
	if target is Node2D:
		nav.target_position = target.global_position
	elif target is NodePath:
		var node := get_node_or_null(target) as Node2D
		if node:
			nav.target_position = node.global_position
	elif target is Vector2:
		nav.target_position = target

# ============================
# TIMERS
# ============================
func _on_scatter_timeout():
	_enter_chase()

func _on_run_away_timeout():
	if current_state != GhostState.RUN_AWAY:
		return

	body_sprite.move()
	eye_sprite.show_eyes()
	_enter_chase()

func _on_blink_timeout():
	eye_sprite.start_blinking()

# ============================
# TARGET REACHED
# ============================
func _on_target_reached():
	match current_state:

		GhostState.SCATTER:
			scatter_index = (scatter_index + 1) % movement_targets.scatter_targets.size()
			_set_target(movement_targets.scatter_targets[scatter_index])

		GhostState.RUN_AWAY:
			_run_away_from_player()

		GhostState.RETURNING_HOME:
			_revive_from_home()

func _revive_from_home():
	body_sprite.show()
	body_sprite.move()
	eye_sprite.show_eyes()

	current_state = GhostState.SCATTER
	scatter_index = 0

	_enter_scatter()

# ============================
# COLLISION
# ============================
func _on_body_entered(body):
	var player := body as Player
	if not player:
		return

	if GameManager.is_safe_state or not player.alive or get_tree().paused:
		return

	if current_state == GhostState.RUN_AWAY:
		get_eaten()
	elif current_state in [GhostState.CHASE, GhostState.SCATTER]:
		player.die()

func _on_global_mode_changed(new_mode: int) -> void:
	if current_state in [GhostState.RUN_AWAY, GhostState.RETURNING_HOME]:
		return

	match new_mode:
		GhostState.SCATTER:
			_enter_scatter()
		GhostState.CHASE:
			_enter_chase()
