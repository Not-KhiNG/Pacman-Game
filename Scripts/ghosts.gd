#extends Node2D

#class_name Ghosts
#@onready var player = $"../Player" as Player

#func _ready():
	#player.player_died.connect(reset_ghosts)

#func reset_ghosts(lifes):
	#var ghosts = get_children() as Array[Ghost]
	#if lifes == 0:
		#for ghost in ghosts:
			#ghost.scatter_timer.stop()
			#ghost.scatter_timer.wait_time = 10000
			#ghost.scatter_timer.start()
			#ghost.current_state = Ghost.GhostState.SCATTER
	#else:		
		#for ghost in ghosts:
			#ghost._enter_chase()
extends Node2D
class_name Ghosts

@onready var player = $"../Player" as Player
@export var ghosts: Array[Ghost] = []

# Wave timings (seconds), arcade-accurate for level 1
var wave_times = [7.0, 20.0, 7.0, 20.0, 5.0, 20.0, 5.0, 9999.0]
var wave_index := 0
var timer := 0.0
var current_mode := Ghost.GhostState.SCATTER

signal mode_changed(new_mode)

func _ready():
	player.player_died.connect(_on_player_died)
	# Initialize ghosts array automatically if empty
	if ghosts.size() == 0:
		ghosts = []
		for child in get_children():
			if child is Ghost:
				ghosts.append(child)

func _process(delta):
	timer += delta
	if timer >= wave_times[wave_index]:
		timer = 0
		wave_index += 1
		if wave_index >= wave_times.size():
			wave_index = wave_times.size() - 1
		_toggle_mode()

func _toggle_mode():
	current_mode = Ghost.GhostState.CHASE if current_mode == Ghost.GhostState.SCATTER else Ghost.GhostState.SCATTER
	# Notify all ghosts
	for ghost in ghosts:
		ghost._on_global_mode_changed(current_mode)
	emit_signal("mode_changed", current_mode)

func _on_player_died(lives: int):
	for ghost in ghosts:
		ghost._on_player_reset(lives)
