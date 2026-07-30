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
	"fall": "res://Assets/audio/sfx_fall.mp3",
	"ghost": "res://Assets/audio/sfx_ghost.mp3",
	"victory": "res://Assets/audio/sfx_victory.ogg",
	"gameover": "res://Assets/audio/sfx_gameover.ogg",
	"atk_tiago": "res://Assets/audio/sfx_atk_tiago.ogg",
	"atk_luna": "res://Assets/audio/sfx_atk_luna.mp3",
	"atk_leo": "res://Assets/audio/sfx_atk_leo.ogg",
	"atk_elisa": "res://Assets/audio/sfx_atk_elisa.ogg",
}

# Normalização por arquivo. Cada .ogg/.mp3 veio de uma fonte diferente e
# foi masterizado num nível diferente, então o `volume_db` do call site
# sozinho não dizia nada: -4.0 num arquivo quente e -4.0 num arquivo fraco
# davam resultados a 10 dB de distância (era esse o salto do "unlock").
#
# Este ganho traz todos para a mesma sonoridade PERCEBIDA, medida com
# ffmpeg (RMS da janela de 100 ms mais alta) e corrigida pela duração —
# som curto soa mais baixo que som longo no mesmo RMS (integração
# temporal do ouvido, ~10 dB por década abaixo de 200 ms).
#
#   ganho = -16.0 - (RMS_100ms + correção_de_duração)
#
# Com isso o `volume_db` do call site vira mixagem pura: o mesmo número
# soa igual em qualquer efeito, e 0.0 = referência (-16 dB percebidos).
# Para reconferir depois de trocar um arquivo: tools/audio_levels.sh
const SFX_GAIN := {
	#              RMS100  dur     ganho
	"click": -7.8,      # -16.2   10ms
	"place": 0.8,       # -17.0  190ms
	"heal": 0.2,        # -18.1  130ms
	"hit": -2.8,        # -16.2  100ms
	"upgrade": -6.4,    #  -9.6  540ms
	"unlock": -5.6,     # -10.4  670ms
	"impact": -5.6,     # -10.4  750ms
	"ghost": -9.9,      #  -6.1  900ms
	"fall": -11.4,      #  -4.6  850ms
	"gameover": -3.9,   # -12.1 1000ms
	"victory": -3.6,    # -12.4  800ms
	"atk_tiago": 1.5,   # -20.5  100ms
	"atk_leo": 1.4,     # -20.0  110ms
	"atk_elisa": -0.3,  # -15.7  280ms
	"atk_luna": -5.1,   # -10.9  940ms
}

# Duas cópias do mesmo efeito no mesmo instante somam ~3 dB (quatro, ~6).
# Acontece de verdade quando vários corações morrem juntos ("heal") ou
# duas torres atiram no mesmo frame. Abaixo desta janela o ouvido junta
# tudo num som só, então a repetição vira só volume — descarta.
const RETRIGGER_MS := 50

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
# último disparo de cada efeito, para o corte de retrigger
var _last_played := {}
# a música só toca durante o gameplay (nunca em menus/galeria)
var music_on := false
# pausa pedida pelo jogo (galeria aberta por cima do pause):
# a volta do foco não pode desfazer esta pausa
var _hold_paused := false
# a referência precisa viver enquanto o jogo rodar (mesmo motivo
# do Progress): senão o navegador perde o callback registrado
var _web_vis_cb

func _ready():
	music_player = AudioStreamPlayer.new()
	var stream: AudioStream = load("res://Assets/audio/music_game.mp3")
	stream.loop = true
	music_player.stream = stream
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music_player)
	_install_web_visibility_hooks()

# começa a música do gameplay (com fade-in); não recomeça se já toca
func play_music():
	if music_on:
		return
	music_on = true
	music_player.stream_paused = false
	music_player.volume_db = -50.0
	music_player.play()
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(music_player, "volume_db", _target_db(), 0.8)

# para a música (fade-out) ao sair do gameplay
func stop_music(fade := 0.5):
	if not music_on:
		return
	music_on = false
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(music_player, "volume_db", -60.0, fade)
	tw.tween_callback(music_player.stop)

# pausa sem perder a posição (galeria por cima do jogo pausado)
func set_music_paused(p: bool):
	_hold_paused = p
	music_player.stream_paused = p

# No webapp da tela de início (iPad/iPhone) a página antiga pode
# continuar viva em segundo plano com a música tocando: ao reabrir o
# jogo ouvia-se música na home e, entrando no gameplay, DUAS trilhas.
# Página escondida => música pausada, sempre.
func _install_web_visibility_hooks():
	if not OS.has_feature("web"):
		return
	_web_vis_cb = JavaScriptBridge.create_callback(_on_web_visibility)
	var doc = JavaScriptBridge.get_interface("document")
	if doc != null:
		doc.addEventListener("visibilitychange", _web_vis_cb)
	var win = JavaScriptBridge.get_interface("window")
	if win != null:
		win.addEventListener("pagehide", _web_vis_cb)
		win.addEventListener("pageshow", _web_vis_cb)

func _on_web_visibility(_args):
	var doc = JavaScriptBridge.get_interface("document")
	var hidden: bool = doc == null or bool(doc.hidden)
	if hidden:
		music_player.stream_paused = true
	else:
		# só desfaz a pausa da troca de aba; a da galeria fica
		music_player.stream_paused = _hold_paused

func _target_db() -> float:
	if music_muted or music_volume <= 0.001:
		return -80.0
	return linear_to_db(music_volume * MUSIC_BASE)

func _apply_music():
	if music_player == null or not music_on:
		return
	music_player.volume_db = _target_db()

# volume_db aqui é MIXAGEM, não ganho bruto: o nível real de cada arquivo
# já foi igualado por SFX_GAIN. 0.0 = referência; -20.0 = bem ao fundo.
func play(sfx_name: String, volume_db := -6.0):
	if sfx_muted or sfx_volume <= 0.001 or not SFX.has(sfx_name):
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_played.get(sfx_name, -RETRIGGER_MS)) < RETRIGGER_MS:
		return
	_last_played[sfx_name] = now
	var p := AudioStreamPlayer.new()
	p.stream = load(SFX[sfx_name])
	p.volume_db = SFX_GAIN.get(sfx_name, 0.0) + volume_db + linear_to_db(sfx_volume)
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
