extends PathFollow2D
# Coração partido que avança pelo caminho. Quando recebe amor
# suficiente (hp <= 0), é CURADO: anima, some e vira corações
# (moeda) para o jogador.

var enemy_type := "":
	set(val):
		enemy_type = val
		var cfg: Dictionary = Data.enemies[val]
		$Sprite2D.texture = load(cfg["sprite"])
		var s: float = cfg.get("scale", 1.0)
		$Sprite2D.scale = Vector2(s, s)
		$Area.scale = Vector2(s, s)
		is_boss = cfg.get("boss", false)
		for stat in cfg["stats"].keys():
			set(stat, cfg["stats"][stat])

enum State {walking, stopped}
var state = State.walking
var goldYield := 10.0
var hp := 10.0
var baseDamage := 5.0
var speed := 1.0
var is_destroyed := false
var is_boss := false

# congelamento (raio da Luna): reduz a velocidade por um tempo
var slow_factor := 1.0
var slow_timer := 0.0

func apply_slow(factor: float, duration: float):
	slow_factor = factor
	slow_timer = duration
	$Sprite2D.self_modulate = Color(0.62, 0.82, 1.0)

# corações andam levemente acima do centro da estrada para não
# encostar na base das casas
const RIDE_OFFSET := -14.0

@onready var spawner := get_parent() as EnemyPath
func _ready():
	add_to_group("enemy")
	v_offset = RIDE_OFFSET

func _process(delta):
	if slow_timer > 0.0:
		slow_timer -= delta
		if slow_timer <= 0.0:
			slow_factor = 1.0
			$Sprite2D.self_modulate = Color.WHITE
	if state == State.walking:
		# Movimento por delta: independente de framerate (iPads 120Hz)
		# e respeita Engine.time_scale (botão 2x).
		progress_ratio += 0.03 * speed * slow_factor * delta
		if progress_ratio >= 1:
			finished_path()
			return
		#Flip
		var angle = int(rotation_degrees) % 360
		if angle > 180:
			angle -= 360
		$Sprite2D.flip_v = abs(angle) > 90

func finished_path():
	if is_destroyed:
		return
	is_destroyed = true
	spawner.enemy_destroyed()
	spawner.enemy_leaked()
	Globals.currentMap.get_base_damage(baseDamage)
	attack_guardian_animation()

# o coração partido pula na Elisa, que treme com o golpe
func attack_guardian_animation():
	state = State.stopped
	remove_from_group("enemy")
	$Area/CollisionShape2D.set_deferred("disabled", true)
	$AnimationPlayer.stop()
	_detach_sprite_upright()
	var guardian: Node2D = Globals.currentMap.get_node_or_null("Mamae")
	if guardian == null:
		queue_free()
		return
	var start: Vector2 = $Sprite2D.global_position
	var target: Vector2 = guardian.global_position + Vector2(0, -26)
	var mid := Vector2((start.x + target.x) / 2.0, minf(start.y, target.y) - 56.0)
	var tween := create_tween()
	tween.tween_property($Sprite2D, "global_position", mid, 0.22) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property($Sprite2D, "global_position", target, 0.2) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): _hit_guardian(guardian))
	tween.tween_property($Sprite2D, "scale", $Sprite2D.scale * Vector2(1.4, 0.5), 0.08)
	tween.tween_property($Sprite2D, "modulate:a", 0.0, 0.16)
	tween.tween_callback(queue_free)

