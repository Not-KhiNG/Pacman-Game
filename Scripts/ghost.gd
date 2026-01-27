extends CharacterBody2D

@export var speed := 120.0
@export var pacman: Node2D
@export var tilemap: TileMap
@export var tile_size := 24

enum Dir { UP, DOWN, LEFT, RIGHT }

var current_dir: Dir = Dir.LEFT
var next_dir: Dir = Dir.LEFT

var dir_vectors := {
	Dir.UP: Vector2.UP,
	Dir.DOWN: Vector2.DOWN,
	Dir.LEFT: Vector2.LEFT,
	Dir.RIGHT: Vector2.RIGHT
}

func _ready():
	global_position = global_position.snapped(Vector2(tile_size, tile_size))
	var start_delay = randf() * 0.2
	await get_tree().create_timer(start_delay).timeout

func _physics_process(delta):
	if not pacman or not tilemap:
		return
	if at_tile_center():
		if is_blocked(current_dir):
			choose_direction(pacman.global_position)
		current_dir = next_dir
	velocity = dir_vectors[current_dir] * speed
	move_and_slide()

func at_tile_center() -> bool:
	return global_position == global_position.snapped(Vector2(tile_size, tile_size))

func can_move(dir: Dir) -> bool:
	var next_pos = global_position + dir_vectors[dir] * tile_size
	var cell = tilemap.local_to_map(next_pos)
	return tilemap.get_cell_source_id(0, cell) == -1

func choose_direction(target_pos: Vector2):
	var possible_dirs := []
	for dir in Dir.values():
		if dir == opposite(current_dir) and can_move(current_dir):
			continue
		if not can_move(dir):
			continue
		possible_dirs.append(dir)
	if possible_dirs.size() == 0:
		next_dir = opposite(current_dir)
		return
	var best_dir = possible_dirs[0]
	var best_dist = (global_position + dir_vectors[best_dir] * tile_size).distance_to(target_pos)
	for dir in possible_dirs:
		var dist = (global_position + dir_vectors[dir] * tile_size).distance_to(target_pos)
		if dist < best_dist:
			best_dir = dir
			best_dist = dist
	var same_best := []
	for dir in possible_dirs:
		var dist = (global_position + dir_vectors[dir] * tile_size).distance_to(target_pos)
		if abs(dist - best_dist) < 0.01:
			same_best.append(dir)
	next_dir = same_best[randi() % same_best.size()]

func opposite(dir: Dir) -> Dir:
	match dir:
		Dir.UP: return Dir.DOWN
		Dir.DOWN: return Dir.UP
		Dir.LEFT: return Dir.RIGHT
		Dir.RIGHT: return Dir.LEFT
	return Dir.UP

func is_blocked(dir: Dir) -> bool:
	return not can_move(dir)
