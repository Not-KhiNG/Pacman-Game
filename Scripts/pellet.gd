extends Area2D

class_name Pellet
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

signal  pellet_eaten(should_allow_eating_ghosts: bool)
@export var should_allow_eating_ghosts = false

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		audio_stream_player_2d.play()
		pellet_eaten.emit(should_allow_eating_ghosts)
		queue_free()