func _hit_guardian(guardian: Node2D):
	Sfx.play("hit", -7.0)
	guardian.modulate = Color(1, 0.45, 0.5)
	var tween := guardian.create_tween()
	tween.set_parallel()
	tween.tween_property(guardian, "modulate", Color.WHITE, 0.35)
	tween.tween_property(guardian, "scale", Vector2(1.12, 0.88), 0.07)
	tween.set_parallel(false)
	tween.tween_property(guardian, "scale", Vector2(1, 1), 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func get_damage(amount):
	# "amount" = poder de cura do defensor
	if is_destroyed:
		return
	hp -= amount
	healing_hit_animation()
	if hp <= 0:
		is_destroyed = true
		spawner.enemy_destroyed()
		Globals.currentMap.gold += goldYield
		healed_animation()

func healing_hit_animation():
	var tween := create_tween()
	tween.tween_property(self, "v_offset", RIDE_OFFSET, 0.05)
	tween.tween_property(self, "modulate", Color(0.65, 1.0, 0.8), 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	tween.set_parallel()
	tween.tween_property(self, "v_offset", RIDE_OFFSET - 5, 0.2)
	tween.set_parallel(false)
	tween.tween_property(self, "v_offset", RIDE_OFFSET, 0.2)

func healed_animation():
	state = State.stopped
	remove_from_group("enemy")
	$Area/CollisionShape2D.set_deferred("disabled", true)
	$AnimationPlayer.stop()
	# vira um coração inteiro e flutua para cima brilhando
	var healed: Texture2D = load(Data.healed_heart_sprite)
	$Sprite2D.texture = healed
	$Sprite2D.hframes = 1
	$Sprite2D.frame = 0
	$Sprite2D.flip_v = false
	Sfx.play("heal", -9.0)
	Progress.add_points(10 if is_boss else 1)
	spawn_reward_label()
	if is_boss:
		spawn_heart_rain()
	$Sprite2D.self_modulate = Color.WHITE
	_detach_sprite_upright()
	# o coração curado voa feliz até a mamãe (Elisa)
	var start: Vector2 = $Sprite2D.global_position
	var guardian: Node2D = Globals.currentMap.get_node_or_null("Mamae")
	var target: Vector2 = start + Vector2(0, -60)
	if guardian != null:
		target = guardian.global_position + Vector2(0, -30)
	var mid := Vector2(lerpf(start.x, target.x, 0.45),
		minf(start.y, target.y) - 90.0)
	var tween := create_tween()
	# pulinho de alegria + voo em arco até a Elisa
	tween.tween_property($Sprite2D, "scale", $Sprite2D.scale * 1.3, 0.16) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property($Sprite2D, "global_position", mid, 0.34) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property($Sprite2D, "global_position", target, 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property($Sprite2D, "scale", $Sprite2D.scale * 0.55, 0.3)
	tween.tween_callback(func(): _arrive_at_guardian(guardian))
	tween.tween_property($Sprite2D, "modulate:a", 0.0, 0.12)
	tween.tween_callback(queue_free)

# solta o sprite da rotação do PathFollow2D para animar sempre
# de pé (na estrada de baixo ele ficava de cabeça para baixo)
func _detach_sprite_upright():
	var gp: Vector2 = $Sprite2D.global_position
	$Sprite2D.top_level = true
	$Sprite2D.global_position = gp
	$Sprite2D.global_rotation = 0.0
	$Sprite2D.flip_v = false
	$Sprite2D.flip_h = false

func _arrive_at_guardian(guardian: Node2D):
	if guardian == null:
		return
	# a Elisa "recebe" o coração com um pulsinho carinhoso
	var tween := guardian.create_tween()
	tween.tween_property(guardian, "scale", Vector2(1.08, 1.08), 0.08)
	tween.tween_property(guardian, "scale", Vector2(1, 1), 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# clímax do chefão: chuva de coraçõezinhos curados
func spawn_heart_rain():
	var tex: Texture2D = load(Data.healed_heart_sprite)
	for i in range(16):
		var h := Sprite2D.new()
		h.texture = tex
		h.z_index = 6
		h.scale = Vector2(0.7, 0.7)
		Globals.currentMap.add_child(h)
		h.global_position = $Sprite2D.global_position \
			+ Vector2(randf_range(-36, 36), randf_range(-26, 12))
		var fly := Vector2(randf_range(-110, 110), randf_range(-150, -50))
		var tw := h.create_tween()
		tw.set_parallel()
		tw.tween_property(h, "global_position", h.global_position + fly, 1.0) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(h, "modulate:a", 0.0, 1.0).set_delay(0.35)
		tw.set_parallel(false)
		tw.tween_callback(h.queue_free)

func spawn_reward_label():
	var label := Label.new()
	label.text = "+%d" % int(goldYield)
	label.z_index = 5
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color("d63c6b"))
	label.add_theme_color_override("font_outline_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 6)
	Globals.currentMap.add_child(label)
	label.global_position = $Sprite2D.global_position + Vector2(10, -30)
	var tween := label.create_tween()
	tween.set_parallel()
	tween.tween_property(label, "global_position",
		label.global_position + Vector2(0, -34), 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.35)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)
