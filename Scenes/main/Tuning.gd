extends Node
# Ajuste fino de atributos SEM recompilar: a página docs/tuning.html
# grava overrides no localStorage do navegador (chave "etd_tuning")
# e este autoload os lê na largada. Fora do navegador (editor),
# nunca há overrides e valem os padrões do Data.gd.

var overrides := {}

func _ready():
	if not OS.has_feature("web"):
		return
	var raw = JavaScriptBridge.eval("localStorage.getItem('etd_tuning') || ''", true)
	if raw is String and raw != "":
		var parsed = JSON.parse_string(raw)
		if parsed is Dictionary:
			overrides = parsed
			print("Tuning: overrides ativos para ", overrides.keys())

# valor ajustado de um atributo do defensor, ou o padrão (fallback)
func value(defender: String, stat: String, fallback):
	var d = overrides.get(defender)
	if d is Dictionary and d.has(stat):
		var v = d[stat]
		if v is float or v is int:
			return v
	return fallback
