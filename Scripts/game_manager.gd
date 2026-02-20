extends Node

# -----------------
# POINT CONSTANTS
# -----------------
const PELLET_POINTS = 10
const POWER_PELLET_POINTS = 50
const BASE_POINTS_FOR_GHOST_VALUE = 200
const EXTRA_LIFE_SCORE := 10000

# -----------------
# GAME STATE
# -----------------
var points := 0
var points_for_ghost_eaten := BASE_POINTS_FOR_GHOST_VALUE
var pellets_eaten := 0
var total_pellets := 0
var eaten_ghost_counter := 0
var extra_life := false
var level_finished := false
var is_safe_state := false

var ui: UI
var lives := 3
var level := 1
var ghost_array: Array[Ghost] = []

# -----------------
# FRUIT SYSTEM (required additions)
# -----------------
@export var fruit_spawn_position: NodePath

var fruit_spawned_1 := false
var fruit_spawned_2 := false

var fruit_table = {
	1: preload("res://Scenes/cherry.tscn"),
	2: preload("res://Scenes/bell.tscn"),
	3: preload("res://Scenes/apple.tscn"),
	4: preload("res://Scenes/galaxian_starrship.tscn"),
	5: preload("res://Scenes/key.tscn"),
	6: preload("res://Scenes/melon.tscn"),
	7: preload("res://Scenes/orange.tscn"),
	8: preload("res://Scenes/straw_berry.tscn"),
}

# -----------------
# SETUP
# -----------------
func _ready():
	ui = get_tree().get_first_node_in_group("ui")

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	await calculate_pellets()

	SoundManager.play_opening()

	await get_tree().create_timer(
		SoundManager.music_player.stream.get_length()
	).timeout

	SoundManager.start_siren()

func calculate_pellets():
	await get_tree().process_frame
	total_pellets = get_tree().get_nodes_in_group("pellet").size()
	print("TOTAL PELLETS:", total_pellets)
	pellets_eaten = 0
	level_finished = false
	fruit_spawned_1 = false
	fruit_spawned_2 = false

	if ui == null:
		ui = get_tree().get_first_node_in_group("ui")

	update_ui()

	ghost_array = []

	var ghosts = get_tree().get_nodes_in_group("ghost")

	for g in ghosts:
		if g is Ghost:
			ghost_array.append(g)
			g.run_away_timeout.connect(_on_run_away_finished)

func set_total_pellets(amount: int):
	total_pellets = amount
	pellets_eaten = 0
	level_finished = false 

func register_ghosts(ghosts: Array[Ghost]):
	ghost_array = ghosts

	for ghost in ghost_array:
		ghost.run_away_timeout.connect(_on_run_away_finished)

# -----------------
# PELLET LOGIC
# -----------------
func pellet_eaten(power: bool):
	pellets_eaten += 1
	print("PELLET COUNT:", pellets_eaten, "/", total_pellets)

	check_spawn_fruit()

	if power:
		SoundManager.play_sfx("power_eat")
		add_power_pellet_points()

		SoundManager.start_power_mode()

		reset_points_for_ghosts()
		eaten_ghost_counter = 0

		for ghost in ghost_array:
			ghost.enter_frightened()
	else:
		SoundManager.play_sfx("chomp")
		add_pellet_points()

	check_level_complete()
	print("Pellet eaten")

func add_pellet_points():
	points += PELLET_POINTS
	update_ui()

func add_power_pellet_points():
	points += POWER_PELLET_POINTS
	update_ui()

func ghost_eaten():
	points += points_for_ghost_eaten
	update_ui()

	points_for_ghost_eaten += BASE_POINTS_FOR_GHOST_VALUE

func reset_points_for_ghosts():
	points_for_ghost_eaten = BASE_POINTS_FOR_GHOST_VALUE

func lose_life():
	lives -= 1
	update_ui()

	if lives <= 0:
		game_over()

func game_over():
	get_tree().paused = true
	if ui:
		ui.game_lost()

