extends SceneTree
# Valida (parse) todos os .gd do projeto no contexto real, com
# autoloads carregados. Uso:
#   Godot --headless --path . tools/check_parse.tscn  (via main_loop)
# Aqui: rodar com  --script  não carrega autoloads, então este script
# é usado como cena raiz via _init em modo -s? Não: usamos --quit-after
# com uma cena que chama isto. Simples: como SceneTree, _initialize roda
# com autoloads ausentes, mas load() ainda reporta erros de parse.

func _initialize():
	var bad := 0
	for path in _all_scripts("res://Scenes"):
		var s = load(path)
		if s == null:
			push_error("FALHOU: " + path)
			bad += 1
	print("PARSE_OK" if bad == 0 else "PARSE_FAIL %d" % bad)
	quit()

func _all_scripts(dir: String) -> Array:
	var out: Array = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	d.list_dir_begin()
	var f := d.get_next()
	while f != "":
		var p := dir + "/" + f
		if d.current_is_dir() and not f.begins_with("."):
			out += _all_scripts(p)
		elif f.ends_with(".gd"):
			out.append(p)
		f = d.get_next()
	return out
