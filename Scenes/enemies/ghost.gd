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
var lift_tween: Tween           # animação de levantar a vítima

func _ready():
	add_to_group("enemy")
	add_to_group("ghost")
	Sfx.play("ghost", -3.0)
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
		if _grabbable(t) and not _claimed_by_other(t):
			var d: float = t.global_position.distance_to(global_position)
			if d < best_d:
				best_d = d
				best = t
	return best

# defesa que dá para agarrar: ativa e ainda no jogo (uma defesa vendida
# só é liberada no fim do frame, mas já não vale mais)
func _grabbable(t) -> bool:
	return is_instance_valid(t) and not t.is_queued_for_deletion() \
		and "deployed" in t and t.deployed

# outro fantasma já está em cima desta defesa? (dois fantasmas na mesma
# vítima deixavam a defesa pendurada no limbo)
func _claimed_by_other(t) -> bool:
	for g in get_tree().get_nodes_in_group("ghost"):
		if g != self and is_instance_valid(g) and not g.is_destroyed and g.target == t:
			return true
	return false

func _seek(delta):
	if not _grabbable(target):
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
	Sfx.play("hit", -6.0)
	# mergulho de agarrar: desce sobre a defesa com squash
	var tween := create_tween()
	tween.tween_property($Sprite2D, "scale", Vector2(1.15, 0.85), 0.1)
	tween.tween_property($Sprite2D, "scale", Vector2(1, 1), 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _grab(delta):
	if not _grabbable(target):
		# vendida/removida no meio do agarrão: solta e procura outra
		_release_victim()
		state = State.seeking
		return
	grab_t += delta
	# a vítima se debate
	target.get_node("Sprite2D").position.x = sin(grab_t * 30.0) * 2.5
	if grab_t >= GRAB_TIME:
		_steal()

func _steal():
	if not _grabbable(target):
		_release_victim()
		state = State.seeking
		return
	state = State.carrying
	Sfx.play("gameover", -6.0)
	home_spot = target.global_position
	target.deployed = false
	# congela a vítima por completo (timers de ataque inclusive)
	target.process_mode = Node.PROCESS_MODE_DISABLED
	target.get_node("Sprite2D").position.x = 0
	target.reparent(self)
	# levanta a vítima num arco suave (pendurada embaixo dele)
	lift_tween = create_tween()
	lift_tween.tween_property(target, "position", Vector2(0, 34), 0.45) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	lift_tween.parallel().tween_property(self, "global_position",
		global_position + Vector2(20, -46), 0.45) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if is_instance_valid(Globals.hud):
		Globals.hud.show_banner("O fantasma levou %s!" % Data.turrets[target.turret_type]["name"], 1.8)

# Solta a vítima: volta ao lugar de origem, viva e atacando de novo.
# Devolve o nome dela (ou "") para quem quiser avisar o jogador.
# ATENÇÃO: religar o process_mode ANTES de criar o tween é obrigatório —
# tween preso a um nó com processamento desligado nunca roda, e era
# justamente isso que deixava a defesa congelada no ar para sempre.
func _release_victim() -> String:
	var victim = target
	target = null
	if lift_tween and lift_tween.is_valid():
		lift_tween.kill()   # senão o tween do "levanta" briga com a volta
	if not is_instance_valid(victim):
		return ""
	if victim.has_node("Sprite2D"):
		victim.get_node("Sprite2D").position.x = 0.0   # para de se debater
	if victim.get_parent() != self:
		return ""   # não está nos meus braços (ou nem foi roubada ainda)
	if not is_instance_valid(Globals.turretsNode):
		return ""   # mapa saindo de cena: não há para onde devolver
	victim.reparent(Globals.turretsNode)
	victim.process_mode = Node.PROCESS_MODE_INHERIT
	victim.deployed = true
	if victim.is_queued_for_deletion():
		return ""   # foi vendida enquanto estava pendurada: nada a devolver
	var back := victim.create_tween()
	back.tween_property(victim, "global_position", home_spot, 0.4) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return Data.turrets[victim.turret_type]["name"]

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
	var rescued := _release_victim()
	Globals.currentMap.gold += reward
	Progress.add_points(3)
	Sfx.play("heal", -6.0)
	if is_instance_valid(Globals.hud):
		if rescued != "":
			Globals.hud.show_banner("Fantasma espantado! %s voltou pra casa! +%d"
				% [rescued, reward], 1.8)
		else:
			Globals.hud.show_banner("Fantasma espantado! +%d" % reward, 1.6)
	# dissolve
	var tween := create_tween()
	tween.set_parallel()
	tween.tween_property($Sprite2D, "modulate:a", 0.0, 0.5)
	tween.tween_property($Sprite2D, "scale", Vector2(1.4, 1.4), 0.5)
	tween.tween_property(self, "global_position", global_position + Vector2(0, -40), 0.5)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
