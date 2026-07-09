extends Node
# ==============================================================
#  ELISA'S DEFENCE
#  Presente de aniversário para a Elisa — de Tiago, Leo e Luna.
#
#  Este arquivo define TODO o conteúdo do jogo: defensores,
#  corações (inimigos), mapa, ondas e textos. Para trocar a arte
#  placeholder pela final, veja ASSETS.md na raiz do projeto.
# ==============================================================

# --------------------------------------------------------------
# DEFENSORES (a chave "turrets" é mantida por compatibilidade
# com os scripts do template).
# Ordem de custo/impacto: Tiago < Luna < Leo < Elisa.
# "directional_sheet": sheet de 3 células horizontais
#   [baixo, direita, cima] — a esquerda é o espelho da direita.
# "portrait": imagem usada no card de compra e no painel de detalhes.
# --------------------------------------------------------------
const turrets := {
	"tiago": {
		"stats": {
			"damage": 4.0,
			"attack_speed": 1.2,
			"attack_range": 190.0,
			"bulletSpeed": 260.0,
			"bulletPierce": 2,
		},
		"upgrades": {
			"damage": {"amount": 3.0, "multiplies": false},
			"attack_speed": {"amount": 1.4, "multiplies": true},
		},
		"name": "Tiago",
		"subtitle": "Toca violão: ondas sonoras de amor",
		"cost": 30,
		"upgrade_cost": 25,
		"max_level": 3,
		"scene": "res://Scenes/turrets/projectileTurret/projectileTurret.tscn",
		"sprite": "res://Assets/defenders/tiago_sheet.png",
		"portrait": "res://Assets/defenders/tiago_portrait.png",
		"idle": "res://Assets/defenders/tiago_idle.png",
		"directional_sheet": true,
		"scale": 1.0,
		"rotates": false,
		"bullet": "sound_wave",
	},
	"luna": {
		"stats": {
			"damage": 2.6,
			"attack_speed": 0.7,
			"attack_range": 220.0,
			"ray_duration": 1.2,
			"ray_length": 240.0,
		},
		"upgrades": {
			"damage": {"amount": 1.6, "multiplies": false},
			"ray_duration": {"amount": 1.3, "multiplies": true},
		},
		"name": "Luna",
		"subtitle": "Coração com as mãos: raio de amor",
		"cost": 55,
		"upgrade_cost": 35,
		"max_level": 3,
		"scene": "res://Scenes/turrets/rayTurret/rayTurret.tscn",
		"sprite": "res://Assets/defenders/luna_sheet.png",
		"portrait": "res://Assets/defenders/luna_portrait.png",
		"idle": "res://Assets/defenders/luna_idle.png",
		"directional_sheet": true,
		"scale": 1.0,
		"rotates": false,
	},
	"leo": {
		"stats": {
			"damage": 12.0,
			"attack_speed": 0.9,
			"attack_range": 200.0,
			"bulletSpeed": 300.0,
			"bulletPierce": 1,
		},
		"upgrades": {
			"damage": {"amount": 6.0, "multiplies": false},
			"attack_speed": {"amount": 1.35, "multiplies": true},
		},
		"name": "Leo",
		"subtitle": "Manda beijo: boquinhas certeiras",
		"cost": 85,
		"upgrade_cost": 45,
		"max_level": 3,
		"scene": "res://Scenes/turrets/projectileTurret/projectileTurret.tscn",
		"sprite": "res://Assets/defenders/leo_sheet.png",
		"portrait": "res://Assets/defenders/leo_portrait.png",
		"idle": "res://Assets/defenders/leo_idle.png",
		"directional_sheet": true,
		"scale": 0.7,
		"rotates": false,
		"bullet": "kiss",
	},
	"elisa": {
		"stats": {
			"damage": 9.0,
			"attack_speed": 2.2,
			"attack_range": 240.0,
			"bulletSpeed": 340.0,
			"bulletPierce": 3,
		},
		"upgrades": {
			"damage": {"amount": 5.0, "multiplies": false},
			"attack_speed": {"amount": 1.3, "multiplies": true},
		},
		"name": "Elisa",
		"subtitle": "Aponta o dedo: corações dourados",
		"cost": 130,
		"upgrade_cost": 60,
		"max_level": 3,
		"scene": "res://Scenes/turrets/projectileTurret/projectileTurret.tscn",
		"sprite": "res://Assets/defenders/elisa_sheet.png",
		"portrait": "res://Assets/defenders/elisa_portrait.png",
		"idle": "res://Assets/defenders/elisa_idle.png",
		"directional_sheet": true,
		"scale": 1.0,
		"rotates": false,
		"bullet": "gold_heart",
		# Surpresa do jogo: Elisa aparece como "?" e é liberada
		# no começo da onda 3 (de 5).
		"locked": true,
		"unlock_wave": 3,
	},
}

