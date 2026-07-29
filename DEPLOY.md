# Deploy no GitHub Pages

O build web fica em `docs/` (gerado pelo preset "Web" do Godot).

## Publicação (uma vez)

1. Crie um repositório no GitHub (ex.: `tower-defense`).
2. Envie este projeto para o repositório:
   ```sh
   git remote add origin git@github.com:SEU_USUARIO/tower-defense.git
   git push -u origin main
   ```
3. No GitHub: **Settings → Pages → Build and deployment**
   - Source: *Deploy from a branch*
   - Branch: `main`, pasta `/docs`
4. O jogo ficará em `https://SEU_USUARIO.github.io/tower-defense/`

## Atualizar o build

Sempre que alterar o jogo:

```sh
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --export-release "Web" docs/index.html
sed -i '' 's/"orientation":"landscape"/"orientation":"landscape-primary"/' docs/index.manifest.json
git add -A && git commit -m "Update web build" && git push
```

O `sed` força `landscape-primary` no manifest do PWA (o Godot só gera
"landscape"): no Android instalado, o app já abre deitado com a câmera
à esquerda. O iPhone não tem API de travar orientação — lá o próprio
jogo pede para virar o aparelho quando o notch está do lado errado.

## Notas técnicas

- Export **sem threads** (`variant/thread_support=false`): funciona no GitHub Pages
  (que não envia headers COOP/COEP) e no Safari do iOS.
- Renderer **GL Compatibility**: obrigatório para web e ideal para GPUs mobile.
- PWA habilitado: no iPhone/iPad, use **Compartilhar → Adicionar à Tela de Início**
  para jogar em tela cheia, sem a barra do Safari. No Chrome do iPhone o caminho é
  o mesmo (menu Compartilhar → Adicionar à Tela de Início).
- Botão ⛶ (canto superior direito): entra em fullscreen de verdade onde a API
  existe — iPad, Android e desktop. No iPhone nenhum navegador tem essa API,
  então o botão não aparece lá; o fullscreen no iPhone é só via Tela de Início.
- O PWA usa service worker com cache: depois de publicar uma atualização, quem
  joga pelo ícone da Tela de Início pode precisar fechar e abrir o app 2x para
  receber a versão nova.
- Stretch `canvas_items` + aspect `expand`: preenche qualquer proporção de tela
  (iPhone 11/13/17e ~19.5:9, iPad Air ~4.3:3) sem barras pretas.
