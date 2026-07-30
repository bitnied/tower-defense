#!/bin/zsh
# Publica o jogo no GitHub Pages com carimbo de versão visível na home.
# Uso: tools/deploy.sh ["mensagem do commit"]
# Passos: carimba BuildInfo.gd -> valida parse -> exporta Web ->
# corrige orientation do manifest -> commit -> push.
set -e
cd "$(dirname "$0")/.."
GODOT="/Applications/Godot.app/Contents/MacOS/Godot"

STAMP="$(date '+%d/%m %H:%M')"
cat > Scenes/main/BuildInfo.gd <<EOF
extends RefCounted
# Carimbo do build mostrado no canto da home, para conferir se o
# webapp (que cacheia builds) já recebeu a versão publicada.
# GERADO pelo tools/deploy.sh a cada publicação — não editar na mão.
const STAMP := "v $STAMP"
EOF

"$GODOT" --headless --path . --script tools/check_parse.gd 2>&1 | grep -q "PARSE_OK" \
	|| { echo "ABORTADO: erro de parse nos scripts"; exit 1; }

"$GODOT" --headless --export-release "Web" docs/index.html
# o Godot só gera "landscape"; primary trava a orientação no Android
sed -i '' 's/"orientation":"landscape"/"orientation":"landscape-primary"/' docs/index.manifest.json

git add -A
git commit -m "${1:-Publica build v $STAMP}"
git push
echo ""
echo "Publicado: v $STAMP  (o carimbo aparece no canto inferior esquerdo da home)"
