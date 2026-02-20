extends Area2D

class_name Fruit

@export var points := 100
@export var lifetime := 10.0

func _ready():
	start_lifetime()

func start_lifetime():
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _on_body_entered(body):
	if body is Player:
		GameManager.points += points
		GameManager.update_ui()

		SoundManager.play_sfx("eatcherry") # change later if needed
		queue_free()
