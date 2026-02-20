extends Node
class_name PelletsManager

@export var ghost_array: Array[Ghost]
@onready var ui: UI = get_tree().get_first_node_in_group("ui")

var pellets_eaten := 0
var eaten_ghost_counter := 0

func _ready():
	add_to_group("pellets_manager")
	for ghost in ghost_array:
		ghost.run_away_timeout.connect(_on_run_away_finished)

func _on_pellet_eaten(power: bool):
	pellets_eaten += 1
	SoundManager.play_sfx("chomp")

	if power:
		GameManager.add_power_pellet_points()
		SoundManager.play_sfx("powerpellet")
		for ghost in ghost_array:
			ghost.enter_frightened()
	else:
		GameManager.add_pellet_points()

func _on_run_away_finished():
	eaten_ghost_counter += 1
	if eaten_ghost_counter == ghost_array.size():
		GameManager.reset_points_for_ghosts()
		eaten_ghost_counter = 0