const locked_icon := "res://Assets/defenders/locked.png"

const stats := {
	"damage": {"name": "Cura"},
	"attack_speed": {"name": "Velocidade"},
	"attack_range": {"name": "Alcance"},
	"bulletSpeed": {"name": "Vel. do carinho"},
	"bulletPierce": {"name": "Alvos por tiro"},
	"ray_length": {"name": "Alcance do raio"},
	"ray_duration": {"name": "Duração do raio"},
}

const bullets := {
	"sound_wave": {
		"frames": "res://Assets/bullets/sound_wave.tres",
		"style": "wave",
	},
	"kiss": {
		"frames": "res://Assets/bullets/kiss.tres",
	},
	"gold_heart": {
		"frames": "res://Assets/bullets/gold_heart.tres",
	},
}

# --------------------------------------------------------------
# CORAÇÕES PARTIDOS (inimigos).
# "hp" = quanto amor falta para curar; "goldYield" = corações
# que o jogador ganha quando o coração é curado.
# --------------------------------------------------------------
const enemies := {
	"coracaoRachado": {
		"stats": {
			"hp": 8.0,
			"speed": 0.75,
			"baseDamage": 1.0,
			"goldYield": 6.0,
			},
		"difficulty": 1.0,
		"sprite": "res://Assets/enemies/heart_cracked.png",
	},
	"coracaoPartido": {
		"stats": {
			"hp": 16.0,
			"speed": 0.6,
			"baseDamage": 2.0,
			"goldYield": 10.0,
			},
		"difficulty": 2.0,
		"sprite": "res://Assets/enemies/heart_broken.png",
	},
	"coracaoDespedacado": {
		"stats": {
			"hp": 30.0,
			"speed": 0.45,
			"baseDamage": 3.0,
			"goldYield": 16.0,
			},
		"difficulty": 3.0,
		"sprite": "res://Assets/enemies/heart_shattered.png",
	},
}

const healed_heart_sprite := "res://Assets/enemies/heart_healed.png"

# --------------------------------------------------------------
# FASE ÚNICA — caminho em U deitado até a mamãe.
# --------------------------------------------------------------
const maps := {
	"elisa": {
		"name": "Jardim da Mamãe",
		"bg": "res://Assets/maps/map_elisa.png",
		"scene": "res://Scenes/maps/map_elisa.tscn",
		"baseHp": 10,
		"startingGold": 60,
		"spawner_settings":
			{
			"difficulty": {"initial": 0.8, "increase": 1.18, "multiplies": true},
			"max_waves": 10,
			"wave_spawn_count": 6,
			"special_waves": {},
			},
	},
}

# --------------------------------------------------------------
# TEXTOS DO JOGO — edite à vontade os recados para a Elisa.
# --------------------------------------------------------------
const texts := {
	"tagline": "Um presente de aniversário para a Elisa",
	"howto": "Corações partidos avançam pela estrada até a mamãe.
Coloque a família no cenário para curá-los com amor.
Cada coração curado se junta a você e vira a sua moeda
para chamar mais reforços da família.
Não deixe os corações partidos chegarem até a mamãe!",
	"howto_title": "Como jogar",
	"congrats": "Feliz aniversário, Elisa!
Com amor: Luna, Leo e Tiago",
	"unlock_banner": "Surpresa! A Elisa entrou na defesa!",
	"gameover_title": "Ainda tem coração precisando de amor...",
	"gameover_msg": "A família inteira está na torcida.
Respira fundo e tenta de novo!",
	"victory_title": "Parabéns, Elisa!",
	"victory_msg": "Você curou todos os corações
e protegeu a mamãe!

Feliz aniversário!
Com amor: Luna, Leo e Tiago",
}

const family_photo := "res://Assets/ui/familia_placeholder.png"
