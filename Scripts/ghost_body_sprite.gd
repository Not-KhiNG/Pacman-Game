extends Sprite2D

class_name BodySprite

@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
@onready var ghost := get_parent() as Ghost

func _ready():
	normal()

func normal():
	self_modulate = ghost.color
	animation_player.play("default")

func run_away():
	self_modulate = Color.BLUE
	animation_player.play("run_away")

func start_blinking():
	var blink_anim = AnimationPlayer
	animation_player.play("frightened_blink")

func hide_body():
	hide()

func show_body():
	show()
