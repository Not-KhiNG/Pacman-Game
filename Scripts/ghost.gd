extends Area2D
class_name Ghost

enum GhostState {
	SCATTER,
	CHASE
}

var current_state: GhostState = GhostState.SCATTER

@export var speed: float = 120.0
@export var movement_targets: Resource   
@export var tile_map: TileMap
@export var chasing_target: Node2D         

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var chase_timer: Timer = $ChaseTimer
@onready var scatter_timer: Timer = $ScatterTimer

var scatter_nodes: Array[Node2D] = []
var current_scatter_index: int = 0

func _ready() -> void:
	_load_scatter_nodes()
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 4.0
	navigation_agent.target_reached.connect(_on_target_reached)
	chase_timer.timeout.connect(_update_chase_target)
	scatter_timer.timeout.connect(start_chase)
	call_deferred("_setup_navigation")

func _setup_navigation() -> void:
	await get_tree().physics_frame

	var nav_map = tile_map.get_navigation_map(0)
	navigation_agent.set_navigation_map(nav_map)
	start_scatter()

func _process(delta: float) -> void:
	if navigation_agent.is_navigation_finished():
		return

	var next_pos: Vector2 = navigation_agent.get_next_path_position()
	var velocity: Vector2 = (next_pos - global_position).normalized() * speed * delta
	global_position += velocity

func start_scatter() -> void:
	current_state = GhostState.SCATTER
	current_scatter_index = 0

	chase_timer.stop()
	scatter_timer.start() 

	_set_scatter_target()

func _set_scatter_target() -> void:
	if scatter_nodes.is_empty():
		push_error("Ghost has no scatter nodes!")
		return

	var target_node := scatter_nodes[current_scatter_index]
	if is_instance_valid(target_node):
		navigation_agent.target_position = target_node.global_position
	else:
		push_error("Scatter target is invalid")

func _on_scatter_target_reached() -> void:
	current_scatter_index = (current_scatter_index + 1) % scatter_nodes.size()
	_set_scatter_target()

func start_chase() -> void:
	if chasing_target == null:
		push_warning("No chasing target set for ghost")
		return

	current_state = GhostState.CHASE
	scatter_timer.stop()
	chase_timer.start()

	_update_chase_target()

func _update_chase_target() -> void:
	if current_state != GhostState.CHASE:
		return
	if chasing_target == null:
		return

	navigation_agent.target_position = chasing_target.global_position

func _on_chase_target_reached() -> void:
	print("Pac-Man caught!")
	# ToDo kill Pac-Man or switch state

func _on_target_reached() -> void:
	match current_state:
		GhostState.SCATTER:
			_on_scatter_target_reached()
		GhostState.CHASE:
			_on_chase_target_reached()

func _load_scatter_nodes() -> void:
	scatter_nodes.clear()

	if movement_targets == null:
		push_error("MovementTargets resource not assigned")
		return

	for path: NodePath in movement_targets.scatter_targets:
		var node := get_node_or_null(path)
		if node and node is Node2D:
			scatter_nodes.append(node)
		else:
			push_error("Invalid scatter NodePath: %s" % path)
