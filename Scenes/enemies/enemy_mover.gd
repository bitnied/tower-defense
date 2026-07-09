extends PathFollow2D
# Coração partido que avança pelo caminho. Quando recebe amor
# suficiente (hp <= 0), é CURADO: anima, some e vira corações
# (moeda) para o jogador.

var enemy_type := "":
	set(val):
		enemy_type = val
		$Sprite2D.texture = load(Data.enemies[val]["sprite"])
		for stat in Data.enemies[val]["stats"].keys():
			set(stat, Data.enemies[val]["stats"][stat])

enum State {walking, healed}
var state = State.walking
var goldYield := 10.0
var hp := 10.0
var baseDamage := 5.0
var speed := 1.0
var is_destroyed := false

@onready var spawner := get_parent() as EnemyPath
func _ready():
	add_to_group("enemy")

func _process(delta):
	if state == State.walking:
		# Movimento por delta: independente de framerate (iPads 120Hz)
		# e respeita Engine.time_scale (botão 2x).
		progress_ratio += 0.03 * speed * delta
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
	Globals.currentMap.get_base_damage(baseDamage)
	queue_free()

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
	tween.tween_property(self, "v_offset", 0, 0.05)
	tween.tween_property(self, "modulate", Color(0.65, 1.0, 0.8), 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	tween.set_parallel()
	tween.tween_property(self, "v_offset", -5, 0.2)
	tween.set_parallel(false)
	tween.tween_property(self, "v_offset", 0, 0.2)

func healed_animation():
	state = State.healed
	remove_from_group("enemy")
	$Area/CollisionShape2D.set_deferred("disabled", true)
	$AnimationPlayer.stop()
	# vira um coração inteiro e flutua para cima brilhando
	var healed: Texture2D = load(Data.healed_heart_sprite)
	$Sprite2D.texture = healed
	$Sprite2D.hframes = 1
	$Sprite2D.frame = 0
	$Sprite2D.flip_v = false
	spawn_reward_label()
	var start: Vector2 = $Sprite2D.global_position
	var tween := create_tween()
	tween.set_parallel()
	tween.tween_property($Sprite2D, "global_position", start + Vector2(0, -46), 0.7) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property($Sprite2D, "scale", $Sprite2D.scale * 1.35, 0.7)
	tween.tween_property($Sprite2D, "modulate:a", 0.0, 0.45).set_delay(0.3)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)

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
