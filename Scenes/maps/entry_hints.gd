extends Node2D
# Antes e entre as ondas: setas animadas marcham na entrada do
# caminho mostrando por onde os corações vão entrar, e um anel
# pulsa no destino (a mamãe). Somem quando a onda começa.

const ENTRY := Vector2(-600, -190)
const ENTRY_DIR := Vector2.RIGHT
const DEST := Vector2(-516, 182)
const SPAN := 140.0

var chevrons: Array[Sprite2D] = []
var ring: Sprite2D
var t := 0.0

func _ready():
	var tex: Texture2D = load("res://Assets/ui/chevron.png")
	for i in range(3):
		var s := Sprite2D.new()
		s.texture = tex
		add_child(s)
		chevrons.append(s)
	ring = Sprite2D.new()
	ring.texture = load("res://Assets/ui/dest_ring.png")
	ring.position = DEST
	add_child(ring)
	Globals.waveStarted.connect(_on_wave_started)
	Globals.waveCleared.connect(_on_wave_cleared)

func _on_wave_started(_wave, _enemies):
	visible = false

func _on_wave_cleared(_wait):
	visible = true

func _process(delta):
	if not visible:
		return
	t += delta
	for i in range(chevrons.size()):
		var off := fmod(t * 70.0 + i * 46.0, SPAN)
		var s := chevrons[i]
		s.position = ENTRY + ENTRY_DIR * off
		s.modulate.a = clampf(sin(off / SPAN * PI) * 1.5, 0.0, 1.0)
	var pulse := 1.0 + 0.12 * sin(t * 4.0)
	ring.scale = Vector2(pulse, pulse)
