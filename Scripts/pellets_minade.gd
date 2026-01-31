extends Node

var total_pellets_count
var pellets_eaten = 0

@onready var ui: CanvasLayer = $"../ui"
@export var ghost_array: Array[Ghost]


func _ready():
	var pellets = self.get_children() as Array[Pellet]
	total_pellets_count = pellets.size()
	for pellet in pellets:
			pellet.pellet_eaten.connect(on_pellet_eaten)

func on_pellet_eaten(should_allow_eating_ghosts: bool):
	pellets_eaten += 1

	if should_allow_eating_ghosts:
		for ghosts in ghost_array:
			ghosts.run_away_from_pacman()
	if pellets_eaten == total_pellets_count:
		ui.game_won()
