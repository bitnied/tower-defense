extends Node2D
class_name Turret

signal turretUpdated

# Spritesheet direcional simples: 3 células horizontais
# [0]=baixo (frente), [1]=direita (perfil, espelha p/ esquerda), [2]=cima.
# A "vida" do sprite vem por código: bob contínuo + recuo no ataque.
const FRAME_DOWN := 0
const FRAME_SIDE := 1
const FRAME_UP := 2

var turret_type := "":
	set(value):
		turret_type = value
		var cfg: Dictionary = Data.turrets[value]
		$Sprite2D.texture = load(cfg["sprite"])
		sprite_scale = cfg["scale"]
		$Sprite2D.scale = Vector2(sprite_scale, sprite_scale)
		uses_sheet = cfg.get("directional_sheet", false)
		if uses_sheet:
			$Sprite2D.hframes = 3
			$Sprite2D.vframes = 1
			$Sprite2D.frame = FRAME_DOWN
		rotates = cfg.get("rotates", false)
		for stat in cfg["stats"].keys():
			set(stat, cfg["stats"][stat])

#Deploying
var deployed := false
var can_place := false
var draw_range := false
#Attacking
var rotates := false
var uses_sheet := false
var sprite_scale := 1.0
var bob_t := 0.0
var punch_tween: Tween
var current_target = null
#Stats
var attack_speed := 1.0:
	set(value):
		attack_speed = value
		$AttackCooldown.wait_time = 1.0/value
var attack_range := 1.0:
	set(value):
		attack_range = value
		$DetectionArea/CollisionShape2D.shape.radius = value
var damage := 1.0
var turret_level := 1

func _process(delta):
	if not deployed:
		@warning_ignore("standalone_ternary")
		colliding() if $CollisionArea.has_overlapping_areas() else not_colliding()
	elif uses_sheet:
		update_facing(delta)
	elif rotates:
		@warning_ignore("standalone_ternary")
		look_at(current_target.position) if is_instance_valid(current_target) else try_get_closest_target()

func update_facing(delta):
	if is_instance_valid(current_target):
		var v: Vector2 = current_target.position - position
		if absf(v.x) >= absf(v.y):
			$Sprite2D.frame = FRAME_SIDE
			$Sprite2D.flip_h = v.x < 0
		elif v.y > 0:
			$Sprite2D.frame = FRAME_DOWN
			$Sprite2D.flip_h = false
		else:
			$Sprite2D.frame = FRAME_UP
			$Sprite2D.flip_h = false
	else:
		try_get_closest_target()
	# respiração/bob contínuo
	bob_t += delta
	$Sprite2D.position.y = sin(bob_t * 3.0) * 2.0

# Recuo rápido ao atacar (chamado pelas torres ao disparar)
func attack_punch():
	if punch_tween and punch_tween.is_running():
		return
	punch_tween = create_tween()
	punch_tween.tween_property($Sprite2D, "scale",
		Vector2(sprite_scale * 1.14, sprite_scale * 0.86), 0.07)
	punch_tween.tween_property($Sprite2D, "scale",
		Vector2(sprite_scale, sprite_scale), 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _draw():
	if draw_range:
		draw_circle(Vector2(0,0), attack_range, "3ccd50a9", false, 1, true)

func set_placeholder():
	modulate = Color("6eff297a")

func build():
	deployed = true
	modulate = Color.WHITE

func colliding():
	can_place = false
	modulate = Color("ff5c2990")

func not_colliding():
	can_place = true
	modulate = Color("6eff297a")

func _on_detection_area_area_entered(area):
	if deployed and not current_target:
		var area_parent = area.get_parent()
		if area_parent.is_in_group("enemy"):
			current_target = area.get_parent()

func _on_detection_area_area_exited(area):
	if deployed and current_target == area.get_parent():
		current_target = null
		try_get_closest_target()

func try_get_closest_target():
	if not deployed:
		return
	var closest = 1000
	var closest_area = null
	for area in $DetectionArea.get_overlapping_areas():
		var dist = area.position.distance_to(position)
		if dist < closest:
			closest = dist
			closest_area = area
	if closest_area:
		current_target = closest_area.get_parent()

func open_details_pane():
	var turretDetailsScene := preload("res://Scenes/ui/turretUI/turret_details.tscn")
	var details := turretDetailsScene.instantiate()
	details.turret = self
	draw_range = true
	queue_redraw()
	Globals.hud.add_child(details)
	Globals.hud.open_details_pane = details

func close_details_pane():
	draw_range = false
	queue_redraw()
	Globals.hud.open_details_pane.queue_free()
	Globals.hud.open_details_pane = null

func _on_collision_area_input_event(_viewport, event, _shape_idx):
	var tapped = (event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed)
	if deployed and tapped:
		if is_instance_valid(Globals.hud.open_details_pane):
			if Globals.hud.open_details_pane.turret == self:
				close_details_pane()
				return
			Globals.hud.open_details_pane.turret.close_details_pane()
		open_details_pane()

func upgrade_turret():
	turret_level += 1
	for upgrade in Data.turrets[turret_type]["upgrades"].keys():
		if Data.turrets[turret_type]["upgrades"][upgrade]["multiplies"]:
			set(upgrade, get(upgrade) * Data.turrets[turret_type]["upgrades"][upgrade]["amount"])
		else:
			set(upgrade, get(upgrade) + Data.turrets[turret_type]["upgrades"][upgrade]["amount"])
	turretUpdated.emit()

func attack():
	if is_instance_valid(current_target):
		pass
	else:
		try_get_closest_target()
