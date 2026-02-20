extends Area2D

class_name Pellet

@export var should_allow_eating_ghosts = false

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		GameManager.pellet_eaten(should_allow_eating_ghosts)
		queue_free()
