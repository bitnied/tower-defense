extends Node
# Áudio do Elisa TD: música em loop contínua + efeitos pontuais,
# com volume e mudo ajustáveis no menu de pause.
# Créditos: Assets/audio/CREDITS.txt (tudo CC0).

const SFX := {
	"place": "res://Assets/audio/sfx_place.ogg",
	"heal": "res://Assets/audio/sfx_heal.ogg",
	"upgrade": "res://Assets/audio/sfx_upgrade.ogg",
	"hit": "res://Assets/audio/sfx_hit.ogg",
	"click": "res://Assets/audio/sfx_click.ogg",
	"unlock": "res://Assets/audio/sfx_unlock.mp3",
	"impact": "res://Assets/audio/sfx_impact.mp3",
	"victory": "res://Assets/audio/sfx_victory.ogg",
	"gameover": "res://Assets/audio/sfx_gameover.ogg",
	"atk_tiago": "res://Assets/audio/sfx_atk_tiago.ogg",
	"atk_luna": "res://Assets/audio/sfx_atk_luna.ogg",
	"atk_leo": "res://Assets/audio/sfx_atk_leo.ogg",
	"atk_elisa": "res://Assets/audio/sfx_atk_elisa.ogg",
}

# ganho base da música (para não competir com os efeitos)
const MUSIC_BASE := 0.2

var music_volume := 1.0:
	set(v):
		music_volume = clampf(v, 0.0, 1.0)
		_apply_music()
var sfx_volume := 1.0:
	set(v):
		sfx_volume = clampf(v, 0.0, 1.0)
var music_muted := false:
	set(v):
		music_muted = v
		_apply_music()
var sfx_muted := false

var music_player: AudioStreamPlayer

func _ready():
	music_player = AudioStreamPlayer.new()
	var stream: AudioStream = load("res://Assets/audio/music_game.mp3")
	stream.loop = true
	music_player.stream = stream
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music_player)
	_apply_music()
	music_player.play()

func _apply_music():
	if music_player == null:
		return
	if music_muted or music_volume <= 0.001:
		music_player.volume_db = -80.0
	else:
		music_player.volume_db = linear_to_db(music_volume * MUSIC_BASE)

func play(sfx_name: String, volume_db := -6.0):
	if sfx_muted or sfx_volume <= 0.001 or not SFX.has(sfx_name):
		return
	var p := AudioStreamPlayer.new()
	p.stream = load(SFX[sfx_name])
	p.volume_db = volume_db + linear_to_db(sfx_volume)
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
