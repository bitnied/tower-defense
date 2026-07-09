extends Node
# Áudio do Elisa TD: música em loop contínua + efeitos pontuais.
# Créditos: Assets/audio/CREDITS.txt (tudo CC0).

const SFX := {
	"place": "res://Assets/audio/sfx_place.ogg",
	"heal": "res://Assets/audio/sfx_heal.ogg",
	"upgrade": "res://Assets/audio/sfx_upgrade.ogg",
	"hit": "res://Assets/audio/sfx_hit.ogg",
	"click": "res://Assets/audio/sfx_click.ogg",
	"unlock": "res://Assets/audio/sfx_unlock.ogg",
	"victory": "res://Assets/audio/sfx_victory.ogg",
	"gameover": "res://Assets/audio/sfx_gameover.ogg",
}

var music_player: AudioStreamPlayer

func _ready():
	music_player = AudioStreamPlayer.new()
	var stream: AudioStream = load("res://Assets/audio/music_game.mp3")
	stream.loop = true
	music_player.stream = stream
	music_player.volume_db = -14.0
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music_player)
	music_player.play()

func play(sfx_name: String, volume_db := -6.0):
	if not SFX.has(sfx_name):
		return
	var p := AudioStreamPlayer.new()
	p.stream = load(SFX[sfx_name])
	p.volume_db = volume_db
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
