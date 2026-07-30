#!/usr/bin/env bash
# Mede a sonoridade percebida de cada arquivo de áudio e imprime o ganho
# de normalização que deve estar em SFX_GAIN (Scenes/main/Sfx.gd).
#
# Rode isto SEMPRE que trocar/adicionar um arquivo em Assets/audio: sem
# atualizar SFX_GAIN o arquivo novo entra no mix no volume que veio da
# fonte, que foi exatamente como o "unlock" acabou 6 dB acima de tudo.
#
#   bash tools/audio_levels.sh
#
# Métrica: RMS da janela de 100 ms mais alta (para arquivos menores que
# 100 ms usa o RMS médio, senão o zero-padding derruba a leitura), mais
# correção de duração — abaixo de 200 ms o ouvido integra menos energia
# e o som soa mais baixo, ~10 dB por década. Referência: -16 dB.
set -euo pipefail

cd "$(dirname "$0")/.."
REF=-16.0

printf "%-20s %7s %8s %6s %8s   %s\n" ARQUIVO DUR RMS100 DUR+ GANHO "(peak)"
for f in Assets/audio/sfx_*.ogg Assets/audio/sfx_*.mp3 Assets/audio/music_*.mp3; do
	[ -e "$f" ] || continue
	name=$(basename "$f")
	dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f")
	dur_ms=$(echo "$dur * 1000" | bc -l)

	# RMS da janela de 100 ms mais alta
	rms=$(ffmpeg -hide_banner -nostats -i "$f" \
		-af "aresample=48000,asetnsamples=4800,astats=metadata=1:reset=1,ametadata=print:key=lavfi.astats.Overall.RMS_level:file=-" \
		-f null - 2>/dev/null | grep -oE '=\-?[0-9.]+' | tr -d '=' | sort -g | tail -1)
	stats=$(ffmpeg -hide_banner -nostats -i "$f" -af volumedetect -f null - 2>&1)
	mean=$(echo "$stats" | grep mean_volume | grep -oE '\-?[0-9.]+ dB' | cut -d' ' -f1)
	peak=$(echo "$stats" | grep max_volume | grep -oE '\-?[0-9.]+ dB' | cut -d' ' -f1)

	# arquivo mais curto que a janela: o padding de silêncio falseia o RMS
	if (($(echo "$dur_ms < 100" | bc -l))); then rms=$mean; fi

	comp=$(echo "if ($dur_ms < 200) { c = 10 * l(200 / $dur_ms) / l(10); if (c > 8) 8 else c } else 0" | bc -l)
	gain=$(echo "$REF - ($rms + $comp)" | bc -l)
	printf "%-20s %6.0fms %8.1f %6.1f %8.1f   (%s)\n" \
		"$name" "$dur_ms" "$rms" "$comp" "$gain" "$peak"
done
