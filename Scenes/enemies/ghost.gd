extends Node2D
# FANTASMA: entra pela direita (na contramão), flutua em linha reta
# até a defesa mais próxima e tenta AGARRÁ-LA e levar embora.
# É muito mais resistente e rápido que os corações — espantá-lo exige
# dano concentrado (varie as defesas!). Se for espantado enquanto
# carrega alguém, a defesa é devolvida ao seu lugar.

const SPEED := 90.0
const GRAB_TIME := 3.2
const FRAME_FRONT := 0
const FRAME_SIDE := 1
const FRAME_BACK := 2

var hp := 130.0
var reward := 12
enum State {seeking, grabbing, carrying, leaving}
var state := State.seeking
var target: Node2D = null
var grab_t := 0.0
var bob_t := 0.0
var is_destroyed := false
var home_spot := Vector2.ZERO   # onde a vítima estava (para devolver)

func _ready():
	add_to_group("enemy")
	if is_instance_valid(Globals.hud):
		Globals.hud.show_banner("Uh! Um fantasma quer levar a família!", 2.0)

func _process(delta):
	bob_t += delta
	$Sprite2D.position.y = sin(bob_t * 3.4) * 5.0
	match state:
		State.seeking:
			_seek(delta)
		State.grabbing:
			_grab(delta)
		State.carrying, State.leaving:
			_leave(delta)

func _closest_defender() -> Node2D:
	var best: Node2D = null
	var best_d := 1e9
	if not is_instance_valid(Globals.turretsNode):
		return null
	for t in Globals.turretsNode.get_children():
		if "deployed" in t and t.deployed:
			var d: float = t.global_position.distance_to(global_position)
			if d < best_d:
				best_d = d
				best = t
	return best

func _seek(delta):
	if not is_instance_valid(target) or not ("deployed" in target) or not target.deployed:
		target = _closest_defender()
		if target == null:
			state = State.leaving
			return
	var to: Vector2 = (target.global_position + Vector2(0, -30)) - global_position
	var dist := to.length()
	if dist < 12.0:
		_start_grab()
		return
	var dir := to / dist
	global_position += dir * SPEED * delta
	$Sprite2D.frame = FRAME_SIDE
	$Sprite2D.flip_h = dir.x < 0

func _start_grab():
	state = State.grabbing
	grab_t = 0.0
	$Sprite2D.frame = FRAME_FRONT
	Sfx.play("hit", -9.0)
	# mergulho de agarrar: desce sobre a defesa com squash
	var tween := create_tween()
	tween.tween_property($Sprite2D, "scale", Vector2(1.15, 0.85), 0.1)
	tween.tween_property($Sprite2D, "scale", Vector2(1, 1), 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _grab(delta):
	if not is_instance_valid(target) or not target.deployed:
		state = State.seeking
		return
	grab_t += delta
	# a vítima se debate
	target.get_node("Sprite2D").position.x = sin(grab_t * 30.0) * 2.5
	if grab_t >= GRAB_TIME:
		_steal()

func _steal():
	if not is_instance_valid(target):
		state = State.seeking
		return
	state = State.carrying
	Sfx.play("gameover", -10.0)
	home_spot = target.global_position
	target.deployed = false
	# congela a vítima por completo (timers de ataque inclusive)
	target.process_mode = Node.PROCESS_MODE_DISABLED
	target.get_node("Sprite2D").position.x = 0
	target.reparent(self)
	# levanta a vítima num arco suave (pendurada embaixo dele)
	var tween := create_tween()
	tween.tween_property(target, "position", Vector2(0, 34), 0.45) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "global_position",
		global_position + Vector2(20, -46), 0.45) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if is_instance_valid(Globals.hud):
		Globals.hud.show_banner("O fantasma levou %s!" % Data.turrets[target.turret_type]["name"], 1.8)

func _leave(delta):
	# de costas, fugindo para cima no DOBRO da velocidade
	$Sprite2D.frame = FRAME_BACK
	$Sprite2D.flip_h = false
	global_position += Vector2(0, -2.0) * SPEED * delta
	if global_position.y < -520.0:
		queue_free()

func get_damage(amount):
	if is_destroyed:
		return
	hp -= amount
	var tween := create_tween()
	tween.tween_property($Sprite2D, "self_modulate", Color(0.7, 0.9, 1.0), 0.06)
	tween.tween_property($Sprite2D, "self_modulate", Color.WHITE, 0.2)
	if hp <= 0:
		_banish()

func _banish():
	is_destroyed = true
	remove_from_group("enemy")
	$Area/CollisionShape2D.set_deferred("disabled", true)
	set_process(false)
	# devolve a vítima ao lugar dela
	if state == State.carrying and is_instance_valid(target) and target.get_parent() == self:
		target.reparent(Globals.turretsNode)
		var back := target.create_tween()
		back.tween_property(target, "global_position", home_spot, 0.4) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		back.tween_callback(func():
			target.deployed = true
			target.process_mode = Node.PROCESS_MODE_INHERIT)
	Globals.currentMap.gold += reward
	Progress.add_points(3)
	Sfx.play("heal", -6.0)
	if is_instance_valid(Globals.hud):
		Globals.hud.show_banner("Fantasma espantado! +%d" % reward, 1.6)
	# dissolve
	var tween := create_tween()
	tween.set_parallel()
	tween.tween_property($Sprite2D, "modulate:a", 0.0, 0.5)
	tween.tween_property($Sprite2D, "scale", Vector2(1.4, 1.4), 0.5)
	tween.tween_property(self, "global_position", global_position + Vector2(0, -40), 0.5)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
