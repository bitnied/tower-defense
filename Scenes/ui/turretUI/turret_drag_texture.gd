extends TextureRect

var turretType := ""

var grabbing := false
var placeholder = null
var grab_start := Vector2.ZERO

func _ready():
	Globals.goldChanged.connect(check_can_purchase)

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed and check_can_purchase(Globals.currentMap.gold):
		start_grab()

func _input(event):
	if not grabbing:
		return
	if event is InputEventMouseMotion:
		update_placeholder_position()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and not event.pressed:
		end_grab()
	elif event is InputEventScreenTouch and not event.pressed:
		end_grab()

func start_grab():
	if is_instance_valid(placeholder):
		return
	grabbing = true
	grab_start = get_global_mouse_position()
	create_placeholder()
	update_placeholder_position()

func update_placeholder_position():
	if is_instance_valid(placeholder):
		# posição no MUNDO (respeita o zoom da câmera)
		placeholder.global_position = placeholder.get_global_mouse_position()

func end_grab():
	grabbing = false
	if not is_instance_valid(placeholder):
		placeholder = null
		return
	update_placeholder_position()
	var ph = placeholder
	placeholder = null
	# toque sem arrastar (ou soltar em cima do painel) = cancela,
	# sem gastar nada
	var moved: float = get_global_mouse_position().distance_to(grab_start)
	var over_panel: bool = get_global_mouse_position().x \
		> get_viewport_rect().size.x - 158.0
	if moved < 24.0 or over_panel:
		ph.queue_free()
		return
	# posicionamento livre: pode construir em qualquer lugar do cenário
	if check_can_purchase(Globals.currentMap.gold):
		var price := Globals.defender_cost(turretType)
		Globals.currentMap.gold -= price
		ph.paid_cost = price
		ph.build()
	else:
		ph.queue_free()

func create_placeholder():
	var turretScene := load(Data.turrets[turretType]["scene"])
	var turret = turretScene.instantiate()
	turret.turret_type = turretType
	Globals.turretsNode.add_child(turret)
	placeholder = turret
	placeholder.set_placeholder()

func check_can_purchase(newGold):
	if turretType:
		if Globals.is_defender_locked(turretType):
			owner.can_purchase = false
			return false
		if newGold >= Globals.defender_cost(turretType):
			owner.can_purchase = true
			return true
		owner.can_purchase = false
		return false
