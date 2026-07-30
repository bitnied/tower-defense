extends PanelContainer

var turret : Node2D
const sell_modifier := 0.7

# a venda só pode acontecer UMA vez: o queue_free() do painel só vale no
# fim do frame, então sem esta trava cada toque extra em "Vender" (e no
# celular um toque chega duas vezes) pagava o preço inteiro outra vez —
# era a chuva de corações ao vender uma defesa agarrada pelo fantasma
var sold := false
var _last_press_frame := -1

func _ready():
	Globals.goldChanged.connect(check_can_upgrade)
	turret.turretUpdated.connect(set_props)
	# se a defesa sair de campo (fantasma fugiu com ela, mapa reiniciou),
	# o painel não pode ficar aberto apontando para quem não existe mais
	turret.tree_exiting.connect(_on_turret_left)
	set_props()
	animate_appear()
	check_can_upgrade()

# um toque de celular chega como toque + clique emulado: só o primeiro vale
func _duplicate_press() -> bool:
	var frame := Engine.get_process_frames()
	if frame == _last_press_frame:
		return true
	_last_press_frame = frame
	return false

func _on_turret_left():
	if not sold:
		dismiss()

# fecha o painel sem mexer na defesa, deixando o HUD sem ponteiro solto
func dismiss():
	if is_instance_valid(Globals.hud) and Globals.hud.open_details_pane == self:
		Globals.hud.open_details_pane = null
	if is_instance_valid(turret):
		turret.draw_range = false
		turret.queue_redraw()
	queue_free()

func animate_appear():
	var tween := create_tween()
	tween.tween_property(self, "position", Vector2(-400,0), 0.01).as_relative()
	tween.tween_property(self, "position", Vector2(400,0), 0.3).as_relative()

func set_props():
	%TurretTexture.texture = Globals.defender_icon(turret.turret_type)
	%TurretName.text = Data.turrets[turret.turret_type]["name"]
	%TurretLevel.text = "Nível "+str(turret.turret_level)
	%UpgradeButton.text = "Melhorar ("+str(get_upgrade_price())+")"
	%SellButton.text = "Vender ("+str(get_sell_price())+")"
	for c in %Stats.get_children():
		c.queue_free()
	var statLabelScene := preload("res://Scenes/ui/turretUI/stat_label.tscn")
	for stat in Data.turrets[turret.turret_type]["stats"].keys():
		var statLabel := statLabelScene.instantiate()
		# mostra casas decimais só quando existem (1.2 não vira "1.0")
		var v: float = snappedf(float(turret.get(stat)), 0.05)
		var v_txt := str(int(v)) if fmod(v, 1.0) == 0.0 else str(v)
		statLabel.text = Data.stats[stat]["name"]+" "+v_txt
		%Stats.add_child(statLabel)

func _on_upgrade_button_pressed():
	if sold or _duplicate_press() or not is_instance_valid(turret):
		return
	if check_can_upgrade():
		Globals.currentMap.gold -= get_upgrade_price()
		turret.upgrade_turret()
		check_can_upgrade()

func get_upgrade_price():
	return turret.turret_level * Data.turrets[turret.turret_type]["upgrade_cost"]

func get_sell_price():
	var total_cost = turret.paid_cost if turret.paid_cost > 0 		else Data.turrets[turret.turret_type]["cost"]
	for i in range(turret.turret_level):
		total_cost += i*Data.turrets[turret.turret_type]["upgrade_cost"]
	return int(round(total_cost * sell_modifier))

func check_can_upgrade(_new_gold=0):
	if turret.turret_level == Data.turrets[turret.turret_type]["max_level"]:
		%UpgradeButton.text = "No máximo"
		%UpgradeButton.disabled = true
	else:
		%UpgradeButton.disabled = Globals.currentMap.gold < get_upgrade_price()
	return not %UpgradeButton.disabled


func _on_sell_button_pressed():
	if sold or not is_instance_valid(turret) or turret.is_queued_for_deletion():
		return
	sold = true
	%SellButton.disabled = true
	%UpgradeButton.disabled = true
	Sfx.play("heal", -10.0)
	Globals.currentMap.gold += get_sell_price()
	turret.queue_free()
	dismiss()

func _on_close_button_pressed():
	if _duplicate_press():
		return
	if is_instance_valid(turret):
		turret.close_details_pane()
	else:
		dismiss()
