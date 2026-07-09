extends Turret

var bulletSpeed := 200.0
var bulletPierce := 1

func attack():
	if is_instance_valid(current_target):
		attack_punch()
		var cfg: Dictionary = Data.turrets[turret_type]
		if cfg.has("attack_sfx"):
			Sfx.play(cfg["attack_sfx"], -20.0)
		var projectileScene := preload("res://Scenes/turrets/projectileTurret/bullet/bulletBase.tscn")
		var projectile := projectileScene.instantiate()
		projectile.bullet_type = cfg["bullet"]
		projectile.damage = damage
		projectile.speed = bulletSpeed
		projectile.pierce = bulletPierce
		# sai da frente do personagem; só fica atrás quando ele
		# está de costas (mirando para cima)
		projectile.z_index = 1 if is_facing_up() else 3
		Globals.projectilesNode.add_child(projectile)
		projectile.position = position + muzzle_offset()
		projectile.target = current_target.position
	else:
		try_get_closest_target()

# ponto de saída do projétil (mão/boca/violão), medido no sheet
# sem escala e ajustado pela escala do personagem
func muzzle_offset() -> Vector2:
	var m: Dictionary = Data.turrets[turret_type].get("muzzle", {})
	var off: Array
	if uses_sheet and $Sprite2D.texture == sheet_tex and $Sprite2D.frame == FRAME_SIDE:
		off = m.get("side", [0, -34])
	elif uses_sheet and $Sprite2D.texture == sheet_tex and $Sprite2D.frame == FRAME_UP:
		off = m.get("up", [0, -34])
	else:
		off = m.get("down", [0, -34])
	var v := Vector2(off[0], off[1]) * sprite_scale
	if $Sprite2D.flip_h:
		v.x = -v.x
	return v
