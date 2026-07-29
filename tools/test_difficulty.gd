extends SceneTree
# Teste headless: confere a curva das 3 dificuldades (quantidade de
# corações por onda, hp por unidade, eventos e ouro teórico).
# Rodar: Godot --headless --script res://tools/test_difficulty.gd

const TIERS := [["rachado", 1.0, 7.0, 3.0], ["partido", 1.8, 18.0, 5.0],
	["despedacado", 2.6, 40.0, 8.0]]

func _init():
	var results := {}
	for key in Data.difficulty_order:
		results[key] = _sim(key)
	print("")
	var med: Array = results["medio"]
	for key in Data.difficulty_order:
		var r: Array = results[key]
		print("%-10s HP total %7.0f (%3.0f%% do medio)   ouro %6.0f (%3.0f%%)" % [
			key, r[0], r[0] / med[0] * 100.0, r[1], r[1] / med[1] * 100.0])
	# checagens
	var ok := true
	if results["vida_real"][0] <= results["medio"][0]:
		print("FALHA: vida_real nao e mais dificil que medio"); ok = false
	if results["vida_real"][0] / med[0] > 1.5:
		print("FALHA: vida_real passou de 150% do HP do medio"); ok = false
	if results["facil"][0] >= med[0]:
		print("FALHA: facil nao e mais facil que medio"); ok = false
	print("RESULTADO: ", "OK" if ok else "FALHOU")
	quit(0 if ok else 1)

func _sim(key: String) -> Array:
	var d: Dictionary = Data.difficulties[key]
	var m: Dictionary = Data.maps["elisa"]["spawner_settings"]
	var inc: float = d["increase"]
	var total_hp := 0.0
	var gold: float = d["startingGold"]
	print("\n=== %s (vida %d, ouro %d) ===" % [d["name"], d["baseHp"], d["startingGold"]])
	for w in range(1, int(m["max_waves"]) + 1):
		var diff: float = pow(inc, w)
		var n: int = roundi(m["wave_spawn_count"] * diff)
		var avg_hp := 0.0
		var avg_yield := 0.0
		var tiers := 0
		for t in TIERS:
			if diff >= float(t[1]):
				avg_hp += float(t[2]); avg_yield += float(t[3]); tiers += 1
		if tiers == 0:
			avg_hp = 7.0; avg_yield = 3.0; tiers = 1
		avg_hp /= tiers
		avg_yield /= tiers
		var f: float = d["hp_mult"] * (1.0 + d["hp_per_wave"] * (w - 1))
		var wave_hp := 0.0
		var wave_gold := 8.0
		if w == int(m["max_waves"]):
			n = int(d["escort"]) + 1
			wave_hp = Data.enemies["coracaoGigante"]["stats"]["hp"] * d["hp_mult"] \
				+ d["escort"] * avg_hp * f
			wave_gold += Data.enemies["coracaoGigante"]["stats"]["goldYield"] + d["escort"] * avg_yield
		else:
			wave_hp = n * avg_hp * f
			wave_gold += n * avg_yield
		var nm: int = d["meteor_waves"].count(w)
		var ng: int = d["ghost_waves"].count(w)
		n += nm
		wave_hp += nm * Data.enemies["coracaoMeteoro"]["stats"]["hp"] * d["hp_mult"]
		wave_gold += nm * Data.enemies["coracaoMeteoro"]["stats"]["goldYield"] + ng * 12
		total_hp += wave_hp
		gold += wave_gold
		var ev := ""
		for i in nm: ev += "M"
		for i in ng: ev += "F"
		if w == int(m["max_waves"]): ev += "B"
		print("onda %2d | %3d coracoes | %5.1f hp cada | %6.0f hp | %-4s | ouro %4.0f" % [
			w, n, avg_hp * f, wave_hp, ev, gold])
	return [total_hp, gold]
