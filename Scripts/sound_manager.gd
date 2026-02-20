extends Node

@onready var music_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var loop_player: AudioStreamPlayer = AudioStreamPlayer.new() # siren / power pellet loop

var current_music_name := ""
var current_loop_name := ""
var siren_active := false
var chomp_cooldown := 0.12
var can_play_chomp := true


var music := {
	"opening": preload("res://Assets/Sounds/Pacman_Opening_Song_Sound_Effect.ogg"),
	"intermission": preload("res://Assets/Sounds/Pacman_Intermission_Sound_Effect.wav")
}

var sfx := {
	"siren": preload("res://Assets/Sounds/Pacman_Siren_Sound_Effect.ogg"),
	"chomp": preload("res://Assets/Sounds/pacman_chomp.ogg"),
	"eatghost": preload("res://Assets/Sounds/pacman_eatghost.wav"),
	"power_eat": preload("res://Assets/Sounds/pacman_eatghost.wav"),
	"power_loop": preload("res://Assets/Sounds/pacman_power_pellet.wav"),
	"death": preload("res://Assets/Sounds/pacman_death.wav"),
	"extralive": preload("res://Assets/Sounds/Pacman_Extra_Live_Sound_Effect.wav"),
	"eatcherry": preload("res://Assets/Sounds/Pacman_Eating_Cherry_Sound_Effect.wav"),
	"level_clear": preload("res://Assets/Sounds/Pacman_Intermission_Sound_Effect.wav")
}

func _ready():
	add_child(music_player)
	add_child(sfx_player)
	add_child(loop_player)

	music_player.bus = "Music"
	sfx_player.bus = "Sfx"
	loop_player.bus = "Sfx"


func play_sfx(name: String):
	if not sfx.has(name):
		return

	# Special handling for chomp
	if name == "chomp":
		if not can_play_chomp:
			return

	can_play_chomp = false

	sfx_player.stream = sfx[name]
	sfx_player.play()

	await get_tree().create_timer(chomp_cooldown).timeout
	can_play_chomp = true
	return


	# Normal SFX
	var player = AudioStreamPlayer.new()
	player.stream = sfx[name]
	player.bus = "Sfx"
	add_child(player)
	player.play()

	player.finished.connect(func():
		player.queue_free()
	)

func play_loop_sfx(name: String):
	if not sfx.has(name):
		print("Sound not found:", name)
		return

	if current_loop_name == name:
		return

	current_loop_name = name

	loop_player.stop()
	loop_player.stream = sfx[name]

	# FORCE LOOP
	if loop_player.stream is AudioStreamOggVorbis:
		loop_player.stream.loop = true
	elif loop_player.stream is AudioStreamWAV:
		loop_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD

	loop_player.play()


func stop_loop_sfx():
	current_loop_name = ""
	loop_player.stop()
	siren_active = false

func start_siren():
	if siren_active:
		return

	siren_active = true
	play_loop_sfx("siren")

func stop_siren():
	if not siren_active:
		return

	siren_active = false
	stop_loop_sfx()

func start_power_mode():
	stop_siren()
	play_loop_sfx("power_loop")

func stop_power_mode():
	stop_loop_sfx()
	start_siren()

func play_death():
	stop_loop_sfx()
	stop_siren()
	play_sfx("death")

func play_opening():
	stop_loop_sfx()
	stop_siren()

	music_player.stream = music["opening"]
	music_player.play()

func play_level_clear():
	stop_loop_sfx()
	stop_siren()
	play_sfx("level_clear")