func update_ui():
	if ui == null:
		ui = get_tree().get_first_node_in_group("ui")

	if ui:
		ui.set_score(points)
		ui.set_lifes(lives)

	check_extra_life()

# -----------------
# FRUIT SPAWN LOGIC
# -----------------
func check_spawn_fruit():
	if pellets_eaten >= 70 and not fruit_spawned_1:
		spawn_fruit()
		fruit_spawned_1 = true

	elif pellets_eaten >= 170 and not fruit_spawned_2:
		spawn_fruit()
		fruit_spawned_2 = true

func get_current_fruit():
	if fruit_table.has(level):
		return fruit_table[level]

	return preload("res://Scenes/key.tscn")

func get_fruit_spawn():
	var nodes = get_tree().get_nodes_in_group("fruit_spawn")
	return nodes[0] if nodes.size() > 0 else null

func spawn_fruit():
	var spawn = get_fruit_spawn()

	if spawn == null:
		return
	var fruit_scene = get_current_fruit()
	var fruit = fruit_scene.instantiate()

	get_tree().current_scene.add_child(fruit)
	fruit.global_position = spawn.global_position

# -----------------
# FRIGHTENED END
# -----------------
func _on_run_away_finished():
	eaten_ghost_counter += 1

	if eaten_ghost_counter == ghost_array.size():
		reset_points_for_ghosts()
		eaten_ghost_counter = 0
		SoundManager.stop_power_mode()

func pause_on_ghost_eaten():
	get_tree().paused = true
	await get_tree().create_timer(0.6).timeout
	get_tree().paused = false

func check_level_complete():
	if level_finished:
		return

	if total_pellets == 0:
		push_error("No pellets detected!")
		return

	if pellets_eaten >= total_pellets:
		print("LEVEL SHOULD COMPLETE")
		level_complete_sequence()

func check_extra_life():
	if points >= EXTRA_LIFE_SCORE and not extra_life:
		extra_life = true
		SoundManager.play_sfx("extralive")

func level_complete_sequence():
	level_finished = true
	is_safe_state = true

	SoundManager.stop_loop_sfx()
	SoundManager.stop_siren()

	if ui:
		ui.game_won()

	await flash_maze()

	SoundManager.play_sfx("level_clear")

	await get_tree().create_timer(2.0).timeout

	restart_level()
	is_safe_state = false


func restart_level():
	level += 1

	level_finished = false
	points_for_ghost_eaten = BASE_POINTS_FOR_GHOST_VALUE

	get_tree().reload_current_scene()

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await calculate_pellets()

func flash_maze():
	var maze := get_tree().get_first_node_in_group("maze") as CanvasItem

	if not maze:
		return

	var normal_color := Color(0.1, 0.4, 1.0)
	var flash_color := Color(2, 2, 2) 

	for i in range(6):
		maze.modulate = flash_color
		await get_tree().create_timer(0.15).timeout

		maze.modulate = normal_color
		await get_tree().create_timer(0.15).timeout

func on_player_died():
	lose_life()

	if lives > 0:
		reset_round()
	else:
		game_over()

func reset_round():
	is_safe_state = true
	get_tree().paused = true

	await get_tree().create_timer(1.0).timeout

	reset_player()
	await reset_ghosts()

	get_tree().paused = false
	is_safe_state = false

func reset_player():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = player.start_position.global_position
		player.next_movement_direction = Vector2.ZERO
		player.movement_direction = Vector2.ZERO
		player.alive = true
		player.set_physics_process(true)

func reset_ghosts():
	for ghost in ghost_array:
		await ghost._return_home()

func start_level(level: int):
	self.level = level
	is_safe_state = true
	SoundManager.play_music("opening")

	# Wait for opening sound to finish
	var opening_duration = SoundManager.music_player.stream.get_length()
	await get_tree().create_timer(opening_duration).timeout

	is_safe_state = false 

	# Reset pellets eaten count and calculate total
	await calculate_pellets()

	reset_ghosts()

	reset_player()
