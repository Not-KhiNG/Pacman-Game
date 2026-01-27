extends CanvasLayer

class_name UI
@onready var center_container: CenterContainer = $MarginContainer/CenterContainer

func game_won():
	center_container.show()
