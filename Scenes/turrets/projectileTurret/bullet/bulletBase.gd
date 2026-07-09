extends Node2D

var bullet_type := "":
	set(value):
		bullet_type = value
		style = Data.bullets[value].get("style", "")
		if style == "wave":
			# onda sonora: efeito procedural (arcos), sem sprite
			$AnimatedSprite2D.visible = false
		else:
			$AnimatedSprite2D.sprite_frames = load(Data.bullets[value]["frames"])

var target = null
var direction: Vector2

var style := ""
var wave_t := 0.0
var speed: float = 400.0
var damage: float = 10
var pierce: int = 1
var time: float = 1.0

func _process(delta):
	if target:
		if not direction:
			direction = (target - position).normalized()
			# boquinhas/corações apontam para a esquerda quando preciso
			$AnimatedSprite2D.flip_h = direction.x < 0
		position += direction * speed * delta
	if style == "wave":
		wave_t += delta
		queue_redraw()

func _draw():
	if style != "wave":
		return
	# arcos de som que se expandem na direção do voo
	var ang := direction.angle() if direction else 0.0
	for i in range(3):
		var t := fmod(wave_t * 2.4 + i * 0.34, 1.0)
		var r := 3.0 + t * 15.0
		var alpha := (1.0 - t) * 0.95
		draw_arc(Vector2.ZERO, r, ang - 0.75, ang + 0.75, 12,
			Color(0.55, 0.83, 1.0, alpha), 2.6, true)
		draw_arc(Vector2.ZERO, r * 0.98, ang - 0.35, ang + 0.35, 8,
			Color(1, 1, 1, alpha * 0.7), 1.4, true)

func _on_area_2d_area_entered(area):
	var obj = area.get_parent()
	if obj.is_in_group("enemy"):
		pierce -= 1
		obj.get_damage(damage)
	if pierce == 0:
		queue_free()

func _on_disappear_timer_timeout():
	queue_free()
