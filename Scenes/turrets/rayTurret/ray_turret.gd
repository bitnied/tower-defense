extends Turret
# Luna: raio de amor. O feixe nasce das MÃOS dela (offset por pose),
# com glow, brilho na origem e partículas no ponto de impacto.

var can_fire := true
var ray_enabled := false
var ray_extension := 0.0

var ray_length := 400.0
var ray_duration := 2.0

var glow: Line2D
var core: Line2D
var origin_sparks: CPUParticles2D
var impact_sparks: CPUParticles2D
var light_t := 0.0

func _ready():
	glow = Line2D.new()
	glow.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])
	glow.width = 30.0
	glow.default_color = Color(1.0, 0.55, 0.8, 0.45)
	glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	glow.end_cap_mode = Line2D.LINE_CAP_ROUND
	glow.z_index = 2
	$HitArea.add_child(glow)
	core = Line2D.new()
	core.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])
	core.width = 5.0
	core.default_color = Color(1.0, 0.96, 1.0, 0.95)
	core.begin_cap_mode = Line2D.LINE_CAP_ROUND
	core.end_cap_mode = Line2D.LINE_CAP_ROUND
	core.z_index = 4
	$HitArea.add_child(core)
	origin_sparks = _make_sparks(16, 24.0)
	$HitArea.add_child(origin_sparks)
	impact_sparks = _make_sparks(26, 38.0)
	$HitArea.add_child(impact_sparks)

func _make_sparks(amount: int, velocity: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.emitting = false
	p.amount = amount
	p.lifetime = 0.45
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = velocity * 0.5
	p.initial_velocity_max = velocity
	p.scale_amount_min = 1.6
	p.scale_amount_max = 3.2
	p.color = Color(1.0, 0.75, 0.9)
	p.color_ramp = _spark_ramp()
	p.z_index = 3
	return p

func _spark_ramp() -> Gradient:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 0.45, 0.75, 0))
	return g

# posição das mãos conforme a pose da sprite
func hand_offset() -> Vector2:
	if $Sprite2D.frame == FRAME_UP:
		return Vector2(0, -64)
	if $Sprite2D.frame == FRAME_SIDE:
		return Vector2(-20 if $Sprite2D.flip_h else 20, -28)
	return Vector2(0, -34)

func _process(delta):
	super._process(delta)
	if ray_enabled and ray_extension < 1.0:
		ray_extension += 0.1
		activate_ray(ray_extension)
	if not ray_enabled and ray_extension > 0:
		# retração rápida: some antes dela virar para outro lado
		ray_extension = maxf(ray_extension - 0.12, 0.0)
		deactivate_ray(ray_extension)
	# pulso de luz enquanto o raio está ativo
	if ray_enabled:
		light_t += delta
		var pulse := 1.0 + 0.25 * sin(light_t * 18.0)
		glow.width = 30.0 * pulse
		core.width = 5.0 + 1.5 * sin(light_t * 24.0)

func attack():
	if not $RayDuration.is_stopped():
		for a in $HitArea.get_overlapping_areas():
			var collider = a.get_parent()
			if collider.is_in_group("enemy"):
				collider.get_damage(damage)
	if is_instance_valid(current_target):
		if can_fire:
			can_fire = false
			ray_enabled = true
			attack_punch()
			origin_sparks.emitting = true
			impact_sparks.emitting = true
			$RayDuration.start()
	else:
		try_get_closest_target()

func activate_ray(ratio):
	if is_instance_valid(current_target):
		$HitArea.position = hand_offset()
		var beam_z := 1 if is_facing_up() else 3
		$HitArea/Line2D.z_index = beam_z
		glow.z_index = beam_z - 1
		core.z_index = beam_z + 1
		var to_target: Vector2 = current_target.position - position - $HitArea.position
		var offset: Vector2 = to_target.normalized() * ray_length * ratio
		$HitArea/Line2D.set_point_position(1, offset)
		glow.set_point_position(1, offset)
		core.set_point_position(1, offset)
		$HitArea/CollisionShape2D.shape.b = offset
		impact_sparks.position = offset

func deactivate_ray(ratio):
	var offset = $HitArea/Line2D.get_point_position(1) * ratio
	$HitArea/Line2D.set_point_position(1, offset)
	glow.set_point_position(1, offset)
	core.set_point_position(1, offset)
	$HitArea/CollisionShape2D.shape.b = offset
	impact_sparks.position = offset

func _on_ray_duration_timeout():
	ray_enabled = false
	origin_sparks.emitting = false
	impact_sparks.emitting = false
	$AttackCooldown.start()

func _on_attack_cooldown_timeout():
	can_fire = true
