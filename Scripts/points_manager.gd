extends Node

const PELLET_POINTS = 10
const POWER_PELLET_POINTS = 50
const BASE_POINTS_FOR_GHOST_VALUE = 200

var points = 0
var points_for_ghost_eaten = BASE_POINTS_FOR_GHOST_VALUE
var ui: UI

func _ready():
	ui = get_tree().get_first_node_in_group("ui")

func add_pellet_points():
	points += PELLET_POINTS
	if ui:
		ui.set_score(points)

func add_power_pellet_points():
	points += POWER_PELLET_POINTS
	if ui:
		ui.set_score(points)

func pause_on_ghost_eaten():
	points += points_for_ghost_eaten
	if ui:
		ui.set_score(points)

	points_for_ghost_eaten += BASE_POINTS_FOR_GHOST_VALUE

func reset_points_for_ghosts():
	points_for_ghost_eaten = BASE_POINTS_FOR_GHOST_VALUE
