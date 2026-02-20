extends Control

class_name MainMenu

var bus_index: int

@onready var start_menu: VBoxContainer = $Panel/StartMenu
@onready var option_menu: VBoxContainer = $Panel/OptionMenu
@onready var mute_button: Button = $Panel/OptionMenu/MuteButton

func _ready() -> void:
	SoundManager.play_music("opening")
	$Panel/StartMenu.show()
	$Panel/OptionMenu.hide()

	bus_index = AudioServer.get_bus_index("Master")

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _on_options_pressed() -> void:
	$Panel/StartMenu.hide()
	$Panel/OptionMenu.show()

func _on_exit_pressed() -> void:
	SoundManager.stop_music()
	get_tree().quit()

func _on_mute_button_pressed() -> void:
	var is_muted = AudioServer.is_bus_mute(bus_index)
	AudioServer.set_bus_mute(bus_index, !is_muted)
	if not is_muted:
		mute_button.text = "Unmute"
	else:
		mute_button.text = "Mute"

func _on_back_button_pressed() -> void:
	$Panel/OptionMenu.hide()
	$Panel/StartMenu.show()
