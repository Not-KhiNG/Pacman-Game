extends Area2D

@export var speed = 120
@export var movement_targets = Resource
@export var tile_map: TileMap
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D

var scatter_nodes: Array[Node2D] = []
var current_scatter_index := 0

func _ready():
	for path in movement_targets.scatter_targets:
		var node = get_node_or_null(path)
		if node:
			scatter_nodes.append(node)
		else:
			push_error("Ghost Error: Could not find node at path: ", path)
		#navigation_agent_2d.path_desired_distance = 4.0
		#navigation_agent_2d.target_desired_distance = 4.0
		navigation_agent_2d.target_reached.connect(on_position_reached)
		call_deferred("setup")

func _process(delta):
	if navigation_agent_2d.is_navigation_finished():
		return
	move_ghost(navigation_agent_2d.get_next_path_position(), delta)

func move_ghost(next_position: Vector2, delta: float):
	if next_position == null:
		return
	var current_ghost_position = global_position
	var new_velocity = (next_position - current_ghost_position).normalized() * speed * delta
	global_position += new_velocity

func setup():
	await get_tree().physics_frame
	navigation_agent_2d.set_navigation_map(tile_map.get_navigation_map(0))
	#NavigationServer2D.agent_set_map(navigation_agent_2d.get_rid(), tile_map.get_navigation_map(0))
	scatter()

func scatter():
	if scatter_nodes.is_empty():
		print("No scatter nodes found")
		return
	var target_node = scatter_nodes[current_scatter_index]
	if is_instance_valid(target_node):
		navigation_agent_2d.target_position = target_node.global_position
	else:
		push_error("Ghost Error: Scatter target node is invalid!")

  #navigation_agent_2d.target_position = movement_targets.scatter_targets[current_scatter_index].position

func on_position_reached():
	if current_scatter_index < 3:
		current_scatter_index += 1
	else:
		current_scatter_index = 0
