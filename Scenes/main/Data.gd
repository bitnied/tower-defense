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
			"attack_range": 170.0,
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
		"upgrade_cost": 40,
		"max_level": 3,
		"scene": "res://Scenes/turrets/projectileTurret/projectileTurret.tscn",
		"sprite": "res://Assets/defenders/tiago_sheet.png",
		"portrait": "res://Assets/defenders/tiago_portrait.png",
		"idle": "res://Assets/defenders/tiago_idle.png",
		"directional_sheet": true,
		"scale": 1.0,
		"rotates": false,
		"bullet": "sound_wave",
		"attack_sfx": "atk_tiago",
		"muzzle": {"down": [4, -28], "side": [14, -30], "up": [0, -40]},
	},
	"luna": {
		"stats": {
			"damage": 1.2,
			"attack_speed": 0.7,
			"attack_range": 170.0,
			"ray_duration": 1.2,
			"ray_length": 160.0,
		},
		"upgrades": {
			"damage": {"amount": 0.8, "multiplies": false},
			"ray_duration": {"amount": 1.3, "multiplies": true},
		},
		"name": "Luna",
		"subtitle": "Raio de amor que congela os corações",
		"cost": 55,
		"upgrade_cost": 55,
		"max_level": 3,
		"scene": "res://Scenes/turrets/rayTurret/rayTurret.tscn",
		"sprite": "res://Assets/defenders/luna_sheet.png",
		"portrait": "res://Assets/defenders/luna_portrait.png",
		"idle": "res://Assets/defenders/luna_idle.png",
		"directional_sheet": true,
		"scale": 0.7,
		"rotates": false,
		"attack_sfx": "atk_luna",
		"locked": true,
		"unlock_wave": 2,
	},
	"leo": {
		"stats": {
			"damage": 12.0,
			"attack_speed": 0.9,
			"attack_range": 180.0,
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
		"upgrade_cost": 70,
		"max_level": 3,
		"scene": "res://Scenes/turrets/projectileTurret/projectileTurret.tscn",
		"sprite": "res://Assets/defenders/leo_sheet.png",
		"portrait": "res://Assets/defenders/leo_portrait.png",
		"idle": "res://Assets/defenders/leo_idle.png",
		"directional_sheet": true,
		"scale": 0.7,
		"rotates": false,
		"bullet": "kiss",
		"attack_sfx": "atk_leo",
		"muzzle": {"down": [0, -44], "side": [12, -44], "up": [0, -58]},
		"locked": true,
		"unlock_wave": 4,
	},
	"elisa": {
		"stats": {
			"damage": 24.0,
			"attack_speed": 1.0,
			"attack_range": 220.0,
			"bulletSpeed": 190.0,
			"bulletPierce": 3,
		},
		"upgrades": {
			"damage": {"amount": 12.0, "multiplies": false},
			"attack_speed": {"amount": 1.25, "multiplies": true},
		},
		"name": "Elisa",
		"subtitle": "Aponta o dedo: corações dourados",
		"cost": 130,
		"upgrade_cost": 95,
		"max_level": 3,
		"scene": "res://Scenes/turrets/projectileTurret/projectileTurret.tscn",
		"sprite": "res://Assets/defenders/elisa_sheet.png",
		"portrait": "res://Assets/defenders/elisa_portrait.png",
		"idle": "res://Assets/defenders/elisa_idle.png",
		"directional_sheet": true,
		"scale": 1.0,
		"rotates": false,
		"bullet": "gold_heart",
		"attack_sfx": "atk_elisa",
		"muzzle": {"down": [10, -25], "side": [24, -40], "up": [18, -61]},
		# Surpresa do jogo: Elisa aparece como "?" e é liberada
		# no começo da onda 5 (de 10).
		"locked": true,
		"unlock_wave": 5,
		"mystery": true,
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
		"scale": 0.7,
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
			"hp": 10.0,
			"speed": 0.85,
			"baseDamage": 1.0,
			"goldYield": 3.0,
			},
		"difficulty": 1.0,
		"sprite": "res://Assets/enemies/heart_cracked.png",
	},
	"coracaoPartido": {
		"stats": {
			"hp": 22.0,
			"speed": 0.68,
			"baseDamage": 2.0,
			"goldYield": 5.0,
			},
		"difficulty": 1.8,
		"sprite": "res://Assets/enemies/heart_broken.png",
	},
	"coracaoDespedacado": {
		"stats": {
			"hp": 45.0,
			"speed": 0.52,
			"baseDamage": 3.0,
			"goldYield": 8.0,
			},
		"difficulty": 2.6,
		"sprite": "res://Assets/enemies/heart_shattered.png",
	},
	# Chefão da onda final: um coração gigante partido, lento e
	# cheio de dor. difficulty 99 = nunca entra no sorteio normal.
	"coracaoGigante": {
		"stats": {
			"hp": 560.0,
			"speed": 0.3,
			"baseDamage": 10.0,
			"goldYield": 40.0,
			},
		"difficulty": 99.0,
		"sprite": "res://Assets/enemies/heart_shattered.png",
		"scale": 2.4,
		"boss": true,
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
		"startingGold": 45,
		"spawner_settings":
			{
			"difficulty": {"initial": 1.0, "increase": 1.22, "multiplies": true},
			"max_waves": 10,
			"wave_spawn_count": 6,
			# onda final: coração gigante + escolta
			"special_waves": {"10": {"boss": "coracaoGigante", "escort": 14}},
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
